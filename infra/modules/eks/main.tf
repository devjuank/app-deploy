locals {
  cluster_name = "${var.project_name}-${var.environment}"
  base_tags = merge({
    Project     = var.project_name,
    Environment = var.environment,
  }, var.tags)
}

resource "aws_cloudwatch_log_group" "cluster" {
  name              = "/aws/eks/${local.cluster_name}/cluster"
  retention_in_days = 14

  tags = merge(local.base_tags, {
    Name = "${local.cluster_name}-eks-logs"
  })
}

resource "aws_security_group" "cluster" {
  name        = "${local.cluster_name}-cluster-sg"
  description = "Security group for EKS control plane"
  vpc_id      = var.vpc_id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(local.base_tags, {
    Name = "${local.cluster_name}-cluster-sg"
  })
}

resource "aws_security_group" "nodes" {
  name        = "${local.cluster_name}-nodes-sg"
  description = "Security group for EKS worker nodes"
  vpc_id      = var.vpc_id

  ingress {
    description = "Node to node communication"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    self        = true
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(local.base_tags, {
    Name = "${local.cluster_name}-nodes-sg"
  })
}

resource "aws_security_group_rule" "cluster_from_nodes" {
  type                     = "ingress"
  description              = "Allow worker nodes to communicate with the control plane"
  from_port                = 443
  to_port                  = 443
  protocol                 = "tcp"
  security_group_id        = aws_security_group.cluster.id
  source_security_group_id = aws_security_group.nodes.id
}

resource "aws_security_group_rule" "nodes_from_cluster" {
  type                     = "ingress"
  description              = "Allow control plane to reach kubelets"
  from_port                = 1025
  to_port                  = 65535
  protocol                 = "tcp"
  security_group_id        = aws_security_group.nodes.id
  source_security_group_id = aws_security_group.cluster.id
}

resource "aws_security_group_rule" "nodes_cluster_health" {
  type                     = "ingress"
  description              = "Allow control plane to reach kubelet health checks"
  from_port                = 443
  to_port                  = 443
  protocol                 = "tcp"
  security_group_id        = aws_security_group.nodes.id
  source_security_group_id = aws_security_group.cluster.id
}

resource "aws_eks_cluster" "this" {
  name     = local.cluster_name
  role_arn = var.cluster_role_arn
  version  = var.cluster_version

  vpc_config {
    subnet_ids              = concat(var.public_subnet_ids, var.private_subnet_ids)
    security_group_ids      = [aws_security_group.cluster.id]
    endpoint_public_access  = true
    endpoint_private_access = true
    public_access_cidrs     = var.allowed_cidrs_admin
  }

  kubernetes_network_config {
    ip_family = "ipv4"
  }

  enabled_cluster_log_types = ["api", "audit", "authenticator", "controllerManager", "scheduler"]

  tags = merge(local.base_tags, {
    Name = local.cluster_name
  })

  depends_on = [
    aws_cloudwatch_log_group.cluster,
    aws_security_group_rule.cluster_from_nodes,
  ]
}

resource "aws_eks_node_group" "on_demand" {
  cluster_name    = aws_eks_cluster.this.name
  node_group_name = "${local.cluster_name}-on-demand"
  node_role_arn   = var.node_role_arn
  subnet_ids      = var.private_subnet_ids
  capacity_type   = "ON_DEMAND"
  version         = var.cluster_version

  scaling_config {
    desired_size = var.eks_on_demand_min
    max_size     = var.eks_on_demand_max
    min_size     = var.eks_on_demand_min
  }

  update_config {
    max_unavailable = 1
  }

  ami_type       = "AL2_x86_64"
  disk_size      = var.node_disk_size
  instance_types = [var.node_instance_type]

  labels = {
    lifecycle = "on-demand"
  }

  tags = merge(local.base_tags, {
    Name = "${local.cluster_name}-on-demand"
  })

  depends_on = [aws_eks_cluster.this]
}

resource "aws_eks_node_group" "spot" {
  cluster_name    = aws_eks_cluster.this.name
  node_group_name = "${local.cluster_name}-spot"
  node_role_arn   = var.node_role_arn
  subnet_ids      = var.private_subnet_ids
  capacity_type   = "SPOT"
  version         = var.cluster_version

  scaling_config {
    desired_size = var.eks_spot_min
    max_size     = var.eks_spot_max
    min_size     = var.eks_spot_min
  }

  update_config {
    max_unavailable = 1
  }

  ami_type       = "AL2_x86_64"
  disk_size      = var.node_disk_size
  instance_types = [var.node_instance_type]

  labels = {
    lifecycle = "spot"
  }

  tags = merge(local.base_tags, {
    Name = "${local.cluster_name}-spot"
  })

  depends_on = [aws_eks_cluster.this]
}

data "tls_certificate" "oidc" {
  url = aws_eks_cluster.this.identity[0].oidc[0].issuer
}

resource "aws_iam_openid_connect_provider" "eks" {
  url             = aws_eks_cluster.this.identity[0].oidc[0].issuer
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = [data.tls_certificate.oidc.certificates[0].sha1_fingerprint]

  tags = merge(local.base_tags, {
    Name = "${local.cluster_name}-oidc"
  })
}

output "cluster_name" {
  description = "Name of the EKS cluster."
  value       = aws_eks_cluster.this.name
}

output "cluster_endpoint" {
  description = "API server endpoint for the EKS cluster."
  value       = aws_eks_cluster.this.endpoint
}

output "cluster_certificate" {
  description = "Certificate authority data for the cluster."
  value       = aws_eks_cluster.this.certificate_authority[0].data
}

output "cluster_security_group_id" {
  description = "Security group ID used by the EKS control plane."
  value       = aws_security_group.cluster.id
}

output "node_security_group_id" {
  description = "Security group ID associated with worker nodes."
  value       = aws_security_group.nodes.id
}

output "oidc_provider_arn" {
  description = "ARN of the IAM OIDC provider for IRSA."
  value       = aws_iam_openid_connect_provider.eks.arn
}

output "oidc_provider_url" {
  description = "Issuer URL for the IAM OIDC provider."
  value       = aws_iam_openid_connect_provider.eks.url
}

output "private_subnet_ids" {
  description = "Private subnet IDs reused by consumers."
  value       = var.private_subnet_ids
}

output "public_subnet_ids" {
  description = "Public subnet IDs reused by consumers."
  value       = var.public_subnet_ids
}
