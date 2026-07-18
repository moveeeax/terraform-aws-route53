# terraform-aws-route53

Terraform module that manages an [Amazon Route
53](https://aws.amazon.com/route53/) hosted zone. It creates a single public
hosted zone and renders DNS records from a map variable, exposing the zone's
name servers for delegation at the registrar.

## Usage

```hcl
module "route53" {
  source = "github.com/cybercapybara/terraform-aws-route53"

  domain_name = "example.com"

  records = {
    www = {
      name    = "www.example.com"
      type    = "A"
      records = ["192.0.2.10"]
    }
  }

  tags = {
    Environment = "production"
    ManagedBy   = "terraform"
  }
}
```

A runnable example lives in [`examples/basic`](examples/basic).

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
| `records`       | Map of DNS records to create.                           | `map(object(...))`  | `{}`      |    no    |
| `tags`          | Tags applied to the hosted zone.                        | `map(string)`       | `{}`      |    no    |

## Outputs

| Name           | Description                                        |
|----------------|----------------------------------------------------|
| `zone_id`      | ID of the hosted zone.                             |
| `arn`          | ARN of the hosted zone.                            |
| `name`         | Domain name of the hosted zone.                    |
| `name_servers` | Name servers assigned to the hosted zone.          |
| `record_names` | Names of the DNS records created in the zone.      |

## License

[MIT](LICENSE)
