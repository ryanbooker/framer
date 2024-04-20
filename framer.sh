#!/bin/bash

# Allow killing the processes in one hit
trap '
  trap - INT # restore default INT handler
  pkill -P $$
' INT

trap '
  rm -rf /tmp/frames
' EXIT

# $1: filter, $2: input file, $3: output path, $4 output type, $5 frames per second, $6 output args
function generate() {
  local duration
  local fps
  local step

  duration=$(ffprobe -v error -select_streams v:0 -show_entries stream=duration -of default=noprint_wrappers=1:nokey=1 "$2")

  fps=$(ffprobe -v error -select_streams v:0 -show_entries stream=r_frame_rate -of default=noprint_wrappers=1:nokey=1 "$2" | bc -l | xargs printf "%.0f")

  step=$(printf '%f\n' "$(echo "1/$5" | bc -l)")

  seq 0 "$step" "$duration" | parallel -j 0 frame "$1" "\"$2\"" "\"$3\"" "$4" "\"$6\"" "$fps" "$step" "{1}"
}

# $1: filter, $2: input file, $3 output path, $4 output type, $5: output args, $6 fps, $7: step, $8: segment to detect
function frame() {
  temp="/tmp/frames/$(basename "$3")/$8"
  mkdir -p "$temp"

  outdir="$3/frames"
  mkdir -p "$outdir"

  # Generate all the frames for this second
  local start_number
  start_number=$(echo "1+$6*$8" | bc -l)

  local to
  to=$(printf '%f\n' "$(echo "$8+$7" | bc -l)")

  ffmpeg -loglevel quiet -y -an -i "$2" -ss "$8" -to "$to" -start_number "$start_number" $5 "$temp/%09d.$4"

  # Pick a frame
  frames=$(ls "$temp"/*."$4")
  $1 "$outdir" "$frames"

  # Clean up
  rm -rf "$temp"
}

# $1: destination, $2: input
function filter_edges() {
  # Find edges
  parallel 'convert {1} -colorspace Gray -edge 1 {1}.edge.png; identify -format "%[standard-deviation]" {1}.edge.png | { read a; echo "$a" | bc; } | xargs printf "%s,{1}\n"' ::: "$2" | sort -nr | head -n 1 | cut -d ',' -f2 | tr -d "'" | {
    read -r f
    mv "$f" "$1"
  }
}

# $1: destination, $2: input
function filter_canny() {
  # Find edges
  parallel 'convert {1} -colorspace Gray -canny 0x1+10%+30% {1}.edge.png; identify -format "%[standard-deviation]" {1}.edge.png | { read a; echo "$a" | bc; } | xargs printf "%s,{1}\n"' ::: "$2" | sort -nr | head -n 1 | cut -d ',' -f2 | tr -d "'" | {
    read -r f
    mv "$f" "$1"
  }
}

# $1: destination, $2: input
function filter_size() {
  stat -c %s,%N $2 | sort -nr | head -n 1 | cut -d ',' -f2 | tr -d "'" | {
    read -r f
    mv "$f" "$1"
  }
}

function spinner() {
  while ps a | awk '{print $1}' | grep -q "$!"
  do
    for x in '-' '/' '|' '\'
    do
      echo -en "\b\b $x"
      sleep 0.1
    done
  done
}

function usage() {
  echo "Usage: $(basename "$0") [-f <canny|edges|size>] [-o <output_path>] [-t <jp[e]g|p[i]ng|tif[f]>] -i <input_file> -n <frames_per_second>" 1>&2
  exit 1
}

export -f frame
export -f filter_edges
export -f filter_canny
export -f filter_size

filter=filter_canny
type="png"
output="."
args="-pix_fmt rgb24 -vcodec tiff"
number=1

while getopts ":f:o:t:i:n:" o; do
  if [[ "$OPTARG" = -* ]]; then
    OPTARG="$o"
    o=":"
  fi

  case "$o" in
    i)
      input="$OPTARG"
      ;;
    o)
      output="$OPTARG"
      ;;
    f)
      case "$OPTARG" in
        canny)
          filter=filter_canny
          ;;
        edge|edges)
          filter=filter_edges
          ;;
        size)
          filter=filter_size
          ;;
        *)
          usage
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
    n)
      number="$OPTARG"
      ;;
    :)
      echo "Option -$OPTARG requires an argument. See usage." >&2
      usage
      ;;
    \?)
      usage
      ;;
  esac
done

if [ ! "$input" ]; then
  usage
else
  echo -en "-- Generating filtered frames...  "
  generate "$filter" "$input" "$output" "$type" "$number" "$args" & spinner
  echo -e "\n-- Done."
fi
