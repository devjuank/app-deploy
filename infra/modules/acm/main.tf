locals {
  base_tags = merge({
    Project     = var.project_name,
    Environment = var.environment,
  }, var.tags)

  primary_domain = "app.${var.subdomain}.${var.hosted_zone_name}"
}

resource "aws_acm_certificate" "this" {
  domain_name               = local.primary_domain
  validation_method         = "DNS"
  subject_alternative_names = var.additional_sans

  lifecycle {
    create_before_destroy = true
  }

  tags = merge(local.base_tags, {
    Name = "${var.project_name}-${var.environment}-app-cert"
  })
}

resource "aws_route53_record" "validation" {
  for_each = {
    for dvo in aws_acm_certificate.this.domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      type   = dvo.resource_record_type
      record = dvo.resource_record_value
    }
  }

  zone_id = var.hosted_zone_id
  name    = each.value.name
  type    = each.value.type
  ttl     = 300
  records = [each.value.record]
}

resource "aws_acm_certificate_validation" "this" {
  certificate_arn         = aws_acm_certificate.this.arn
  validation_record_fqdns = [for record in aws_route53_record.validation : record.fqdn]
}

output "certificate_arn" {
  description = "ARN of the validated ACM certificate."
  value       = aws_acm_certificate.this.arn
}

output "domain_name" {
  description = "Primary domain covered by the certificate."
  value       = local.primary_domain
}
