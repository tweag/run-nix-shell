# Set up a new working directory
cwd="${PWD}/working-dir"
rm -rf "${cwd}"
mkdir -p "${cwd}"
cp shell.nix "${cwd}/"

assert_msg="set RNS_VERBOSE env var"
output="$( 
  RNS_VERBOSE="true" \
  RNS_CWD="${cwd}" \
  RNS_OPTS='--arg customVarBool true ' \
  RNS_PURE="true" \
  "${run_nix_shell_sh}" \
    --argstr customVarStr "This is a custom value." \
    'echo HELLO' 2>&1 1>/dev/null
)"
assert_match "RNS_CWD: .*working-dir" "${output}" "${assert_msg}"
assert_match "RNS_OPTS: --arg customVarBool true" "${output}" "${assert_msg}"
assert_match "RNS_PURE: true" "${output}" "${assert_msg}"
assert_match "RNS_RUN: " "${output}" "${assert_msg}"
assert_match "cwd: .*working-dir" "${output}" "${assert_msg}"
assert_match 'nix_shell_opts: --argstr customVarStr This\\ is\\ a\\ custom\\ value\.' \
  "${output}" "${assert_msg}"
assert_match "pure: true" "${output}" "${assert_msg}"
assert_match "script: echo HELLO" "${output}" "${assert_msg}"
