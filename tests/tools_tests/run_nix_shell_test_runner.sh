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

assertions_sh_location=cgrindel_bazel_starlib/shlib/lib/assertions.sh
assertions_sh="$(rlocation "${assertions_sh_location}")" || \
  (echo >&2 "Failed to locate ${assertions_sh_location}" && exit 1)
source "${assertions_sh}"

run_nix_shell_sh_location=run_nix_shell/tools/run_nix_shell.sh
run_nix_shell_sh="$(rlocation "${run_nix_shell_sh_location}")" || \
  (echo >&2 "Failed to locate ${run_nix_shell_sh_location}" && exit 1)

flake_lock_location=run_nix_shell/flake.lock
flake_lock="$(rlocation "${flake_lock_location}")" || \
  (echo >&2 "Failed to locate ${flake_lock_location}" && exit 1)

node_binary_location=nodejs/bin/node
node_binary="$(rlocation "${node_binary_location}")" || \
  (echo >&2 "Failed to locate ${node_binary_location}" && exit 1)

node_bundle_mjs_location=run_nix_shell/generated/bundle.mjs
node_bundle_mjs="$(rlocation "${node_bundle_mjs_location}")" || \
  (echo >&2 "Failed to locate ${node_bundle_mjs_location}" && exit 1)

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
