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

# MARK - Setup

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

assert_msg="simple script"
output="$( "${run_nix_shell_sh}" 'echo "Hello, World!"' )"
assert_equal "Hello, World!" "${output}" "${assert_msg}"

assert_msg="multi-line script"
output="$( 
"${run_nix_shell_sh}" '
echo "Hello, World!"
echo "Second Line"
' 
)"
assert_match "Hello, World" "${output}" "${assert_msg}"
assert_match "Second Line" "${output}" "${assert_msg}"

assert_msg="path to script file"
custom_script_path="./custom_script.sh"
cat >"${custom_script_path}" <<-EOF
#!/usr/bin/env bash
set -o errexit -o nounset -o pipefail
echo "Hello from custom script"
EOF
chmod +x "${custom_script_path}"
output="$( "${run_nix_shell_sh}" "${custom_script_path}" )"
assert_equal "Hello from custom script" "${output}" "${assert_msg}"

assert_msg="default value for CUSTOM_VAR_BOOl"
output="$( "${run_nix_shell_sh}" 'echo "${CUSTOM_VAR_BOOL}"' )"
assert_equal "false" "${output}" "${assert_msg}"

assert_msg="default value for CUSTOM_VAR_STR"
output="$( "${run_nix_shell_sh}" 'echo "${CUSTOM_VAR_STR}"' )"
assert_equal "default" "${output}" "${assert_msg}"

assert_msg="custom value for CUSTOM_VAR_BOOL"
output="$( "${run_nix_shell_sh}" --arg customVarBool true 'echo "${CUSTOM_VAR_BOOL}"' )"
assert_equal "true" "${output}" "${assert_msg}"

assert_msg="custom value for CUSTOM_VAR_STR"
expected="This is a custom value."
output="$( "${run_nix_shell_sh}" --argstr customVarStr "${expected}" 'echo "${CUSTOM_VAR_STR}"' )"
assert_equal "${expected}" "${output}" "${assert_msg}"
