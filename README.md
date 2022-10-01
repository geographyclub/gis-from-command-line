# GIS FROM COMMAND LINE

GDAL (Geospatial Data Abstraction Library) is a computer software library for reading and writing raster and vector geospatial data formats. But it is much more than that. This is how I use GDAL with a little BASH scripting to make my own *Geographic Information Systems* from the command line.

<img src="images/space_globe_grid.jpg"/>

## TABLE OF CONTENTS

1. [Raster](#1-raster)  
    1.1 [Resampling](#11-resampling)  
    1.2 [Reprojecting](#12-reprojecting)  
    1.3 [Georeferencing](#13-georeferencing)  
    1.4 [Clipping](#14-clipping)  
    1.5 [Converting](#15-converting)    

[ImageMagick for Mapmakers](https://github.com/geographyclub/imagemagick-for-mapmakers#readme)

## 1. Raster

### 1.1 Resampling

Resize Natural Earth hypsometric raster by desired width. This will be our example raster.  
```
gdalwarp -overwrite -ts 1920 0 -r cubicspline HYP_HR_SR_OB_DR.tif hyp.tif
```

<img src="images/hyp.jpg"/>

Convert and resize all geotiffs in the folder to jpg. These will be our example thumbnails.  
```
ls *.tif | while read file; do
  gdal_translate -of 'JPEG' -outsize 25% 25% ${file} ${file%.*}.jpg
done
```

Resize raster by a factor of its original size using output of `gdalinfo`.  
```
file='hyp.tif'
factor=100
width=$(echo $(gdalinfo ${file} | grep "Size is" | sed 's/Size is //g' | sed 's/,.*$//g')/${factor} | bc)
gdalwarp -overwrite -ts ${width} 0 -r cubicspline ${file} ${file%.*}_${width}.tif
```

Downsample then upsample by the same amount to smooth raster (for making contour lines).  
```
file='hyp.tif'
factor=10
width=$(echo $(gdalinfo ${file} | grep "Size is" | sed 's/Size is //g' | sed 's/,.*$//g')/${factor} | bc)
gdalwarp -overwrite -ts ${width} 0 -r cubicspline ${file} /vsistdout/ | gdalwarp -overwrite -ts $(echo $(gdalinfo ${file} | grep "Size is" | sed 's/Size is //g' | sed 's/,.*$//g')) 0 -r cubicspline /vsistdin/ ${file%.*}_smooth.tif
```

<img src="images/hyp_192_smooth.jpg"/>

### 1.2 Reprojecting

Use EPSG code to transform from lat-long to the popular Web Mercator projection (Google Maps, OpenStreetMap).  
```
file='hyp.tif'
proj='epsg:3857'
gdalwarp -overwrite -s_srs 'EPSG:4326' -t_srs "${proj}" ${file} ${file%.*}_"${proj//:/_}".tif
```

<img src="images/hyp_epsg_3857.jpg"/>

Use PROJ definition to transform from lat-long to van der Grinten projection.  
```
file='hyp.tif'
proj='+proj=vandg +lon_0=0 +x_0=0 +y_0=0 +R_A +a=6371000 +b=6371000 +units=m no_defs'
gdalwarp -overwrite -s_srs 'EPSG:4326' -t_srs "${proj}" ${file} ${file%.*}_"$(echo ${proj} | sed -e 's/+proj=//g' -e 's/ +.*$//g')".tif
```

<img src="images/hyp_192_vandg.jpg"/>

Customize PROJ definition to transform from lat-long to an orthographic projection centered on Toronto.  
```gdalwarp -overwrite -s_srs 'EPSG:4326' -t_srs '+proj=ortho +lat_0='43.65' +lon_0='-79.34' +ellps='sphere'' HYP_HR_SR_OB_DR_1024_512.tif HYP_HR_SR_OB_DR_1024_512_ortho_toronto.tif```

Shift prime meridian on a 0-360° raster and a -180-180° raster.  
```gdalwarp -overwrite -s_srs 'EPSG:4326' -t_srs '+proj=latlong +datum=WGS84 +pm=180dE' HYP_HR_SR_OB_DR_1024_512.tif HYP_HR_SR_OB_DR_1024_512_180pm.tif```

```gdalwarp -overwrite -s_srs 'EPSG:4326' -t_srs '+proj=longlat +ellps=WGS84 +pm=-360 +datum=WGS84 +no_defs +lon_wrap=360 +over' HYP_HR_SR_OB_DR_1024_512.tif HYP_HR_SR_OB_DR_1024_512_180pm.tif```

### 1.3 Georeferencing

Georeference by extent.  
```gdal_translate -a_ullr -180 90 180 -90 HYP_HR_SR_OB_DR_1024_512.png HYP_HR_SR_OB_DR_1024_512_georeferenced.tif```

Georeference by ground control points.  
```gdal_translate -gcp 0 0 -180 -90 -gcp 1024 512 180 90 -gcp 0 512 -180 90 -gcp 1024 0 180 -90 HYP_HR_SR_OB_DR_1024_512.png HYP_HR_SR_OB_DR_1024_512_georeferenced.tif```

Georeference and transform in one step.  
```gdal_translate -a_ullr -180 90 180 -90 HYP_HR_SR_OB_DR_1024_512.png /vsistdout/ | gdalwarp -overwrite -t_srs 'EPSG:4326' /vsistdin/ HYP_HR_SR_OB_DR_1024_512_crs.tif```

### 1.4 Clipping

Clip to bounding box using `gdalwarp` or `gdal_translate`.  
```gdalwarp -overwrite -dstalpha -te -94 42 -82 54 HYP_HR_SR_OB_DR_1024_512.tif HYP_HR_SR_OB_DR_1024_512_clipped.tif```

```gdal_translate -projwin -94 54 -82 42 HYP_HR_SR_OB_DR_1024_512.tif HYP_HR_SR_OB_DR_1024_512_clipped.tif```

Clip to vector features selected by SQL.  
```gdalwarp -overwrite -dstalpha -crop_to_cutline -cutline 'natural_earth_vector.gpkg' -csql 'SELECT geom FROM ne_110m_ocean' HYP_HR_SR_OB_DR_1024_512.tif HYP_HR_SR_OB_DR_1024_512_clipped.tif```

Clip to raster mask using `gdal_calc.py`.  
```
# make raster mask by setting values greater than 0 to 1
gdal_calc.py --overwrite --type=Int16 --NoDataValue=0 -A HYP_HR_SR_OB_DR_1024_512_A.tif --outfile=HYP_HR_SR_OB_DR_1024_512_mask.tif --calc="1*(A>0)"

# make raster mask by keeping values greater than 0
gdal_calc.py --overwrite --NoDataValue=0 -A HYP_HR_SR_OB_DR_1024_512_A.tif --outfile=HYP_HR_SR_OB_DR_1024_512_mask.tif --calc="A*(A>0)"

# clip to mask
gdal_calc.py -A HYP_HR_SR_OB_DR_1024_512.tif -B HYP_HR_SR_OB_DR_1024_512_mask.tif --outfile="HYP_HR_SR_OB_DR_1024_512_clipped.tif" --overwrite --type=Float32 --NoDataValue=0 --calc="A*(B>0)"
```

Add rasters with `gdal_calc.py`.  
```
# add where raster A is greater than zero.
gdal_calc.py --overwrite -A HYP_HR_SR_OB_DR_1024_512_A.tif -B HYP_HR_SR_OB_DR_1024_512_B.tif --outfile=HYP_HR_SR_OB_DR_1024_512_A_B.tif --calc="((A>0)*A)+B"

# add with logical operator
gdal_calc.py --overwrite -A HYP_HR_SR_OB_DR_1024_512_A.tif --outfile=HYP_HR_SR_OB_DR_1024_512_100_150.tif --calc="A*logical_and(A>100,A<150)"
```

### 1.5 Converting

Use `gdal_translate` to convert from GeoTIFF to VRT.  
```gdal_translate -if 'GTiff' -of 'VRT' HYP_HR_SR_OB_DR_1024_512.tif HYP_HR_SR_OB_DR_1024_512.vrt```

Use `gdalwarp` to convert from GeoTIFF to regular TIFF (use with programs like imagemagick).  
```gdalwarp -overwrite -dstalpha --config GDAL_PAM_ENABLED NO -co PROFILE=BASELINE -f 'GTiff' -of 'GTiff' HYP_HR_SR_OB_DR_1024_512.tif HYP_HR_SR_OB_DR_1024_512.tif```

Make mosaic from two or more raster images.  
```gdal_merge.py -o mosaic.tif part1.tif part2.tif part3.tif part4.tif```

