# Update-in-place regression coverage: round 1's suite only ever exercised a
# single apply per record shape, so nothing proved that changing a record's
# ttl or answer set on a second apply actually updates state instead of
# erroring or silently keeping the old values. Run blocks in the same test
# file share state by default, so this drives a real create-then-update
# sequence against the mocked provider.
#
# `mock_provider` requires Terraform >= 1.7 (OpenTofu >= 1.7) to run.

mock_provider "aws" {}

variables {
  domain_name = "example.com"
}

run "create_initial_record" {
  variables {
    records = {
      www = {
        name    = "www.example.com"
        type    = "A"
        records = ["192.0.2.10"]
      }
    }
  }

  assert {
    condition     = aws_route53_record.this["www"].ttl == 300
    error_message = "Initial apply must use the default ttl of 300."
  }
}

run "update_ttl_and_records_in_place" {
  variables {
    records = {
      www = {
        name    = "www.example.com"
        type    = "A"
        ttl     = 600
        records = ["192.0.2.10", "192.0.2.11"]
      }
    }
  }

  assert {
    condition     = aws_route53_record.this["www"].ttl == 600
    error_message = "A changed ttl must be applied on an update, not just on initial create."
  }

  assert {
    condition     = length(aws_route53_record.this["www"].records) == 2
    error_message = "An updated records list must be applied on an update, not just on initial create."
  }
}

run "convert_record_to_alias_in_place" {
  variables {
    records = {
      www = {
        name = "www.example.com"
        type = "A"
        alias = {
          name    = "d111111abcdef8.cloudfront.net"
          zone_id = "Z2FDTNDATAQYW2"
        }
      }
    }
  }

  assert {
    condition     = aws_route53_record.this["www"].ttl == null
    error_message = "Switching an existing ordinary record to an alias must clear its ttl."
  }

  assert {
    condition     = aws_route53_record.this["www"].records == null
    error_message = "Switching an existing ordinary record to an alias must clear its records list."
  }

  assert {
    condition     = one(aws_route53_record.this["www"].alias).zone_id == "Z2FDTNDATAQYW2"
    error_message = "The alias block must reflect the updated alias target."
  }
}
