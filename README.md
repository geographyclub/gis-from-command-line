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

Resize Natural Earth hypsometric raster by desired width while keeping the aspect ratio. This will be our example raster.  
```
file='HYP_HR_SR_OB_DR.tif'
width=1920
gdalwarp -overwrite -ts ${width} 0 -r cubicspline ${file} hyp.tif
```

<img src="images/hyp.jpg"/>

Resize and convert all geotiffs in the folder to jpg. These will be our example thumbnails.  
```
ls *.tif | while read file; do
  gdal_translate -of 'JPEG' -outsize 25% 25% ${file} ${file%.*}.jpg
done
```

Resize raster as a fraction of its original size using output from `gdalinfo`.  
```gdalwarp -overwrite -ts $(echo $(gdalinfo hyp.tif | grep "Size is" | sed 's/Size is //g' | sed 's/,.*$//g')/10 | bc) 0 -r cubicspline hyp.tif hyp_192.tif```

### 1.2 Reprojecting

Set prime meridian on 0-360° raster.  
```gdalwarp -overwrite -s_srs 'EPSG:4326' -t_srs "+proj=longlat +ellps=WGS84 +pm=-360 +datum=WGS84 +no_defs +lon_wrap=360 +over" hyp.tif hyp_180pm.tif```

Set prime meridian on -180-180° raster by desired degree.  
```
file='hyp.tif'
prime=180
gdalwarp -overwrite -s_srs 'EPSG:4326' -t_srs "+proj=latlong +datum=WGS84 +pm=${prime}dE" ${file} ${file%.*}_180pm.tif
```

<img src="images/hyp_180pm.jpg"/>

Set prime meridian on -180-180° raster by desired placename. Use `ogrinfo` to query a Natural Earth geopackage.  
```
file='hyp.tif'
place='Toronto'
prime=$(ogrinfo /home/steve/maps/naturalearth/packages/natural_earth_vector.gpkg -sql "SELECT round(ST_X(ST_Shift_Longitude(geom))) FROM ne_10m_populated_places WHERE nameascii = '${place}'" | grep '=' | sed -e 's/^.*= //g')
gdalwarp -overwrite -s_srs 'EPSG:4326' -t_srs "+proj=latlong +datum=WGS84 +pm=${prime}dE" ${file} ${file%.*}_${prime}pm.tif
```

<img src="images/hyp_281pm.jpg"/>

Transform from lat-long to the popular Web Mercator projection using EPSG code.  
```
file='hyp.tif'
proj='epsg:3857'
gdalwarp -overwrite -s_srs 'EPSG:4326' -t_srs ${proj} -te -180 -85 180 80 -te_srs EPSG:4326 ${file} ${file%.*}_"${proj//:/_}".tif
```

<img src="images/hyp_epsg_3857.jpg"/>

Transform from lat-long to van der Grinten projection using PROJ definition.  
```
file='hyp.tif'
proj='+proj=vandg +lon_0=0 +x_0=0 +y_0=0 +R_A +a=6371000 +b=6371000 +units=m no_defs'
gdalwarp -overwrite -s_srs 'EPSG:4326' -t_srs "${proj}" ${file} ${file%.*}_"$(echo ${proj} | sed -e 's/+proj=//g' -e 's/ +.*$//g')".tif
```

<img src="images/hyp_vandg.jpg"/>

Transform from lat-long to an orthographic projection with a custom PROJ definition. Again use `ogrinfo` to query a Natural Earth geopackage.  
```
file='hyp.tif'
place='Seoul'
xy=($(ogrinfo /home/steve/maps/naturalearth/packages/natural_earth_vector.gpkg -sql "SELECT round(ST_X(ST_Centroid(geom))), round(ST_Y(ST_Centroid(geom))) FROM ne_10m_populated_places WHERE nameascii = '${place}'" | grep '=' | sed -e 's/^.*= //g'))
gdalwarp -overwrite -s_srs 'EPSG:4326' -t_srs '+proj=ortho +lat_0="'${xy[1]}'" +lon_0="'${xy[0]}'" +ellps='sphere'' ${file} ${file%.*}_ortho_"${xy[0]}"_"${xy[1]}".tif
```

