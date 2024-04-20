#!/bin/bash

# Allow killing the processes in one hit
trap '
  trap - INT # restore default INT handler
  pkill -P $$
' INT

trap '
  rm -rf /tmp/frames
' EXIT

# $1: filter
# $2: input file
# $3: output path
# $4 output type
# $5 frames per second
# $6 output args
# $7 max parallel jobs
function generate() {
  local duration
  local fps
  local step

  duration=$(ffprobe -v error -select_streams v:0 -show_entries stream=duration -of default=noprint_wrappers=1:nokey=1 "$2")

  fps=$(ffprobe -v error -select_streams v:0 -show_entries stream=r_frame_rate -of default=noprint_wrappers=1:nokey=1 "$2" | bc -l | xargs printf "%.0f")

  step=$(printf '%f\n' "$(echo "1/$5" | bc -l)")

  seq 0 "$step" "$duration" | parallel -j "$7" frame "$1" "\"$2\"" "\"$3\"" "$4" "\"$6\"" "$fps" "$step" "{1}" "$7"
}

# $1: filter
# $2: input file
# $3 output path
# $4 output type
# $5: output args
# $6 fps
# $7: step
# $8: segment to detect
# $9: max parallel jobs
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
  $1 "$outdir" "$frames" "$9"

  # Clean up
  rm -rf "$temp"
}

# $1: destination
# $2: input file list
# $3: max parallel jobs
function filter_edges() {
  # Find edges
  parallel -j "$3" 'convert {1} -colorspace Gray -edge 1 {1}.edge.png; identify -format "%[standard-deviation]" {1}.edge.png | { read a; echo "$a" | bc; } | xargs printf "%s,{1}\n"' ::: "$2" | sort -nr | head -n 1 | cut -d ',' -f2 | tr -d "'" | {
    read -r f
    mv "$f" "$1"
  }
}

# $1: destination
# $2: input file list
# $3: max parallel jobs
function filter_canny() {
  # Find edges
  parallel -j "$3" 'convert {1} -colorspace Gray -canny 0x1+10%+30% {1}.edge.png; identify -format "%[standard-deviation]" {1}.edge.png | { read a; echo "$a" | bc; } | xargs printf "%s,{1}\n"' ::: "$2" | sort -nr | head -n 1 | cut -d ',' -f2 | tr -d "'" | {
    read -r f
    mv "$f" "$1"
  }
}

# $1: destination
# $2: input file list
# $3: max parallel jobs
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
  echo "Usage: $(basename "$0") [-f <canny|edges|size>] [-o <output_path>] [-t <jp[e]g|p[i]ng|tif[f]>] -i <input_file> -n <frames_per_second> -j <max_parallel_jobs>" 1>&2
  echo "Parameters:"
  echo "  -f filtering method, defaults to 'canny'"
  echo "  -o output path, a subfolder 'frames' will be created here"
  echo "  -t output format, defaults to 'tiff'"
  echo "  -i input file path"
  echo "  -n frame per second of input, defaults to 1"
  echo "  -j maximum parallel job count, defaults to 20% of cpu cores, passing 0 will be eat all your resources. It is passed directly to GNU parallel's -j option"
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
maxjobs="20%"

while getopts ":f:o:t:i:n:j:" o; do
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
    j)
      maxjobs="$OPTARG"
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
  generate "$filter" "$input" "$output" "$type" "$number" "$args" "$maxjobs" & spinner
  echo -e "\n-- Done."
fi
