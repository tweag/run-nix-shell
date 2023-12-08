assert_msg="default value for CUSTOM_VAR_BOOl"
output="$( "${run_nix_shell_sh}" 'echo "${CUSTOM_VAR_BOOL}"' )"
assert_equal "false" "${output}" "${assert_msg}"

assert_msg="custom value for CUSTOM_VAR_BOOL via command-line arg"
output="$( "${run_nix_shell_sh}" --arg customVarBool true 'echo "${CUSTOM_VAR_BOOL}"' )"
assert_equal "true" "${output}" "${assert_msg}"

