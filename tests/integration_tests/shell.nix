{ 
  customVarBool ? false,
  customVarStr ? "default",
  lock ? builtins.fromJSON (builtins.readFile ./../../flake.lock),
  flakeCompat ? fetchTarball {
    url = lock.nodes.flake-compat.locked.url or "https://github.com/edolstra/flake-compat/archive/${lock.nodes.flake-compat.locked.rev}.tar.gz";
    sha256 = lock.nodes.flake-compat.locked.narHash;
  },
  nixpkgs ? fetchTarball {
    url = "https://github.com/NixOS/nixpkgs/archive/${lock.nodes.nixpkgs.locked.rev}.tar.gz";
    sha256 = lock.nodes.nixpkgs.locked.narHash;
  },
}:
(
  # Call flakeCompat with src pointing to the location of the flake.nix.
  import flakeCompat { src = ./../../.; }
).shellNix // (
  # This expression is generating a shell that is merged with the one provided by shellNix.
  let pkgs = import nixpkgs {}; in
  with pkgs;
  mkShell {
    CUSTOM_VAR_BOOL = if customVarBool then "true" else "false";
    CUSTOM_VAR_STR = customVarStr;
  }
)
