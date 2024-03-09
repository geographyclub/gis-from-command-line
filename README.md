# GIS FROM COMMAND LINE

All the software and scripts you need to make Linux a complete *Geographic Information System* from command line.

## TABLE OF CONTENTS

1. [GDAL](#GDAL)  
2. [OGR](#OGR)  
3. [SAGA-GIS](#saga-gis)   
4. [Dataset examples](#dataset-examples)  
5. [Misc](#misc)  
6. [PostGIS Cookbook](https://github.com/geographyclub/postgis-cookbook#readme)  
7. [ImageMagick for Mapmakers](https://github.com/geographyclub/imagemagick-for-mapmakers#readme)  
8. [Weather to Video: scripts to download & animate weather data ](https://github.com/geographyclub/weather-to-video)  
9. [American Geography: PostGIS + Leaflet with census data](https://github.com/geographyclub/american-geography#readme)  

## GDAL

Resize the Natural Earth hypsometric raster to a web-safe width while keeping the aspect ratio.  
```shell
file='HYP_HR_SR_OB_DR.tif'
width=1920
gdalwarp -overwrite -ts ${width} 0 -r cubicspline ${file} hyp.tif
```

Resize raster as a fraction of its original size using output from *gdalinfo*.  
```shell
gdalwarp -overwrite -ts $(echo $(gdalinfo hyp.tif | grep "Size is" | sed 's/Size is //g' | sed 's/,.*$//g')/10 | bc) 0 -r cubicspline hyp.tif hyp_192.tif
```

Set prime meridian on 0-360° raster.  
```shell
gdalwarp -overwrite -ts 1920 0 -s_srs 'EPSG:4326' -t_srs "+proj=longlat +ellps=WGS84 +pm=-360 +datum=WGS84 +no_defs +lon_wrap=360 +over" hyp.tif hyp_180pm.tif
```

Set prime meridian on -180-180° raster by desired degree.  
```shell
file='hyp.tif'
prime=180
gdalwarp -overwrite -ts 1920 0 -s_srs 'EPSG:4326' -t_srs "+proj=latlong +datum=WGS84 +pm=${prime}dE" ${file} ${file%.*}_180pm.tif
```

Set prime meridian by desired placename. Use *ogrinfo* to query the Natural Earth geopackage.  
```shell
file='hyp.tif'
name='Toronto'
prime=$(ogrinfo naturalearth/packages/natural_earth_vector.gpkg -sql "SELECT round(ST_X(ST_Shift_Longitude(geom))) FROM ne_10m_populated_places WHERE nameascii = '${name}'" | grep '=' | sed -e 's/^.*= //g')
gdalwarp -overwrite -ts 1920 0 -s_srs 'EPSG:4326' -t_srs "+proj=latlong +datum=WGS84 +pm=${prime}dE" ${file} ${file%.*}_${prime}pm.tif
```

Transform from lat-long to the popular Web Mercator projection using EPSG code, setting extent between -85* and 80* latitude.  
```shell
file='hyp.tif'
proj='epsg:3857'
gdalwarp -overwrite -dstalpha --config OGR_ENABLE_PARTIAL_REPROJECTION TRUE -ts 1920 0 -s_srs 'EPSG:4326' -t_srs ${proj} -te -180 -85 180 80 -te_srs EPSG:4326 ${file} ${file%.*}_"${proj//:/_}".tif
```

Transform from lat-long to the Times projection using PROJ definition.  
```shell
file='hyp.tif'
proj='+proj=times'
gdalwarp -overwrite -dstalpha --config OGR_ENABLE_PARTIAL_REPROJECTION TRUE -ts 1920 0 -s_srs 'EPSG:4326' -t_srs "${proj}" ${file} ${file%.*}_"$(echo ${proj} | sed -e 's/+proj=//g' -e 's/ +.*$//g')".tif
```

Transform from lat-long to an orthographic projection with a custom PROJ definition. Again use *ogrinfo* to query the Natural Earth geopackage.  
```shell
file='hyp.tif'
name='Seoul'
xy=($(ogrinfo naturalearth/packages/natural_earth_vector.gpkg -sql "SELECT round(ST_X(ST_Centroid(geom))), round(ST_Y(ST_Centroid(geom))) FROM ne_10m_populated_places WHERE nameascii = '${name}'" | grep '=' | sed -e 's/^.*= //g'))
gdalwarp -overwrite -dstalpha --config OGR_ENABLE_PARTIAL_REPROJECTION TRUE -ts 1920 0 -s_srs 'EPSG:4326' -t_srs '+proj=ortho +lat_0="'${xy[1]}'" +lon_0="'${xy[0]}'" +ellps='sphere'' ${file} ${file%.*}_ortho_"${xy[0]}"_"${xy[1]}".tif
```

Center the orthographic projection on the centroid of a country using the same method.  
```shell
file='hyp.tif'
name='Ukraine'
xy=($(ogrinfo naturalearth/packages/natural_earth_vector.gpkg -sql "SELECT round(ST_X(ST_Centroid(geom))), round(ST_Y(ST_Centroid(geom))) FROM ne_110m_admin_0_countries WHERE name = '${name}'" | grep '=' | sed -e 's/^.*= //g'))
gdalwarp -overwrite -dstalpha --config OGR_ENABLE_PARTIAL_REPROJECTION TRUE -ts 1920 0 -s_srs 'EPSG:4326' -t_srs '+proj=ortho +lat_0="'${xy[1]}'" +lon_0="'${xy[0]}'" +ellps='sphere'' ${file} ${file%.*}_ortho_"${xy[0]}"_"${xy[1]}".tif
```

ogr2ogr pipe to ogrinfo.  
```shell
ogr2ogr -overwrite -skipfailures --config OGR_ENABLE_PARTIAL_REPROJECTION TRUE -f GeoJSON -s_srs 'epsg:4326' -t_srs "+proj=ortho" /vsistdout/ -nln ${layer1} PG:dbname=world ${layer1} | ogrinfo -dialect sqlite -sql "SELECT X(Centroid(geometry)), Y(Centroid(geometry)) FROM ${layer1}" /vsistdin/
```

Some other popular map projections and their PROJ definitions.  
| Name | PROJ |
|------|------|
| Azimuthal Equidistant | +proj=aeqd +lat_0=45 +lon_0=-80 +a=1000000 +b=1000000 +over |
| Lambert Azimuthal Equal Area | +proj=laea +lat_0=0 +lon_0=0 +x_0=0 +y_0=0 +datum=WGS84 +units=m |
| Lambert Conformal Conic | +proj=lcc +lon_0=-90 +lat_1=33 +lat_2=45 |
| Stereographic | +proj=stere +lon_0=-119 +lat_0=36 +lat_ts=36 |
| Van der Grinten | +proj=vandg +lon_0=0 +x_0=0 +y_0=0 +R_A +a=6371000 +b=6371000 +units=m |

Georeference by extent.  
```shell
gdal_translate -a_ullr -180 90 180 -90 HYP_HR_SR_OB_DR_1024_512.png HYP_HR_SR_OB_DR_1024_512_georeferenced.tif
```

Georeference by ground control points.  
```shell
gdal_translate -gcp 0 0 -180 -90 -gcp 1024 512 180 90 -gcp 0 512 -180 90 -gcp 1024 0 180 -90 HYP_HR_SR_OB_DR_1024_512.png HYP_HR_SR_OB_DR_1024_512_georeferenced.tif
```

Georeference and transform in one step.  
```shell
gdal_translate -a_ullr -180 90 180 -90 HYP_HR_SR_OB_DR_1024_512.png /vsistdout/ | gdalwarp -overwrite -s_srs 'EPSG:4326' -t_srs 'EPSG:3857' /vsistdin/ HYP_HR_SR_OB_DR_1024_512_crs.tif
```

Clip raster to a bounding box using either *gdal_translate* or *gdalwarp*. Use the appropriate stereographic projection for each hemisphere.  
```shell
gdal_translate -projwin -180 90 180 0 hyp.tif /vsistdout/ | gdalwarp -overwrite -dstalpha --config OGR_ENABLE_PARTIAL_REPROJECTION TRUE -ts 1920 0 -s_srs 'EPSG:4326' -t_srs '+proj=stere +lat_0=90 +lat_ts_0' /vsistdin/ hyp_north_stere.tif

gdalwarp -te -180 -90 180 0 hyp.tif /vsistdout/ | gdalwarp -overwrite -dstalpha --config OGR_ENABLE_PARTIAL_REPROJECTION TRUE -ts 1920 0 -s_srs 'EPSG:4326' -t_srs '+proj=stere +lat_0=-90 +lat_ts_0' /vsistdin/ hyp_south_stere.tif
```

Clip raster to extent of vector geometries in the same way. Use North America Lambert Conformal Conic projection here.  
```shell
file='hyp.tif'
continent='North America'
extent=($(ogrinfo naturalearth/packages/natural_earth_vector.gpkg -sql "SELECT ROUND(ST_MinX(geom)), ROUND(ST_MinY(geom)), ROUND(ST_MaxX(geom)), ROUND(ST_MaxY(geom)) FROM (SELECT ST_Union(geom) geom FROM ne_110m_admin_0_countries WHERE CONTINENT = '${continent}')" | grep '=' | sed -e 's/^.*= //g'))
gdalwarp -te ${extent[*]} ${file} /vsistdout/ | gdalwarp -overwrite -dstalpha --config OGR_ENABLE_PARTIAL_REPROJECTION TRUE -ts 1920 0 -s_srs 'EPSG:4326' -t_srs 'ESRI:102010' /vsistdin/ ${file%.*}_extent_$(echo "${extent[@]}" | sed 's/ /_/g').tif
```

Clip to vector geometry with *crop_to_cutline*. The cutline is the extent of the Indian Ocean so we center the projection on its centroid here.  
```shell
file='hyp.tif'
name='INDIAN OCEAN'
xy=($(ogrinfo naturalearth/packages/natural_earth_vector.gpkg -sql "SELECT round(ST_X(ST_Centroid(geom))), round(ST_Y(ST_Centroid(geom))) FROM ne_110m_geography_marine_polys WHERE name = '${name}'" | grep '=' | sed -e 's/^.*= //g'))
gdalwarp -dstalpha -crop_to_cutline -cutline 'naturalearth/packages/natural_earth_vector.gpkg' -csql "SELECT Extent(geom) FROM ne_110m_geography_marine_polys WHERE name = '${name}'" ${file} /vsistdout/ | gdalwarp -overwrite -dstalpha --config OGR_ENABLE_PARTIAL_REPROJECTION TRUE -ts 1920 0 -s_srs 'EPSG:4326' -t_srs '+proj=ortho +lat_0="'${xy[1]}'" +lon_0="'${xy[0]}'" +ellps='sphere'' /vsistdin/ ${file%.*}_ortho_"${xy[0]}"_"${xy[1]}".tif
```

Make a shaded relief map from TOPO by setting zfactor, azimuth and altitude.  
```shell
zfactor=100
azimuth=315
altitude=45
gdaldem hillshade -combined -z ${zfactor} -s 111120 -az ${azimuth} -alt ${altitude} -compute_edges topo.tif topo_hillshade.tif
```

Multiply Natural Earth and shaded relief rasters, then take a closer look at the Himalayas.  
```shell
gdal_calc.py --overwrite -A topo_hillshade.tif -B hyp.tif --allBands B --outfile=hyp_hillshade.tif --calc="((A - numpy.min(A)) / (numpy.max(A) - numpy.min(A))) * B"

file='hyp_hillshade.tif'
name='HIMALAYAS'
xy=($(ogrinfo naturalearth/packages/natural_earth_vector.gpkg -sql "SELECT round(ST_X(ST_Centroid(geom))), round(ST_Y(ST_Centroid(geom))) FROM ne_110m_geography_regions_polys WHERE name = '${name}'" | grep '=' | sed -e 's/^.*= //g'))
gdalwarp -overwrite -dstalpha --config OGR_ENABLE_PARTIAL_REPROJECTION TRUE -ts 1920 0 -s_srs 'EPSG:4326' -t_srs '+proj=ortho +lat_0="'${xy[1]}'" +lon_0="'${xy[0]}'" +ellps='sphere'' ${file} ${file%.*}_ortho_"${xy[0]}"_"${xy[1]}".tif
```

Use *gdalwarp* to convert from GeoTIFF to regular TIFF (use with programs like imagemagick).  
```shell
gdalwarp -overwrite -dstalpha --config GDAL_PAM_ENABLED NO -co PROFILE=BASELINE -ts 1920 0 -f 'GTiff' -of 'GTiff' hyp.tif hyp_nogeo.tif
```

Use *gdal_translate* to convert from GeoTIFF to JPEG, PNG and other image formats. Use *outsize* to set width and maintain aspect ratio of output image.  
```shell
gdal_translate -outsize 1920 0 -if 'GTiff' -of 'JPEG' hyp.tif hyp.png

gdal_translate -outsize 1920 0 -if 'GTiff' -of 'PNG' hyp.tif hyp.png
```

Resize and convert all geotiffs in the folder to png.  
```shell
ls *.tif | while read file; do
  gdal_translate -of 'PNG' -outsize 1920 0 ${file} ${file%.*}.png
done
```

Raster math with *gdal_calc*.  
```shell
# empty raster
gdal_calc.py --overwrite -A N43W080_3857.tif --outfile="empty.tif" --calc="0"

# adding
gdal_calc.py --overwrite -A ${dem%_wgs84.tif}_3857.tif -B ${city}/${city}_buildings.tif --outfile="${city}/${city}_dembuildings.tif" --calc="((A>=0)*A)+((A<0)*A*-0.1)+(B*20)"
gdal_calc.py --overwrite -A N43W080_3857.tif -B buildings.tif --outfile="N43W080_3857_buildings.tif" --calc="A+(B*20)"

# slicing
gdal_calc.py --overwrite --NoDataValue=0 -A topo15_43200_slope.tif --outfile topo15_43200_slope1.tif --calc="A*(A>=1)"
gdal_calc.py -A input.tif --outfile=result.tif --calc="A*logical_and(A>100,A<150)"
# slicing with a loop
for a in $(seq 1 100 5000); do
  gdal_calc.py --NoDataValue=0 -A ${dem} --outfile ${dir}/$(basename ${dem%.*}_${a}.tif) --calc="0*(A<0)" --calc="${a}*(A>=${a})"
done

# rounding
gdal_calc.py --overwrite -A topo15_43200.tif --outfile topo15_43200_rounded1000.tif --type 'Int16' --calc="A*0.001"

# mask
gdal_calc.py -A worldclim/wc2.0_bio_30s_15.tif --outfile=wc2.0_bio_30s_15_mask.tif --overwrite --type=Int16 --NoDataValue=0 --calc="1*(A>0)"
gdal_calc.py -A topo15_43200_tmp.tif -B worldclim/wc2.0_bio_30s_15_mask.tif --outfile=topo15_43200_slope.tif --overwrite --type=Float32 --NoDataValue=0 --co=TILED=YES --co=COMPRESS=LZW --calc="A*(B>0)"

# binary
gdal_calc.py -A topo15_004_0004_lev01_hillshade.tif --outfile=topo15_004_0004_hillshade_binary.tif --overwrite --type=Int16 --calc="1*(A<2)"

# binary (null)
gdal_calc.py -A topo15_004_0004_lev01_hillshade.tif --outfile=topo15_004_0004_hillshade_mask.tif --overwrite --type=Int16 --NoDataValue=0 --calc="1*(A<2)"

# misc
gdal_calc.py --overwrite -A topo15_down.tif --outfile dem.tif --NoDataValue=0 --calc="0*(A<0)" --calc="(A/A)*(A>=0)"
gdal_calc.py --overwrite -A temp.nc -B dem.tif --outfile temp_calc.tif --calc="trunc(A/${denominator})*(B==1)"
```

Make grid from points using VRT and gdal_grid.  
```shell
cat > metar.vrt <<- EOM
<OGRVRTDataSource>
  <OGRVRTLayer name='metar'>
    <SrcDataSource>metar.csv</SrcDataSource>
    <LayerSRS>EPSG:4326</LayerSRS>
    <GeometryType>wkbPoint</GeometryType>
    <GeometryField encoding="PointFromColumns" x="lon" y="lat"/>
    <ExtentXMin>-180</ExtentXMin>
    <ExtentYMin>-90</ExtentYMin>
    <ExtentXMax>180</ExtentXMax>
    <ExtentYMax>90</ExtentYMax>
  </OGRVRTLayer>
</OGRVRTDataSource>
EOM
gdal_grid -of netCDF -co WRITE_BOTTOMUP=NO -zfield "temp" -a invdist -txe -180 180 -tye -90 90 -outsize ${width} $(( width/2 )) -ot Float64 -l $(basename "${file%.*}") ${file%.*}.vrt temp.nc
```

## OGR

Print info from ogr package with *ogrinfo*.  
```shell

# list tables using *sqlite_master* or *sqlite_schema*
ogrinfo -dialect sqlite -sql 'SELECT tbl_name FROM sqlite_master' natural_earth_vector.gpkg
ogrinfo -dialect sqlite -sql 'SELECT tbl_name FROM sqlite_schema' natural_earth_vector.gpkg

# list tables with wildcard
ogrinfo -sql "SELECT tbl_name FROM sqlite_master WHERE name like 'ne_10m%'" natural_earth_vector.gpkg

# list tables prettily
ogrinfo -so natural_earth_vector.gpkg | grep '^[0-9]' | grep 'ne_110m' | sed -e 's/^.*: //g' -e 's/ .*$//g'

# list tables with certain geom type
ogrinfo -sql "SELECT name FROM sqlite_master WHERE name like 'ne_50m%'" natural_earth_vector.gpkg | grep '=' | sed -e 's/^.*= //g' | while read table; do geomtype=$(ogrinfo -sql "SELECT GeometryType(geom) FROM ${table};" natural_earth_vector.gpkg | grep '=' | sed 's/^.*= //g'); if [[ ${geomtype} =~ 'POLYGON' ]]; then echo ${table}; fi; done
```

Operations with *ogrinfo*
```shell
# some basics
ogrinfo db.sqlite -sql "VACUUM"
ogrinfo db.sqlite -sql "SELECT CreateSpatialIndex('the_table','GEOMETRY')"
ogrinfo poly_spatialite.sqlite -sql "drop table poly"
ogrinfo -dialect indirect_sqlite -sql "update line set geometry=ST_Simplify(geometry,1)" highway_EPSG4326_tertiary_simple.gpkg

# select from table
ogrinfo -sql 'SELECT AsSVG(geom,1) FROM ne_110m_admin_0_countries_lakes' natural_earth_vector.gpkg

# perform spatial operation and output into bash array
xy=($(ogrinfo naturalearth/packages/natural_earth_vector.gpkg -sql "SELECT round(ST_X(ST_Centroid(geom))), round(ST_Y(ST_Centroid(geom))) FROM ne_10m_admin_0_map_subunits WHERE name = '${name}'" | grep '=' | sed -e 's/^.*= //g')) natural_earth_vector.gpkg

# use in a loop
ogrinfo -so natural_earth_vector.gpkg | grep '^[0-9]' | grep 'ne_110m' | sed -e 's/^.*: //g' -e 's/ .*$//g' | while read layer; do count=$(ogrinfo -so  natural_earth_vector.gpkg ${layer} | grep 'Feature Count' | sed 's/^.* //g'); for (( a=1; a<=${count}; a=a+1 )); do gdal_rasterize -at -ts 180 90 -te -180 -90 180 90 -burn $[ ( $RANDOM % 255 ) + 1 ] -where "fid='${a}'" -l ${layer} natural_earth_vector.gpkg rasterize/${layer}_${a}.tif; done; done

# select extent
ogrinfo -so natural_earth_vector.gpkg ne_110m_land | grep '^Extent' | sed 's/Extent://g' | sed 's/[()]//g' | sed 's/ - /,/g' | sed 's/ //g'

# select extent with buffer
ogrinfo -so -sql "SELECT Extent(ST_Buffer(geom,${buffer})) FROM ${layer} WHERE name = '${name}'" natural_earth_vector.gpkg | grep 'Extent' | sed -e 's/Extent: //g' -e 's/(\|)//g' -e 's/ - /, /g' -e 's/, / /g'

# add xy columns
ogrinfo -update -sql 'ALTER TABLE lines ADD COLUMN x double; UPDATE lines SET x = ST_X(ST_Centroid(geom))' Bangkok.osm_gcp.gpkg
ogrinfo -update -sql 'ALTER TABLE lines ADD COLUMN y double; UPDATE lines SET y = ST_Y(ST_Centroid(geom))' Bangkok.osm_gcp.gpkg
```

Export with *ogrinfo*
```shell
ogrinfo --config SPATIALITE_SECURITY=relaxed -dialect Spatialite -sql "SELECT ExportGeoJSON2('ne_110m_admin_0_countries', 'geom', 'ne_110m_admin_o_countries.geojson')" natural_earth_vector.gpkg
```

Select vector layers processed from the Natural Earth geopackage.  
```shell
ogr2ogr -overwrite -f 'GPKG' -s_srs 'EPSG:4326' -t_srs 'EPSG:4326' countries.gpkg naturalearth/packages/ne_110m_admin_0_boundary_lines_land_coastline_split1.gpkg countries
```

Transform from lat-long to an orthographic projection, this time using *ogr2ogr* for vectors.  
```shell
file='countries.gpkg'
layer='countries'
name='Cairo'
xy=($(ogrinfo naturalearth/packages/natural_earth_vector.gpkg -sql "SELECT round(ST_X(ST_Centroid(geom))), round(ST_Y(ST_Centroid(geom))) FROM ne_10m_populated_places WHERE nameascii = '${name}'" | grep '=' | sed -e 's/^.*= //g'))
ogr2ogr -overwrite -skipfailures --config OGR_ENABLE_PARTIAL_REPROJECTION TRUE -s_srs 'EPSG:4326' -t_srs '+proj=ortho +lat_0="'${xy[1]}'" +lon_0="'${xy[0]}'" +ellps='sphere'' ${layer}_ortho_"${xy[0]}"_"${xy[1]}".gpkg ${file} ${layer}
```

Transform points for projected extent reference.  
```shell
rm -rf points1/*
for x in $(seq -180 10 -160); do
  for y in $(seq -90 10 -70); do
    proj='+proj=ortho +lat_0='"${y}"' +lon_0='"${x}"' +ellps=sphere'
    ogr2ogr -overwrite -skipfailures --config OGR_ENABLE_PARTIAL_REPROJECTION TRUE -s_srs 'epsg:4326' -t_srs "${proj}" -nln points1_${x}_${y} points1/points1_${x}_${y}.gpkg points1.gpkg points1
  done
done
```

Center the orthographic projection on the centroid of a country.  
```shell
file='countries.gpkg'
layer='countries'
name='Brazil'
xy=($(ogrinfo naturalearth/packages/natural_earth_vector.gpkg -sql "SELECT round(ST_X(ST_Centroid(geom))), round(ST_Y(ST_Centroid(geom))) FROM ne_110m_admin_0_countries WHERE name = '${name}'" | grep '=' | sed -e 's/^.*= //g'))
ogr2ogr -overwrite -skipfailures --config OGR_ENABLE_PARTIAL_REPROJECTION TRUE -s_srs 'EPSG:4326' -t_srs '+proj=ortho +lat_0="'${xy[1]}'" +lon_0="'${xy[0]}'" +ellps='sphere'' ${layer}_ortho_"${xy[0]}"_"${xy[1]}".gpkg ${file} ${layer}
```

Clip and reproject vector and raster data to the same extent.  
```shell
# make extent
name='North America'
extent=($(ogrinfo naturalearth/packages/natural_earth_vector.gpkg -sql "SELECT ROUND(ST_MinX(geom)), ROUND(ST_MinY(geom)), ROUND(ST_MaxX(geom)), ROUND(ST_MaxY(geom)), round(ST_X(ST_Centroid(geom))), round(ST_Y(ST_Centroid(geom))) FROM (SELECT ST_Union(geom) geom FROM ne_110m_admin_0_countries WHERE CONTINENT = '${name}')" | grep '=' | sed -e 's/^.*= //g'))
# clip hyp
gdalwarp -te_srs 'EPSG:4326' -te ${extent[0]} ${extent[1]} ${extent[2]} ${extent[3]} naturalearth/raster/HYP_HR_SR_OB_DR_5400_2700.tif /vsistdout/ | gdalwarp -overwrite -dstalpha -s_srs 'EPSG:4326' -t_srs '+proj=ortho +lat_0="'${extent[5]}'" +lon_0="'${extent[4]}'" +ellps='sphere'' /vsistdin/ hyp_${extent[0]}_${extent[1]}_${extent[2]}_${extent[3]}.tif
# clip topo
gdalwarp -te_srs 'EPSG:4326' -te ${extent[0]} ${extent[1]} ${extent[2]} ${extent[3]} srtm/topo15_4000.tif /vsistdout/ | gdalwarp -overwrite -dstalpha -s_srs 'EPSG:4326' -t_srs '+proj=ortho +lat_0="'${extent[5]}'" +lon_0="'${extent[4]}'" +ellps='sphere'' /vsistdin/ topo_${extent[0]}_${extent[1]}_${extent[2]}_${extent[3]}.tif
# clip vectors
ogr2ogr -overwrite -skipfailures --config OGR_ENABLE_PARTIAL_REPROJECTION TRUE -clipsrc ${extent[0]} ${extent[1]} ${extent[2]} ${extent[3]} -a_srs 'EPSG:4326' -t_srs '+proj=ortho +lat_0="'${extent[5]}'" +lon_0="'${extent[4]}'" +ellps='sphere'' subunits_${extent[0]}_${extent[1]}_${extent[2]}_${extent[3]}.gpkg naturalearth/packages/natural_earth_vector.gpkg ne_10m_admin_0_map_subunits
```

Convert layer to raster.  
```shell
gdal_rasterize PG:"dbname=osm" -l planet_osm_polygon -a levels -where "levels IS NOT NULL" -at /home/steve/Projects/maps/osm/${city}/${city}_buildings.tif
```

Export features to svg.  
```shell
file=natural_earth_vector.gpkg
layer=ne_50m_populated places
width=1920
height=960

ogrinfo -dialect sqlite -sql "SELECT ST_MinX(extent(geom)) || CAST(X'09' AS TEXT) || (-1 * ST_MaxY(extent(geom))) || CAST(X'09' AS TEXT) || (ST_MaxX(extent(geom)) - ST_MinX(extent(geom))) || CAST(X'09' AS TEXT) || (ST_MaxY(extent(geom)) - ST_MinY(extent(geom))) || CAST(X'09' AS TEXT) || GeometryType(geom) FROM '"${layer}"'" ${file} | grep -e '=' | sed -e 's/^.*://g' -e 's/^.* = //g' | while IFS=$'\t' read -a array; do
  echo '<svg xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" height="'${height}'" width="'${width}'" viewBox="'${array[0]}' '${array[1]}' '${array[2]}' '${array[3]}'">' > svg/${layer}.svg
  case ${array[4]} in
    POINT|MULTIPOINT)
      ogrinfo -dialect sqlite -sql "SELECT fid || CAST(X'09' AS TEXT) || ST_X(ST_Centroid(geom)) || CAST(X'09' AS TEXT) || (-1 * ST_Y(ST_Centroid(geom))) || CAST(X'09' AS TEXT) || REPLACE(name,'&','and') FROM ${layer} WHERE geom NOT LIKE '%null%'" ${file} | grep -e '=' | sed -e 's/^.*://g' -e 's/^.* = //g' | while IFS=$'\t' read -a array; do
        echo '<circle id="'${array[0]}'" cx="'${array[1]}'" cy="'${array[2]}'" r="1em" vector-effect="non-scaling-stroke" fill="#FFF" fill-opacity="1" stroke="#000" stroke-width="0.6px" stroke-linejoin="round" stroke-linecap="round"><title>'${array[2]}'</title></circle>' >> svg/${layer}.svg
      done
      ;;
    LINESTRING|MULTILINESTRING)
      ogrinfo -dialect sqlite -sql "SELECT fid || CAST(X'09' AS TEXT) || 'M ' || ST_X(StartPoint(geom)) || ' ' || (-1 * ST_Y(StartPoint(geom))) || 'L ' || ST_X(EndPoint(geom)) || ' ' || (-1 * ST_Y(EndPoint(geom))) || CAST(X'09' AS TEXT) || REPLACE(name,'&','and') FROM ${layer} WHERE geom NOT LIKE '%null%'" ${file} | grep -e '=' | sed -e 's/^.*://g' -e 's/^.* = //g' | while IFS=$'\t' read -a array; do
        echo '<path id="'${array[0]}'" d="'${array[1]}'" vector-effect="non-scaling-stroke" stroke="#000" stroke-width="0.6px" stroke-linejoin="round" stroke-linecap="round" fill="none"><title>'${array[2]}'</title></path>' >> svg/${layer}.svg
      done
      ;;
    POLYGON|MULTIPOLYGON)
      ogrinfo -dialect sqlite -sql "SELECT fid || CAST(X'09' AS TEXT) || AsSVG(geom, 1) || CAST(X'09' AS TEXT) || REPLACE(name,'&','and') FROM ${layer} WHERE geom NOT LIKE '%null%'" ${file} | grep -e '=' | sed -e 's/^.*://g' -e 's/^.* = //g' | while IFS=$'\t' read -a array; do
        echo '<path id="'${array[0]}'" d="'${array[1]}'" vector-effect="non-scaling-stroke" fill="#000" fill-opacity="1" stroke="#FFF" stroke-width="0.6px" stroke-linejoin="round" stroke-linecap="round"><title>'${array[2]}'</title></path>' >> svg/${layer}.svg
      done
      ;;
  esac
  echo '</svg>' >> svg/${layer}.svg
done
```

Convert all 50m polygon layers.  
```shell
ogrinfo -sql "SELECT name FROM sqlite_master WHERE name like 'ne_50m%'" natural_earth_vector.gpkg | grep '=' | sed -e 's/^.*= //g' | while read layer; do
  geomtype=$(ogrinfo -sql "SELECT GeometryType(geom) FROM ${layer};" natural_earth_vector.gpkg | grep '=' | sed 's/^.*= //g')
  if [[ ${geomtype} =~ 'POLYGON' ]]; then
    ogrinfo -dialect sqlite -sql "SELECT ST_MinX(extent(geom)) || CAST(X'09' AS TEXT) || (-1 * ST_MaxY(extent(geom))) || CAST(X'09' AS TEXT) || (ST_MaxX(extent(geom)) - ST_MinX(extent(geom))) || CAST(X'09' AS TEXT) || (ST_MaxY(extent(geom)) - ST_MinY(extent(geom))) FROM '"${layer}"'" natural_earth_vector.gpkg | grep -e '=' | sed -e 's/^.*://g' -e 's/^.* = //g' | while IFS=$'\t' read -a array; do
      echo '<svg xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" height="'${height}'" width="'${width}'" viewBox="'${array[0]}' '${array[1]}' '${array[2]}' '${array[3]}'">' > svg/${layer}.svg
      ogrinfo -dialect sqlite -sql "SELECT fid || CAST(X'09' AS TEXT) || ST_X(ST_Centroid(geom)) || CAST(X'09' AS TEXT) || (-1 * ST_Y(ST_Centroid(geom))) || CAST(X'09' AS TEXT) || AsSVG(geom, 1) || CAST(X'09' AS TEXT) || GeometryType(geom) FROM ${layer} WHERE geom NOT LIKE '%null%'" ${file} | grep -e '=' | sed -e 's/^.*://g' -e 's/^.* = //g' | while IFS=$'\t' read -a array; do
        echo '<path id="'${array[0]}'" d="'${array[3]}'" vector-effect="non-scaling-stroke" fill="#000" fill-opacity="1" stroke="#FFF" stroke-width="0.6px" stroke-linejoin="round" stroke-linecap="round"><title>'${array[0]}'</title></path>' >> svg/${layer}.svg
      done
    echo '</svg>' >> svg/${layer}.svg
    done
  fi
done
```

Merge layers.  
```shell
# use ogrmerge
ogrmerge.py -f VRT -o asean.vrt $(ls *.osm.pbf | tr '\n' ' ')

# use vrt with union
cat > ${file%.*}_contours.vrt <<- EOM
<OGRVRTDataSource>
  <OGRVRTUnionLayer name="contours">
    <OGRVRTLayer name='$(basename "${file%.*}_0m")'>
      <SrcDataSource>${file%.*}_0m.csv</SrcDataSource>
      <LayerSRS>EPSG:4326</LayerSRS>
      <GeometryType>wkbLineString</GeometryType>
      <GeometryField encoding="WKT" field="WKT"/>
      <Field name="elev" type="Integer"/>
    </OGRVRTLayer>
    <OGRVRTLayer name='$(basename "${file%.*}_1000m")'>
      <SrcDataSource>${file%.*}_1000m.csv</SrcDataSource>
      <LayerSRS>EPSG:4326</LayerSRS>
      <GeometryType>wkbLineString</GeometryType>
      <GeometryField encoding="WKT" field="WKT"/>
      <Field name="elev" type="Integer"/>
    </OGRVRTLayer>
  </OGRVRTUnionLayer>
</OGRVRTDataSource>
EOM
```

## SAGA-GIS

Misc  
```shell
saga_cmd --cores 1
```

Classify  
```shell
saga_cmd imagery_classification 1 -NCLUSTER 20 -MAXITER 0 -METHOD 1 -GRIDS N43W080_wgs84_500_5000.tif -CLUSTER N43W080_wgs84_500_5000_cluster.tif
```

Watershed  
```shell
saga_cmd imagery_segmentation 0 -OUTPUT 0 -DOWN 1 -JOIN 0 -THRESHOLD 0 -EDGE 1 -BBORDERS 0 -GRID N43W080_wgs84_500.tif -SEGMENTS N43W080_wgs84_500_segments.tif

saga_cmd ta_channels 5 -THRESHOLD 1 -DEM N43W080_wgs84_500.tif -SEGMENTS N43W080_wgs84_500_segments.shp -BASINS N43W080_wgs84_500_basins.shp
```

Raster to polygons  
```shell
saga_cmd shapes_grid 6 -GRID N43W080_wgs84.tif -POLYGONS N43W080_wgs84.shp
```

Raster values to vector  
```shell
saga_cmd shapes_grid 0

saga_cmd shapes_grid 1
```

Arrows  
```shell
saga_cmd shapes_grid 15 -SURFACE N43W080_wgs84_500.tif -VECTORS N43W080_wgs84_500_gradient.shp
```

Vector processing  
```shell
saga_cmd shapes_lines

saga_cmd shapes_points

saga_cmd shapes_polygons
```

Smoothing  
```shell
saga_cmd shapes_lines 7 -SENSITIVITY 3 -ITERATIONS 10 -PRESERVATION 10 -SIGMA 2 -LINES_IN N43W080_wgs84_500_segments.shp -LINES_OUT N43W080_wgs84_500_segments_smooth.shp
```

Landscape  
```shell
saga_cmd ta_compound 0 -THRESHOLD 1 -ELEVATION N43W080_wgs84_500.tif -SHADE N43W080_wgs84_500_shade.tif -CHANNELS N43W080_wgs84_500_channels.shp -BASINS N43W080_wgs84_500_basins.shp
```

Terrain  
```shell
saga_cmd ta_morphometry 16 -DEM N43W080_wgs84_500.tif -TRI N43W080_wgs84_500_tri.shp

saga_cmd ta_morphometry 17 -DEM N43W080_wgs84_500.tif -VRM N43W080_wgs84_500_vrm.tif

saga_cmd ta_morphometry 18 -DEM N43W080_wgs84_500.tif -TPI N43W080_wgs84_500_tpi.tif
```

TIN  
```shell
saga_cmd tin_tools 0 -GRID N48W092_N47W092_N48W091_N47W091_smooth.tif -TIN N48W092_N47W092_N48W091_N47W091_tin.shp

saga_cmd tin_tools 3 -TIN N48W092_N47W092_N48W091_N47W091_tin.shp -POLYGONS N48W092_N47W092_N48W091_N47W091_poly.shp
```

## Dataset Examples

### ALOS
```shell
# alos merge directory
dir=N005E095_N010E100
gdal_merge.py `ls ${dir}/*_DSM.tif` -o ${dir}.tif

# smooth
gdalwarp -s_srs 'EPSG:4326' -t_srs 'EPSG:4326' -ts $(echo $(gdalinfo ${dir}.tif | grep "Size is" | sed 's/Size is //g' | sed 's/,.*$//g')/10 | bc) 0 -r cubicspline ${dir}.tif /vsistdout/ | gdalwarp -overwrite -s_srs 'EPSG:4326' -t_srs 'EPSG:4326' -ts $(echo $(gdalinfo ${dir}.tif | grep "Size is" | sed 's/Size is //g' | sed 's/,.*$//g') | bc) 0 -r cubicspline /vsistdin/ ${dir}_smooth.tif

# contours
gdal_contour -a meters -i 10 ${dir}.tif ${dir}_contours.gpkg -nln contours
gdal_contour -p -amin amin -amax amax -i 10 ${dir}.tif ${dir}_contours_polygons.gpkg -nln contours

# hillshade
gdaldem hillshade -z 1 -az 315 -alt 45 ${dir}.tif ${dir}_hillshade.tif
gdal_calc.py --overwrite --NoDataValue=0 -A ${dir}_hillshade.tif --calc="1*(A<=2)" --out=${dir}_hillshade_mask.tif
gdal_polygonize.py ${dir}_hillshade_mask.tif ${dir}_hillshade_polygon.gpkg hillshade_polygon
```

### Natural Earth  

OGR/BASH scripts to work with Natural Earth vectors (download the data here: https://naciscdn.org/naturalearth/packages/natural_earth_vector.gpkg.zip)  
```shell
#==============# 
# earth-to-svg #
#==============#

### select layer to convert ###
layer=ne_110m_admin_0_countries
width=1920
height=960

### get extent and start file ###
ogrinfo -dialect sqlite -sql "SELECT ST_MinX(extent(geom)) || CAST(X'09' AS TEXT) || (-1 * ST_MaxY(extent(geom))) || CAST(X'09' AS TEXT) || (ST_MaxX(extent(geom)) - ST_MinX(extent(geom))) || CAST(X'09' AS TEXT) || (ST_MaxY(extent(geom)) - ST_MinY(extent(geom))) FROM '"${layer}"'" natural_earth_vector.gpkg | grep -e '=' | sed -e 's/^.*://g' -e 's/^.* = //g' | while IFS=$'\t' read -a array; do
echo '<svg xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" height="'${height}'" width="'${width}'" viewBox="'${array[0]}' '${array[1]}' '${array[2]}' '${array[3]}'">' > svg/${layer}.svg
done

### convert features ###
file=natural_earth_vector.gpkg
layer=ne_50m_populated places
width=1920
height=960

ogrinfo -dialect sqlite -sql "SELECT ST_MinX(extent(geom)) || CAST(X'09' AS TEXT) || (-1 * ST_MaxY(extent(geom))) || CAST(X'09' AS TEXT) || (ST_MaxX(extent(geom)) - ST_MinX(extent(geom))) || CAST(X'09' AS TEXT) || (ST_MaxY(extent(geom)) - ST_MinY(extent(geom))) || CAST(X'09' AS TEXT) || GeometryType(geom) FROM '"${layer}"'" ${file} | grep -e '=' | sed -e 's/^.*://g' -e 's/^.* = //g' | while IFS=$'\t' read -a array; do
  echo '<svg xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" height="'${height}'" width="'${width}'" viewBox="'${array[0]}' '${array[1]}' '${array[2]}' '${array[3]}'">' > svg/${layer}.svg
  case ${array[4]} in
    POINT|MULTIPOINT)
      ogrinfo -dialect sqlite -sql "SELECT fid || CAST(X'09' AS TEXT) || ST_X(ST_Centroid(geom)) || CAST(X'09' AS TEXT) || (-1 * ST_Y(ST_Centroid(geom))) || CAST(X'09' AS TEXT) || REPLACE(name,'&','and') FROM ${layer} WHERE geom NOT LIKE '%null%'" ${file} | grep -e '=' | sed -e 's/^.*://g' -e 's/^.* = //g' | while IFS=$'\t' read -a array; do
        echo '<circle id="'${array[0]}'" cx="'${array[1]}'" cy="'${array[2]}'" r="1em" vector-effect="non-scaling-stroke" fill="#FFF" fill-opacity="1" stroke="#000" stroke-width="0.6px" stroke-linejoin="round" stroke-linecap="round"><title>'${array[2]}'</title></circle>' >> svg/${layer}.svg
      done
      ;;
    LINESTRING|MULTILINESTRING)
      ogrinfo -dialect sqlite -sql "SELECT fid || CAST(X'09' AS TEXT) || 'M ' || ST_X(StartPoint(geom)) || ' ' || (-1 * ST_Y(StartPoint(geom))) || 'L ' || ST_X(EndPoint(geom)) || ' ' || (-1 * ST_Y(EndPoint(geom))) || CAST(X'09' AS TEXT) || REPLACE(name,'&','and') FROM ${layer} WHERE geom NOT LIKE '%null%'" ${file} | grep -e '=' | sed -e 's/^.*://g' -e 's/^.* = //g' | while IFS=$'\t' read -a array; do
        echo '<path id="'${array[0]}'" d="'${array[1]}'" vector-effect="non-scaling-stroke" stroke="#000" stroke-width="0.6px" stroke-linejoin="round" stroke-linecap="round" fill="none"><title>'${array[2]}'</title></path>' >> svg/${layer}.svg
      done
      ;;
    POLYGON|MULTIPOLYGON)
      ogrinfo -dialect sqlite -sql "SELECT fid || CAST(X'09' AS TEXT) || AsSVG(geom, 1) || CAST(X'09' AS TEXT) || REPLACE(name,'&','and') FROM ${layer} WHERE geom NOT LIKE '%null%'" ${file} | grep -e '=' | sed -e 's/^.*://g' -e 's/^.* = //g' | while IFS=$'\t' read -a array; do
        echo '<path id="'${array[0]}'" d="'${array[1]}'" vector-effect="non-scaling-stroke" fill="#000" fill-opacity="1" stroke="#FFF" stroke-width="0.6px" stroke-linejoin="round" stroke-linecap="round"><title>'${array[2]}'</title></path>' >> svg/${layer}.svg
      done
      ;;
  esac
  echo '</svg>' >> svg/${layer}.svg
done
```

```shell
#================# 
# earth-to-ortho #
#================#

# make ortho layers
file='grids/hex1_ne_50m_admin_0_countries_lakes.gpkg'
layer='hex1_ne_50m_admin_0_countries_lakes'
for x in $(seq -180 40 180); do
  for y in '-20'; do
    proj='+proj=ortho +lat_0='"${y}"' +lon_0='"${x}"' +ellps=sphere'
    ogr2ogr -overwrite -skipfailures --config OGR_ENABLE_PARTIAL_REPROJECTION TRUE -s_srs 'epsg:4326' -t_srs "${proj}" ${layer}_${x}_${y}.gpkg ${file} ${layer}
  done
done

# combine and make svg (graticules + boundary + coastline)
layer1='ne_50m_admin_0_boundary_lines_land_split1'
layer2='ne_50m_coastline_split1'
layer3='ne_10m_graticules_1_split1'
height=540
width=540
for x in $(seq -180 40 180); do
  for y in '-20'; do
    ogrinfo -dialect sqlite -sql "SELECT ST_MinX(extent(geom)) || CAST(X'09' AS TEXT) || (-1 * ST_MaxY(extent(geom))) || CAST(X'09' AS TEXT) || (ST_MaxX(extent(geom)) - ST_MinX(extent(geom))) || CAST(X'09' AS TEXT) || (ST_MaxY(extent(geom)) - ST_MinY(extent(geom))) FROM ${layer3}" ${layer3}_-100_-20.gpkg | grep -e '=' | sed -e 's/^.*://g' -e 's/^.* = //g' | while IFS=$'\t' read -a array; do
      echo '<svg xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" height="'${height}'" width="'${width}'" viewBox="'${array[0]}' '${array[1]}' '${array[2]}' '${array[3]}'">' > ${layer}_${x}_${y}.svg
      # layer 1
      ogrinfo -dialect sqlite -sql "SELECT fid || CAST(X'09' AS TEXT) || 'M ' || ST_X(StartPoint(geom)) || ' ' || (-1 * ST_Y(StartPoint(geom))) || 'L ' || ST_X(EndPoint(geom)) || ' ' || (-1 * ST_Y(EndPoint(geom))) FROM ${layer1} WHERE geom NOT LIKE '%null%'" ${layer1}_${x}_${y}.gpkg | grep -e '=' | sed -e 's/^.*://g' -e 's/^.* = //g' | while IFS=$'\t' read -a array; do
        echo '<path id="'${array[0]}'" d="'${array[1]}'" vector-effect="non-scaling-stroke" stroke="#000" stroke-width="0.6px" stroke-linejoin="round" stroke-linecap="round" fill="none"></path>' >> ${layer}_${x}_${y}.svg
      done
      # layer 2
      ogrinfo -dialect sqlite -sql "SELECT fid || CAST(X'09' AS TEXT) || 'M ' || ST_X(StartPoint(geom)) || ' ' || (-1 * ST_Y(StartPoint(geom))) || 'L ' || ST_X(EndPoint(geom)) || ' ' || (-1 * ST_Y(EndPoint(geom))) FROM ${layer2} WHERE geom NOT LIKE '%null%'" ${layer2}_${x}_${y}.gpkg | grep -e '=' | sed -e 's/^.*://g' -e 's/^.* = //g' | while IFS=$'\t' read -a array; do
        echo '<path id="'${array[0]}'" d="'${array[1]}'" vector-effect="non-scaling-stroke" stroke="#000" stroke-width="0.6px" stroke-linejoin="round" stroke-linecap="round" fill="none"></path>' >> ${layer}_${x}_${y}.svg
      done
      # layer 3
      ogrinfo -dialect sqlite -sql "SELECT fid || CAST(X'09' AS TEXT) || 'M ' || ST_X(StartPoint(geom)) || ' ' || (-1 * ST_Y(StartPoint(geom))) || 'L ' || ST_X(EndPoint(geom)) || ' ' || (-1 * ST_Y(EndPoint(geom))) FROM ${layer3} WHERE geom NOT LIKE '%null%' AND degrees LIKE '%0' OR degrees IN ('0')" ${layer3}_${x}_${y}.gpkg | grep -e '=' | sed -e 's/^.*://g' -e 's/^.* = //g' | while IFS=$'\t' read -a array; do
        echo '<path id="'${array[0]}'" d="'${array[1]}'" vector-effect="non-scaling-stroke" stroke="#000" stroke-width="0.2px" stroke-linejoin="round" stroke-linecap="round" fill="none"></path>' >> ${layer}_${x}_${y}.svg
      done
      echo '</svg>' >> ${layer}_${x}_${y}.svg
    done
  done
done

# combine and make svg (graticules + hex1)
layer1='hex1_ne_50m_admin_0_countries_lakes'
layer2='ne_10m_graticules_1_split1'
height=540
width=540
for x in $(seq -180 40 180); do
  for y in '-20'; do
    ogrinfo -dialect sqlite -sql "SELECT ST_MinX(extent(geom)) || CAST(X'09' AS TEXT) || (-1 * ST_MaxY(extent(geom))) || CAST(X'09' AS TEXT) || (ST_MaxX(extent(geom)) - ST_MinX(extent(geom))) || CAST(X'09' AS TEXT) || (ST_MaxY(extent(geom)) - ST_MinY(extent(geom))) FROM ${layer2}" ${layer2}_-100_-20.gpkg | grep -e '=' | sed -e 's/^.*://g' -e 's/^.* = //g' | while IFS=$'\t' read -a array; do
      echo '<svg xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" height="'${height}'" width="'${width}'" viewBox="'${array[0]}' '${array[1]}' '${array[2]}' '${array[3]}'">' > ${layer}_${x}_${y}.svg
      # layer 1
      ogrinfo -dialect sqlite -sql "SELECT fid || CAST(X'09' AS TEXT) || AsSVG(ST_Union(geom), 1) FROM ${layer1} WHERE geom NOT LIKE '%null%' GROUP BY ADM0_A3" ${layer1}_${x}_${y}.gpkg | grep -e '=' | sed -e 's/^.*://g' -e 's/^.* = //g' | while IFS=$'\t' read -a array; do
        echo '<path id="'${array[0]}'" d="'${array[1]}'" vector-effect="non-scaling-stroke" fill="#000" fill-opacity="1" stroke="#FFF" stroke-width="0" stroke-linejoin="round" stroke-linecap="round"><title>'${array[2]}'</title></path>' >>  ${layer}_${x}_${y}.svg
      done
      # layer 2
      ogrinfo -dialect sqlite -sql "SELECT fid || CAST(X'09' AS TEXT) || 'M ' || ST_X(StartPoint(geom)) || ' ' || (-1 * ST_Y(StartPoint(geom))) || 'L ' || ST_X(EndPoint(geom)) || ' ' || (-1 * ST_Y(EndPoint(geom))) FROM ${layer2} WHERE geom NOT LIKE '%null%' AND degrees LIKE '%0' OR degrees IN ('0')" ${layer2}_${x}_${y}.gpkg | grep -e '=' | sed -e 's/^.*://g' -e 's/^.* = //g' | while IFS=$'\t' read -a array; do
        echo '<path id="'${array[0]}'" d="'${array[1]}'" vector-effect="non-scaling-stroke" stroke="#000" stroke-width="0.2px" stroke-linejoin="round" stroke-linecap="round" fill="none"></path>' >> ${layer}_${x}_${y}.svg
      done
      echo '</svg>' >> ${layer}_${x}_${y}.svg
    done
  done
done
```

```shell
#===============# 
# earth-to-json #
#===============#

### select layer to convert ###
layer=ne_110m_admin_0_countries

### convert ###
ogr2ogr -f GeoJSON ${layer}.geojson natural_earth_vector.gpkg ${layer}
```

```shell
#=================# 
# earth-to-raster #
#=================#

# rasterize all
layer=ne_10m_roads
res=0.1
gdal_rasterize -at -tr ${res} ${res} -te -180 -90 180 90 -burn 1 -a_nodata NA -l ${layer} natural_earth_vector.gpkg rasterize/${layer}.tif

# rasterize and color features
layer=ne_10m_roads
rm rasterize/*
ogrinfo -so natural_earth_vector.gpkg | grep '^[0-9]' | grep 'ne_110m' | sed -e 's/^.*: //g' -e 's/ .*$//g' | while read layer; do count=$(ogrinfo -so  natural_earth_vector.gpkg ${layer} | grep 'Feature Count' | sed 's/^.* //g'); for (( a=1; a<=${count}; a=a+1 )); do gdal_rasterize -at -ts 180 90 -te -180 -90 180 90 -burn $[ ( $RANDOM % 255 ) + 1 ] -where "fid='${a}'" -l ${layer} natural_earth_vector.gpkg rasterize/${layer}_${a}.tif; done; done

gdal_create -ot Byte -if $(ls rasterize/*.tif | head -n 1) naturalearth_layers.tif

ls rasterize/*.tif | while read file; do
  convert -quiet naturalearth_layers.tif ${file} -gravity center -geometry +0+0 -compose Lighten -composite naturalearth_layers.tif
done
convert naturalearth_layers.tif naturalearth_layers.png
```

```shell
#===============# 
# earth-clipper #
#===============#

### select clipper ###
name='Thailand'
layer=ne_10m_admin_0_countries
proj='epsg:4326'

### clip layers at same scale & drop empty tables ###
rm -rf $(echo ${layer} | awk -F  "_" '{print $1"_"$2}')_${name// /_}.gpkg
ogrinfo -dialect sqlite -sql "SELECT name FROM sqlite_master WHERE name LIKE '$(echo ${layer} | awk -F  "_" '{print $1"_"$2}')%'" natural_earth_vector.gpkg | grep ' = ' | sed -e 's/^.* = //g' | while read table; do
  ogr2ogr -update -append -skipfailures --config OGR_ENABLE_PARTIAL_REPROJECTION TRUE -nlt promote_to_multi -s_srs 'epsg:4326' -t_srs ${proj} -clipsrc 'natural_earth_vector.gpkg' -clipsrclayer ${layer} -clipsrcwhere "name = '${name}'" $(echo ${layer} | awk -F  "_" '{print $1"_"$2}')_${name// /_}.gpkg natural_earth_vector.gpkg ${table}
  # drop empty tables
  case `ogrinfo -so $(echo ${layer} | awk -F  "_" '{print $1"_"$2}')_${name// /_}.gpkg ${table} | grep 'Feature Count' | sed -e 's/^.*: //g'` in
    0)
      ogrinfo -dialect sqlite -sql "DROP TABLE ${table}" $(echo ${layer} | awk -F  "_" '{print $1"_"$2}')_${name// /_}.gpkg
      ;;
	*)
      echo 'DONE'
      ;;
  esac
done
```

```shell
#================# 
# earth-contours #
#================#

### select clipper ###
name='Thailand'
layer=ne_10m_admin_0_map_subunits
dem='srtm/topo15.grd'
factor=100
interval=100

### clip raster with buffer & make contours ###
gdalwarp -s_srs 'EPSG:4326' -t_srs 'EPSG:4326' -tr 0.04 0.04 -r cubicspline -crop_to_cutline -cutline 'naturalearth/packages/natural_earth_vector.gpkg' -csql "SELECT geom FROM ${layer} WHERE name = '${name}'" ${dem} /vsistdout/ | gdalwarp -overwrite -s_srs 'EPSG:4326' -t_srs 'EPSG:4326' -tr 0.004 0.004 -r cubicspline /vsistdin/ /vsistdout/ | gdal_contour -p -amin amin -amax amax -i ${interval} /vsistdin/ top15_${name// /_}_${interval}m.gpkg

### clip contours ###
ogr2ogr -append -update -makevalid -s_srs 'EPSG:4326' -t_srs 'EPSG:3857' -clipsrc 'naturalearth/packages/natural_earth_vector.gpkg' -clipsrclayer ${layer} -clipsrcwhere "name = '${name}'" -nlt MULTIPOLYGON -nln contour_clip top15_${name// /_}_${interval}m.gpkg top15_${name// /_}_${interval}m.gpkg contour
```

## Misc

```shell
# find disk usage
du -h --max-depth=1 /home/steve/maps | sort -h
```
