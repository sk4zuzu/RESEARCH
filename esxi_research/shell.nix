{ pkgs ? import <nixpkgs> {} }:

with pkgs;

stdenv.mkDerivation {
  name = "esxi_research-env";
  buildInputs = [
    curl
    git
    gnumake
    gnutar
    libarchive # bsdtar
    libxslt
    patchelf
    unzip
  ];
}
