#!/bin/bash

trap '
  trap - INT # restore default INT handler
  kill -s INT "$$"
' INT

echo "-- Generating frames..."

d=`ffprobe -v error -select_streams v:0 -show_entries stream=duration -of default=nokey=1:noprint_wrappers=1 $1`
t=0

mkdir -p "frames"
mkdir -p "/tmp/frames"

while (( $(echo "$t<$d" | bc -l) ))
do
  n=`echo "$t+1" | bc`
  ffmpeg -loglevel quiet -i "$1" -ss "$t" -t 1 -q:v 1 "/tmp/frames/%06d.jpg"
  frame=`printf "frames/%06d.jpg" $n`
  ls -S /tmp/frames/*.jpg | head -n 1 | { read f; mv "$f" "$frame"; }
  rm /tmp/frames/*.jpg
  ((t++))
  printf "."
done

echo "-- Done."

rm -rf "/tmp/frames"
