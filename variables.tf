variable "domain_name" {
  description = "Fully qualified domain name for the hosted zone."
  type        = string

  validation {
    condition     = length(trimspace(var.domain_name)) > 0
    error_message = "The domain_name must not be empty."
  }
}

variable "comment" {
  description = "Comment attached to the hosted zone."
  type        = string
  default     = "Managed by Terraform"
}

variable "force_destroy" {
  description = "Whether to destroy all records in the zone when the zone is deleted."
  type        = bool
  default     = false
}

variable "records" {
  description = <<-EOT
    Map of DNS records to create in the zone, keyed by an arbitrary name.

    Set exactly one of `records` (an ordinary record) or `alias` (a Route 53
    alias record). `ttl` applies to ordinary records only and defaults to 300;
    alias records inherit the TTL of their target.

    `allow_overwrite` defaults to `false`. Leave it that way unless you are
    deliberately adopting a record that already exists in the zone: when it is
    `true`, an apply overwrites the existing record without warning.
  EOT

  type = map(object({
    name            = string
    type            = string
    ttl             = optional(number)
    records         = optional(list(string))
    allow_overwrite = optional(bool, false)
    alias = optional(object({
      name                   = string
      zone_id                = string
      evaluate_target_health = optional(bool, false)
    }))
  }))
  default = {}

  validation {
    condition = alltrue([
      for v in var.records : contains(
        [
          "A", "AAAA", "CAA", "CNAME", "DS", "HTTPS", "MX", "NAPTR", "NS",
          "PTR", "SOA", "SPF", "SRV", "SSHFP", "SVCB", "TLSA", "TXT",
        ],
        v.type
      )
    ])
    error_message = "Each record `type` must be a record type supported by Route 53 (A, AAAA, CAA, CNAME, DS, HTTPS, MX, NAPTR, NS, PTR, SOA, SPF, SRV, SSHFP, SVCB, TLSA, TXT)."
  }

  validation {
    condition     = alltrue([for v in var.records : (v.records == null) != (v.alias == null)])
    error_message = "Each record must set exactly one of `records` or `alias`."
  }

  validation {
    condition     = alltrue([for v in var.records : length(coalesce(v.records, ["placeholder"])) > 0])
    error_message = "`records` must contain at least one value when it is set."
  }

  validation {
    condition     = alltrue([for v in var.records : v.alias == null || v.ttl == null])
    error_message = "`ttl` cannot be set on an alias record; Route 53 uses the TTL of the alias target."
  }

  validation {
    condition = alltrue([
      for v in var.records : coalesce(v.ttl, 300) >= 0 && coalesce(v.ttl, 300) <= 172800
    ])
    error_message = "`ttl` must be between 0 and 172800 seconds."
  }
}

variable "tags" {
  description = "Tags applied to the hosted zone."
  type        = map(string)
  default     = {}
}
