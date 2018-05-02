# Framer

Pick the best frame from every second of video, for an extremely naive definition of best. There are two filtering options available. By default the script uses edge detection, however when using compressed image types, you may want to use image size as a fast a dirty approiximation for clarity.

```
$ ./framer.sh
Usage: framer.sh [-f <edges|size>] [-o <jp[e]g|p[i]ng|tif[f]>] -i <input_file>

$ ./framer.sh -i input.mov # generate tiff frames using image edges
$ ./framer.sh -f edges -o tif -i input.mov # generate tiff frames using image edges
$ ./framer.sh -f size -o jpg -i input.mov # generate jpeg frames using image size
$ ./framer.sh -f size -o png -i input.mov # generate ping frames using image size
```

## Dependencies
0. *nixish environment
1. ffmpeg
2. imagemagick
3. GNU Parallel
