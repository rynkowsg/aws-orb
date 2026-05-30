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
source "${SHELL_GR_DIR}/lib/error.bash" # fail_code, ERROR_INVALID_FN_CALL

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
