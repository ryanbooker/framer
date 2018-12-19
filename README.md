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

## Installation

### Using the Homebrew package manager

0. Open `Terminal.app` on `macOS`, or equivalent on any other *nixish platform
1. Install `Homebrew` by following the instructions @ https://brew.sh/
2. In the terminal type:
    ```
    $ brew install ffmpeg imagemagick parallel git
    ```
3. Download `framer` from https://github.com/ryanbooker/Framer/archive/master.zip, and unzip it in your home folder (or wherever you want to install it)

    Or in the terminal type:
    ```
    git clone https://github.com/ryanbooker/Framer.git ~/framer
    ```
4. Run `framer` as described in the first section, above. Enjoy. :)

### Using the Nix package manager

0. Open `Terminal.app` on `macOS`, or equivalent on any other *nixish platform
1. Install `Nix` by following the instructions @ https://nixos.org/nix/
3. Download `framer` from https://github.com/ryanbooker/Framer/archive/master.zip, and unzip it in your home folder (or wherever you want to install it)

    Or in the terminal type:
    ```
    git clone https://github.com/ryanbooker/Framer.git ~/framer
    ```
3. Run `framer` as described in the first section, above. Either via the `nix-shell` command
    ```
    $ nix-shell --run "./framer.sh -i input.mov"
    ```
    Or inside an actual `nix-shell`
    ```
    $ nix-shell
    [nix-shell]$ ./framer.sh -i input.mov
    ```
