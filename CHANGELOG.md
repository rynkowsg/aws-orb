# Changelog

## [Unreleased]

[Unreleased]: https://github.com/rynkowsg/aws-orb/compare/v0.1.0..main

## [0.1.0](https://github.com/rynkowsg/aws-orb/commits/v0.1.0) (2026-05-31)

### Added

- `assume_role` command — assumes an IAM role via `aws sts assume-role` and
  exports the temporary credentials to `BASH_ENV` for subsequent steps.
- `export_credentials` command — exports a named profile's credentials to
  `BASH_ENV` via `aws configure export-credentials` for subsequent steps.
- `with_assumed_role` command — assumes an IAM role and runs a single command
  with its credentials in scope; nothing is written to `BASH_ENV`.
- `with_profile` command — runs a single command with a named profile's
  credentials in scope; nothing is written to `BASH_ENV`.
