{ 
  customVarBool ? false,
  customVarStr ? "default",
}:
(import
  (
    let lock = builtins.fromJSON (builtins.readFile ./../../flake.lock); in
    fetchTarball {
      url = lock.nodes.flake-compat.locked.url or "https://github.com/edolstra/flake-compat/archive/${lock.nodes.flake-compat.locked.rev}.tar.gz";
      sha256 = lock.nodes.flake-compat.locked.narHash;
    }
  )
  { src = ./../../.; }
).shellNix // (
  let pkgs = import (
    let lock = builtins.fromJSON (builtins.readFile ./../../flake.lock); in
    fetchTarball {
      url = "https://github.com/NixOS/nixpkgs/archive/${lock.nodes.nixpkgs.locked.rev}.tar.gz";
      sha256 = lock.nodes.nixpkgs.locked.narHash;
    }
  ) {}; in
  with pkgs;
  mkShell {
    CUSTOM_VAR_BOOL = if customVarBool then "true" else "false";
    CUSTOM_VAR_STR = customVarStr;
    # packages = [ nix ];
  }
)
