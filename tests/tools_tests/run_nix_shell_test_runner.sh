#!/usr/bin/env bash

# --- begin runfiles.bash initialization v2 ---
# Copy-pasted from the Bazel Bash runfiles library v2.
set -o nounset -o pipefail; f=bazel_tools/tools/bash/runfiles/runfiles.bash
# shellcheck disable=SC1090
source "${RUNFILES_DIR:-/dev/null}/$f" 2>/dev/null || \
  source "$(grep -sm1 "^$f " "${RUNFILES_MANIFEST_FILE:-/dev/null}" | cut -f2- -d' ')" 2>/dev/null || \
  source "$0.runfiles/$f" 2>/dev/null || \
  source "$(grep -sm1 "^$f " "$0.runfiles_manifest" | cut -f2- -d' ')" 2>/dev/null || \
  source "$(grep -sm1 "^$f " "$0.exe.runfiles_manifest" | cut -f2- -d' ')" 2>/dev/null || \
  { echo>&2 "ERROR: cannot find $f"; exit 1; }; f=; set -o errexit
# --- end runfiles.bash initialization v2 ---

# MARK - Locate Deps

assertions_sh="$(rlocation "${ASSERTIONS_SH_LOCATION}")" ||
  (echo >&2 "Failed to locate ${ASSERTIONS_SH_LOCATION}" && exit 1)
source "${assertions_sh}"

run_nix_shell_sh="$(rlocation "${RUN_NIX_SHELL_SH_LOCATION}")" ||
  (echo >&2 "Failed to locate ${RUN_NIX_SHELL_SH_LOCATION}" && exit 1)

flake_lock="$(rlocation "${FLAKE_LOCK_LOCATION}")" ||
  (echo >&2 "Failed to locate ${FLAKE_LOCK_LOCATION}" && exit 1)

node_binary="$(rlocation "${NODE_BINARY_LOCATION}")" ||
  (echo >&2 "Failed to locate ${NODE_BINARY_LOCATION}" && exit 1)

node_bundle_mjs="$(rlocation "${NODE_BUNDLE_MJS_LOCATION}")" ||
  (echo >&2 "Failed to locate ${NODE_BUNDLE_MJS_LOCATION}" && exit 1)

# MARK - Setup

export NODE="$node_binary"
export RNS_BUNDLE_MJS="$node_bundle_mjs"

cat >shell.nix <<-EOF
{ 
  pkgs ? import (
    let lock = builtins.fromJSON (builtins.readFile ${flake_lock}); in
    fetchTarball {
      url = "https://github.com/NixOS/nixpkgs/archive/\${lock.nodes.nixpkgs.locked.rev}.tar.gz";
      sha256 = lock.nodes.nixpkgs.locked.narHash;
    }
  ) {},
  customVarBool ? false,
  customVarStr ? "default",
}:
with pkgs;
mkShell {
  CUSTOM_VAR_BOOL = if customVarBool then "true" else "false";
  CUSTOM_VAR_STR = customVarStr;
  packages = [ nix ];
}
EOF

# MARK - Test

source "${1}"
