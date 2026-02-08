load("@rules_shell//shell:sh_library.bzl", "sh_library")
load("@rules_shell//shell:sh_test.bzl", "sh_test")

def run_nix_shell_test(name, test_file = None, **kwargs):
    if test_file == None:
        test_file = "{}.sh".format(name)

    lib_name = name + "_library"
    sh_library(
        name = lib_name,
        srcs = [test_file],
    )

    sh_test(
        name = name,
        srcs = ["@run_nix_shell//tests/tools_tests:run_nix_shell_test_runner.sh"],
        args = [
            "$(location :{})".format(lib_name),
        ],
        data = [
            lib_name,
            "//:dist",
            "//:flake_files",
            "//tools:run_nix_shell",
            "@nodejs//:bin/node",
        ],
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
