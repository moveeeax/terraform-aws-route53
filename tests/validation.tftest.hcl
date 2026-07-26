# Input-validation tests: every one of these must be rejected at plan time
# rather than blowing up mid-apply against the Route 53 API.
#
# `mock_provider` requires Terraform >= 1.7 (OpenTofu >= 1.7) to run.

mock_provider "aws" {}

variables {
  domain_name = "example.com"
}

run "rejects_unknown_record_type" {
  command = plan

  variables {
    records = {
      bad = {
        name    = "bad.example.com"
        type    = "ALIAS"
        records = ["192.0.2.10"]
      }
    }
  }

  expect_failures = [var.records]
}

run "rejects_record_with_both_records_and_alias" {
  command = plan

  variables {
    records = {
      both = {
        name    = "both.example.com"
        type    = "A"
        records = ["192.0.2.10"]
        alias = {
          name    = "d111111abcdef8.cloudfront.net"
          zone_id = "Z2FDTNDATAQYW2"
        }
      }
    }
  }

  expect_failures = [var.records]
}

run "rejects_record_with_neither_records_nor_alias" {
  command = plan

  variables {
    records = {
      empty = {
        name = "empty.example.com"
        type = "A"
      }
    }
  }

  expect_failures = [var.records]
}

run "rejects_empty_records_list" {
  command = plan

  variables {
    records = {
      blank = {
        name    = "blank.example.com"
        type    = "A"
        records = []
      }
    }
  }

  expect_failures = [var.records]
}

run "rejects_ttl_on_alias_record" {
  command = plan

  variables {
    records = {
      apex = {
        name = "example.com"
        type = "A"
        ttl  = 60
        alias = {
          name    = "d111111abcdef8.cloudfront.net"
          zone_id = "Z2FDTNDATAQYW2"
        }
      }
    }
  }

  expect_failures = [var.records]
}

run "rejects_out_of_range_ttl" {
  command = plan

  variables {
    records = {
      long = {
        name    = "long.example.com"
        type    = "A"
        ttl     = 999999
        records = ["192.0.2.10"]
      }
    }
  }

  expect_failures = [var.records]
}

run "rejects_cname_at_zone_apex" {
  command = plan

  variables {
    records = {
      apex = {
        name    = "example.com."
        type    = "CNAME"
        records = ["target.example.net"]
      }
    }
  }

  expect_failures = [aws_route53_record.this]
}

run "rejects_empty_domain_name" {
  command = plan

  variables {
    domain_name = "  "
  }

  expect_failures = [var.domain_name]
}

run "rejects_blank_record_name" {
  command = plan

  variables {
    records = {
      blank_name = {
        name    = "   "
        type    = "A"
        records = ["192.0.2.10"]
      }
    }
  }

  expect_failures = [var.records]
}

run "rejects_blank_entry_in_records_list" {
  command = plan

  variables {
    records = {
      blank_entry = {
        name    = "blank.example.com"
        type    = "A"
        records = ["192.0.2.10", "  "]
      }
    }
  }

  expect_failures = [var.records]
}

run "rejects_blank_alias_fields" {
  command = plan

  variables {
    records = {
      apex = {
        name = "example.com"
        type = "A"
        alias = {
          name    = ""
          zone_id = "Z2FDTNDATAQYW2"
        }
      }
    }
  }

  expect_failures = [var.records]
}

run "rejects_duplicate_name_and_type" {
  command = plan

  variables {
    records = {
      www_one = {
        name    = "www.example.com"
        type    = "A"
        records = ["192.0.2.10"]
      }
      www_two = {
        name    = "www.example.com."
        type    = "A"
        records = ["192.0.2.20"]
      }
    }
  }

  expect_failures = [var.records]
}
