# [`rynkowsg/aws`][orb-page] orb

[![CircleCI Build Status][ci-build-badge]][ci-build]
[![CircleCI Orb Version][orb-version-badge]][orb-page]
[![License][license-badge]][license]
[![CircleCI Community][orbs-discuss-badge]][orbs-discuss]

Commands for working with AWS credentials in CircleCI.
Assumes roles via `aws sts assume-role` and exports profile credentials via
`aws configure export-credentials`, either persisted to `BASH_ENV` for the
whole job or scoped to a single step.

For the full orb reference, see the [orb registry listing][orb-page].

## Commands

| Command               | Scope            | Description                                                                  |
|-----------------------|------------------|------------------------------------------------------------------------------|
| `assume_role`         | Job (`BASH_ENV`) | Assumes an IAM role; exports credentials to `BASH_ENV` for subsequent steps  |
| `export_credentials`  | Job (`BASH_ENV`) | Exports a named profile's credentials to `BASH_ENV` for subsequent steps     |
| `with_assumed_role`   | Single step      | Assumes an IAM role and runs a command with its credentials in scope         |
| `with_profile`        | Single step      | Runs a command with a named profile's credentials in scope                   |

They pair naturally with the [`circleci/aws-cli`](https://circleci.com/developer/orbs/orb/circleci/aws-cli)
orb, which sets up the OIDC entry profile.

## Quickstart

### One role for the whole job

`aws-cli/setup` creates an OIDC entry profile. `assume_role` then assumes the
deployer role and writes its credentials to `BASH_ENV`, so every subsequent step
runs with them automatically.

```yaml
version: '2.1'

orbs:
  aws-cli: circleci/aws-cli@5.4.1
  aws: rynkowsg/aws@0.1.0

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

### Two roles in one job

Use `with_assumed_role` when different steps need different roles. Here the
builder role runs the build step and the deployer role runs the deploy step —
each call discards its credentials afterwards, nothing is written to `BASH_ENV`.

```yaml
version: '2.1'

orbs:
  aws-cli: circleci/aws-cli@5.4.1
  aws: rynkowsg/aws@0.1.0

jobs:
  build_and_deploy:
    docker: [{image: "cimg/base:stable"}]
    steps:
      - aws-cli/setup:
          profile_name: identity/oidc-circleci
          role_arn: "arn:aws:iam::${IDENTITY_ACCOUNT_ID}:role/oidc/circleci-role"
          role_session_name: "circleci-${CIRCLE_WORKFLOW_ID}"
          set_aws_env_vars: false
      - aws/with_assumed_role:
          source_profile: identity/oidc-circleci
          role_arn: "arn:aws:iam::${FORGE_ACCOUNT_ID}:role/ci/builder-role"
          command: "aws sts get-caller-identity"
      - aws/with_assumed_role:
          source_profile: identity/oidc-circleci
          role_arn: "arn:aws:iam::${FORGE_ACCOUNT_ID}:role/ci/deployer-role"
          command: "aws sts get-caller-identity"

workflows:
  main-workflow:
    jobs:
      - build_and_deploy
```

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
[license]: https://raw.githubusercontent.com/rynkowsg/aws-orb/main/LICENSE
[orb-page]: https://circleci.com/developer/orbs/orb/rynkowsg/aws
[orb-version-badge]: https://badges.circleci.com/orbs/rynkowsg/aws.svg
[orbs-discuss-badge]: https://img.shields.io/badge/community-CircleCI%20Discuss-343434.svg
[orbs-discuss]: https://discuss.circleci.com/c/ecosystem/orbs
