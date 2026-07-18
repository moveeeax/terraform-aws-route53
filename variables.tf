variable "domain_name" {
  description = "Fully qualified domain name for the hosted zone."
  type        = string
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
  description = "Map of DNS records to create in the zone, keyed by an arbitrary name."
  type = map(object({
    name    = string
    type    = string
    ttl     = optional(number, 300)
    records = list(string)
  }))
  default = {}
}

variable "tags" {
  description = "Tags applied to the hosted zone."
  type        = map(string)
  default     = {}
}
