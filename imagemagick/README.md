# ImageMagick for Mapmakers

Use ImageMagick to create, edit, compose or convert digital images. This is a growing list of my most used ImageMagick commands that extend and enhance map making.

## The Magick

### Basics

Resize  
```shell
# resize all png files by 25% and save as jpg
ls *.png | while read file; do convert -resize 25% ${file} ${file%.*}.jpg; done

# force resize
convert shift_primemeridian_281_04_21_185611.gif -resize 1920x1080\! shift_primemeridian_1920_1080.gif

# resize by width.  
file='Esquire-Magazine-1990-05_0018.jpg'
convert "${file}" -gravity Center -resize 1920x\> +repage "${file%.*}.png"

# pixelate
convert chicago.png -scale 10% -filter point -scale 1000% chicago_pixelated.png
```

Change extent  
```shell
convert "${file}" -background none -gravity center -extent 1920x "${file%.*}_1920.png"
```

Convert to A4 pdf  
```shell
convert `ls *.webp` -colorspace gray -background white -level 60%,100% -page a4 shakespeare_a4_dark.pdf
```

Make blank image  
```shell
convert -size 1920x1080 xc:transparent box.png
```

Crop image  
```shell
convert hyp.png -gravity center -crop 960x540+0+0 +repage hyp_crop.png

convert -gravity center largeprint_kdp-page077.png -crop 1940x600+0+350 +repage largeprint_kdp-page077_1940x600.png

file='ne_50m_land.png'
convert "${file}" -gravity center -geometry 1920x1080^ -crop 1920x1080+0+0 "${file%.*}_1920_1080.png"
```

Split image into parts  
```shell
convert hyp.png -crop 25%x100% +repage hyp_part.png

# halve
convert /home/steve/Downloads/toronto4.png -crop 50%x100% /home/steve/Downloads/toronto4_split.png

# directory
ls /home/steve/tmp/*a.svg | while read frame; do
  convert -background None $frame -crop 100%x2% +repage ${frame%.*}_%d.png
done

# use adjoin to name separate files
convert master-pnp-highsm-04300-04322a.png -crop 25%x100% +repage +adjoin split_%d.png
```

Join using append  
```shell
# append split images in reverse order and flip horizontally
convert $(ls -r hyp_part-*.png) -flop +append hyp_append.png

# append 2 images
file1='Nick Mag #0 - Premiere 1990_0021.jpg'
file2='Nick Mag #0 - Premiere 1990_0022.jpg'
convert "${file1}" "${file2}" -gravity Center +append -resize 960x +repage ~/archive-mag/archive/"${file1%.*}.png"

# split and join in one command using clone
convert master-pnp-highsm-04300-04322a.tif -crop 25%x100% +repage -clone 0 +append master-pnp-highsm-04300-04322a_combined.png
```

Split, apply separate processing and append in one command  
```shell
convert master-pnp-highsm-04300-04322a.png -crop 25%x100% \
  \( -clone 0 -level 10%,90% +repage \) \
  \( -clone 1 -level 20%,80% +repage \) \
  \( -clone 2 -level 30%,70% +repage \) \
  \( -clone 3 -level 40%,60% +repage \) \
  -delete 0,1,2,3 +append +repage master-pnp-highsm-04300-04322a_combined.png
```

Split then append with glitch  
```shell
signs=(+ -)
ls /home/steve/tmp/frame_*.png | while read frame; do
  convert -roll ${signs[$[ ( $RANDOM % 2 ) ]]}`shuf -i 0-20 -n 1`+0 $frame ${frame%.*}_roll.png
done

ls /home/steve/tmp/*a.svg | while read frame; do
  convert -background None `ls -v ${frame%.*}_*_roll.png` -append ${frame%.*}.png
done
rm -f /home/steve/tmp/*roll.png
rm -f /home/steve/tmp/*[0-9].png
```

Analyze image  
```shell
# histogram
convert tianshan.jpg -format %c -depth 8 histogram:info: | sort -n -k 1,1

# convert to HSL
convert tianshan.jpg -colorspace HSL -format "%[fx:mean.h] %[fx:mean.s] %[fx:mean.l]" histogram:info:

# color distribution
convert tianshan.jpg -format %c -depth 8 histogram:info: | awk '{print $2}' | sort | uniq -c | sort -nr
```

### Colors & Effects

Basic adjustments  
```
# automagically adjust colors
convert bangkok.png -auto-level bangkok_levels.png

# adjust gamma
convert bangkok.png -auto-gamma bangkok_levels.png

# set gamma
convert bangkok.png -gamma 1.2 bangkok_levels.png

# bring out contrast
convert bangkok.png -equalize bangkok_levels.png
```

Black & white with threshold  
```shell
convert -colorspace gray manhattan.png -threshold 50% manhattan_threshold.png
```

