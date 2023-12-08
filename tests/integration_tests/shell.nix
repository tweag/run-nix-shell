{ 
  customVarBool ? false,
  customVarStr ? "default",
  lock ? builtins.fromJSON (builtins.readFile ./../../flake.lock),
}:
(import
  (
    fetchTarball {
      url = lock.nodes.flake-compat.locked.url or "https://github.com/edolstra/flake-compat/archive/${lock.nodes.flake-compat.locked.rev}.tar.gz";
      sha256 = lock.nodes.flake-compat.locked.narHash;
    }
  )
  { src = ./../../.; }
).shellNix // (
  # let pkgs = import (
  #   fetchTarball {
  #     url = "https://github.com/NixOS/nixpkgs/archive/${lock.nodes.nixpkgs.locked.rev}.tar.gz";
  #     sha256 = lock.nodes.nixpkgs.locked.narHash;
  #   }
  # ) {}; in
  # with pkgs;
  # mkShell {
  #   CUSTOM_VAR_BOOL = if customVarBool then "true" else "false";
  #   CUSTOM_VAR_STR = customVarStr;
  # }
  {}
)
