{ pkgs ? import <nixpkgs> {} }:

with pkgs;

stdenv.mkDerivation {
  name = "k3s+virtual-kubelet+nomad-env";
  buildInputs = [
    git
    gnumake pkgconfig
    go
  ];
}