Reduce the number of colors  
```shell
onvert manhattan.png -colors 4 manhattan_color4.png
```

Adjust black & white point
```shell
convert HYP_HR_SR_OB_DR.png -level 50%,100% hyp.png
```

Stretch contrast  
```shell
convert master-pnp-highsm-04300-04322a.tif -contrast-stretch 0x10 master-pnp-highsm-04300-04322a_level.png
```

Adjust brightness + contrast
```shell
convert master-pnp-highsm-04300-04322a.tif -brightness-contrast 0x30 master-pnp-highsm-04300-04322a_level.png
```

Modulate brightness, saturation, hue  
```shell
convert -modulate 150,120,100 block_us.png block_us_modulated.png
```

Fade to white  
```shell
convert -gravity Center london.png \( london_2.png -fill white -colorize 50% \) -compose Multiply -composite london_composite.png
```

Edge detection  
```shell
convert master-pnp-highsm-04300-04322a.tif -edge 2 -threshold 50% -negate master-pnp-highsm-04300-04322a_level.png
```

Add a sketch effect with a canny edge detection layer  
```shell
convert hyp.png \( +clone -modulate 150 -canny 0x1+5%+20% -negate \) -gravity center -compose multiply -composite hyp_canny.png

# hydroatlas
convert guiana.png \( +clone -modulate 120 -canny 0x5+15%+20% -negate \) -gravity center -compose multiply -composite -level 20%,100% guiana_canny.png
```

Add color overlay  
```shell
# multiply
convert toronto_buildings.png \( -clone 0 -fill "#A6CEE3" -colorize 100% \) -compose Multiply -composite toronto_buildings_blue.png

# burn with color
convert toronto_buildings.png \( -clone 0 -fill "#A6CEE3" -colorize 100% \) -compose ColorBurn -composite toronto_buildings_blue.png

# burn with color layer
convert toronto_buildings.png \( -size $(identify -format "%wx%h" "$file") xc:"#ffdc97" \) -compose ColorBurn -composite toronto_buildings_linearburn.png
```

Colorize all files in directory  
```shell
# colorize
for file in *.png; do
  convert "$file" -fill "#5F9EA0" -colorize 50% "${file%.*}_colorized.png"
done

# burn
for file in *.png; do
  convert "$file" \( -size $(identify -format "%wx%h" "$file") xc:"#ffdc97" \) -compose colorBurn -composite "${file%.*}_colorized.png"
done
```

Separate color channel  
```
# multiply
convert master-pnp-highsm-04300-04322a.tif -channel B -evaluate Multiply 2 +channel master-pnp-highsm-04300-04322a_blue.png

# white/black levels
convert master-pnp-highsm-04300-04322a.tif -channel B -level 10%,80% +channel master-pnp-highsm-04300-04322a_blue.png

# colorize
convert master-pnp-highsm-04300-04322a.tif -channel B -colorize 0,0,50 +channel master-pnp-highsm-04300-04322a_blue.png

# average
convert input.jpg -separate -channel R -average red_channel.jpg
```

Replace color 
```shell
convert master-pnp-highsm-04300-04322a.tif -fuzz 10% -fill white -opaque "#0000ff" master-pnp-highsm-04300-04322a_level.png
```

Shade by azimuth and elevation  
```shell
convert map.png -shade 120x45 -normalize map_3d.png
```

Create gradient of top 10 colors from histogram (resize to reduce range)  
```shell
convert tianshan.jpg -resize 100x100 -format %c -depth 8 histogram:info: | sort -n -k 1,1 | head -n 2 | sed -e 's/^.*#/#/g' -e 's/ .*$//g' | xargs -I{} convert -size 50x1920 -rotate 90 gradient:{} gradient.png
```

Create color bars from bright to dark  
```shell
convert tianshan.jpg -resize 50x50 -depth 8 -format "%[fx:lightness] %c" histogram:info:
```

Dilate  
```shell
convert /home/steve/Downloads/test.jpg -morphology Dilate Diamond:1 /home/steve/Downloads/test_dilate.jpg
convert -virtual-pixel None /home/steve/Downloads/test_dilate.jpg -rotate 180 -distort Arc '45 180' /home/steve/Downloads/test_distort.jpg

ls /home/steve/maps/biomes/boreal/5m/*.jpg | while read file; do
  convert "$file" -morphology Dilate Diamond:1  "${file%.*}_dilate.jpg"
done
```

Erode (poosite of dilate)  
```shell
convert sumo1.png -morphology erode Diamond:2 sumo1_dilate.png
```

### Composite

Composite cloud cover image over Natural Earth raster  
```shell
convert hyp.png tcdc.png -gravity center -compose over -composite hyp_tcdc.png
```

