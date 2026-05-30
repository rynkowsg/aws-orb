#!/bin/bash

###
# Assumes an AWS role via `aws sts assume-role` and writes the resulting
# credentials to BASH_ENV.
#
# Clears any AWS credentials previously written to BASH_ENV, then obtains
# credentials for ROLE_ARN (ROLE_SESSION_NAME is the session name;
# SOURCE_PROFILE, if set, is the source profile). When SOURCE_PROFILE is empty,
# --profile is omitted.
#
# Example:
#
#   ROLE_ARN=arn:aws:iam::123456789012:role/ci/my-role \
#     ROLE_SESSION_NAME=my-job \
#     SOURCE_PROFILE=identity/ci \
#     ./src/scripts/assume_role.bash
#
###

# Bash Strict Mode Settings
set -euo pipefail
# Path Initialization
if [ -z "${SHELL_GR_DIR:-}" ]; then
  SCRIPT_PATH_1="${BASH_SOURCE[0]:-$0}"
  SCRIPT_PATH="$([[ ! "${SCRIPT_PATH_1}" =~ /bash$ ]] && readlink -f "${SCRIPT_PATH_1}" || echo "")"
  SCRIPT_DIR="$([ -n "${SCRIPT_PATH}" ] && (cd "$(dirname "${SCRIPT_PATH}")" && pwd -P) || echo "")"
  ROOT_DIR="$([ -n "${SCRIPT_DIR}" ] && (cd "${SCRIPT_DIR}/../.." && pwd -P) || echo "/tmp")"
  SHELL_GR_DIR="${ROOT_DIR}/.github_deps/rynkowsg/shell-gr@v0.5.0"
fi
# Library Sourcing
# shellcheck source=.github_deps/rynkowsg/shell-gr@v0.5.0/lib/error.bash
source "${SHELL_GR_DIR}/lib/error.bash" # fail_code, ERROR_INVALID_FN_CALL

DEBUG=${PARAM_DEBUG:-${DEBUG:-0}}
[ "${DEBUG}" = 1 ] && set -x

ROLE_ARN="${PARAM_ROLE_ARN:-"${ROLE_ARN:-""}"}"
# Derive the session name at runtime (CircleCI does not expand ${...} in defaults).
ROLE_SESSION_NAME="${PARAM_ROLE_SESSION_NAME:-"${ROLE_SESSION_NAME:-""}"}"
if [ -z "${ROLE_SESSION_NAME}" ]; then
  if [ -n "${CIRCLE_WORKFLOW_ID:-""}" ]; then
    ROLE_SESSION_NAME="circleci-${CIRCLE_WORKFLOW_ID}"
  else
    ROLE_SESSION_NAME="local-$(hostname)-$(date +%s)"
  fi
fi
SOURCE_PROFILE="${PARAM_SOURCE_PROFILE:-"${SOURCE_PROFILE:-""}"}"

function clear_credentials {
  # aws-cli orb env vars
  sed -i '/^export AWS_CLI_STR_ACCESS_KEY_ID=/d' "${BASH_ENV}"
  sed -i '/^export AWS_CLI_STR_SECRET_ACCESS_KEY=/d' "${BASH_ENV}"
  sed -i '/^export AWS_CLI_STR_SESSION_TOKEN=/d' "${BASH_ENV}"
  # current role secrets
  sed -i '/^export AWS_ACCESS_KEY_ID=/d' "${BASH_ENV}"
  sed -i '/^export AWS_SECRET_ACCESS_KEY=/d' "${BASH_ENV}"
  sed -i '/^export AWS_SESSION_TOKEN=/d' "${BASH_ENV}"
}

function main {
  [ -n "${ROLE_ARN}" ] || fail_code "${ERROR_INVALID_FN_CALL}" "ERROR: ROLE_ARN is required."

  clear_credentials

  local creds key secret token profile_args=()
  [ -n "${SOURCE_PROFILE}" ] && profile_args=(--profile "${SOURCE_PROFILE}")
  creds="$(aws sts assume-role \
    --role-arn "${ROLE_ARN}" \
    --role-session-name "${ROLE_SESSION_NAME}" \
    "${profile_args[@]}" \
    --query 'Credentials.[AccessKeyId,SecretAccessKey,SessionToken]' \
    --output text)"
  IFS=$'\t' read -r key secret token <<<"${creds}"
  {
    echo "export AWS_ACCESS_KEY_ID=\"${key}\""
    echo "export AWS_SECRET_ACCESS_KEY=\"${secret}\""
    echo "export AWS_SESSION_TOKEN=\"${token}\""
  } >>"${BASH_ENV}"
}

# shellcheck disable=SC2199
# to disable warning about concatenation of BASH_SOURCE[@].
# It is not a problem. This part of condition is only to prevent `unbound variable` error.
if [[ -n "${BASH_SOURCE[@]}" && "${BASH_SOURCE[0]}" != "${0}" ]]; then
  [[ -n "${BASH_SOURCE[0]}" ]] && printf "%s\n" "Loaded: ${BASH_SOURCE[0]}"
else
  main "$@"
fi
