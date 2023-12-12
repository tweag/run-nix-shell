# Ensure that our development shell uses the same Nixpkgs version as what
# rules_nixpkgs uses in Bazel.
let
  lock = builtins.fromJSON (builtins.readFile ./flake.lock);
  spec = lock.nodes.nixpkgs.locked;
  nixpkgs = fetchTarball "https://github.com/${spec.owner}/${spec.repo}/archive/${spec.rev}.tar.gz";
in
import nixpkgs
