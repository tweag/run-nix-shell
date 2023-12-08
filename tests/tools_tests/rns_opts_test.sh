assert_msg="custom value for CUSTOM_VAR_BOOL via RNS_OPTS"
output="$( 
RNS_OPTS='--arg customVarBool true --argstr customVarStr "This is a custom value."' \
  "${run_nix_shell_sh}" 'echo "${CUSTOM_VAR_BOOL}"; echo "${CUSTOM_VAR_STR}"' 
)"
assert_match "true" "${output}" "${assert_msg}"
assert_match "This is a custom value" "${output}" "${assert_msg}"

