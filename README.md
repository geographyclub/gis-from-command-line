# GIS FROM COMMAND LINE

This is my introduction to using open source command-line tools in Linux to make your own *Geographic Information Systems*.

## 1. GDAL

The Geospatial Data Abstraction Library is a computer software library for reading and writing raster and vector geospatial data formats.

### 1.1 Convert data formats

`gdal_translate -if 'GTiff' -of 'VRT' HYP_HR_SR_OB_DR.tif HYP_HR_SR_OB_DR.vrt`

### 1.2 Reproject coordinates

Using EPSG code to transform from lat-long to Web Mercator projection:

`gdalwarp -s_srs 'EPSG:4326' -t_srs 'EPSG:3857' HYP_HR_SR_OB_DR.tif HYP_HR_SR_OB_DR_3857.tif`

Using PROJ definition to transform from lat-long to Van der Grinten projection:

`gdalwarp -s_srs 'EPSG:4326' -t_srs '+proj=vandg +lon_0=0 +x_0=0 +y_0=0 +R_A +a=6371000 +b=6371000 +units=m no_defs' HYP_HR_SR_OB_DR.tif HYP_HR_SR_OB_DR_vandergrinten.tif`

Editing PROJ definition to transform from lat-long to an orthographic projection centered on Toronto:

`gdalwarp -s_srs 'EPSG:4326' -t_srs '+proj=ortho +lat_0='43.65' +lon_0='-79.34' +ellps='sphere'' HYP_HR_SR_OB_DR.tif HYP_HR_SR_OB_DR_ortho_toronto.tif`

### 1.3 Rescale raster

Rescaling by  output file size by width and/or height:

gdalwarp -overwrite -f 'GTiff' -ts 4000 0 -r cubicspline -t_srs "EPSG:4326" ${file} ${file%.*}_4000.tif

gdalwarp -overwrite -f 'GTiff' -ts 4000 0 -r cubicspline -t_srs "EPSG:4326" ${file} ${file%.*}_4000.tif
gdalwarp -overwrite -f 'GTiff' -ts 40000 0 -r cubicspline -t_srs "EPSG:4326" ${file%.*}_4000.tif ${file%.*}_4000_40000.tif

# by pixel size
gdalwarp -overwrite -ts `echo $(gdalinfo /home/steve/Projects/maps/dem/srtm/N48W092_N47W092_N48W091_N47W091.tif | grep "Size is" | sed 's/Size is //g' | sed 's/,.*$//g')/2 | bc` 0 -r cubicspline /home/steve/Projects/maps/dem/srtm/$(echo ${id[@]} | tr ' ' '_').tif /home/steve/Projects/maps/dem/srtm/$(echo ${id[@]} | tr ' ' '_')_half.tif
gdalwarp -overwrite -ts `echo $(gdalinfo /home/steve/Projects/maps/dem/srtm/N48W092_N47W092_N48W091_N47W091.tif | grep "Size is" | sed 's/Size is //g' | sed 's/,.*$//g')` 0 -r cubicspline /home/steve/Projects/maps/dem/srtm/$(echo ${id[@]} | tr ' ' '_')_half.tif /home/steve/Projects/maps/dem/srtm/$(echo ${id[@]} | tr ' ' '_')_smooth.tif

### Georeference raster

Pipe `gdal_translate` to `gdalwarp` to georeference an image and transform in one step:

gdal_translate -of 'VRT' -a_ullr -180 90 180 -90 ${dir}/tmp/tmp0.tif /vsistdout/ | 

### Miscellaneous raster operations

Compress:

`gdalwarp -overwrite -co COMPRESS=LZW HYP_HR_SR_OB_DR.tif HYP_HR_SR_OB_DR_3857_compressed.tif`

Tile:

`gdalwarp -overwrite -co TILED=YES HYP_HR_SR_OB_DR.tif HYP_HR_SR_OB_DR_3857_tiled.tif`