Composite and adjust levels of each image in one command  
```shell
convert -size 1920x1080 xc:none \( hyp.png -level 50%,100% \) -gravity center -compose over -composite \( tcdc.png -level 50%,100% \) -gravity center -compose over -composite hyp_tcdc.png
```

Composite satellite images  
```shell
# compose methods: Over, Pegtop_Light, Screen, Darken_Intensity, Hardlight
convert -size 1920x1080 xc:none \( chicago2.png -level 50%,100% \) -gravity center -compose over -composite \( chicago2_2.png -level 50%,100% \) -gravity center -compose Darken_Intensity -composite hyp_tcdc.png
```

Montage images  
```shell
montage -background none $(ls -1 ~/svgeo/svg/ortho/*coastline* | sort -t_ -k4,4n) -tile 3x -geometry +0+0 -resize 640x -bordercolor none -border 50x50 -gravity center miff:- | convert - -gravity center -geometry 1920x1080^ -crop 1920x1080+0+0 +repage ne_50m_coastline.png

montage -background none screen1.jpg screen2.jpg screen3.jpg -tile 3x -geometry +0+0 -resize 640x -gravity center miff:- | convert - -gravity center -white-threshold 90% -geometry 1920x1080^ -crop 1920x1080+0+0 +repage websites.png

montage /home/steve/qgis-expressions/screens/20240307001511.png  -gravity center -crop 384x500+0+0 -geometry +0+0 -tile 5x1 - | convert - maps4.png

# random
montage $(ls *.png | shuf -n 15) -gravity center -crop 384x384+0+0 -geometry +0+0 -tile 5x3 output.png
```

Circle mask  
```
convert moscow.png -gravity center -crop 1080x1080+0+0 +repage \( -size 1080x1080 xc:none -fill white -draw "circle 540,540 540,0" \) -alpha set -compose DstIn -composite moscow_circle.png

# with outline
convert moscow.png -gravity center -crop 1080x1080+0+0 +repage \( -size 1080x1080 xc:none -fill white -draw "circle 540,540 540,0" \) -alpha set -compose DstIn -composite \( -size 1080x1080 xc:none -stroke black -strokewidth 6 -fill none -draw "circle 540,540 540,3" \) -compose Over -composite moscow_circle.png
```

### Distort

Change the prime meridian 180*  
```shell
convert hyp.png -roll +960 hyp_roll.png
```

Apply an arc projection  
```shell
convert -size 1920x1080 xc:none \( hyp.png -virtual-pixel none -resize 50% -distort Arc '45' \) -gravity center -compose over -composite hyp_arc45.png

convert -size 1920x1080 xc:none \( hyp.png -virtual-pixel none -resize 50% -rotate 180 -distort Arc '45 180' \) -gravity center -compose over -composite hyp_arc45.png

convert -size 1920x1080 xc:none \( chicago.png -virtual-pixel none -resize 150% -rotate 180 -distort Arc '45 180' \) -gravity center -compose over -composite chicago_arc.png
```

Apply perspective  
```shell
convert -size 1920x1080 xc:none \
    \( chicago.png -virtual-pixel none -resize 150% -distort Arc '45 180' \
    -distort Perspective '0,0,0,0 0,1000,0,1000 1000,0,1200,0 1000,1000,1000,1000' \) \
    -gravity center -compose over -composite chicago_bend.png
```

Apply a polar projection  
```shell
convert -size 1920x1080 xc:none \( hyp.png -virtual-pixel none -resize 50% -distort Polar '0' \) -gravity center -compose over -composite hyp_polar_0.png
```

Apply a displacement distort  
```shell
convert HYP_HR_SR_OB_DR.png GRAY_HR_SR_OB_DR.png -set option:compose:args '%[fx:w/2]x%[fx:h/2]' -compose distort -composite +repage HYP_HR_SR_OB_DR_displace.png
```

### Animate

Extract frame  
```shell
convert input.gif[$selected_frame] output_frame.png
```

Make a gif from directory  
```shell
convert -delay 60 $PWD/*.png $(basename $PWD).gif

# hillshade animation (with resize)
convert -resize 25% -delay 60 *hillshade_zfactor*.tif topo15_4u320_hillshade_zfactor.gif
```

Make gif from svgs    
```shell
rm -rf ~/tmp/*
ls *.svg | while read file; do convert ${file} ~/tmp/${file%.*}.png; done
convert -delay 60 ~/tmp/*.png $(basename $PWD).gif
```

Make terrain animations  
```shell
# hillshade zfactor
sorted_files=$(ls -v *hillshade_zfactor*.tif)
convert -resize 25% -delay 24 ${sorted_files} -coalesce -quiet -layers OptimizePlus -loop 0 -level 50%,100% topo15_4320_hillshade_zfactor.gif

# hillshade azimuth
sorted_files=$(ls -v *hillshade_azimuth*.tif)
convert -resize 400x -delay 12 ${sorted_files} -coalesce -quiet -layers OptimizePlus -loop 0 topo15_4320_hillshade_azimuth.gif
```

