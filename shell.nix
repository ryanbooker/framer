{ pkgs ? import <nixpkgs> {} }:

with pkgs;
stdenv.mkDerivation {
  name = "framer";
  buildInputs = [
    bc
    ffmpeg
    imagemagick
    parallel
    ps
  ];
}

