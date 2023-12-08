assert_msg="simple script"
output="$( "${run_nix_shell_sh}" 'echo "Hello, World!"' )"
assert_equal "Hello, World!" "${output}" "${assert_msg}"
