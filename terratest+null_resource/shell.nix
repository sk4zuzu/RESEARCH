{ pkgs ? import <nixpkgs> {} }:

with pkgs;

stdenv.mkDerivation {
  name = "research-terratest-aws-env";
  buildInputs = [
    gnumake
    go
  ];
}
