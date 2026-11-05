# terraform-aws-route53

Terraform module that manages an [Amazon Route
53](https://aws.amazon.com/route53/) hosted zone. It creates a single public
hosted zone and renders DNS records from a map variable, exposing the zone's
name servers for delegation at the registrar.

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
| `records`       | Map of DNS records to create (see [schema](#record-schema)). | `map(object(...))` | `{}` |    no    |
| `tags`          | Tags applied to the hosted zone.                        | `map(string)`       | `{}`      |    no    |

## Outputs

| Name           | Description                                        |
|----------------|----------------------------------------------------|
| `zone_id`      | ID of the hosted zone.                             |
| `arn`          | ARN of the hosted zone.                            |
| `name`         | Domain name of the hosted zone.                    |
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

Query logging, DNSSEC signing and private-zone VPC associations are
deliberately out of scope. The first two need companion resources pinned to
`us-east-1` (a CloudWatch log group, a KMS key), which a single-region module
cannot create without forcing a provider alias on every caller. Wire them up
alongside the module using the exported `zone_id`.

## License

[MIT](LICENSE)
