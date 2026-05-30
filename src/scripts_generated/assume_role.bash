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
# source "${SHELL_GR_DIR}/lib/error.bash" # fail_code, ERROR_INVALID_FN_CALL # BEGIN
#!/usr/bin/env bash
# Copyright (c) 2024-2026 Greg Rynkowski. All rights reserved.
# License: MIT License

# Path Initialization
if [ -n "${SHELL_GR_DIR:-}" ]; then
  _SHELL_GR_DIR="${SHELL_GR_DIR}"
elif [ -z "${_SHELL_GR_DIR:-}" ]; then
  _SCRIPT_PATH_1="${BASH_SOURCE[0]:-$0}"
  _SCRIPT_PATH="$([[ ! "${_SCRIPT_PATH_1}" =~ /bash$ ]] && readlink -f "${_SCRIPT_PATH_1}" || exit 1)"
  _SCRIPT_DIR="$(cd "$(dirname "${_SCRIPT_PATH}")" && pwd -P || exit 1)"
  _ROOT_DIR="$(cd "${_SCRIPT_DIR}/.." && pwd -P || exit 1)"
  _SHELL_GR_DIR="${_ROOT_DIR}"
fi
# Library Sourcing
# source "${_SHELL_GR_DIR}/lib/color.bash" # NC, RED # BEGIN
#!/usr/bin/env bash
# Copyright (c) 2024-2026 Greg Rynkowski. All rights reserved.
# License: MIT License

# shellcheck disable=SC2034
GREEN=$(printf '\033[32m')
# shellcheck disable=SC2034
RED=$(printf '\033[31m')
# shellcheck disable=SC2034
YELLOW=$(printf '\033[33m')
# shellcheck disable=SC2034
NC=$(printf '\033[0m')

# Color enabled by default
COLOR=${COLOR:-1}

is_color() {
  case "${COLOR}" in
    1 | "true") return 0 ;; # true
    *) return 1 ;;          # false
  esac
}
# source "${_SHELL_GR_DIR}/lib/color.bash" # NC, RED # END

# generic
export ERROR_UNKNOWN=101
export ERROR_INVALID_FN_CALL=102
export ERROR_INVALID_STATE=103
# specific
export ERROR_COMMAND_DOES_NOT_EXIST=104

# TODO: consider removing this and replacing with simpler fail without error codes
# At the end, why do I need error codes?
error_exit() {
  local msg="${1:-"Unknown Error"}"
  local code="${2:-${UNKNOWN_ERROR}}"
  printf "${RED}Error: %s${NC}\n" "${msg}" >&2
  exit "${code}"
}

fail() {
  printf "%s\n" "$*" >&2
  exit 1
}

fail_code() {
  local code="$1"
  shift
  printf "%s\n" "$*" >&2
  exit "${code}"
}

assert_command_exist() {
  local command="$1"
  if ! command -v "${command}" &>/dev/null; then
    error_exit "'${command}' doesn't exist. Please install '${command}'." "${COMMAND_DONT_EXIST}"
  else
    printf "%s\n" "'${command}' detected..."
    printf "%s\n" ""
  fi
}

assert_not_empty() {
  local -r var_name="${1}"
  local -r var_value="${!var_name}"
  if [ -z "${var_value}" ]; then
    error_exit "${var_name} must not be empty"
  fi
}

run_with_unset_e() {
  # Check the current 'set -e' state
  local e_enabled
  if set +o | grep "set -o errexit" &>/dev/null; then
    e_enabled=1
  else
    e_enabled=0
  fi
  # If enabled, disable
  if [ ${e_enabled} -eq 1 ]; then
    set +e
  fi
  # Run the passed command(s)
  "$@"
  local -r res=$?
  # Enable 'errexit' if it was enabled
  if [ ${e_enabled} -eq 1 ]; then
    set -e
  fi
  # Return the result of the command
  return $res
}
# source "${SHELL_GR_DIR}/lib/error.bash" # fail_code, ERROR_INVALID_FN_CALL # END

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
