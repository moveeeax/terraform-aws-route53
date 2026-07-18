resource "aws_route53_zone" "this" {
  name          = var.domain_name
  comment       = var.comment
  force_destroy = var.force_destroy

  tags = var.tags
}

resource "aws_route53_record" "this" {
  for_each = var.records

  zone_id = aws_route53_zone.this.zone_id
  name    = each.value.name
  type    = each.value.type
  ttl     = each.value.ttl
  records = each.value.records
}
