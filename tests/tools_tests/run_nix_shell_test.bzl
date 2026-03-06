load("@rules_shell//shell:sh_library.bzl", "sh_library")
load("@rules_shell//shell:sh_test.bzl", "sh_test")

def _resolve_rlocationpath(env):
    return {name: "$(rlocationpath {})".format(label) for name, label in env.items()}

def run_nix_shell_test(name, test_file = None, **kwargs):
    if test_file == None:
        test_file = "{}.sh".format(name)

    lib_name = name + "_library"
    sh_library(
        name = lib_name,
        srcs = [test_file],
    )

    location_env = {
        "ASSERTIONS_SH_LOCATION": "@cgrindel_bazel_starlib//shlib/lib:assertions.sh",
        "FLAKE_LOCK_LOCATION": "//:flake.lock",
        "NODE_BINARY_LOCATION": "@nodejs//:bin/node",
        "NODE_BUNDLE_MJS_LOCATION": "//:dist",
        "RUN_NIX_SHELL_SH_LOCATION": "//tools:run_nix_shell",
    }
    sh_test(
        name = name,
        srcs = ["@run_nix_shell//tests/tools_tests:run_nix_shell_test_runner.sh"],
        args = [
            "$(location :{})".format(lib_name),
        ],
        env = _resolve_rlocationpath(location_env),
        data = [lib_name] + location_env.values(),
        tags = [
            # MacOS sandbox fails this test with the following error:
            #   sandbox-exec: sandbox_apply: Operation not permitted
            "no-sandbox",
            # Avoid race condition with fetchTarball failing to access
            #   $HOME/.cache/nix/tarball-cache
            "exclusive-if-local",
        ],
        deps = [
            "@bazel_tools//tools/bash/runfiles",
            "@cgrindel_bazel_starlib//shlib/lib:assertions",
        ],
        **kwargs
    )
