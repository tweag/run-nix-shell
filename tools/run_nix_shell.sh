#!/usr/bin/env bash

set -o errexit -o nounset -o pipefail

# NOTE: This script has been implemented so that it can be executed without Bazel. Do not pull in
# external dependencies.

fail() {
  echo >&2 "$@"
  exit 1
}

# MARK - Arguments

script="${RNS_RUN:-}"

# TODO(chuck): Process RNS_OPTS

nix_shell_opts=()
while (("$#")); do
  case "${1}" in
    # Supports:
    # --arg docTools false
    # --argstr ghcVersion "1.2.3"
    "--arg*")
      nix_shell_opts+=( "${1}" "${2}" "${3}" )
      shift 3
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

if [[ -z "${script:-}" ]]; then
  fail "A script for a path to a file must be provided."
fi

# MARK - Execute script

cmd=( nix-shell --pure )
if [[ ${#nix_shell_opts[@]} -gt 0 ]]; then
  cmd+=( "${nix_shell_opts[@]}" )
fi
cmd+=( --run "${script}" )
"${cmd[@]}"
