assert_msg="pure by default"
output="$( 
  "${run_nix_shell_sh}" --verbose 'echo "Hello, World!"' 2>&1 1>/dev/null
)"
assert_match "nix-shell .*--pure " "${output}" "${assert_msg}"

assert_msg="pure flag"
output="$( 
  "${run_nix_shell_sh}" --verbose --pure 'echo "Hello, World!"' 2>&1 1>/dev/null
)"
assert_match "nix-shell .*--pure " "${output}" "${assert_msg}"

assert_msg="nopure flag"
output="$( 
  "${run_nix_shell_sh}" --verbose --nopure 'echo "Hello, World!"' 2>&1 1>/dev/null
)"
assert_no_match "nix-shell .*--pure " "${output}" "${assert_msg}"

assert_msg="set RNS_PURE to true"
output="$( 
  RNS_PURE=true \
  "${run_nix_shell_sh}" --verbose 'echo "Hello, World!"' 2>&1 1>/dev/null
)"
assert_match "nix-shell .*--pure " "${output}" "${assert_msg}"

assert_msg="set RNS_PURE to false"
output="$( 
  RNS_PURE=false \
  "${run_nix_shell_sh}" --verbose 'echo "Hello, World!"' 2>&1 1>/dev/null
)"
assert_no_match "nix-shell .*--pure " "${output}" "${assert_msg}"
