# GIS FROM COMMAND LINE

This is my introduction to using open source command-line tools in Linux to make your own *Geographic Information Systems*.

## GDAL

The Geospatial Data Abstraction Library is a computer software library for reading and writing raster and vector geospatial data formats.

### 1. Print raster info

```gdalinfo HYP_HR_SR_OB_DR.tif```

### 2. Convert data formats

Converting from GeoTIFF to VRT:

```gdal_translate -if 'GTiff' -of 'VRT' HYP_HR_SR_OB_DR.tif HYP_HR_SR_OB_DR.vrt```

Converting an image into a georeferenced raster by extent:

```gdal_translate -of 'GTiff' -a_ullr -180 90 180 -90 HYP_HR_SR_OB_DR.png HYP_HR_SR_OB_DR_georeferenced.tif```

Converting an image into a georeferenced raster by ground control points:

```gdal_translate -of 'GTiff' -gcp 0 0 -180 -90 -gcp 360 180 180 90 -gcp 0 180 -180 90 -gcp 360 0 180 -90 HYP_HR_SR_OB_DR.png HYP_HR_SR_OB_DR_georeferenced.tif```

### 3. Transform coordinates

Using EPSG code to transform from lat-long to Web Mercator projection:

```gdalwarp -overwrite -s_srs 'EPSG:4326' -t_srs 'EPSG:3857' HYP_HR_SR_OB_DR.tif HYP_HR_SR_OB_DR_3857.tif```

Using PROJ definition to transform from lat-long to van der Grinten projection:

```gdalwarp -overwrite -s_srs 'EPSG:4326' -t_srs '+proj=vandg +lon_0=0 +x_0=0 +y_0=0 +R_A +a=6371000 +b=6371000 +units=m no_defs' HYP_HR_SR_OB_DR.tif HYP_HR_SR_OB_DR_vandergrinten.tif```

Customizing PROJ definition to transform from lat-long to an orthographic projection centered on Toronto:

```gdalwarp -overwrite -s_srs 'EPSG:4326' -t_srs '+proj=ortho +lat_0='43.65' +lon_0='-79.34' +ellps='sphere'' HYP_HR_SR_OB_DR.tif HYP_HR_SR_OB_DR_ortho_toronto.tif```

Piping `gdal_translate` to `gdalwarp` to georeference and transform an image in one step:

```gdal_translate -of 'GTiff' -a_ullr -180 90 180 -90 HYP_HR_SR_OB_DR.png /vsistdout/ | gdalwarp -overwrite -f 'GTiff' -of 'GTiff' -t_srs 'EPSG:4326' /vsistdin/ HYP_HR_SR_OB_DR_crs.tif```

### 4. Rescale raster

Rescaling to output pixel resolution:

```gdalwarp -overwrite -tr 1 1 HYP_HR_SR_OB_DR.tif HYP_HR_SR_OB_DR_1xres_1yres.tif```

Rescaling to output raster width:

```gdalwarp -overwrite -ts 4000 0 HYP_HR_SR_OB_DR.tif HYP_HR_SR_OB_DR_4000w.tif```

Smoothing raster by scaling down then scaling up:

```gdalwarp -of 'VRT' -ts `echo $(gdalinfo HYP_HR_SR_OB_DR.tif | grep "Size is" | sed 's/Size is //g' | sed 's/,.*$//g')/10 | bc` 0 -r cubicspline HYP_HR_SR_OB_DR.tif /vsistdout/ | gdalwarp -overwrite -ts `echo $(gdalinfo HYP_HR_SR_OB_DR.tif | grep "Size is" | sed 's/Size is //g' | sed 's/,.*$//g')` 0 -r cubicspline -t_srs 'EPSG:4326' /vsistdin/ HYP_HR_SR_OB_DR_smooth.tif```

Using different resampling methods:

```gdalwarp -overwrite -ts 4000 0 -r near -t_srs "EPSG:4326" HYP_HR_SR_OB_DR.tif HYP_HR_SR_OB_DR_near.tif```

```gdalwarp -overwrite -ts 4000 0 -r cubicspline -t_srs "EPSG:4326" HYP_HR_SR_OB_DR.tif HYP_HR_SR_OB_DR_cubicspline.tif```


### Miscellaneous raster operations

Compress:

```gdalwarp -overwrite -co COMPRESS=LZW HYP_HR_SR_OB_DR.tif HYP_HR_SR_OB_DR_3857_compressed.tif```

Tile:

```gdalwarp -overwrite -co TILED=YES HYP_HR_SR_OB_DR.tif HYP_HR_SR_OB_DR_3857_tiled.tif```
