# Ensure that our development shell uses the same Nixpkgs version as what
# rules_nixpkgs uses in Bazel.
let
  lock = builtins.fromJSON (builtins.readFile ./flake.lock);
  nodeName = lock.nodes.${lock.root}.inputs.nixpkgs;
  spec = lock.nodes.${nodeName}.locked;
  nixpkgs = fetchTarball {
    url = spec.url or "https://github.com/${spec.owner}/${spec.repo}/archive/${spec.rev}.tar.gz";
    sha256 = spec.narHash;
  };
in
import nixpkgs
