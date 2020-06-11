#!/usr/bin/env bash

# Create placeholder image
# Inspired by https://dummyimage.com
img() {
  output="$1"
  filename="${output##*/}"
  size="${filename%.*}"
  ext="${filename##*.}"

  background="#888"
  foreground="#fff"

  # "×"
  read width height <<<$(tr x " " <<< "$size")
  label=$(tr "x" "×" <<< "$size")

  if [ -n "$output" ] && [ $ext != "svg" ]; then
    # convert -size "$size" xc:"$background" "$output"
    # convert -size "$size" -background "$background" -fill "$foreground" -gravity center -pointsize 60 label:"$label" "$output"
    # Scale text porportinately
    convert -background "$background" -fill "$foreground" -pointsize 1000 label:"$label" -trim +repage -resize "$((width / 2))x$((height / 2))" -gravity center -extent "$size" "$output"
  else
    echo "<svg xmlns='http://www.w3.org/2000/svg' width='$width' height='$height' viewBox='0 0 $width $height'><rect width='$width' height='$height' fill='$background'/><text text-anchor='middle' alignment-baseline='central' x='50%' y='50%' fill='$foreground'>$label</text></svg>"
  fi
}

img "$@"
