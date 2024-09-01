#!/bin/bash

# start up
randName=`< /dev/urandom tr -cd 0-9 | head -c 5`
dir_in="/home/steve/Downloads"
dir="/home/steve/Downloads/"`echo ${1%.*}`
ww=`convert $dir/start.png -format %w info:`
hh=`convert $dir/start.png -format %h info:`
mkdir -p $dir
rm -f $dir/*

# rename files/folders numerically
filetype=jpg
SAVEIFS=$IFS
IFS=$(echo -en "\n\b")
a=1
for i in $1/*.${filetype}; do
  new=$(printf "%04d" "$a")
  mv -- "$i" "$1/${new}.${filetype}"
  let a=a+1
done
IFS=$SAVEIFS

# replace spaces with underscores
find -name "* *" -type d | rename 's/ /_/g'    # do directories first
find -name "* *" -type f | rename 's/ /_/g'

# remove parentheses and brackets
rename -n 's/\(|\[|\]|\)//g' *
# remove characters in parentheses or brackets
rename -n 's/\(.*\)|\[.*\]//g' *
# remove spaces
rename -n 's/\(.*\)|\[.*\]| //g' *

# named or random file
passed=$1
if [ -d "${passed}" ]; then
  dir=${1}
  file1=`ls $dir/*.jpg | shuf -n1`
  file2=`ls $dir/*.jpg | shuf -n1`
else
  dir=${1}
  file1='${dir}/${2}'
  file2='${dir}/${3}'
fi

# shepards distort
# starting
x1=$(( $RANDOM % ww ))
y1=$(( $RANDOM % hh ))
x2=$(( $RANDOM % ww ))
y2=$(( $RANDOM % hh ))
x3=$(( $RANDOM % ww ))
y3=$(( $RANDOM % hh ))
# moving
alimit=50
a1=${signs[$[ ( $RANDOM % 2 ) +1 ]]}$(( $RANDOM % $alimit ))
a2=${signs[$[ ( $RANDOM % 2 ) +1 ]]}$(( $RANDOM % $alimit ))
a3=0
echo "distort: "$a1 $a2 $a3
#echo "distorting..."
#convert -gravity Center -virtual-pixel ${virtual} -composite -compose Screen $1 /home/steve/Downloads/tmp/rgb2.png -define shepards:power=8.0 -distort Shepards "$((x1)),$((y1)) $((x1)),$((${y1}+${a1})) $((x2)),$((y2)) $((${x2}+${a2})),$((y2))" -roll +0+${roll} /home/steve/Downloads/tmp/rgb.png

# add bottom padding
-gravity South -splice 0x200

# stripe (HORIZONTAL, HORIZONTAL2, HORIZONTAL3, CROSSHATCH)
echo "striping..."
convert -alpha on -size $((ww))x$((hh)) pattern:HORIZONTAL -transparent white /home/steve/Downloads/tmp/mask.png
convert -channel A -evaluate set 50% -gravity Center -composite -compose ATop /home/steve/Downloads/tmp/rgb2.png /home/steve/Downloads/tmp/mask.png /home/steve/Downloads/tmp/masked.png

# rgb split (old school look)
echo "rgb splitting..."
convert $1 -quiet -alpha on -black-threshold ${blackThreshold}% -roll -20+0 -channel GB -evaluate set 0 -channel A -evaluate set ${alpha}% -transparent black /home/steve/Downloads/tmp/red.png
convert $1 -quiet -virtual-pixel ${virtual} -background $back -roll -20+0 -channel GB -evaluate set 0 -channel A -evaluate set ${alpha}% /home/steve/Downloads/tmp/red.png
convert $1 -quiet -virtual-pixel ${virtual} -background $back -roll +0+0 -channel RB -evaluate set 0 -channel A -evaluate set ${alpha}% /home/steve/Downloads/tmp/green.png
convert $1 -quiet -virtual-pixel ${virtual} -background $back -roll +20+0 -channel RG -evaluate set 0 -channel A -evaluate set ${alpha}% /home/steve/Downloads/tmp/blue.png
convert -composite -compose Screen /home/steve/Downloads/tmp/red.png /home/steve/Downloads/tmp/green.png /home/steve/Downloads/tmp/rg.png
convert -composite -compose Screen /home/steve/Downloads/tmp/rg.png /home/steve/Downloads/tmp/blue.png -brightness-contrast 25x100% -colorspace CMYK -gravity Center -geometry $((ww))x$((hh))^ -crop $((ww))x$((hh))+0+0 /home/steve/Downloads/tmp/rgb.png

# shadow layer
echo "distorting..."
width1=`identify -quiet -format "%w" $1`
height1=`identify -quiet -format "%h" $1`
convert $1 -quiet -virtual-pixel ${virtual} -background $back -rotate $rotate1 /home/steve/Downloads/tmp/in1.png
convert $2 -quiet -virtual-pixel ${virtual} -background $back -rotate $rotate2 -shave ${shave}x${shave} /home/steve/Downloads/tmp/in2a.png
convert $2 -quiet -virtual-pixel ${virtual} -background $back -rotate $rotate1 -roll +20+0 -threshold 50% -distort Perspective "0,0 20,20  ${width1},0 $(( width1-20 )),20  0,${height1} 0,${height1}  ${width1},${height1} ${width1},${height1}" -alpha on -channel a -evaluate set 20% /home/steve/Downloads/tmp/in2b.png
convert -composite -compose Over /home/steve/Downloads/tmp/in2a.png /home/steve/Downloads/tmp/in2b.png /home/steve/Downloads/tmp/in2.png

# mask shadow
#convert $1 -quiet -alpha on -black-threshold ${blackThreshold}% -roll -20+0 -channel GB -evaluate set 0 -channel a -evaluate set ${alpha}% -transparent black /home/steve/Downloads/tmp/red.png

# perspective distort
echo "distorting..."
width1=`identify -quiet -format "%w" $1`
height1=`identify -quiet -format "%h" $1`
convert $1 -quiet -virtual-pixel ${virtual} -background $back -rotate $rotate1 -distort Perspective "0,0 200,200  ${width1},0 $(( width1-200 )),200  0,${height1} 0,${height1}  ${width1},${height1} ${width1},${height1}" /home/steve/Downloads/tmp/in1.png

# grid
echo "boxing..."
for ((a=0; a<=972; a=a+108)); do
  for ((b=0; b<=972; b=b+108)); do
    convert $1 -gravity Center -roll -${a}-${b} -extent 108x108+0+0 /home/steve/Downloads/tmp/box${a}-${b}.png
  done
done
echo "assembling.."
for ((a=0; a<=972; a=a+108)); do
  files=`ls /home/steve/Downloads/tmp/box${a}-*.png`
  convert `echo $files` -append /home/steve/Downloads/tmp/column${a}.png
done
files=`ls /home/steve/Downloads/tmp/column*.png`
convert `echo $files` +append /home/steve/Downloads/tmp/all.png

# vertical strips
echo "stripping..."
for a in 0 100 200 300 400 500 600 700 800 900; do
  convert $dir/tmp/green.png -roll -${a}+0 -gravity West -crop $((ww/geom))x$((hh))+0+0 -roll +0+`echo "$(shuf -i 0-100 | head -1)-50" | bc` $dir/tmp/strip${a}.png
done
files=`ls $dir/tmp/strip*.png`
convert -colorspace RGB `echo $files` +append $dir/tmp/all.png

# just shadows
convert $1 -gravity Center -geometry 750x750^ -crop 750x750+0+0 -alpha on -background black -extent ${ww}x${hh} -modulate 100,300,100 -channel BG -evaluate set 0 -channel R -modulate 300,10,0 $dir/tmp/shadow.png

# triangle
  convert -size 100x60 xc:skyblue -fill white -stroke black \
          -draw "path 'M 20,55  A 100,100 0 0,0 25,10
                                A 100,100 0 0,0 70,5
                                A 100,100 0 0,0 20,55 Z' " triangle_curved.gif

# partially filled in
convert "$1" -alpha on -background none -gravity Center -geometry $((ww))x$((hh))^ -crop $((ww))x$((hh))+0+0 -modulate 50,100,${hue} -channel RG -evaluate set 0 -fuzz 50% -transparent blue $dir/tmp/blue.png

# pixelate
convert $1 -gravity Center -scale 10% -scale 1000% -geometry $((ww))x$((hh))^ -crop $((ww))x$((hh))+0+0 /home/steve/Downloads/tmp/in.png

# red pencil
echo "making..."
convert "$1" -alpha on -background black -gravity Center -geometry $((ww))x$((hh))^ -crop $((ww))x$((hh))+0+0 -modulate ${brightness},${saturation},${hue} -shade 0x90 -channel BG -evaluate set 0 -channel R -negate $dir/tmp/red.png

# brightness mask
convert $1 -quiet -alpha on -black-threshold ${blackThreshold}% -roll -50+0 -channel GB -evaluate set 0 -channel A -evaluate set ${alpha}% -transparent black /home/steve/Downloads/tmp/red.png

# vertical text
convert -alpha on -background none -fill ${color_fill} -font '/home/steve/.fonts/chinese/GB5ZYB1B.TTF' -gravity Center -size $((ww))x$((hh)) -pointsize 100 -interline-spacing 0 caption:"a\nb\nc\nd" -roll +7+0 $dir/tmp/caption.png

# b&w cutout
convert "$1" -modulate ${brightness},${saturation},${hue} -negate -colorspace CMYK -channel K -separate $dir/tmp/color.png

# arc distort
convert $1 -virtual-pixel edge -gravity ${gravity} -distort Arc 180 -extent ${ww}x${hh} $dir/poster3_$(basename "${1%.*}").png

# add transparent gradient bottom
#convert $dir/tint1.png \( -size ${ww}x${hh} gradient: \) -compose copy_opacity -composite $dir/tint.png

# grayscale without dither
convert $dir_in/$1 -dither none -colors 6 -colorspace Gray $dir/"gray.png"

# darken
convert $dir_in/$1 -level 50%,100% $dir/comic1.png

# vertigo
convert -size ${ww}x${hh} -virtual-pixel Tile pattern:left45 -distort Polar 0 $dir/vertigo.png

# shooting stars
convert -size ${ww}x${hh} xc: +noise Random -channel RGB -threshold .4% -channel RGB -separate +channel \( +clone \) -compose multiply -flatten -virtual-pixel tile -blur 0x.4 -motion-blur 0x20+45 -normalize $dir/stars.png

# color w/ transparency
convert -fill red -colorize 100 $a -channel rgba -alpha set `echo ${a%.*}`_red.png

# trace with potrace
convert $1 -canny 0x1+10%+20% -negate -gravity Center -geometry $((ww))x$((hh))^ -crop $((ww))x$((hh))+0+0 $dir/tmp/canny.pbm
potrace --alphamax 1 -b svg --color \#ff3333 --opttolerance 0.2 --output $dir/tmp/trace.svg --turdsize 20 --turnpolicy min --unit 10 $dir/tmp/canny.pbm

# trace with autotrace
autotrace -output-file $dir/gray1.svg $dir/gray1_smooth.png

# masking
convert -composite -compose Multiply $dir/tmp/caption.png $dir/tmp/red.png -alpha Set $dir/$(basename "${file1%.*}")_$(basename "${file2%.*}").png

# photocopying
convert $dir_in/$1 -colorspace Gray \( +clone -blur 0x2 \) +swap -compose divide -composite -linear-stretch 5%x0% $dir/"photocopy.png"

# smoothing
convert $dir_in/$1 -kuwahara 9 $dir/"smooth.png"

# motion blurring
convert $dir/gray1_red.png -channel RGBA -motion-blur 0x10+90 $dir/motionblur.png

# default sketching
convert $dir_in/$1 -colorspace gray -sketch 0x10+120 $dir/"sketch.png"

# gradienting
convert $dir_in/$1 \( -size ${ww}x${hh} gradient: \) -alpha off -compose copy_opacity -composite $dir/"gradient1.png"
