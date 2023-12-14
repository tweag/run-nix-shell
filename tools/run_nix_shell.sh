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

absolute_path() {
  local path="${1}"
  local bname
  local dname
  bname="$( basename "${path}" )"
  dname="$( dirname "${path}" )"
  echo "$( cd "${dname}"; pwd )/${bname}"
}

# MARK - Arguments

cwd="${RNS_CWD:-}"
script="${RNS_RUN:-}"
derivation_path="${RNS_DERIVATION_PATH:-}"

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
cwd: ${cwd:-}
nix_shell_opts: $( printf "%q " "${nix_shell_opts[@]}" )
pure: ${pure:-}
script: ${script:-}
derivation_path: ${derivation_path:-}
===
EOF
)"
  warn "${verbose_output}"
fi

# MARK - Process Options and Arguments

if [[ -n "${derivation_path:-}" ]]; then
  derivation_path="$( absolute_path "${derivation_path}" )"
  nix_shell_opts+=( "${derivation_path}" )
fi

if [[ "${pure}" == "true" ]]; then
  nix_shell_opts+=( --pure )
fi

# Look for any options passed via the RNS_OPTS environment variable.
# Add them to the nix_shell_opts.
if [[ -n "${RNS_OPTS:-}" ]]; then
  # Parse the RNS_OPTS string.
  while IFS=$'\0' read -r -d '' arg; do 
    more_nix_shell_opts+=( "${arg}" ) 
  done < <(xargs printf '%s\0' <<<"${RNS_OPTS}")
  # Add to the nix_shell_opts if we found any
  if [[ ${#more_nix_shell_opts[@]} ]]; then
    nix_shell_opts+=( "${more_nix_shell_opts[@]}" )
  fi
fi

if [[ -z "${script:-}" ]]; then
  fail "A script for a path to a file must be provided."
fi

# MARK - Execute script

# Change to the specified working directory
if [[ -n "${cwd:-}" ]]; then
  cd "${cwd}"
fi

cmd=( nix-shell )
if [[ ${#nix_shell_opts[@]} -gt 0 ]]; then
  cmd+=( "${nix_shell_opts[@]}" )
fi
cmd+=( --run "${script}" )

if is_verbose; then
  verbose_output="$(cat <<-EOF
=== run_nix_shell command-line invocation ===
$( printf "%q " "${cmd[@]}" )
===
EOF
)"
  warn "${verbose_output}"
fi

"${cmd[@]}"
