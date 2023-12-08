assert_msg="path to script file"
custom_script_path="./custom_script.sh"
cat >"${custom_script_path}" <<-EOF
#!/usr/bin/env bash
set -o errexit -o nounset -o pipefail
echo "Hello from custom script"
EOF
chmod +x "${custom_script_path}"
output="$( "${run_nix_shell_sh}" "${custom_script_path}" )"
assert_equal "Hello from custom script" "${output}" "${assert_msg}"

