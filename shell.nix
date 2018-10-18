{ pkgs ? import <nixpkgs> {} }:

with pkgs;
stdenv.mkDerivation {
  name = "shell";
  buildInputs = [
    bc
    ffmpeg
    imagemagick
    parallel
    ps
  ];
}

