# Set up a new working directory
cwd="${PWD}/working-dir"
rm -rf "${cwd}"
mkdir -p "${cwd}"
cp shell.nix "${cwd}/"

assert_msg="set working-directory flag"
output="$( "${run_nix_shell_sh}" --working-directory "${cwd}" 'echo "${PWD}"' )"
assert_equal "${cwd}" "${output}" "${assert_msg}"

assert_msg="set RNS_CWD env var"
output="$( RNS_CWD="${cwd}" "${run_nix_shell_sh}" 'echo "${PWD}"' )"
assert_equal "${cwd}" "${output}" "${assert_msg}"
