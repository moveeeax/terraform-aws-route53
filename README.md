# terraform-aws-route53

Terraform module that manages an [Amazon Route
53](https://aws.amazon.com/route53/) hosted zone. It creates a single hosted
zone, public by default or private when given VPCs, and renders DNS records
from a map variable, exposing the zone's name servers for delegation at the
registrar.

## Usage

```hcl
module "route53" {
  source = "github.com/moveeeax/terraform-aws-route53?ref=v1.0.0" # pin to a release tag

  domain_name = "example.com"

  records = {
    www = {
      name    = "www.example.com"
      type    = "A"
      records = ["192.0.2.10"]
    }

    # A CNAME is invalid at the zone apex — use an alias record instead.
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
    Environment = "production"
    ManagedBy   = "terraform"
  }
}
```

A runnable example lives in [`examples/basic`](examples/basic).

### Record schema

Each entry in `records` accepts:

| Field             | Type           | Default | Notes                                                                 |
|-------------------|----------------|---------|-----------------------------------------------------------------------|
| `name`            | `string`       | n/a     | Record name. Relative names are expanded against the zone.            |
| `type`            | `string`       | n/a     | Any record type Route 53 supports (`A`, `AAAA`, `CNAME`, `MX`, …).    |
| `ttl`             | `number`       | `300`   | Ordinary records only. Must be unset on alias records.                |
| `records`         | `list(string)` | n/a     | Ordinary records only. Set exactly one of `records` or `alias`.       |
| `allow_overwrite` | `bool`         | `false` | See below.                                                            |
| `alias`           | `object`       | `null`  | `{ name, zone_id, evaluate_target_health = false }`.                  |

Invalid combinations (`records` **and** `alias`, neither of them, a `ttl` on an
alias record, an out-of-range `ttl`, an unknown type, a `CNAME` at the zone
apex, a blank `name`/`records` entry/`alias` field, or two entries sharing the
same `name` and `type`) are rejected at plan time rather than failing
part-way through an apply.

### `allow_overwrite`

`allow_overwrite` defaults to `false`, which means an apply **fails** rather
than silently replacing a record that already exists in the zone. Only set it
to `true` on a record you are deliberately adopting into Terraform — with it
enabled, the module will overwrite whatever is already there without warning.

## Private hosted zones

Pass `vpc_associations` to make the zone private. It then resolves only inside
the listed VPCs:

```hcl
module "internal_dns" {
  source = "github.com/moveeeax/terraform-aws-route53?ref=v1.0.0" # pin to a release tag

  domain_name = "internal.example.com"

  vpc_associations = [
    { vpc_id = "vpc-0123456789abcdef0" },
    { vpc_id = "vpc-0fedcba9876543210", vpc_region = "eu-west-1" },
  ]

  records = {
    db = {
      name    = "db.internal.example.com"
      type    = "A"
      records = ["10.0.1.10"]
    }
  }
}
```

`vpc_region` defaults to the provider's region. The `is_private` output is
`true` when at least one VPC is listed.

Things to know before switching:

* Public versus private is fixed when the zone is created. The AWS provider
  does not mark the change as a replacement: adding the first VPC to an
  existing public zone, or removing the last VPC from a private one, plans as
  an in-place update and then fails at apply time when Route 53 refuses the
  association change. Create a separate module instance for internal DNS
  instead of converting a zone. The default (`[]`) keeps existing zones public
  and their plan unchanged. Adding or removing VPCs on a zone that is already
  private, while at least one stays, is a normal in-place update.
* VPCs are attached as inline `vpc` blocks on `aws_route53_zone`, and those
  blocks are the complete list. Do not also create
  `aws_route53_zone_association` resources for this zone: the module would see
  them as drift and remove them on the next apply. The cross-account case
  (associating a VPC owned by another account, which needs
  `aws_route53_vpc_association_authorization` plus a separate association) is
  not supported by this module for the same reason.
* DNSSEC signing is not available for private zones. The module does not
  manage DNSSEC at all (see below), so there is nothing to turn off, but do not
  attach a `aws_route53_hosted_zone_dnssec` to a private zone from outside.

## Requirements

| Name      | Version  |
|-----------|----------|
| terraform | >= 1.5   |
| aws       | >= 5.0   |

## Inputs

| Name            | Description                                             | Type                | Default   | Required |
|-----------------|---------------------------------------------------------|---------------------|-----------|:--------:|
| `domain_name`   | Fully qualified domain name for the hosted zone.        | `string`            | n/a       |   yes    |
| `comment`       | Comment attached to the hosted zone.                    | `string`            | `"Managed by Terraform"` | no |
| `force_destroy` | Destroy all records when the zone is deleted.           | `bool`              | `false`   |    no    |
| `vpc_associations` | VPCs to associate; any entry makes the zone private (see [private hosted zones](#private-hosted-zones)). | `list(object({ vpc_id = string, vpc_region = optional(string) }))` | `[]` | no |
| `records`       | Map of DNS records to create (see [schema](#record-schema)). | `map(object(...))` | `{}` |    no    |
| `tags`          | Tags applied to the hosted zone.                        | `map(string)`       | `{}`      |    no    |

## Outputs

| Name           | Description                                        |
|----------------|----------------------------------------------------|
| `zone_id`      | ID of the hosted zone.                             |
| `arn`          | ARN of the hosted zone.                            |
| `name`         | Domain name of the hosted zone.                    |
| `is_private`   | Whether the zone is private (has at least one VPC association). |
| `name_servers` | Name servers assigned to the hosted zone.          |
| `record_names` | Names of the DNS records created in the zone.      |

## Tests

```
terraform test
```

The suite under [`tests/`](tests) runs against a mocked AWS provider, so it
needs no credentials and no network access. Running it requires Terraform (or
OpenTofu) >= 1.7 for `mock_provider`; the module itself still supports >= 1.5.

## Not managed by this module

Query logging, DNSSEC signing and cross-account VPC associations are
deliberately out of scope. The first two need companion resources pinned to
`us-east-1` (a CloudWatch log group, a KMS key), which a single-region module
cannot create without forcing a provider alias on every caller. Wire them up
alongside the module using the exported `zone_id`. Cross-account associations
conflict with the inline `vpc` blocks, as described under
[private hosted zones](#private-hosted-zones).

## License

[MIT](LICENSE)
