# Framer

Pick the best frame from every second of video, for an extremely naive definition of best. There are two filtering options available. By default the script uses edge detection, however when using compressed image types, you may want to use image size as a fast a dirty approiximation for clarity.

```
$ ./framer.sh
Usage: framer.sh [-f <edges|size>] [-o <output_path>] [-t <jp[e]g|p[i]ng|tif[f]>] -i <input_file>

$ ./framer.sh -i input.mov # generate ping frames using image edges
$ ./framer.sh -f edges -t tif -i input.mov # generate tiff frames using image edges
$ ./framer.sh -f size -t jpg -i input.mov # generate jpeg frames using image size
$ ./framer.sh -f size -t png -i input.mov # generate ping frames using image size
```

## Runtime Dependencies
0. *nixish environment
1. [ffmpeg](https://ffmpeg.org)
2. [imagemagick](https://www.imagemagick.org)
3. [GNU Parallel](https://www.gnu.org/software/parallel/)

## Nix

If you have the nix package manager installed, you can run everything via `nix-shell` and have it handle the dependencies.

```
$ nix-shell --run "./framer.sh -i input.mov"
```
or inside an actual `nix-shell`
```
$ nix-shell
[nix-shell]$ ./framer.sh -i input.mov
```
