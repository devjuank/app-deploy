locals {
  base_tags = merge({
    Project     = var.project_name,
    Environment = var.environment,
  }, var.tags)

  oidc_provider_host = var.oidc_provider_url != null ? replace(var.oidc_provider_url, "https://", "") : null
}

# EKS control plane role
resource "aws_iam_role" "eks_cluster" {
  count = var.create_cluster_role ? 1 : 0

  name = "${var.project_name}-${var.environment}-eks-cluster"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Principal = {
          Service = "eks.amazonaws.com"
        },
        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = merge(local.base_tags, {
    Name = "${var.project_name}-${var.environment}-eks-cluster"
  })
}

resource "aws_iam_role_policy_attachment" "eks_cluster_policy" {
  count      = var.create_cluster_role ? 1 : 0
  role       = aws_iam_role.eks_cluster[0].name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
}

resource "aws_iam_role_policy_attachment" "eks_vpc_controller" {
  count      = var.create_cluster_role ? 1 : 0
  role       = aws_iam_role.eks_cluster[0].name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSVPCCNIPolicy"
}

# Worker node role shared by node groups
resource "aws_iam_role" "eks_nodes" {
  count = var.create_node_role ? 1 : 0

  name = "${var.project_name}-${var.environment}-eks-nodes"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Principal = {
          Service = "ec2.amazonaws.com"
        },
        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = merge(local.base_tags, {
    Name = "${var.project_name}-${var.environment}-eks-nodes"
  })
}

resource "aws_iam_role_policy_attachment" "nodes_worker" {
  count      = var.create_node_role ? 1 : 0
  role       = aws_iam_role.eks_nodes[0].name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
}

resource "aws_iam_role_policy_attachment" "nodes_cni" {
  count      = var.create_node_role ? 1 : 0
  role       = aws_iam_role.eks_nodes[0].name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
}

resource "aws_iam_role_policy_attachment" "nodes_ecr" {
  count      = var.create_node_role ? 1 : 0
  role       = aws_iam_role.eks_nodes[0].name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}

# IAM Roles for Service Accounts (IRSA)
locals {
  irsa_enabled = var.enable_irsa && var.oidc_provider_arn != null && var.oidc_provider_url != null
}

data "aws_iam_policy_document" "irsa_assume" {
  count = local.irsa_enabled ? 1 : 0

  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = [var.oidc_provider_arn]
    }

    condition {
      test     = "StringEquals"
      variable = "${local.oidc_provider_host}:aud"
      values   = ["sts.amazonaws.com"]
    }
  }
}

locals {
  irsa_service_accounts = local.irsa_enabled ? {
    aws_load_balancer_controller = {
      name               = "aws-load-balancer-controller"
      namespace          = "kube-system"
      policy_attachments = ["arn:aws:iam::aws:policy/AWSLoadBalancerControllerIAMPolicy"]
      inline_policy      = null
    }
    external_dns = {
      name               = "external-dns"
      namespace          = "kube-system"
      policy_attachments = []
      inline_policy = jsonencode({
        Version = "2012-10-17",
        Statement = [
          {
            Effect = "Allow",
            Action = [
              "route53:ChangeResourceRecordSets"
            ],
            Resource = "arn:aws:route53:::hostedzone/*"
          },
          {
            Effect = "Allow",
            Action = [
              "route53:ListHostedZones",
              "route53:ListResourceRecordSets",
              "route53:ListTagsForResource"
            ],
            Resource = "*"
          }
        ]
      })
    }
    external_secrets = {
      name               = "external-secrets"
      namespace          = "external-secrets"
      policy_attachments = []
      inline_policy = jsonencode({
        Version = "2012-10-17",
        Statement = [
          {
            Effect = "Allow",
            Action = [
              "secretsmanager:GetSecretValue",
              "secretsmanager:DescribeSecret"
            ],
            Resource = "arn:aws:secretsmanager:*:${var.account_id}:secret:${var.project_name}/${var.environment}/*"
          },
          {
            Effect   = "Allow",
            Action   = "secretsmanager:ListSecrets",
            Resource = "*"
          }
        ]
      })
    }
    cluster_autoscaler = {
      name               = "cluster-autoscaler"
      namespace          = "kube-system"
      policy_attachments = []
      inline_policy = jsonencode({
        Version = "2012-10-17",
        Statement = [
          {
            Effect = "Allow",
            Action = [
              "autoscaling:DescribeAutoScalingGroups",
              "autoscaling:DescribeAutoScalingInstances",
              "autoscaling:DescribeLaunchConfigurations",
              "autoscaling:DescribeTags",
              "ec2:DescribeLaunchTemplateVersions",
              "ec2:DescribeInstances",
              "ec2:DescribeImages",
              "ec2:DescribeInstanceTypes",
              "ec2:DescribeSubnets",
              "ec2:DescribeSecurityGroups",
              "ec2:DescribeInstanceStatus",
              "eks:DescribeNodegroup"
            ],
            Resource = "*"
          },
          {
            Effect = "Allow",
            Action = [
              "autoscaling:SetDesiredCapacity",
              "autoscaling:TerminateInstanceInAutoScalingGroup",
              "autoscaling:UpdateAutoScalingGroup"
            ],
            Resource = "*"
          }
        ]
      })
    }
  } : {}
}

locals {
  irsa_managed_policies = local.irsa_enabled ? {
    for idx, item in flatten([
      for key, value in local.irsa_service_accounts : [
        for policy in value.policy_attachments : {
          service    = key
          policy_arn = policy
        }
      ]
    ]) : "${item.service}-${idx}" => item
  } : {}
}

resource "aws_iam_role" "irsa" {
  for_each = local.irsa_service_accounts

  name = "${var.project_name}-${var.environment}-${each.key}"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Principal = {
          Federated = var.oidc_provider_arn
        },
        Action = "sts:AssumeRoleWithWebIdentity",
        Condition = {
          StringEquals = {
            "${local.oidc_provider_host}:aud" = "sts.amazonaws.com",
            "${local.oidc_provider_host}:sub" = "system:serviceaccount:${each.value.namespace}:${each.value.name}"
          }
        }
      }
    ]
  })

  tags = merge(local.base_tags, {
    Name = "${var.project_name}-${var.environment}-${each.key}"
  })
}

resource "aws_iam_role_policy_attachment" "irsa_managed" {
  for_each = local.irsa_managed_policies

  role       = aws_iam_role.irsa[each.value.service].name
  policy_arn = each.value.policy_arn
}

resource "aws_iam_role_policy" "irsa_inline" {
  for_each = {
    for k, v in local.irsa_service_accounts : k => v if v.inline_policy != null
  }

  role   = aws_iam_role.irsa[each.key].id
  name   = "${var.project_name}-${var.environment}-${each.key}-policy"
  policy = each.value.inline_policy
}

output "cluster_role_arn" {
  description = "IAM role ARN for the EKS control plane."
  value       = var.create_cluster_role ? aws_iam_role.eks_cluster[0].arn : null
}

output "node_role_arn" {
  description = "IAM role ARN for EKS managed node groups."
  value       = var.create_node_role ? aws_iam_role.eks_nodes[0].arn : null
}

output "irsa_role_arns" {
  description = "Map of service account logical names to IAM role ARNs."
  value       = { for k, role in aws_iam_role.irsa : k => role.arn }
}
