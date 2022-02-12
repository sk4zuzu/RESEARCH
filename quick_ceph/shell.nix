{ pkgs ? import <nixpkgs> {} }:

with pkgs;

let
  python3-with-pkgs = python3.withPackages (python-pkgs: with python-pkgs; [
    ansible # 2.9
    netaddr
    python
    six
  ]);
in stdenv.mkDerivation {
  name = "quick_ceph-env";
  buildInputs = [
    python3-with-pkgs
    openssh
  ];
}
