# GIS FROM COMMAND LINE

This is how I use Linux to make my own *Geographic Information Systems* from command line.

<img src="images/ascii_space.png"/>

## TABLE OF CONTENTS

1. [GDAL](#1-GDAL)  
    1.1 [Resampling](#11-resampling)  
    1.2 [Reprojecting](#12-reprojecting)  
    1.3 [Geoprocessing](#13-geoprocessing)  
    1.4 [Converting](#14-converting)  

2. [OGR](#2-OGR)  
    2.1 [Selecting](#21-selecting)  
    2.2 [Reprojecting](#22-reprojecting)  

3. [SAGA-GIS](#3-SAGA-GIS)  

4. [PostGIS Cookbook](https://github.com/geographyclub/postgis-cookbook#readme) 

5. [Earth Basher](https://github.com/geographyclub/earth-basher#readme) 

6. [ImageMagick for Mapmakers](https://github.com/geographyclub/imagemagick-for-mapmakers#readme)

7. [Weather to Video: scripts to download & animate weather data ](https://github.com/geographyclub/weather-to-video)

8. [American Geography: PostGIS + Leaflet with census data](https://github.com/geographyclub/american-geography#readme)

## 1. GDAL

GDAL (Geospatial Data Abstraction Library) is a computer software library for reading and writing raster and vector geospatial data formats.

### 1.1 Resampling

Resize the Natural Earth hypsometric raster to a web-safe width while keeping the aspect ratio. This will be our example raster.  
```bash
file='HYP_HR_SR_OB_DR.tif'
width=1920
gdalwarp -overwrite -ts ${width} 0 -r cubicspline ${file} hyp.tif
```

<img src="images/hyp.png"/>

Resize raster as a fraction of its original size using output from *gdalinfo*.  
```gdalwarp -overwrite -ts $(echo $(gdalinfo hyp.tif | grep "Size is" | sed 's/Size is //g' | sed 's/,.*$//g')/10 | bc) 0 -r cubicspline hyp.tif hyp_192.tif```

### 1.2 Reprojecting

Set prime meridian on 0-360° raster.  
```gdalwarp -overwrite -ts 1920 0 -s_srs 'EPSG:4326' -t_srs "+proj=longlat +ellps=WGS84 +pm=-360 +datum=WGS84 +no_defs +lon_wrap=360 +over" hyp.tif hyp_180pm.tif```

Set prime meridian on -180-180° raster by desired degree.  
```bash
file='hyp.tif'
prime=180
gdalwarp -overwrite -ts 1920 0 -s_srs 'EPSG:4326' -t_srs "+proj=latlong +datum=WGS84 +pm=${prime}dE" ${file} ${file%.*}_180pm.tif
```

<img src="images/hyp_180pm.png"/>

Set prime meridian by desired placename. Use *ogrinfo* to query the Natural Earth geopackage.  
```bash
file='hyp.tif'
name='Toronto'
prime=$(ogrinfo /home/steve/maps/naturalearth/packages/natural_earth_vector.gpkg -sql "SELECT round(ST_X(ST_Shift_Longitude(geom))) FROM ne_10m_populated_places WHERE nameascii = '${name}'" | grep '=' | sed -e 's/^.*= //g')
gdalwarp -overwrite -ts 1920 0 -s_srs 'EPSG:4326' -t_srs "+proj=latlong +datum=WGS84 +pm=${prime}dE" ${file} ${file%.*}_${prime}pm.tif
```

<img src="images/hyp_281pm.png"/>

Transform from lat-long to the popular Web Mercator projection using EPSG code, setting extent between -85* and 80* latitude.  
```bash
file='hyp.tif'
proj='epsg:3857'
gdalwarp -overwrite -dstalpha --config OGR_ENABLE_PARTIAL_REPROJECTION TRUE -ts 1920 0 -s_srs 'EPSG:4326' -t_srs ${proj} -te -180 -85 180 80 -te_srs EPSG:4326 ${file} ${file%.*}_"${proj//:/_}".tif
```

<img src="images/hyp_epsg_3857.png"/>

Transform from lat-long to the Times projection using PROJ definition.  
```bash
file='hyp.tif'
proj='+proj=times'
gdalwarp -overwrite -dstalpha --config OGR_ENABLE_PARTIAL_REPROJECTION TRUE -ts 1920 0 -s_srs 'EPSG:4326' -t_srs "${proj}" ${file} ${file%.*}_"$(echo ${proj} | sed -e 's/+proj=//g' -e 's/ +.*$//g')".tif
```

<img src="images/hyp_times.png"/>

Transform from lat-long to an orthographic projection with a custom PROJ definition. Again use *ogrinfo* to query the Natural Earth geopackage.  
```bash
file='hyp.tif'
name='Seoul'
xy=($(ogrinfo /home/steve/maps/naturalearth/packages/natural_earth_vector.gpkg -sql "SELECT round(ST_X(ST_Centroid(geom))), round(ST_Y(ST_Centroid(geom))) FROM ne_10m_populated_places WHERE nameascii = '${name}'" | grep '=' | sed -e 's/^.*= //g'))
gdalwarp -overwrite -dstalpha --config OGR_ENABLE_PARTIAL_REPROJECTION TRUE -ts 1920 0 -s_srs 'EPSG:4326' -t_srs '+proj=ortho +lat_0="'${xy[1]}'" +lon_0="'${xy[0]}'" +ellps='sphere'' ${file} ${file%.*}_ortho_"${xy[0]}"_"${xy[1]}".tif
```

<img src="images/hyp_ortho_127_38.png"/>

Center the orthographic projection on the centroid of a country using the same method.  
```bash
file='hyp.tif'
name='Ukraine'
xy=($(ogrinfo /home/steve/maps/naturalearth/packages/natural_earth_vector.gpkg -sql "SELECT round(ST_X(ST_Centroid(geom))), round(ST_Y(ST_Centroid(geom))) FROM ne_110m_admin_0_countries WHERE name = '${name}'" | grep '=' | sed -e 's/^.*= //g'))
gdalwarp -overwrite -dstalpha --config OGR_ENABLE_PARTIAL_REPROJECTION TRUE -ts 1920 0 -s_srs 'EPSG:4326' -t_srs '+proj=ortho +lat_0="'${xy[1]}'" +lon_0="'${xy[0]}'" +ellps='sphere'' ${file} ${file%.*}_ortho_"${xy[0]}"_"${xy[1]}".tif
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
```gdal_translate -a_ullr -180 90 180 -90 HYP_HR_SR_OB_DR_1024_512.png /vsistdout/ | gdalwarp -overwrite -s_srs 'EPSG:4326' -t_srs 'EPSG:3857' /vsistdin/ HYP_HR_SR_OB_DR_1024_512_crs.tif```

### 1.3 Geoprocessing

Clip raster to a bounding box using either *gdal_translate* or *gdalwarp*. Use the appropriate stereographic projection for each hemisphere.  
```gdal_translate -projwin -180 90 180 0 hyp.tif /vsistdout/ | gdalwarp -overwrite -dstalpha --config OGR_ENABLE_PARTIAL_REPROJECTION TRUE -ts 1920 0 -s_srs 'EPSG:4326' -t_srs '+proj=stere +lat_0=90 +lat_ts_0' /vsistdin/ hyp_north_stere.tif```

<img src="images/hyp_north_stere.png"/>

```gdalwarp -te -180 -90 180 0 hyp.tif /vsistdout/ | gdalwarp -overwrite -dstalpha --config OGR_ENABLE_PARTIAL_REPROJECTION TRUE -ts 1920 0 -s_srs 'EPSG:4326' -t_srs '+proj=stere +lat_0=-90 +lat_ts_0' /vsistdin/ hyp_south_stere.tif```

<img src="images/hyp_south_stere.png"/>

Clip raster to extent of vector geometries in the same way. Use North America Lambert Conformal Conic projection here.  
```bash
file='hyp.tif'
continent='North America'
extent=($(ogrinfo /home/steve/maps/naturalearth/packages/natural_earth_vector.gpkg -sql "SELECT ROUND(ST_MinX(geom)), ROUND(ST_MinY(geom)), ROUND(ST_MaxX(geom)), ROUND(ST_MaxY(geom)) FROM (SELECT ST_Union(geom) geom FROM ne_110m_admin_0_countries WHERE CONTINENT = '${continent}')" | grep '=' | sed -e 's/^.*= //g'))
gdalwarp -te ${extent[*]} ${file} /vsistdout/ | gdalwarp -overwrite -dstalpha --config OGR_ENABLE_PARTIAL_REPROJECTION TRUE -ts 1920 0 -s_srs 'EPSG:4326' -t_srs 'ESRI:102010' /vsistdin/ ${file%.*}_extent_$(echo "${extent[@]}" | sed 's/ /_/g').tif
```

<img src="images/hyp_extent_-172_7_-12_84.png"/>

Clip to vector geometry with *crop_to_cutline*. The cutline is the extent of the Indian Ocean so we center the projection on its centroid here.  
```bash
file='hyp.tif'
name='INDIAN OCEAN'
xy=($(ogrinfo /home/steve/maps/naturalearth/packages/natural_earth_vector.gpkg -sql "SELECT round(ST_X(ST_Centroid(geom))), round(ST_Y(ST_Centroid(geom))) FROM ne_110m_geography_marine_polys WHERE name = '${name}'" | grep '=' | sed -e 's/^.*= //g'))
gdalwarp -dstalpha -crop_to_cutline -cutline '/home/steve/maps/naturalearth/packages/natural_earth_vector.gpkg' -csql "SELECT Extent(geom) FROM ne_110m_geography_marine_polys WHERE name = '${name}'" ${file} /vsistdout/ | gdalwarp -overwrite -dstalpha --config OGR_ENABLE_PARTIAL_REPROJECTION TRUE -ts 1920 0 -s_srs 'EPSG:4326' -t_srs '+proj=ortho +lat_0="'${xy[1]}'" +lon_0="'${xy[0]}'" +ellps='sphere'' /vsistdin/ ${file%.*}_ortho_"${xy[0]}"_"${xy[1]}".tif
```

<img src="images/hyp_ortho_82_-34.png"/>

Make a shaded relief map from TOPO by setting zfactor, azimuth and altitude.  
```bash
zfactor=100
azimuth=315
altitude=45
gdaldem hillshade -combined -z ${zfactor} -s 111120 -az ${azimuth} -alt ${altitude} -compute_edges topo.tif topo_hillshade.tif
```

<img src="images/topo_hillshade.png"/>

Multiply Natural Earth and shaded relief rasters, then take a closer look at the Himalayas.  
```bash
gdal_calc.py --overwrite -A topo_hillshade.tif -B hyp.tif --allBands B --outfile=hyp_hillshade.tif --calc="((A - numpy.min(A)) / (numpy.max(A) - numpy.min(A))) * B"

file='hyp_hillshade.tif'
name='HIMALAYAS'
xy=($(ogrinfo /home/steve/maps/naturalearth/packages/natural_earth_vector.gpkg -sql "SELECT round(ST_X(ST_Centroid(geom))), round(ST_Y(ST_Centroid(geom))) FROM ne_110m_geography_regions_polys WHERE name = '${name}'" | grep '=' | sed -e 's/^.*= //g'))
gdalwarp -overwrite -dstalpha --config OGR_ENABLE_PARTIAL_REPROJECTION TRUE -ts 1920 0 -s_srs 'EPSG:4326' -t_srs '+proj=ortho +lat_0="'${xy[1]}'" +lon_0="'${xy[0]}'" +ellps='sphere'' ${file} ${file%.*}_ortho_"${xy[0]}"_"${xy[1]}".tif
```

<img src="images/hyp_hillshade_ortho_85_29.png"/>

### 1.4 Converting

Use *gdalwarp* to convert from GeoTIFF to regular TIFF (use with programs like imagemagick).  
```gdalwarp -overwrite -dstalpha --config GDAL_PAM_ENABLED NO -co PROFILE=BASELINE -ts 1920 0 -f 'GTiff' -of 'GTiff' hyp.tif hyp_nogeo.tif```

Use *gdal_translate* to convert from GeoTIFF to JPEG, PNG and other image formats. Use *outsize* to set width and maintain aspect ratio of output image.  
```gdal_translate -outsize 1920 0 -if 'GTiff' -of 'JPEG' hyp.tif hyp.png```

```gdal_translate -outsize 1920 0 -if 'GTiff' -of 'PNG' hyp.tif hyp.png```

Resize and convert all geotiffs in the folder to png. This is how to make the example thumbnails.  
```bash
ls *.tif | while read file; do
  gdal_translate -of 'PNG' -outsize 1920 0 ${file} ${file%.*}.png
done
```

## 2. OGR

### 2.1 Selecting

Select vector layers processed from the Natural Earth geopackage. These will be our example layers.  
```ogr2ogr -overwrite -f 'GPKG' -s_srs 'EPSG:4326' -t_srs 'EPSG:4326' countries.gpkg /home/steve/maps/naturalearth/packages/ne_110m_admin_0_boundary_lines_land_coastline_split1.gpkg countries```

<img src="images/countries.svg"/>

### 2.2 Reprojecting

Transform from lat-long to an orthographic projection, this time using *ogr2ogr* for vectors.  
```bash
file='countries.gpkg'
layer='countries'
name='Cairo'
xy=($(ogrinfo /home/steve/maps/naturalearth/packages/natural_earth_vector.gpkg -sql "SELECT round(ST_X(ST_Centroid(geom))), round(ST_Y(ST_Centroid(geom))) FROM ne_10m_populated_places WHERE nameascii = '${name}'" | grep '=' | sed -e 's/^.*= //g'))
ogr2ogr -overwrite -skipfailures --config OGR_ENABLE_PARTIAL_REPROJECTION TRUE -s_srs 'EPSG:4326' -t_srs '+proj=ortho +lat_0="'${xy[1]}'" +lon_0="'${xy[0]}'" +ellps='sphere'' ${layer}_ortho_"${xy[0]}"_"${xy[1]}".gpkg ${file} ${layer}
```

<img src="images/countries_ortho_31_30.svg"/>

Center the orthographic projection on the centroid of a country.  
```bash
file='countries.gpkg'
layer='countries'
name='Brazil'
xy=($(ogrinfo /home/steve/maps/naturalearth/packages/natural_earth_vector.gpkg -sql "SELECT round(ST_X(ST_Centroid(geom))), round(ST_Y(ST_Centroid(geom))) FROM ne_110m_admin_0_countries WHERE name = '${name}'" | grep '=' | sed -e 's/^.*= //g'))
ogr2ogr -overwrite -skipfailures --config OGR_ENABLE_PARTIAL_REPROJECTION TRUE -s_srs 'EPSG:4326' -t_srs '+proj=ortho +lat_0="'${xy[1]}'" +lon_0="'${xy[0]}'" +ellps='sphere'' ${layer}_ortho_"${xy[0]}"_"${xy[1]}".gpkg ${file} ${layer}
```

<img src="images/countries_ortho_-53_-11.svg"/>

### 2.3 Geoprocessing

Clip and reproject vector and raster data to the same extent.  
```bash
# make extent
name='North America'
extent=($(ogrinfo /home/steve/maps/naturalearth/packages/natural_earth_vector.gpkg -sql "SELECT ROUND(ST_MinX(geom)), ROUND(ST_MinY(geom)), ROUND(ST_MaxX(geom)), ROUND(ST_MaxY(geom)), round(ST_X(ST_Centroid(geom))), round(ST_Y(ST_Centroid(geom))) FROM (SELECT ST_Union(geom) geom FROM ne_110m_admin_0_countries WHERE CONTINENT = '${name}')" | grep '=' | sed -e 's/^.*= //g'))
# clip hyp
gdalwarp -te_srs 'EPSG:4326' -te ${extent[0]} ${extent[1]} ${extent[2]} ${extent[3]} /home/steve/maps/naturalearth/raster/HYP_HR_SR_OB_DR_5400_2700.tif /vsistdout/ | gdalwarp -overwrite -dstalpha -s_srs 'EPSG:4326' -t_srs '+proj=ortho +lat_0="'${extent[5]}'" +lon_0="'${extent[4]}'" +ellps='sphere'' /vsistdin/ hyp_${extent[0]}_${extent[1]}_${extent[2]}_${extent[3]}.tif
# clip topo
gdalwarp -te_srs 'EPSG:4326' -te ${extent[0]} ${extent[1]} ${extent[2]} ${extent[3]} /home/steve/maps/srtm/topo15_4000.tif /vsistdout/ | gdalwarp -overwrite -dstalpha -s_srs 'EPSG:4326' -t_srs '+proj=ortho +lat_0="'${extent[5]}'" +lon_0="'${extent[4]}'" +ellps='sphere'' /vsistdin/ topo_${extent[0]}_${extent[1]}_${extent[2]}_${extent[3]}.tif
# clip vectors
ogr2ogr -overwrite -skipfailures --config OGR_ENABLE_PARTIAL_REPROJECTION TRUE -clipsrc ${extent[0]} ${extent[1]} ${extent[2]} ${extent[3]} -a_srs 'EPSG:4326' -t_srs '+proj=ortho +lat_0="'${extent[5]}'" +lon_0="'${extent[4]}'" +ellps='sphere'' subunits_${extent[0]}_${extent[1]}_${extent[2]}_${extent[3]}.gpkg /home/steve/maps/naturalearth/packages/natural_earth_vector.gpkg ne_10m_admin_0_map_subunits
```

### Converting

Convert vector layer to svg file using *ogrinfo* to get data and fill in svg according to data type. These are the vector examples shown here.  
```bash
file='subunits_laea.gpkg'
layer='subunits'
width=1920
height=960
ogrinfo -dialect sqlite -sql "SELECT ST_MinX(extent(geom)) || CAST(X'09' AS TEXT) || (-1 * ST_MaxY(extent(geom))) || CAST(X'09' AS TEXT) || (ST_MaxX(extent(geom)) - ST_MinX(extent(geom))) || CAST(X'09' AS TEXT) || (ST_MaxY(extent(geom)) - ST_MinY(extent(geom))) FROM ${layer}" ${file} | grep -e '=' | sed -e 's/^.*://g' -e 's/^.* = //g' | while IFS=$'\t' read -a array; do
echo '<svg xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" height="'${height}'" width="'${width}'" viewBox="'${array[0]}' '${array[1]}' '${array[2]}' '${array[3]}'">' > ${file%.*}.svg
done
ogrinfo -dialect sqlite -sql "SELECT fid || CAST(X'09' AS TEXT) || ST_X(ST_Centroid(geom)) || CAST(X'09' AS TEXT) || (-1 * ST_Y(ST_Centroid(geom))) || CAST(X'09' AS TEXT) || AsSVG(geom, 1) || CAST(X'09' AS TEXT) || GeometryType(geom) FROM ${layer} WHERE geom NOT LIKE '%null%'" ${file} | grep -e '=' | sed -e 's/^.*://g' -e 's/^.* = //g' | while IFS=$'\t' read -a array; do
  case ${array[4]} in
    POINT|MULTIPOINT)
      echo '<circle id="'${array[0]}'" cx="'${array[1]}'" cy="'${array[2]}'" r="1em" vector-effect="non-scaling-stroke" fill="#FFF" fill-opacity="1" stroke="#000" stroke-width="0.6px" stroke-linejoin="round" stroke-linecap="round"/>' >> ${file%.*}.svg
      ;;
    LINESTRING|MULTILINESTRING)
      echo '<path id="'${array[0]}'" d="'${array[3]}'" vector-effect="non-scaling-stroke" stroke="#000" stroke-width="0.6px" stroke-linejoin="round" stroke-linecap="round"/>' >> ${file%.*}.svg
      ;;
    POLYGON|MULTIPOLYGON)
      echo '<path id="'${array[0]}'" d="'${array[3]}'" vector-effect="non-scaling-stroke" fill="#000" fill-opacity="1" stroke="#FFF" stroke-width="0.6px" stroke-linejoin="round" stroke-linecap="round"/>' >> ${file%.*}.svg
      ;;
  esac
done
echo '</svg>' >> ${file%.*}.svg
```

## 3. SAGA-GIS

Misc

`saga_cmd --cores 1`

Classify

`saga_cmd imagery_classification 1 -NCLUSTER 20 -MAXITER 0 -METHOD 1 -GRIDS N43W080_wgs84_500_5000.tif -CLUSTER N43W080_wgs84_500_5000_cluster.tif`

Watershed

`saga_cmd imagery_segmentation 0 -OUTPUT 0 -DOWN 1 -JOIN 0 -THRESHOLD 0 -EDGE 1 -BBORDERS 0 -GRID N43W080_wgs84_500.tif -SEGMENTS N43W080_wgs84_500_segments.tif`

`saga_cmd ta_channels 5 -THRESHOLD 1 -DEM N43W080_wgs84_500.tif -SEGMENTS N43W080_wgs84_500_segments.shp -BASINS N43W080_wgs84_500_basins.shp`

Raster to polygons

`saga_cmd shapes_grid 6 -GRID N43W080_wgs84.tif -POLYGONS N43W080_wgs84.shp`

Raster values to vector

`saga_cmd shapes_grid 0`

`saga_cmd shapes_grid 1`

Arrows

`saga_cmd shapes_grid 15 -SURFACE N43W080_wgs84_500.tif -VECTORS N43W080_wgs84_500_gradient.shp`

Vector processing

`saga_cmd shapes_lines`

`saga_cmd shapes_points`

`saga_cmd shapes_polygons`

Smoothing

`saga_cmd shapes_lines 7 -SENSITIVITY 3 -ITERATIONS 10 -PRESERVATION 10 -SIGMA 2 -LINES_IN N43W080_wgs84_500_segments.shp -LINES_OUT N43W080_wgs84_500_segments_smooth.shp`

Landcsape

`saga_cmd ta_compound 0 -THRESHOLD 1 -ELEVATION N43W080_wgs84_500.tif -SHADE N43W080_wgs84_500_shade.tif -CHANNELS N43W080_wgs84_500_channels.shp -BASINS N43W080_wgs84_500_basins.shp`

Terrain

`saga_cmd ta_morphometry 16 -DEM N43W080_wgs84_500.tif -TRI N43W080_wgs84_500_tri.shp`

`saga_cmd ta_morphometry 17 -DEM N43W080_wgs84_500.tif -VRM N43W080_wgs84_500_vrm.tif`

`saga_cmd ta_morphometry 18 -DEM N43W080_wgs84_500.tif -TPI N43W080_wgs84_500_tpi.tif`

TIN

`saga_cmd tin_tools 0 -GRID N48W092_N47W092_N48W091_N47W091_smooth.tif -TIN N48W092_N47W092_N48W091_N47W091_tin.shp`

`saga_cmd tin_tools 3 -TIN N48W092_N47W092_N48W091_N47W091_tin.shp -POLYGONS N48W092_N47W092_N48W091_N47W091_poly.shp`

