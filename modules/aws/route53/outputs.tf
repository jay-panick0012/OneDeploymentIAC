###############################################################################
# AWS Route53 Module – outputs.tf
###############################################################################

output "zone_id" {
  description = "ID of the Route53 hosted zone."
  value       = aws_route53_zone.this.zone_id
}

output "name_servers" {
  description = "List of name servers assigned to the zone. Always empty for private hosted zones."
  value       = var.private_zone ? [] : aws_route53_zone.this.name_servers
}

output "zone_arn" {
  description = "ARN of the Route53 hosted zone."
  value       = aws_route53_zone.this.arn
}