Loop gif nicely  
```shell
convert shift_primemeridian_1920_1080.gif -coalesce -duplicate 1,-2-1 -quiet -layers OptimizePlus -loop 0 shift_primemeridian_1920_1080_loop.gif
```

Convert video to gif  
```shell
convert weather_03_17_170534.mp4 -coalesce -layers OptimizePlus weather_03_17_170534.gif

file='Mazola.ia.mp4'
ffmpeg -y -i "$file" -r 10 -vf "fps=10,crop=in_w-50:in_h-50,scale=960:-1,setpts=PTS-STARTPTS" ~/archive-mag/archive/"${file%.*}.gif"
```

Make a scrolling gif by ofsetting images  
```shell
rm frame*.png
i=1
ls sumo*.png | while read file; do
  convert -size 1920x1080 xc:white \( sumo${i}.png -resize 25% \) -gravity West -geometry +$(( (1920/8) * (${i}-1) ))+0 -composite frame${i}.png
  i=$((i + 1))
done
convert -delay 40 frame*.png -morphology erode Diamond:1 -fill "#F5F5DC" -opaque white -texture canvas:canvas sumo.gif
```

### Text

Add caption  
```
convert -alpha On -background None -fill Black -font '/home/steve/.fonts/ofl/playfairdisplay/PlayfairDisplay[wght].ttf' -gravity Center -size 1920x1080 -interline-spacing 0 caption:'TIANSHAN' -trim +repage -bordercolor None -border 0 tianshan_label.png
```

Add caption to images in a folder  
```
rm -rf *_label.png
rm -rf *_frame.png

# make label from filename
ls *.png | while read file; do
  # justify
  convert -alpha On -background None -fill Black -font '/home/steve/.fonts/ofl/playfairdisplay/PlayfairDisplay[wght].ttf' -gravity Center -size 1920x1080 -interline-spacing 0 caption:${file%.*} -trim +repage -bordercolor None -border 0 ${file%.*}_label.png
  # pointsize
  # convert -alpha On -background None -fill Black -font '/home/steve/.fonts/ofl/playfairdisplay/PlayfairDisplay[wght].ttf' -gravity Center -size 1920x1080 -interline-spacing 0 -pointsize 60 caption:${file%.*} -trim +repage -bordercolor None -border 0 ${file%.*}_label.png
done

# overlay label and map
ls *_label.png | while read file; do
  convert -gravity Center ${file%_*}.png ${file} -compose Over -composite ${file%_*}_frame.png
done

# make video
ffmpeg -framerate 3 -pattern_type glob -i '*_frame.png' -c:v libx264 -pix_fmt yuv420p atlas.mp4
```

Fit multiline text to canvas (automatically justify and resize font)  
```
lines=("" "")
for i in "${!lines[@]}"; do
  line=${lines[$i]}
  convert -gravity center -size 400x -font '/home/steve/.fonts/ofl/bebasneue/BebasNeue-Regular.ttf' label:"${line}" -trim +repage ~/tmp/line_$i.png
done
convert ~/tmp/line_*.png -append label.png
```

Simulate printed page  
```
convert -size 800x200 xc:'#f5f5dc' -font Courier -pointsize 30 -gravity northwest -annotate +0+0 "Your Caption Here\nSecond line" -fill none -stroke '#333333' -strokewidth 1 -trim +repage -bordercolor '#f5f5dc' -border 20x20 -attenuate 0.2 +noise Gaussian -texture canvas:canvas -quality 100 printed_caption.png
```

### Misc

Install latest on Debian  
```shell
# install dependencies
sudo apt-get update
sudo apt-get install build-essential checkinstall libx11-dev libxext-dev libxrender-dev libpng-dev libjpeg-dev libtiff-dev libwebp-dev
sudo apt-get install libjpeg-turbo8-devqq

# download
wget https://github.com/ImageMagick/ImageMagick/archive/refs/tags/$(curl -s https://api.github.com/repos/ImageMagick/ImageMagick/releases/latest | grep tag_name | cut -d '"' -f 4).tar.gz

# extract
tar xvzf ImageMagick-*.tar.gz
cd ImageMagick-*

# install
make clean
./configure --with-jpeg=yes
make
sudo make install
sudo ldconfig
```

Override cache limit  
```shell
sudo vim /etc/ImageMagick-6/policy.xml
<policy domain="resource" name="disk" value="8GB"/>
```

Fonts  
```shell
# list installed fonts
fc-list 

# query specific font
fc-query [fontname]
```
