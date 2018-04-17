#!/bin/bash

# Allow killing the processes in one hit
trap '
  trap - INT # restore default INT handler
  kill -s INT "$$"
' INT

function generate_frames() {
  echo "-- Generating frames..."

  mkdir -p "frames"
  mkdir -p "/tmp/frames"

  # Loop through the video
  d=`ffprobe -v error -select_streams v:0 -show_entries stream=duration -of default=nokey=1:noprint_wrappers=1 $2`
  t=0

  while (( $(echo "$t<$d" | bc -l) ))
  do
    # Generate frames
    ffmpeg -loglevel quiet -i "$2" -ss "$t" -t 1 -q:v 1 "/tmp/frames/%06d.jpg"

    # Filter frames
    n=`echo "$t+1" | bc`
    frame=`printf "frames/%06d.jpg" $n`
    ($1 $frame)

    # Clean up
    rm /tmp/frames/*.jpg

    # Loop
    ((t++))

    # Progress
    printf "."
  done

  echo "-- Done."

  rm -rf "/tmp/frames"
}

function filter_edges() {
  # Find edges
  for f in /tmp/frames/*.jpg
  do
    convert "$f" -colorspace Gray -edge 2 "$f.edge.jpg"
  done

  # Select frame
  i=0; x=0
  for f in /tmp/frames/*[^edge].jpg
  do
    y=`identify -format '%[mean]+%[standard-deviation]' "$f.edge.jpg" | { read a; echo "$a" | bc; }`
    if (( $(echo "$y>$x" | bc -l) ))
    then
      i=$f
    fi
  done

  # Move selected frame
  cp "$i" "$1"
}

function filter_size() {
  ls -S /tmp/frames/*.jpg | head -n 1 | { read f; mv "$f" "$1"; }
}

# Do it
if [ "$1" = "--edges" ]; then
  generate_frames filter_edges $2
elif [ "$1" = "--size" ]; then
  generate_frames filter_size $2
else
  generate_frames filter_size $1
fi
