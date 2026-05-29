# [`rynkowsg/aws`][orb-page] orb

[![CircleCI Build Status][ci-build-badge]][ci-build]
[![CircleCI Orb Version][orb-version-badge]][orb-page]
[![License][license-badge]][license]
[![CircleCI Community][orbs-discuss-badge]][orbs-discuss]

Commands for working with AWS credentials in CircleCI.

[What are Orbs?](https://circleci.com/orbs/)

## Motivation

These commands cover two recurring needs in CI jobs that talk to AWS:

- **Assume a role** via `aws sts assume-role` (`assume_role`, `with_assumed_role`).
- **Export a configured profile's credentials** via `aws configure export-credentials` (`export_credentials`, `with_profile`).

Each pair comes in two flavours:

- `assume_role` / `export_credentials` persist the credentials to `BASH_ENV`,
  so every subsequent step in the job runs with them.
- `with_assumed_role` / `with_profile` run a single command with the
  credentials in scope and write nothing to `BASH_ENV`, keeping them scoped to
  that one step.

They pair naturally with the [`circleci/aws-cli`](https://circleci.com/developer/orbs/orb/circleci/aws-cli)
orb, which sets up the OIDC entry profile.

## Commands

| Command              | Effect                                                                       |
|----------------------|------------------------------------------------------------------------------|
| `assume_role`        | Assume a role and persist its credentials to `BASH_ENV` for the whole job.   |
| `with_assumed_role`  | Assume a role and run a single command with its credentials in scope.        |
| `export_credentials` | Export a profile's credentials to `BASH_ENV` for the whole job.              |
| `with_profile`       | Run a single command with a profile's credentials in scope.                  |

## Quickstart

```yaml
version: '2.1'

orbs:
  aws-cli: circleci/aws-cli@5.4.1
  aws: rynkowsg/aws@1.0.0

jobs:
  deploy:
    docker: [{image: "cimg/base:stable"}]
    steps:
      - aws-cli/setup:
          profile_name: identity/oidc-circleci
          role_arn: "arn:aws:iam::${IDENTITY_ACCOUNT_ID}:role/oidc/circleci-role"
          role_session_name: "circleci-${CIRCLE_WORKFLOW_ID}"
          set_aws_env_vars: false
      - aws/assume_role:
          source_profile: identity/oidc-circleci
          role_arn: "arn:aws:iam::${FORGE_ACCOUNT_ID}:role/ci/deployer-role"
      - run: aws sts get-caller-identity

workflows:
  main-workflow:
    jobs:
      - deploy
```

## Usage

For full usage guidelines, see the [orb registry listing][orb-page].

## `rynkowsg/` orb family

| Name                                                            | Description                                                                                       |
|-----------------------------------------------------------------|---------------------------------------------------------------------------------------------------|
| [`rynkowsg/asdf`](https://github.com/rynkowsg/asdf-orb)         | Orb providing support for ASDF                                                                    |
| [`rynkowsg/aws`](https://github.com/rynkowsg/aws-orb)           | Commands for working with AWS credentials                                                         |
| [`rynkowsg/checkout`](https://github.com/rynkowsg/checkout-orb) | Advanced checkout with support of LFS, submodules, custom SSH identities, shallow clones and more |
| [`rynkowsg/rynkowsg`](https://github.com/rynkowsg/rynkowsg-orb) | Orb with no particular theme, used primarily for prototyping                                      |

## License

Copyright © 2026 Grzegorz Rynkowski

Use is permitted solely for executing CircleCI workflows; all other rights are
reserved. See the [LICENSE][license] file for details.

[ci-build-badge]: https://circleci.com/gh/rynkowsg/aws-orb.svg?style=shield "CircleCI Build Status"
[ci-build]: https://circleci.com/gh/rynkowsg/aws-orb
[license-badge]: https://img.shields.io/badge/license-proprietary-lightgrey.svg
[license]: https://raw.githubusercontent.com/rynkowsg/aws-orb/master/LICENSE
[orb-page]: https://circleci.com/developer/orbs/orb/rynkowsg/aws
[orb-version-badge]: https://badges.circleci.com/orbs/rynkowsg/aws.svg
[orbs-discuss-badge]: https://img.shields.io/badge/community-CircleCI%20Discuss-343434.svg
[orbs-discuss]: https://discuss.circleci.com/c/ecosystem/orbs
