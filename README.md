# Framer

Pick the best frame from every second of video, for an extremely naive definition of best. There are two filtering options available. By the default the script uses image size as a proxy for clarity. The `--edges` option calculates image clarity using edge detection, and is orders of magnitude slower than size.

```
./framer.sh input.mov # generate frames using image size
./framer.sh --size input.mov # generate frames using image size
./framer.sh --edges input.mov # generate frames using image edges
```

## Dependencies
1. ffmpeg
2. imagemagick
