# GIS FROM COMMAND LINE

GDAL (Geospatial Data Abstraction Library) is a computer software library for reading and writing raster and vector geospatial data formats. But it is much more than that. This is how I use GDAL with a little BASH scripting to make my own *Geographic Information Systems* from the command line.

<img src="images/space_globe_grid.jpg"/>

## TABLE OF CONTENTS

1. [Raster](#1-raster)  
    1.1 [Resampling](#11-resampling)  
    1.2 [Reprojecting](#12-reprojecting)  
    1.3 [Clipping](#13-clipping)  
    1.4 [Geoprocessing](#14-geoprocessing)  
    1.5 [Converting](#15-converting)  

2. [Vector](#2-vector)   

3. [ImageMagick for mapmakers](https://github.com/geographyclub/imagemagick-for-mapmakers#readme)

4. [Animating maps - weather data](https://github.com/geographyclub/weather-to-video)

5. [Web mapping - census data](https://github.com/geographyclub/american-geography#readme)

## 1. Raster

### 1.1 Resampling

Resize the Natural Earth hypsometric raster to a web-safe width while keeping the aspect ratio. This will be our example raster.  
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

Set prime meridian by desired placename. Use `ogrinfo` to query a Natural Earth geopackage.  
```
file='hyp.tif'
place='Toronto'
prime=$(ogrinfo /home/steve/maps/naturalearth/packages/natural_earth_vector.gpkg -sql "SELECT round(ST_X(ST_Shift_Longitude(geom))) FROM ne_10m_populated_places WHERE nameascii = '${place}'" | grep '=' | sed -e 's/^.*= //g')
gdalwarp -overwrite -s_srs 'EPSG:4326' -t_srs "+proj=latlong +datum=WGS84 +pm=${prime}dE" ${file} ${file%.*}_${prime}pm.tif
```

<img src="images/hyp_281pm.jpg"/>

Transform from lat-long to the popular Web Mercator projection using EPSG code, setting extent between -85* and 80* latitude.  
```
file='hyp.tif'
proj='epsg:3857'
gdalwarp -overwrite -s_srs 'EPSG:4326' -t_srs ${proj} -te -180 -85 180 80 -te_srs EPSG:4326 ${file} ${file%.*}_"${proj//:/_}".tif
```

<img src="images/hyp_epsg_3857.jpg"/>

Transform from lat-long to van der Grinten projection using PROJ definition.  
```
file='hyp.tif'
proj='+proj=vandg +lon_0=0 +x_0=0 +y_0=0 +R_A +a=6371000 +b=6371000 +units=m'
gdalwarp -overwrite -s_srs 'EPSG:4326' -t_srs "${proj}" ${file} ${file%.*}_"$(echo ${proj} | sed -e 's/+proj=//g' -e 's/ +.*$//g')".tif
```

<img src="images/hyp_vandg.jpg"/>

Transform from lat-long to an orthographic projection with a custom PROJ definition, being careful to set ellipse to sphere. Again use `ogrinfo` to query a Natural Earth geopackage.  
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

Georeference by extent.  
```gdal_translate -a_ullr -180 90 180 -90 HYP_HR_SR_OB_DR_1024_512.png HYP_HR_SR_OB_DR_1024_512_georeferenced.tif```

Georeference by ground control points.  
```gdal_translate -gcp 0 0 -180 -90 -gcp 1024 512 180 90 -gcp 0 512 -180 90 -gcp 1024 0 180 -90 HYP_HR_SR_OB_DR_1024_512.png HYP_HR_SR_OB_DR_1024_512_georeferenced.tif```

Georeference and transform in one step.  
```gdal_translate -a_ullr -180 90 180 -90 HYP_HR_SR_OB_DR_1024_512.png /vsistdout/ | gdalwarp -overwrite -t_srs 'EPSG:4326' /vsistdin/ HYP_HR_SR_OB_DR_1024_512_crs.tif```

### 1.3 Clipping

Clip to bounding box using `gdal_translate` or `gdalwarp`.  
```gdal_translate -projwin -180 90 0 -90 hyp.tif hyp_west.tif```

```gdalwarp -overwrite -te 0 -90 180 90 hyp.tif hyp_east.tif```

Merge our two clipped rasters back together to remake the original.  
```gdal_merge.py -o hyp_east_west.tif hyp_east.tif hyp_west.tif```

<img src="images/hyp_east_west.jpg"/>

Clip to extent of vector geometries.  
```
file='hyp.tif'
continent='North America'
extent=($(ogrinfo /home/steve/maps/naturalearth/packages/natural_earth_vector.gpkg -sql "SELECT ROUND(ST_MinX(geom)), ROUND(ST_MinY(geom)), ROUND(ST_MaxX(geom)), ROUND(ST_MaxY(geom)) FROM (SELECT ST_Union(geom) geom FROM ne_110m_admin_0_countries WHERE CONTINENT = '${continent}')" | grep '=' | sed -e 's/^.*= //g'))
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

### 1.4 Geoprocessing

Make a shaded relief map from DEM by setting zfactor, azimuth and altitude.  
```
zfactor=100
azimuth=315
altitude=45
gdaldem hillshade -combined -z ${zfactor} -s 111120 -az ${azimuth} -alt ${altitude} -compute_edges topo.tif topo_hillshade_${zfactor}_${azimuth}_${altitude}.tif
```

Multiply Natural Earth and shaded relief rasters with `gdal_calc.py`.  
```gdal_calc.py --overwrite -A topo_hillshade.tif -B hyp.tif --allBands B --outfile=hyp_hillshade.tif --calc="((A - numpy.min(A)) / (numpy.max(A) - numpy.min(A))) * B"```

<img src="images/hyp_hillshade.jpg"/>

Create a raster mask by keeping values greater than 0.  
```gdal_calc.py --overwrite --type=Byte --NoDataValue=0 -A topo.tif --outfile=topo_mask.tif --calc="A*(A>0)"```

Create a raster mask by setting values greater than 0 to 1.  
```gdal_calc.py --overwrite --NoDataValue=0 -A topo.tif --outfile=topo_mask.tif --calc="1*(A>0)"```

Clip Natural Earth raster to the land mask.  
```gdal_calc.py --overwrite --type=Byte --NoDataValue=0 -A topo_mask.tif -B hyp.tif --allBands B --outfile="hyp_mask.tif" --calc="B*(A>0)"```

<img src="images/hyp_mask.jpg"/>

Rasterize vector features selected from Natural Earth geopackage at specified output size.  
```gdal_rasterize -ts 1920 960 -te -180 -90 180 90 -l ne_110m_admin_0_countries_lakes -a mapcolor9 -a_nodata NA -ot Byte -at /home/steve/maps/naturalearth/packages/natural_earth_vector.gpkg countries.tif```

Create custom color file and color raster map.  
```
cat > rainbow.cpt <<- EOM
100% 118 147 142 255
50% 152 177 179
25% 192 203 206
0% 217 217 217 255
NA 255 255 255 0
EOM
gdaldem color-relief -alpha countries.tif rainbow.cpt countries_color.tif
```

<img src="images/countries_color.jpg"/>

Multiply Natural Earth and our colored raster.  
```gdal_calc.py --overwrite -A states_color.tif -B hyp.tif --allBands B --outfile=hyp_states.tif --calc="((A - numpy.min(A)) / (numpy.max(A) - numpy.min(A))) * B"```

### 1.5 Converting

Use `gdalwarp` to convert from GeoTIFF to regular TIFF (use with programs like imagemagick).  
```gdalwarp -overwrite -dstalpha --config GDAL_PAM_ENABLED NO -co PROFILE=BASELINE -f 'GTiff' -of 'GTiff' hyp.tif hyp_nogeo.tif```

Use `gdal_translate` to convert from GeoTIFF to JPEG, PNG and other image formats. Use `outsize` to set width and maintain aspect ratio of output image.  
```gdal_translate -outsize 1920 0 -if 'GTiff' -of 'JPEG' hyp.tif hyp.jpg```

```gdal_translate -outsize 1920 0 -if 'GTiff' -of 'PNG' hyp.tif hyp.png```

## 2. Vector
