{ pkgs ? import <nixpkgs> {} }:

with pkgs;

stdenv.mkDerivation {
  name = "xslt_research-env";
  buildInputs = [
    gnumake
    libxslt
  ];
}
