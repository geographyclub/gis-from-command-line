# GIS FROM COMMAND LINE

GDAL (Geospatial Data Abstraction Library) is a computer software library for reading and writing raster and vector geospatial data formats. But it is much more than that. This is how I use GDAL with a little BASH scripting to make my own *Geographic Information Systems* from the command line.

<img src="images/ascii_space.png"/>

## TABLE OF CONTENTS

1. [Raster](#1-raster)  
    1.1 [Resampling](#11-resampling)  
    1.2 [Reprojecting](#12-reprojecting)  
    1.3 [Geoprocessing](#13-geoprocessing)  
    1.4 [Converting](#14-converting)  

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

<img src="images/hyp.png"/>

Resize and convert all geotiffs in the folder to png. These will be our example thumbnails.  
```
ls *.tif | while read file; do
  gdal_translate -of 'PNG' -outsize 50% 50% ${file} ${file%.*}.png
done
```

Resize raster as a fraction of its original size using output from *gdalinfo*.  
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

<img src="images/hyp_180pm.png"/>

Set prime meridian by desired placename. Use *ogrinfo* to query a Natural Earth geopackage.  
```
file='hyp.tif'
place='Toronto'
prime=$(ogrinfo /home/steve/maps/naturalearth/packages/natural_earth_vector.gpkg -sql "SELECT round(ST_X(ST_Shift_Longitude(geom))) FROM ne_10m_populated_places WHERE nameascii = '${place}'" | grep '=' | sed -e 's/^.*= //g')
gdalwarp -overwrite -s_srs 'EPSG:4326' -t_srs "+proj=latlong +datum=WGS84 +pm=${prime}dE" ${file} ${file%.*}_${prime}pm.tif
```

<img src="images/hyp_281pm.png"/>

Transform from lat-long to the popular Web Mercator projection using EPSG code, setting extent between -85* and 80* latitude.  
```
file='hyp.tif'
proj='epsg:3857'
gdalwarp -overwrite -s_srs 'EPSG:4326' -t_srs ${proj} -te -180 -85 180 80 -te_srs EPSG:4326 ${file} ${file%.*}_"${proj//:/_}".tif
```

<img src="images/hyp_epsg_3857.png"/>

Transform from lat-long to the Times projection using PROJ definition.  
```
file='hyp.tif'
proj='+proj=times'
gdalwarp -overwrite -dstalpha -s_srs 'EPSG:4326' -t_srs "${proj}" ${file} ${file%.*}_"$(echo ${proj} | sed -e 's/+proj=//g' -e 's/ +.*$//g')".tif
```

<img src="images/hyp_times.png"/>

Transform from lat-long to an orthographic projection with a custom PROJ definition. Again use *ogrinfo* to query a Natural Earth geopackage.  
```
file='hyp.tif'
place='Seoul'
xy=($(ogrinfo /home/steve/maps/naturalearth/packages/natural_earth_vector.gpkg -sql "SELECT round(ST_X(ST_Centroid(geom))), round(ST_Y(ST_Centroid(geom))) FROM ne_10m_populated_places WHERE nameascii = '${place}'" | grep '=' | sed -e 's/^.*= //g'))
gdalwarp -overwrite -dstalpha -s_srs 'EPSG:4326' -t_srs '+proj=ortho +lat_0="'${xy[1]}'" +lon_0="'${xy[0]}'" +ellps='sphere'' ${file} ${file%.*}_ortho_"${xy[0]}"_"${xy[1]}".tif
```

<img src="images/hyp_ortho_127_38.png"/>

Center the orthographic projection on the centroid of a country using the same method.  
```
file='hyp.tif'
place='Ukraine'
xy=($(ogrinfo /home/steve/maps/naturalearth/packages/natural_earth_vector.gpkg -sql "SELECT round(ST_X(ST_Centroid(geom))), round(ST_Y(ST_Centroid(geom))) FROM ne_110m_admin_0_countries WHERE name = '${place}'" | grep '=' | sed -e 's/^.*= //g'))
gdalwarp -overwrite -dstalpha -s_srs 'EPSG:4326' -t_srs '+proj=ortho +lat_0="'${xy[1]}'" +lon_0="'${xy[0]}'" +ellps='sphere'' ${file} ${file%.*}_ortho_"${xy[0]}"_"${xy[1]}".tif
```

<img src="images/hyp_ortho_31_49.png"/>

Some other popular map projections and their PROJ definitions.  
| Name | PROJ |
|------|------|
| Azimuthal Equidistant | +proj=aeqd +lat_0=45 +lon_0=-80 +a=1000000 +b=1000000 +over |
| Lambert Azimuthal Equal Area | +proj=laea +lat_0=0 +lon_0=0 +x_0=0 +y_0=0 +datum=WGS84 +units=m |
| Lambert Conformal Conic | +proj=lcc +lon_0=-90 +lat_1=33 +lat_2=45 |
| Stereographic | +proj=stere +lon_0=-119 +lat_0=36 +lat_ts=36 |
| Van der Grinten | +proj=vandg +lon_0=0 +x_0=0 +y_0=0 +R_A +a=6371000 +b=6371000 +units=m |

Georeference by extent.  
```gdal_translate -a_ullr -180 90 180 -90 HYP_HR_SR_OB_DR_1024_512.png HYP_HR_SR_OB_DR_1024_512_georeferenced.tif```

Georeference by ground control points.  
```gdal_translate -gcp 0 0 -180 -90 -gcp 1024 512 180 90 -gcp 0 512 -180 90 -gcp 1024 0 180 -90 HYP_HR_SR_OB_DR_1024_512.png HYP_HR_SR_OB_DR_1024_512_georeferenced.tif```

Georeference and transform in one step.  
```gdal_translate -a_ullr -180 90 180 -90 HYP_HR_SR_OB_DR_1024_512.png /vsistdout/ | gdalwarp -overwrite -t_srs 'EPSG:4326' /vsistdin/ HYP_HR_SR_OB_DR_1024_512_crs.tif```

### 1.3 Geoprocessing

Clip raster to a bounding box using either *gdal_translate* or *gdalwarp*. Use the appropriate stereographic projection for each hemisphere.  
```gdal_translate -projwin -180 90 180 0 hyp.tif /vsistdout/ | gdalwarp -overwrite -dstalpha -ts 1920 0 -t_srs '+proj=stere +lat_0=90 +lat_ts_0' /vsistdin/ hyp_north_stere.tif```

<img src="images/hyp_north_stere.png"/>

```gdalwarp -te -180 -90 180 0 hyp.tif /vsistdout/ | gdalwarp -overwrite -dstalpha -ts 1920 0 -t_srs '+proj=stere +lat_0=-90 +lat_ts_0' /vsistdin/ hyp_south_stere.tif```

<img src="images/hyp_south_stere.png"/>

Clip raster to extent of vector geometries. Use North America Lambert Conformal Conic projection here.  
```
file='hyp.tif'
continent='North America'
extent=($(ogrinfo /home/steve/maps/naturalearth/packages/natural_earth_vector.gpkg -sql "SELECT ROUND(ST_MinX(geom)), ROUND(ST_MinY(geom)), ROUND(ST_MaxX(geom)), ROUND(ST_MaxY(geom)) FROM (SELECT ST_Union(geom) geom FROM ne_110m_admin_0_countries WHERE CONTINENT = '${continent}')" | grep '=' | sed -e 's/^.*= //g'))
gdalwarp -te ${extent[*]} ${file} /vsistdout/ | gdalwarp -overwrite -dstalpha -ts 1920 0 -t_srs 'ESRI:102010' /vsistdin/ ${file%.*}_extent_$(echo "${extent[@]}" | sed 's/ /_/g').tif
```

<img src="images/hyp_extent_-172_7_-12_84.png"/>

Clip to vector geometry directly with *gdalwarp* with *crop_to_cutline* option.  
```
file='hyp.tif'
featurecla='Ocean'
gdalwarp -overwrite -crop_to_cutline -cutline '/home/steve/maps/naturalearth/packages/natural_earth_vector.gpkg' -csql "SELECT geom FROM ne_110m_ocean WHERE featurecla = '${featurecla}'" hyp.tif hyp_${featurecla,,}.tif
```

<img src="images/hyp_ocean.png"/>

Create a raster mask by keeping values greater than 0 using *gdal_calc*.  
```gdal_calc.py --overwrite --type=Byte --NoDataValue=0 -A topo.tif --outfile=topo_mask.tif --calc="A*(A>0)"```

Create a raster mask by setting values greater than 0 to 1.  
```gdal_calc.py --overwrite --NoDataValue=0 -A topo.tif --outfile=topo_mask.tif --calc="1*(A>0)"```

Clip Natural Earth raster to the land mask.  
```gdal_calc.py --overwrite --type=Byte --NoDataValue=0 -A topo_mask.tif -B hyp.tif --allBands B --outfile="hyp_mask.tif" --calc="B*(A>0)"```

<img src="images/hyp_mask.png"/>

Make a shaded relief map from DEM by setting zfactor, azimuth and altitude.  
```
zfactor=100
azimuth=315
altitude=45
gdaldem hillshade -combined -z ${zfactor} -s 111120 -az ${azimuth} -alt ${altitude} -compute_edges topo.tif topo_hillshade_${zfactor}_${azimuth}_${altitude}.tif
```

Multiply Natural Earth and shaded relief rasters.  
```gdal_calc.py --overwrite -A topo_hillshade.tif -B hyp.tif --allBands B --outfile=hyp_hillshade.tif --calc="((A - numpy.min(A)) / (numpy.max(A) - numpy.min(A))) * B"```

<img src="images/hyp_hillshade.png"/>

Rasterize vector feature and burn in value into the Natural Earth raster.
```
cp hyp.tif hyp_land.tif
gdal_rasterize -b 1 -b 2 -b 3 -burn 0 -burn 0 -burn 0 -l ne_110m_ocean -at /home/steve/maps/naturalearth/packages/natural_earth_vector.gpkg hyp_land.tif
```

<img src="images/hyp_land.png"/>

Rasterize vector feature with attribute selected from the Natural Earth geopackage.  
```gdal_rasterize -ts 1920 960 -te -180 -90 180 90 -l ne_110m_admin_0_countries_lakes -a mapcolor9 -a_nodata NA -ot Byte -at /home/steve/maps/naturalearth/packages/natural_earth_vector.gpkg countries.tif```

Create custom color file and color raster map.  
```
cat > greyoclock.cpt <<- EOM
100% 118 147 142 255
50% 152 177 179
25% 192 203 206
0% 217 217 217 255
NA 255 255 255 0
EOM
gdaldem color-relief -alpha countries.tif greyoclock.cpt countries_color.tif
```

<img src="images/countries_color.png"/>

### 1.4 Converting

Use *gdalwarp* to convert from GeoTIFF to regular TIFF (use with programs like imagemagick).  
```gdalwarp -overwrite -dstalpha --config GDAL_PAM_ENABLED NO -co PROFILE=BASELINE -f 'GTiff' -of 'GTiff' hyp.tif hyp_nogeo.tif```

Use *gdal_translate* to convert from GeoTIFF to JPEG, PNG and other image formats. Use *outsize* to set width and maintain aspect ratio of output image.  
```gdal_translate -outsize 1920 0 -if 'GTiff' -of 'JPEG' hyp.tif hyp.png```

```gdal_translate -outsize 1920 0 -if 'GTiff' -of 'PNG' hyp.tif hyp.png```

## 2. Vector

### 2.1 Reprojecting

Select the 110m coastline from the Natural Earth geopackage. This will be our example vector.  
```ogr2ogr -overwrite coastline.gpkg /home/steve/maps/naturalearth/packages/ne_110m_coastline_split1.gpkg coastline```

<img src="images/coastline.svg"/>

Transform from lat-long to the Web Mercator projection using EPSG code as we did with the raster, this time using *ogr2ogr*.  
```
file='coastline.gpkg'
proj='epsg:3857'
ogr2ogr -overwrite -skipfailures --config OGR_ENABLE_PARTIAL_REPROJECTION TRUE -t_srs ${proj} -spat -179 -85 179 80 ${file%.*}_"${proj//:/_}".gpkg ${file}
```

<img src="images/coastline_epsg_3857.svg"/>

Transform from lat-long to an orthographic projection with a custom PROJ definition.  
```
file='coastline.gpkg'
place='Seoul'
xy=($(ogrinfo /home/steve/maps/naturalearth/packages/natural_earth_vector.gpkg -sql "SELECT round(ST_X(ST_Centroid(geom))), round(ST_Y(ST_Centroid(geom))) FROM ne_10m_populated_places WHERE nameascii = '${place}'" | grep '=' | sed -e 's/^.*= //g'))
ogr2ogr -overwrite -skipfailures --config OGR_ENABLE_PARTIAL_REPROJECTION TRUE -t_srs '+proj=ortho +lat_0="'${xy[1]}'" +lon_0="'${xy[0]}'" +ellps='sphere'' ${file%.*}_ortho_"${xy[0]}"_"${xy[1]}".gpkg ${file} 
```

<img src="images/coastline_ortho_127_38.svg"/>

Center the orthographic projection on the centroid of a country using the same method.  
```
file='coastline.gpkg'
place='Ukraine'
xy=($(ogrinfo /home/steve/maps/naturalearth/packages/natural_earth_vector.gpkg -sql "SELECT round(ST_X(ST_Centroid(geom))), round(ST_Y(ST_Centroid(geom))) FROM ne_110m_admin_0_countries WHERE name = '${place}'" | grep '=' | sed -e 's/^.*= //g'))
ogr2ogr -overwrite -skipfailures --config OGR_ENABLE_PARTIAL_REPROJECTION TRUE -t_srs '+proj=ortho +lat_0="'${xy[1]}'" +lon_0="'${xy[0]}'" +ellps='sphere'' ${file%.*}_ortho_"${xy[0]}"_"${xy[1]}".gpkg ${file}
```

<img src="images/coastline_ortho_31_49.svg"/>

### Geoprocessing

Clip feature by grid.  
```

```

### Converting

Convert vector layer to svg file using *ogrinfo* to get extent and *AsSVG* to write paths. These are the vector examples shown here.  
```
file='coastline.gpkg'
layer='coastline'
width=1920
height=960

ogrinfo -dialect sqlite -sql "SELECT ST_MinX(extent(geom)) || CAST(X'09' AS TEXT) || (-1 * ST_MaxY(extent(geom))) || CAST(X'09' AS TEXT) || (ST_MaxX(extent(geom)) - ST_MinX(extent(geom))) || CAST(X'09' AS TEXT) || (ST_MaxY(extent(geom)) - ST_MinY(extent(geom))) FROM ${layer}" ${file} | grep -e '=' | sed -e 's/^.*://g' -e 's/^.* = //g' | while IFS=$'\t' read -a array; do
echo '<svg xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" height="'${height}'" width="'${width}'" viewBox="'${array[0]}' '${array[1]}' '${array[2]}' '${array[3]}'">' > ${file%.*}.svg
done
ogrinfo -dialect sqlite -sql "SELECT AsSVG(geom, 1) FROM ${layer}" ${file} | grep -e '=' | sed -e 's/^.*://g' -e 's/^.* = //g' | while IFS=$'\t' read -a array; do
  echo '<path d="'${array[0]}'" vector-effect="non-scaling-stroke" fill="#000" fill-opacity="1" stroke="#000" stroke-width="1px" stroke-linejoin="round" stroke-linecap="round"/>' >> ${file%.*}.svg
done
echo '</svg>' >> ${file%.*}.svg

```
