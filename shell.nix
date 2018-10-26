let pkgs = import <nixpkgs> {};
in with pkgs;
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
