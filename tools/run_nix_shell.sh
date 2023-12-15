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

# MARK - Process Options and Arguments

# Resolve the target directory to an absolute path before processing the
# derivation path. That logic may change directories.
if [[ -n "${cwd:-}" ]]; then
  cwd="$( absolute_path "${cwd}" )"
fi

# The shell.nix or default.nix may contain relative paths to other files. The
# Nix logic does not appear to resolve these relative to the file, but to the
# current directory. So, we will ensure that we are in the derivation's
# directory before executing the command.
if [[ -n "${derivation_path:-}" ]]; then
  derivation_path="$( absolute_path "${derivation_path}" )"
  if [[ -d "${derivation_path}" ]]; then
    derivation_dirname="${derivation_path}"
  else
    derivation_dirname="$( dirname "${derivation_path}" )"
    derivation_basename="$( basename "${derivation_path}" )"
  fi
  cd "${derivation_dirname}"
  if [[ -n "${derivation_basename:-}" ]]; then
    nix_shell_opts+=( "${derivation_basename}" )
  fi
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

# If the client does not want any shell flags, we use the special value "false"
# to indicate that no flags should be applied.
if [[ "${shell_flags:-}" == "false" ]]; then
  shell_flags=""
fi

if [[ -z "${script:-}" ]]; then
  fail "A script or a path to a file must be provided."
fi

# MARK - Execute script

# Change to the specified working directory
if [[ -n "${cwd:-}" ]]; then
  cd_cmd="cd ${cwd}"
fi

script="$(cat <<-EOF
${shell_flags:-}
${cd_cmd:-}
${script}
EOF
)"

cmd=( nix-shell )
if [[ ${#nix_shell_opts[@]} -gt 0 ]]; then
  cmd+=( "${nix_shell_opts[@]}" )
fi
cmd+=( --run "${script}" )

if is_verbose; then
  verbose_output="$(cat <<-EOF
=== run_nix_shell command-line invocation ===
pwd: ${PWD}
$( printf "%q " "${cmd[@]}" )
===
EOF
)"
  warn "${verbose_output}"
fi

"${cmd[@]}"
