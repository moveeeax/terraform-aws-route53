output "zone_id" {
  description = "ID of the hosted zone."
  value       = aws_route53_zone.this.zone_id
}

output "arn" {
  description = "ARN of the hosted zone."
  value       = aws_route53_zone.this.arn
}

output "name" {
  description = "Domain name of the hosted zone."
  value       = aws_route53_zone.this.name
}

output "name_servers" {
  description = "Name servers assigned to the hosted zone."
  value       = aws_route53_zone.this.name_servers
}

output "record_names" {
  description = "Names of the DNS records created in the zone."
  value       = [for r in aws_route53_record.this : r.fqdn]
}
