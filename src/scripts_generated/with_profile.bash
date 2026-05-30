#!/bin/bash

###
# Runs a command with credentials from an AWS profile.
#
# Materializes PROFILE's credentials into the current shell via
# `aws configure export-credentials`, then runs COMMAND. Nothing is written to
# BASH_ENV, so the credentials are scoped to this single step.
#
# Example:
#
#   PROFILE=forge/deployer \
#     COMMAND='aws sts get-caller-identity' \
#     ./src/scripts/with_profile.bash
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

PROFILE="${PARAM_PROFILE:-"${PROFILE:-""}"}"
COMMAND="${PARAM_COMMAND:-"${COMMAND:-""}"}"

function load_credentials {
  # capture first so a failing `aws` is caught by `set -e`
  # (a bare `eval "$(aws ...)"` would mask its exit code)
  local env_out
  env_out="$(aws configure export-credentials --profile "${PROFILE}" --format env)"
  # `--format env` output already contains `export` statements
  eval "${env_out}"
}

function main {
  [ -n "${PROFILE}" ] || fail_code "${ERROR_INVALID_FN_CALL}" "ERROR: PROFILE is required."
  [ -n "${COMMAND}" ] || fail_code "${ERROR_INVALID_FN_CALL}" "ERROR: COMMAND is required."

  load_credentials

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
