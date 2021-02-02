#!/usr/bin/env bash

# Set global variables
PROGNAME=$(basename "$0")
VERSION='1.1.1'

print_help() {
cat <<EOF
Usage:    $PROGNAME [options] output
Version:  $VERSION

Creates placeholder images.

Options: (all optional)
  -b BACKGROUND  The background color [default: #888]
  -f FOREGROUND  The foreground color [default: #fff]
  -l LABEL       The label [default: image dimensions]
  -w WIDTH       The image width [default: parsed from output name]
  -h HEIGHT      The image height [default: parsed from output name]

Example:
  ${PROGNAME} -b #eee -f #000 600x400.png

EOF
exit $1
}

##
# Check for a dependency
#
# @param 1 Command to check
##
dependency() {
  hash "$1" &>/dev/null || error "$1 must be installed"
}

################################################################################

# Check dependencies
dependency convert

# Initialize variables
background="#888"
foreground="#fff"
label=""

while getopts "b:f:l:w:h:H" opt; do
  case $opt in
    b) background=$OPTARG;;
    f) foreground=$OPTARG;;
    l) label=$OPTARG;;
    w) width=$OPTARG;;
    h) height=$OPTARG;;
    H) print_help 0;;
    *) print_help 1;;
  esac
done

shift $(( OPTIND - 1 ))

# Store output filename
output="$1"

# Print help, if no input file
[ -z "$output" ] && print_help 1

# Create placeholder image
# Inspired by https://dummyimage.com
mkimg() {
  filename="${output##*/}"
  ext="${filename##*.}"

  # "×"
  if [ -z "$width" ] || [ -z "$height" ]; then
    # Parse size from output filename
    name_size="${filename%.*}"
    read width height <<<$(tr x " " <<< "$name_size")
  fi
  size="${width}x${height}"

  if [ -z "$label" ]; then
    label=$(tr "x" "×" <<< "$size")
  fi

  if [ -n "$output" ] && [ $ext != "svg" ]; then
    # convert -size "$size" xc:"$background" "$output"
    # convert -size "$size" -background "$background" -fill "$foreground" -gravity center -pointsize 60 label:"$label" "$output"
    # Scale text porportinately
    convert -background "$background" -fill "$foreground" -pointsize 1000 label:"$label" -trim +repage -resize "$((width / 2))x$((height / 2))" -gravity center -extent "$size" "$output"
  else
    echo "<svg xmlns='http://www.w3.org/2000/svg' width='$width' height='$height' viewBox='0 0 $width $height'><rect width='$width' height='$height' fill='$background'/><text text-anchor='middle' alignment-baseline='central' x='50%' y='50%' fill='$foreground'>$label</text></svg>"
  fi
}

mkimg "$@"
