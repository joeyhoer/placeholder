#!/usr/bin/env bash

# Set global variables
PROGNAME=$(basename "$0")
VERSION='1.2.0'

print_help() {
cat <<EOF
Usage:    $PROGNAME [options] output
Version:  $VERSION

Creates placeholder images.

Options: (all optional)
  -b BACKGROUND  The background color [default: #888]
  -f FOREGROUND  The foreground color [default: #fff]
  -F FONT        The label font [default: "SF-Pro"]
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
font="SF-Pro"

while getopts "b:f:F:l:w:h:H" opt; do
  case $opt in
    b) background=$OPTARG;;
    f) foreground=$OPTARG;;
    F) font=$OPTARG;;
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

  # Get font file path
  font_info=$(convert -list font | awk -v font="${font}\$" '$2~font{getline;while($1!="Font:"){print;getline}}')
  font_family=$(echo "$font_info" | awk '$1=="family:"{$1="";print substr($0,2)}')
  font_path=$(echo "$font_info" | awk '$1=="glyphs:"{print $2}')

  if [ -n "$output" ] && [ $ext != "svg" ]; then
    # convert -size "$size" xc:"$background" "$output"
    # convert -size "$size" -background "$background" -fill "$foreground" -gravity center -pointsize 60 label:"$label" "$output"
    # Scale text porportinately
    convert -background "$background" -fill "$foreground" -pointsize 1000 -font "$font" label:"$label" -trim +repage -resize "$((width / 2))x$((height / 2))" -gravity center -extent "$size" "$output"
  else
    # This is a magic number based on the font and the number of characters
    font_size=$((width / 8))
    if [[ $font_size > $((height / 2)) ]]; then
      font_size=$((height / 2))
    fi
    echo -n "<svg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 $width $height'><defs><style>@font-face{font-family:'$font_family';src:url('$font_path')}:root{background:$background}rect{fill:none;outline:$foreground;outline-style:solid;outline-width:1px}</style></defs><rect width='$width' height='$height'/><text text-anchor='middle' alignment-baseline='central' x='50%' y='50%' fill='$foreground' font-family='$font_family' font-size='$font_size'>$label</text></svg>" > "$output"
  fi
}

mkimg "$@"
