#!/bin/bash

# Allow killing the processes in one hit
trap '
  trap - INT # restore default INT handler
  pkill -P $$
' INT

trap '
  rm -rf /tmp/frames
' EXIT

# $1: filter, $2: input file, $3: output path, $4 output type, $5 output args
function generate() {
  local duration=`ffprobe -v error -select_streams v:0 -show_entries stream=duration -of default=noprint_wrappers=1:nokey=1 "$2"`
  local fps=`ffprobe -v error -select_streams v:0 -show_entries stream=r_frame_rate -of default=noprint_wrappers=1:nokey=1 "$2" | bc -l | xargs printf "%.0f"`
  seq 0 $duration | parallel frame "$1" "\"$2\"" "\"$3\"" "$4" "\"$5\"" "$fps" {1}
}

# $1: filter, $2: input file, $3 output path, $4 output type, $5: output args, $6 fps, $7: second to detect
function frame() {
  temp="/tmp/frames/$(basename "$3")/$7"
  mkdir -p "$temp"

  outdir="$3/frames"
  mkdir -p "$outdir"

  # Generate all the frames for this second
  local start_number=`echo "1+$6*$7" | bc`
  ffmpeg -loglevel quiet -y -i "$2" -ss "$7" -t 1 -start_number "$start_number" -an $5 "$temp/%06d.$4"

  # Pick a frame
  frames=$(ls "$temp"/*.$4)
  $1 "$outdir" "$frames"

  # Clean up
  rm -rf "$temp"
}

# $1: destination, $2: input
function filter_edges() {
  # Find edges
  parallel 'convert "{1}" -colorspace Gray -edge 2 "{1}.edge.png"; identify -format "%[mean]+%[standard-deviation]" "{1}.edge.png" | { read a; echo "$a" | bc; } | xargs printf "%s,{1}\n"' ::: $2 | sort -nr | head -n 1 | tr "," "\n" | tail -n 1 | { read f; mv "$f" "$1"; }
}

# $1: destination, $2: input
function filter_size() {
  stat -f %z,%N "$2" | sort -nr | head -n 1 | tr "," "\n" | tail -n 1 | { read f; mv "$f" "$1"; }
}

function spinner() {
  while [ "$(ps a | awk '{print $1}' | grep $!)" ]
  do
    for X in '-' '/' '|' '\'
    do
      echo -en "\b\b $X"
      sleep 0.1
    done
  done
}

function usage() { echo "Usage: `basename $0` [-f <edges|size>] [-o <output_path>] [-t <jp[e]g|p[i]ng|tif[f]>] -i <input_file>" 1>&2; exit 1; }

export -f frame
export -f filter_edges
export -f filter_size

filter=filter_edges
type="png"
output="."
args="-pix_fmt rgb24 -vcodec tiff"

while getopts ":f:o:t:i:" o; do
  if [[ $OPTARG = -* ]]; then
    OPTARG=$o
    o=":"
  fi

  case "$o" in
    i) input="$OPTARG";;
    o) output="$OPTARG";;
    f)
      case "$OPTARG" in
        edge|edges)
          filter=filter_edges
          ;;
        size)
          filter=filter_size
          ;;
        *)
          usage
          exit $E_OPTERROR
          ;;
      esac
      ;;
    t)
      case "$OPTARG" in
        jpg|jpeg)
          type="jpg"
          args="-q:v 1"
          ;;
        png|ping)
          type="png"
          args=""
          ;;
        tif|tiff|*)
          type="tif"
          args="-pix_fmt rgb24 -vcodec tiff"
          ;;
      esac
      ;;
    :)
      echo "Option -$OPTARG requires an argument. See usage." >&2
      usage
      exit $E_OPTERROR;
      ;;
    \?) usage;;
  esac
done

if [ ! "$input" ]; then
  usage
  exit $E_OPTERROR
else
  echo -en "-- Generating edge filtered frames...  "
  generate "$filter" "$input" "$output" "$type" "$args" & spinner
  echo -e "\n-- Done."
fi
