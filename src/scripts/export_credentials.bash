#!/bin/bash

###
# Exports an AWS profile's credentials to BASH_ENV via
# `aws configure export-credentials`.
#
# Clears any AWS credentials previously written to BASH_ENV, then exports
# PROFILE's credentials.
#
# Example:
#
#   PROFILE=forge/deployer ./src/scripts/export_credentials.bash
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
  [ -n "${PROFILE}" ] || fail_code "${ERROR_INVALID_FN_CALL}" "ERROR: PROFILE is required."

  clear_credentials

  aws configure export-credentials --profile "${PROFILE}" --format env >>"${BASH_ENV}"
}

# shellcheck disable=SC2199
# to disable warning about concatenation of BASH_SOURCE[@].
# It is not a problem. This part of condition is only to prevent `unbound variable` error.
if [[ -n "${BASH_SOURCE[@]}" && "${BASH_SOURCE[0]}" != "${0}" ]]; then
  [[ -n "${BASH_SOURCE[0]}" ]] && printf "%s\n" "Loaded: ${BASH_SOURCE[0]}"
else
  main "$@"
fi
