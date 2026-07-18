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
  }

  tags = {
    Environment = "sandbox"
    ManagedBy   = "terraform"
  }
}

output "zone_name_servers" {
  value = module.route53.name_servers
}
