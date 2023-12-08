assert_msg="multi-line script"
output="$( 
"${run_nix_shell_sh}" '
echo "Hello, World!"
echo "Second Line"
' 
)"
assert_match "Hello, World" "${output}" "${assert_msg}"
assert_match "Second Line" "${output}" "${assert_msg}"
