let
  getInputFromLock =
    lock: input:
    let
      nodeName = lock.nodes.${lock.root}.inputs.${input};
      spec = lock.nodes.${nodeName}.locked;
    in
    fetchTarball {
      url = spec.url or "https://github.com/${spec.owner}/${spec.repo}/archive/${spec.rev}.tar.gz";
      sha256 = spec.narHash;
    };
in
{
  customVarBool ? false,
  customVarStr ? "default",
  lock ? builtins.fromJSON (builtins.readFile ./../../flake.lock),
  flakeCompat ? getInputFromLock lock "flake-compat",
  nixpkgs ? getInputFromLock lock "nixpkgs",
}:
(
  # Call flakeCompat with src pointing to the location of the flake.nix.
  import flakeCompat { src = ./../../.; }
).shellNix
// (
  # This expression is generating a shell that is merged with the one provided by shellNix.
  let
    pkgs = import nixpkgs { };
  in
  with pkgs;
  mkShell {
    CUSTOM_VAR_BOOL = if customVarBool then "true" else "false";
    CUSTOM_VAR_STR = customVarStr;
  }
)
