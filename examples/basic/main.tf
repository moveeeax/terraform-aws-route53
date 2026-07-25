terraform {
  required_version = ">= 1.5"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0"
    }
  }
}

variable "region" {
  description = "AWS region for the provider."
  type        = string
  default     = "us-east-1"
}

provider "aws" {
  region = var.region
}

module "route53" {
  source = "../.."

  domain_name = "example.com"

  records = {
    www = {
      name    = "www.example.com"
      type    = "A"
      ttl     = 300
      records = ["192.0.2.10"]
    }

    # A CNAME cannot exist at the zone apex, so point the apex at the
    # distribution with an alias record instead. Z2FDTNDATAQYW2 is the fixed
    # hosted zone ID that AWS publishes for every CloudFront distribution.
    apex = {
      name = "example.com"
      type = "A"
      alias = {
        name    = "d111111abcdef8.cloudfront.net"
        zone_id = "Z2FDTNDATAQYW2"
      }
    }
  }

  tags = {
    Environment = "sandbox"
    ManagedBy   = "terraform"
  }
}

output "zone_name_servers" {
  value = module.route53.name_servers
}
