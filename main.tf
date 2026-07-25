locals {
  # Normalised zone apex, used to reject CNAMEs at the apex.
  zone_apex = lower(trimsuffix(var.domain_name, "."))
}

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

  # Route 53 takes the TTL and the answer set from the alias target, so both
  # must be unset on alias records.
  ttl     = each.value.alias == null ? coalesce(each.value.ttl, 300) : null
  records = each.value.alias == null ? each.value.records : null

  # Defaults to false (see variables.tf) so an apply can never silently take
  # over a record that already exists in the zone.
  allow_overwrite = each.value.allow_overwrite

  dynamic "alias" {
    for_each = each.value.alias == null ? [] : [each.value.alias]

    content {
      name                   = alias.value.name
      zone_id                = alias.value.zone_id
      evaluate_target_health = alias.value.evaluate_target_health
    }
  }

  lifecycle {
    # A CNAME is invalid at the zone apex (RFC 1034). Route 53 only rejects it
    # at apply time; catching it during plan gives a usable error instead.
    precondition {
      condition = each.value.type != "CNAME" || !contains(
        ["", "@", local.zone_apex],
        lower(trimsuffix(each.value.name, "."))
      )
      error_message = "Record \"${each.key}\": a CNAME is not valid at the zone apex (${var.domain_name}). Use an alias record instead."
    }
  }
}
