assert_msg="custom derivation path via RNS_DERIVATION_PATH"
derivation_path="${PWD}/shell.nix"
another_dir="${PWD}/somewhere_else"
mkdir -p "${another_dir}"
cd "${another_dir}"
output="$( 
RNS_DERIVATION_PATH="${derivation_path}" \
  "${run_nix_shell_sh}" 'echo "${CUSTOM_VAR_STR}"' 
)"
assert_match "default" "${output}" "${assert_msg}"
