{
  inputs = {
    # Track a specific tag on the nixpkgs repo.
    # nixpkgs.url = "github:NixOS/nixpkgs/nixos-23.11";
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    # The flake format itself is very minimal, so the use of this
    # library is common.
    flake-utils.url = "github:numtide/flake-utils";

    # Library for working with tools that need default.nix and shell.nix.
    # https://nixos.wiki/wiki/Flakes#Using_flakes_with_stable_Nix
    flake-compat = {
      url = "github:edolstra/flake-compat";
      flake = false;
    };
  };

  # Here we can define various kinds of "outputs": packages, tests, 
  # and so on, but we will only define a development shell.

  outputs = { nixpkgs, flake-utils, ... }:

    # For every platform that Nix supports, we ...
    flake-utils.lib.eachDefaultSystem (system:

      # ... get the package set for this particular platform ...
      let pkgs = import nixpkgs { inherit system; };
      in 
      {

        # ... and define a development shell for it ...
        devShells.default = with pkgs; mkShell {
            # do not use Xcode on macOS
            BAZEL_USE_CPP_ONLY_TOOLCHAIN = "1";
            # for nixpkgs cc wrappers, select C++ explicitly (see https://github.com/NixOS/nixpkgs/issues/150655)
            BAZEL_CXXOPTS = "-x:c++";

            # name = "rules_nixpkgs_shell";
            # buildInputs = lib.optional pkgs.stdenv.isDarwin darwin.cctools;
            # packages = [ bazel_6 bazel-buildtools cacert gcc nix git openssh ];
            name = "run_nix_shell_shell";

            # ... which makes available the following dependencies, 
            # all sourced from the `pkgs` package set:
            # packages = with pkgs; [ bazel_5 bazel-buildtools cacert nix git ];
            # packages = with pkgs; [ bazel_6 cacert nix git ];
            # packages = with pkgs; [ bazelisk cacert nix git ];

            buildInputs = lib.optional pkgs.stdenv.isDarwin darwin.cctools;
            packages = [ bazel_6 bazel-buildtools cacert gcc nix git openssh ];
          };
      });
}
