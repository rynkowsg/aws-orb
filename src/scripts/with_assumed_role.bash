#!/bin/bash

###
# Runs a command with credentials from an assumed AWS role.
#
# Assumes ROLE_ARN via `aws sts assume-role`, exports the temporary
# credentials into the current shell, then runs COMMAND. Nothing is written to
# BASH_ENV, so the credentials are scoped to this single step.
#
# Example:
#
#   SOURCE_PROFILE=identity/ci \
#     ROLE_ARN=arn:aws:iam::123456789012:role/ci/my-role \
#     ROLE_SESSION_NAME=my-job \
#     COMMAND='aws sts get-caller-identity' \
#     ./src/scripts/with_assumed_role.bash
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

SOURCE_PROFILE="${PARAM_SOURCE_PROFILE:-"${SOURCE_PROFILE:-""}"}"
ROLE_ARN="${PARAM_ROLE_ARN:-"${ROLE_ARN:-""}"}"
COMMAND="${PARAM_COMMAND:-"${COMMAND:-""}"}"
# Derive the session name at runtime (CircleCI does not expand ${...} in defaults).
ROLE_SESSION_NAME="${PARAM_ROLE_SESSION_NAME:-"${ROLE_SESSION_NAME:-""}"}"
if [ -z "${ROLE_SESSION_NAME}" ]; then
  if [ -n "${CIRCLE_WORKFLOW_ID:-""}" ]; then
    ROLE_SESSION_NAME="circleci-${CIRCLE_WORKFLOW_ID}"
  else
    ROLE_SESSION_NAME="local-$(hostname)-$(date +%s)"
  fi
fi

function assume_role {
  local creds profile_args=()
  [ -n "${SOURCE_PROFILE}" ] && profile_args=(--profile "${SOURCE_PROFILE}")
  creds="$(aws sts assume-role \
    --role-arn "${ROLE_ARN}" \
    --role-session-name "${ROLE_SESSION_NAME}" \
    "${profile_args[@]}" \
    --query 'Credentials.[AccessKeyId,SecretAccessKey,SessionToken]' \
    --output text)"
  IFS=$'\t' read -r AWS_ACCESS_KEY_ID AWS_SECRET_ACCESS_KEY AWS_SESSION_TOKEN <<<"${creds}"
  export AWS_ACCESS_KEY_ID AWS_SECRET_ACCESS_KEY AWS_SESSION_TOKEN
}

function main {
  [ -n "${ROLE_ARN}" ] || fail_code "${ERROR_INVALID_FN_CALL}" "ERROR: ROLE_ARN is required."
  [ -n "${COMMAND}" ] || fail_code "${ERROR_INVALID_FN_CALL}" "ERROR: COMMAND is required."

  assume_role

  # run the wrapped command with the credentials in scope; do not impose
  # nounset on it (matches CircleCI's default shell options)
  set +u
  eval "${COMMAND}"
}

# shellcheck disable=SC2199
# to disable warning about concatenation of BASH_SOURCE[@].
# It is not a problem. This part of condition is only to prevent `unbound variable` error.
if [[ -n "${BASH_SOURCE[@]}" && "${BASH_SOURCE[0]}" != "${0}" ]]; then
  [[ -n "${BASH_SOURCE[0]}" ]] && printf "%s\n" "Loaded: ${BASH_SOURCE[0]}"
else
  main "$@"
fi
