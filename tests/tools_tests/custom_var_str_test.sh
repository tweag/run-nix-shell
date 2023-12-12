assert_msg="default value for CUSTOM_VAR_STR"
output="$( "${run_nix_shell_sh}" 'echo "${CUSTOM_VAR_STR}"' )"
assert_equal "default" "${output}" "${assert_msg}"

assert_msg="custom value for CUSTOM_VAR_STR via command-line arg"
expected="This is a custom value."
output="$( "${run_nix_shell_sh}" --argstr customVarStr "${expected}" 'echo "${CUSTOM_VAR_STR}"' )"
assert_equal "${expected}" "${output}" "${assert_msg}"
