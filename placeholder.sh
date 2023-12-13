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
  -F FONT_SIZE   The label font size [default: Calculated based on image size]
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

while getopts "b:f:F:s:l:w:h:H" opt; do
  case $opt in
    b) background=$OPTARG;;
    f) foreground=$OPTARG;;
    F) font=$OPTARG;;
    s) font_size=$OPTARG;;
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

# Print help, if no output file
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

  # When the default label is used, replace "x" with multiplication sign in label
  if [ -z "$label" ]; then
    label=$(tr "x" "×" <<< "$size")
  fi

  # Get font file path
  font_info=$(convert -list font | awk -v font="${font}\$" '$2~font{getline;while($1!="Font:"){print;getline}}')
  font_family=$(echo "$font_info" | awk '$1=="family:"{$1="";print substr($0,2)}')
  font_path=$(echo "$font_info" | awk '$1=="glyphs:"{print $2}')

  # Set font size, if undefined
  if [ -z "$font_size" ]; then
    # This is a magic number based on the font and the number of characters
    font_size=$((width / 8))
    if (( $font_size > $((height / 2)) )); then
      font_size=$((height / 2))
    fi
  fi

  if [ $ext == "svg" ]; then
    echo -n "<svg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 $width $height'><defs><style>@font-face{font-family:'$font_family';src:url('$font_path')}svg{background:$background;font-family:'$font_family'}rect{fill:#0000;outline:1px solid $foreground}text{fill:$foreground;text-anchor:middle;alignment-baseline:central}</style></defs><rect width='$width' height='$height'/><text x='50%' y='50%' font-size='$font_size'>$label</text></svg>" > "$output"
  elif [ $ext == "mp4" ]; then
    duration=5
    ffmpeg -loglevel error -loop 1 -r 1/${duration} -i <(convert -background "$background" -fill "$foreground" -pointsize "$font_size" -font "$font" "label:${label}" -trim +repage -gravity center -extent "$size" png:-) -c:v libx264 -tune stillimage -t ${duration} -pix_fmt yuv420p "$output"
  else
    # convert -size "$size" xc:"$background" "$output"
    # convert -size "$size" -background "$background" -fill "$foreground" -gravity center -pointsize 60 label:"$label" "$output"
    # Scale text porportinately
    convert -background "$background" -fill "$foreground" -pointsize "$font_size" -font "$font" "label:${label}" -trim +repage -gravity center -extent "$size" "$output"
  fi
}

mkimg "$@"
