locals {
  base_tags = merge({
    Project     = var.project_name,
    Environment = var.environment,
  }, var.tags)
}

resource "aws_route53_zone" "this" {
  name = var.hosted_zone_name

  tags = merge(local.base_tags, {
    Name = "${var.project_name}-${var.environment}-zone"
  })
}

output "zone_id" {
  description = "ID of the hosted zone."
  value       = aws_route53_zone.this.zone_id
}

output "name_servers" {
  description = "Name servers for the hosted zone."
  value       = aws_route53_zone.this.name_servers
}