<img src="images/hyp_ortho_127_38.jpg"/>

Center the orthographic projection on the centroid of a country using the same method.  
```
file='hyp.tif'
place='Ukraine'
xy=($(ogrinfo /home/steve/maps/naturalearth/packages/natural_earth_vector.gpkg -sql "SELECT round(ST_X(ST_Centroid(geom))), round(ST_Y(ST_Centroid(geom))) FROM ne_110m_admin_0_countries WHERE name = '${place}'" | grep '=' | sed -e 's/^.*= //g'))
gdalwarp -overwrite -s_srs 'EPSG:4326' -t_srs '+proj=ortho +lat_0="'${xy[1]}'" +lon_0="'${xy[0]}'" +ellps='sphere'' ${file} ${file%.*}_ortho_"${xy[0]}"_"${xy[1]}".tif
```

<img src="images/hyp_ortho_31_49.jpg"/>

### 1.3 Georeferencing

Georeference by extent.  
```gdal_translate -a_ullr -180 90 180 -90 HYP_HR_SR_OB_DR_1024_512.png HYP_HR_SR_OB_DR_1024_512_georeferenced.tif```

Georeference by ground control points.  
```gdal_translate -gcp 0 0 -180 -90 -gcp 1024 512 180 90 -gcp 0 512 -180 90 -gcp 1024 0 180 -90 HYP_HR_SR_OB_DR_1024_512.png HYP_HR_SR_OB_DR_1024_512_georeferenced.tif```

Georeference and transform in one step.  
```gdal_translate -a_ullr -180 90 180 -90 HYP_HR_SR_OB_DR_1024_512.png /vsistdout/ | gdalwarp -overwrite -t_srs 'EPSG:4326' /vsistdin/ HYP_HR_SR_OB_DR_1024_512_crs.tif```

### 1.4 Clipping

Clip to bounding box using `gdal_translate` or `gdalwarp`.  
```gdal_translate -projwin -180 90 0 -90 hyp.tif hyp_west.tif```

```gdalwarp -overwrite -te 0 -90 180 90 hyp.tif hyp_east.tif```

Merge our two clipped rasters back together.  
```gdal_merge.py -o hyp_east_west.tif hyp_east.tif hyp_west.tif```

<img src="images/hyp_east_west.jpg"/>

Clip to extent of vector geometry by name.  
```
file='hyp.tif'
place='North America'
extent=($(ogrinfo /home/steve/maps/naturalearth/packages/natural_earth_vector.gpkg -sql "SELECT ROUND(ST_MinX(geom)), ROUND(ST_MinY(geom)), ROUND(ST_MaxX(geom)), ROUND(ST_MaxY(geom)) FROM (SELECT ST_Union(geom) geom FROM ne_110m_admin_0_countries WHERE CONTINENT = '${place}')" | grep '=' | sed -e 's/^.*= //g'))
gdalwarp -overwrite -ts 1920 0 -te ${extent[*]} ${file} ${file%.*}_extent_$(echo "${extent[@]}" | sed 's/ /_/g').tif
```

<img src="images/hyp_extent_-172_7_-12_84.jpg"/>

Clip to vector geometry with `crop_to_cutline` option.  
```
file='hyp.tif'
featurecla='Ocean'
gdalwarp -overwrite -crop_to_cutline -cutline '/home/steve/maps/naturalearth/packages/natural_earth_vector.gpkg' -csql "SELECT geom FROM ne_110m_ocean WHERE featurecla = '${featurecla}'" hyp.tif hyp_${featurecla,,}.tif
```

<img src="images/hyp_ocean.jpg"/>

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


