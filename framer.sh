#!/bin/bash

# Allow killing the processes in one hit
trap '
  trap - INT # restore default INT handler
  kill -s INT "$$"
' INT

# $1: filter, $2: input
function generate() {
  destination="frames"
  temp="/tmp/frames"

  mkdir -p "$destination"
  mkdir -p "$temp"

  # Generate all the frames
  ffmpeg -loglevel quiet -i "$2" -q:v 1 "$temp/%06d.jpg"

  # Pick from every 30
  ls /tmp/frames/*.jpg | xargs -n30 | parallel $1 $destination {1}

  # Clean up
  rm -rf "$temp"
}

# $1: destination, $2: input
function filter_edges() {
  # Find edges
  printf "%s\n" $2 | parallel 'convert "{1}" -colorspace Gray -edge 2 "{1}.edge.jpg"; identify -format "%[mean]+%[standard-deviation]" "{1}.edge.jpg" | { read a; echo "$a" | bc; } | xargs printf "%s,{1}\n"' | sort -nr | head -n 1 | tr "," "\n" | tail -n 1 | { read f; mv "$f" "$1"; }
}

# $1: destination, $2: input
function filter_size() {
  stat -f %z,%N $2 | sort -nr | head -n 1 | tr "," "\n" | tail -n 1 | { read f; mv "$f" "$1"; }
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

export -f filter_size
export -f filter_edges

# Do it
if [ "$1" = "--edges" ]; then
  echo -en "-- Generating edge filtered frames...  "
  generate filter_edges $2 & spinner
elif [ "$1" = "--size" ]; then
  echo -en "-- Generating size filtered frames...  "
  generate filter_size $2 & spinner
else
  echo -en "-- Generating size filtered frames...  "
  generate filter_size $1 & spinner
fi

echo -e "\n-- Done."
