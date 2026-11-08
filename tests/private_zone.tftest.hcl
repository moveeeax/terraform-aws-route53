# Private hosted zones: VPC associations rendered as inline vpc blocks.
#
# `mock_provider` requires Terraform >= 1.7 (OpenTofu >= 1.7) to run.

mock_provider "aws" {}

variables {
  domain_name = "internal.example.com"
}

run "zone_is_public_by_default" {
  command = plan

  assert {
    condition     = length(aws_route53_zone.this.vpc) == 0
    error_message = "With no vpc_associations the zone must stay public; existing public zones cannot take a vpc block."
  }

  assert {
    condition     = output.is_private == false
    error_message = "is_private must be false for a public zone."
  }
}

run "associates_every_listed_vpc" {
  command = plan

  variables {
    vpc_associations = [
      { vpc_id = "vpc-0123456789abcdef0" },
      { vpc_id = "vpc-0fedcba9876543210", vpc_region = "eu-west-1" },
    ]
  }

  assert {
    condition     = length(aws_route53_zone.this.vpc) == 2
    error_message = "Every entry in vpc_associations must become a vpc block."
  }

  assert {
    condition     = contains([for v in aws_route53_zone.this.vpc : v.vpc_id], "vpc-0123456789abcdef0")
    error_message = "The vpc block must carry the vpc_id from vpc_associations."
  }

  assert {
    condition     = one([for v in aws_route53_zone.this.vpc : v.vpc_region if v.vpc_id == "vpc-0fedcba9876543210"]) == "eu-west-1"
    error_message = "An explicit vpc_region must be passed through."
  }

  assert {
    condition     = output.is_private == true
    error_message = "is_private must be true once the zone has a VPC association."
  }
}

run "private_zone_still_takes_records" {
  command = plan

  variables {
    vpc_associations = [{ vpc_id = "vpc-0123456789abcdef0" }]
    records = {
      db = {
        name    = "db.internal.example.com"
        type    = "A"
        records = ["10.0.1.10"]
      }
    }
  }

  assert {
    condition     = aws_route53_record.this["db"].records == toset(["10.0.1.10"])
    error_message = "Records must be created in a private zone exactly as in a public one."
  }
}

run "rejects_a_malformed_vpc_id" {
  command = plan

  variables {
    vpc_associations = [{ vpc_id = "my-vpc" }]
  }

  expect_failures = [var.vpc_associations]
}

run "rejects_a_duplicate_vpc" {
  command = plan

  variables {
    vpc_associations = [
      { vpc_id = "vpc-0123456789abcdef0" },
      { vpc_id = "vpc-0123456789abcdef0", vpc_region = "eu-west-1" },
    ]
  }

  expect_failures = [var.vpc_associations]
}
