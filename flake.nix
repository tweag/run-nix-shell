{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    # Library for working with tools that need default.nix and shell.nix.
    # https://nixos.wiki/wiki/Flakes#Using_flakes_with_stable_Nix
    flake-compat = {
      url = "github:edolstra/flake-compat";
      flake = false;
    };
  };
  outputs = { nixpkgs, flake-utils, ... }:
    # For every platform that Nix supports, we ...
    flake-utils.lib.eachDefaultSystem (system:
      # ... get the package set for this particular platform ...
      let pkgs = import nixpkgs { inherit system; };
      in {
        # ... and define a development shell for it ...
        devShells.default = with pkgs; mkShell {
            # BEGIN Config to build Bazel 6
            # do not use Xcode on macOS
            BAZEL_USE_CPP_ONLY_TOOLCHAIN = "1";
            # for nixpkgs cc wrappers, select C++ explicitly (see https://github.com/NixOS/nixpkgs/issues/150655)
            BAZEL_CXXOPTS = "-x:c++";
            buildInputs = lib.optional pkgs.stdenv.isDarwin darwin.cctools;
            # END Config to build Bazel 6
            # Name for the shell
            name = "run_nix_shell_shell";
            # ... which makes available the following dependencies, 
            packages = [ bazel_6 bazel-buildtools cacert gcc nix git openssh ];
          };
      });
}
