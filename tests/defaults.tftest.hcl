# Behavioural tests for the module's defaults and alias handling.
#
# These run entirely offline against a mocked AWS provider, so no credentials
# and no network access are needed. `mock_provider` requires Terraform >= 1.7
# (OpenTofu >= 1.7) to *run the tests*; the module itself still supports the
# >= 1.5 declared in versions.tf.

mock_provider "aws" {}

variables {
  domain_name = "example.com"
}

run "zone_defaults_are_safe" {
  assert {
    condition     = aws_route53_zone.this.force_destroy == false
    error_message = "force_destroy must default to false so a destroy cannot wipe records that were not created here."
  }

  assert {
    condition     = aws_route53_zone.this.name == "example.com"
    error_message = "The zone name must come straight from var.domain_name."
  }
}

run "records_do_not_overwrite_by_default" {
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
    condition     = aws_route53_record.this["www"].allow_overwrite == false
    error_message = "allow_overwrite must default to false; otherwise an apply silently hijacks a pre-existing record."
  }

  assert {
    condition     = aws_route53_record.this["www"].ttl == 300
    error_message = "An ordinary record with no explicit ttl must fall back to 300."
  }
}

run "allow_overwrite_is_opt_in" {
  variables {
    records = {
      adopt = {
        name            = "adopt.example.com"
        type            = "A"
        records         = ["192.0.2.20"]
        allow_overwrite = true
      }
    }
  }

  assert {
    condition     = aws_route53_record.this["adopt"].allow_overwrite == true
    error_message = "allow_overwrite must be settable per record for deliberate adoption."
  }
}

run "alias_records_omit_ttl_and_records" {
  variables {
    records = {
      apex = {
        name = "example.com"
        type = "A"
        alias = {
          name    = "d111111abcdef8.cloudfront.net"
          zone_id = "Z2FDTNDATAQYW2"
        }
      }
    }
  }

  assert {
    condition     = aws_route53_record.this["apex"].ttl == null
    error_message = "Alias records must not carry a ttl; Route 53 rejects the combination."
  }

  assert {
    condition     = aws_route53_record.this["apex"].records == null
    error_message = "Alias records must not carry a records list; Route 53 rejects the combination."
  }

  assert {
    condition     = one(aws_route53_record.this["apex"].alias).zone_id == "Z2FDTNDATAQYW2"
    error_message = "The alias block must be rendered from the record's alias object."
  }

  assert {
    condition     = one(aws_route53_record.this["apex"].alias).evaluate_target_health == false
    error_message = "evaluate_target_health must default to false."
  }
}
