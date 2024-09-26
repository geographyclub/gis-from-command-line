#!/bin/bash
#./get_metar.sh
#./get_gdps.sh

### video options
height=540
width=960
height_frame=540
width_frame=960

#mkdir ~/data/tmp
rm -f ~/data/tmp/*

### layers
# longlat
gdalwarp -overwrite -dstalpha --config GDAL_PAM_ENABLED NO -co PROFILE=BASELINE -f 'GTiff' -r cubicspline -ts ${width} ${height} -s_srs 'epsg:4326' -t_srs 'epsg:4326' ~/maps/naturalearth/raster/HYP_HR_SR_OB_DR.tif ~/data/tmp/layer0.tif
# cloud cover
counter=1
ls ~/data/gdps/*TCDC*.grib2 | while read file; do
  gdaldem color-relief -alpha -f 'GRIB' -of 'GTiff' --config GDAL_PAM_ENABLED NO ${file} '/home/steve/data/colors/white-black.txt' /vsistdout/ | gdalwarp -overwrite -dstalpha --config GDAL_PAM_ENABLED NO -co PROFILE=BASELINE -f 'GTiff' -r cubicspline -ts ${width} ${height} -s_srs 'epsg:4326' -t_srs 'epsg:4326' /vsistdin/ ~/data/tmp/layer1_$(printf "%06d" ${counter}).tif
  (( counter = counter + 1 )) 
done

### composite
count=$(ls ~/data/tmp/layer1_*.tif | wc -l)
for (( counter = 1; counter <= ${count}; counter++ )); do
  convert -size ${width_frame}x${height_frame} xc:none \( ~/data/tmp/layer0.tif -level 50%,100% \) -gravity center -compose over -composite \( ~/data/tmp/layer1_$(printf "%06d" ${counter}).tif -level 50%,100% \) -gravity center -compose over -composite ~/data/tmp/frame_$(printf "%06d" ${counter}).tif
done

### stream
video=$(echo ~/data/out/weather_$(date +%m_%d_%H%M%S).mp4)
ls -tr ~/data/tmp/frame_*.tif | sed -e "s/^/file '/g" -e "s/$/'/g" > ~/data/tmp/filelist.txt
ffmpeg -y -r 12 -f concat -safe 0 -i ~/data/tmp/filelist.txt -c:v libx264 -crf 23 -pix_fmt yuv420p -preset fast -threads 0 -movflags +faststart ${video}
ffplay -loop 0 ${video}
