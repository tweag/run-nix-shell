assert_msg="default flags will exit with an error code on failure"
failed=false
"${run_nix_shell_sh}" '
[[ "true" == "false" ]]
echo "This should not be seen."
' > output.txt || failed=true
output="$( <output.txt )"
assert_no_match ".*This should not be seen.*" "${output}" "${assert_msg}"
assert_equal "true" "${failed}" "${assert_msg}"

assert_msg="with no shell flags, script will exit without an error code on failure"
success=false
RNS_SHELL_FLAGS="false" "${run_nix_shell_sh}" '
[[ "true" == "false" ]]
echo "This should be seen."
' > output.txt && success=true
output="$( <output.txt )"
assert_equal "This should be seen." "${output}" "${assert_msg}"
assert_equal "true" "${success}" "${assert_msg}"
