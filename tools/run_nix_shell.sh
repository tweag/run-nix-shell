#!/usr/bin/env bash

set -o errexit -o nounset -o pipefail

# NOTE: This script has been implemented so that it can be executed without Bazel. Do not pull in
# external dependencies.

warn() {
  echo >&2 "$@"
}

fail() {
  warn "$@"
  exit 1
}

# MARK - Arguments

cwd="${RNS_CWD:-}"
script="${RNS_RUN:-}"
derivation_path="${RNS_DERIVATION_PATH:-}"
# The default flags listed below are equivalent to `set -euo pipefail`.
shell_flags="${RNS_SHELL_FLAGS:-set -o errexit -o nounset -o pipefail}"

pure="${RNS_PURE:-true}"
verbose="${RNS_VERBOSE:-false}"
nix_shell_opts=()
while (("$#")); do
  case "${1}" in
    # Supports:
    # --arg docTools false
    # --argstr ghcVersion "1.2.3"
    --arg*)
      nix_shell_opts+=( "${1}" "${2}" "${3}" )
      shift 3
      ;;
    --pure)
      pure="true"
      shift 1
      ;;
    --nopure)
      pure="false"
      shift 1
      ;;
    --working-directory)
      cwd="${2}"
      shift 2
      ;;
    --verbose)
      verbose=true
      shift 1
      ;;
    *)
      if [[ -z "${script:-}" ]]; then
        script="${1}"
        shift 1
      else
        fail "Unexpected argument:" "${1}"
      fi
      ;;
  esac
done

# MARK - Verbose

is_verbose() {
  [[ "${verbose}" == "true" ]]
}

if is_verbose; then
  verbose_output="$(cat <<-EOF
=== run_nix_shell Inputs ===
RNS_CWD: ${RNS_CWD:-}
RNS_OPTS: ${RNS_OPTS:-}
RNS_RUN: ${RNS_RUN:-}
RNS_DERIVATION_PATH: ${RNS_DERIVATION_PATH:-}
RNS_PURE: ${RNS_PURE:-}
RNS_SHELL_FLAGS: ${RNS_SHELL_FLAGS:-}
cwd: ${cwd:-}
nix_shell_opts: $( printf "%q " "${nix_shell_opts[@]}" )
pure: ${pure:-}
shell_flags: ${shell_flags:-}
script: ${script:-}
derivation_path: ${derivation_path:-}
===
EOF
)"
  warn "${verbose_output}"
fi

# Mark - set inputs for action

if [ "${#nix_shell_opts[@]}" -gt 0 ]; then
    options=$( printf "%q " "${nix_shell_opts[@]}" )
    options="${options% }" # strip right space
else
    options="${RNS_OPTS:-}"
fi

# map script variables to action inputs (see action.yaml)
declare -a INPUTS=(
    derivation-path "${derivation_path:-}"
    options "$options"
    pure "$pure"
    run "$script"
    shell-flags "${shell_flags:-}"
    verbose "$verbose"
    working-directory "${cwd:-}"
)

for ((i=0; i < ${#INPUTS[@]}; i+=2)); do
    name="${INPUTS[i]}"
    value="${INPUTS[i+1]}"

    if [[ -n "$value" ]]; then
        input="INPUT_$(echo "${name}" | tr '[:lower:]' '[:upper:]')" # prefix with INPUT_ and uppercase
        input="${input// /_}"   # replace spaces with underscores
        variables+=( "${input}=${value}" )
    fi
done

exec env "${variables[@]}" "${RNS_NODE:-node}" "${RNS_INDEX_JS:-dist/index.js}"
