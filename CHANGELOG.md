# Changelog

All notable changes to this module are documented here. The format follows
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and the project uses
[Semantic Versioning](https://semver.org/).

## [Unreleased]

### Added

- Private hosted zones: `vpc_associations` (list of `{ vpc_id, vpc_region }`)
  renders inline `vpc` blocks on the zone. Defaults to `[]`, so existing zones
  stay public and plan unchanged. VPC IDs are format-checked and must be
  unique.
- `is_private` output.

## [1.1.0] - 2026-11-05

### Fixed

- Reject records that share a name and type, and blank record names, `records`
  entries and alias fields, at plan time.

### Changed

- CI: add tflint, move actions to their node24 majors, pin tool versions.

## [1.0.0] - 2026-07-26

Initial release (`v0.1.0` points at the same commit).

[Unreleased]: https://github.com/moveeeax/terraform-aws-route53/compare/v1.1.0...HEAD
[1.1.0]: https://github.com/moveeeax/terraform-aws-route53/compare/v1.0.0...v1.1.0
[1.0.0]: https://github.com/moveeeax/terraform-aws-route53/releases/tag/v1.0.0
