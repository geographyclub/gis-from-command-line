# GIS FROM COMMAND LINE

All the software and scripts you need to make Linux a complete *Geographic Information System* from command line.

## TABLE OF CONTENTS

### Sections
1. [GDAL](#GDAL)  
2. [OGR](#OGR)  
3. [SAGA-GIS](#saga-gis)   
4. [Dataset examples](#dataset-examples)  
5. [Misc](#misc)  
### Github Repos
1. [GRASS Scripts⤴](https://github.com/geographyclub/grass-scripts)  
2. [PostGIS Cookbook⤴](https://github.com/geographyclub/postgis-cookbook)  
3. [American Geography⤴](https://github.com/geographyclub/american-geography) 
4. [ImageMagick for Mapmakers⤴](https://github.com/geographyclub/imagemagick-for-mapmakers)  
5. [Weather to Video⤴](https://github.com/geographyclub/weather-to-video)   
### Extras
1. [QGIS Expressions⤴](https://github.com/geographyclub/qgis-expressions)  

## GDAL

Print histogram and other info.  
```shell
gdalinfo -hist ${file} | grep -A1 'buckets from' | tail -1
```

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

Georeference by ground control points  
```shell
gdal_translate -gcp 0 0 -180 -90 -gcp 1024 512 180 90 -gcp 0 512 -180 90 -gcp 1024 0 180 -90 HYP_HR_SR_OB_DR_1024_512.png HYP_HR_SR_OB_DR_1024_512_georeferenced.tif

# raster-to-globe
file=chicago.tif
extent=($(gdalinfo ${file} | grep -E '^Lower Left|^Upper Right' | sed -e 's/Upper Left  (//g' -e 's/Lower Left  (//g' -e 's/Upper Right (//g' -e 's/Lower Right (//g' -e 's/) (.*$//g' -e 's/,//g'))
x_min=-180
x_max=180
y_min=0
y_max=90

gdal_translate -gcp ${extent[0]} ${extent[1]} ${x_min} ${y_min} -gcp ${extent[0]} ${extent[3]} ${x_min} ${y_max} -gcp ${extent[2]} ${extent[3]} ${x_max} ${y_max} -gcp ${extent[2]} ${extent[1]} ${x_max} ${y_min} ${file} ${file%.*}_${x_min}_${x_max}_${y_min}_${y_max}.tif
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

Make contours from dem  
```shell
# lines
file=/home/steve/maps/srtm/topo15.grd
gdal_contour --config GDAL_CACHEMAX 500 -lco GEOMETRY=AS_WKT -f "CSV" -a elev -fl 500 ${file}
gdal_contour --config GDAL_CACHEMAX 500 -f "GPKG" -a meters -i 100 /home/steve/maps/srtm/topo15_4000_40000.tif /home/steve/maps/srtm/topo15_4000_40000_100m.gpkg
gdal_contour --config GDAL_CACHEMAX 500 -f "PostgreSQL" -a elev -i 10 ${file} PG:dbname=world topo15_4000_40000_10m

# polygons
gdal_contour -p -f "GPKG" -amin amin -amax amax -i 100 topo15_4320_ocean.tif topo15_4320_ocean_100m_polygon.gpkg

ogr2ogr -overwrite -f "SQLite" -dsco SPATIALITE=YES -lco OVERWRITE=YES -dialect sqlite -sql "SELECT elev, ST_MakePolygon(GEOMETRY) FROM topo15_43200 WHERE elev IN (-10000,-9000,-8000,-7000,-6000,-5000,-4000,-3000,-2000,-1000,-900,-800,-700,-600,-500,-400,-300,-200,-100,0,100,200,300,400,500,600,700,800,900,1000,1500,2000,2500,3000,3500,4000,4500,5000,5500,6000,6500,7000,7500,8000);" /home/steve/maps/srtm/srtm15/topo15_43200_polygon.sqlite -t_srs "EPSG:4326" -nlt POLYGON -nln topo15_43200_polygon -explodecollections /home/steve/maps/srtm/srtm15/topo15_43200.sqlite

# values
ogr2ogr -f 'GPKG' -dim XYM -zfield 'CATCH_SKM' /home/steve/maps/wwf/hydroatlas/RiverATLAS_v10_xym.gpkg /home/steve/maps/wwf/hydroatlas/RiverATLAS_v10.gdb RiverATLAS_v10
```

Make terrain from dem  
```shell
gdaldem aspect -compute_edges /home/steve/maps/srtm/topo15_1000_10000.tif /home/steve/maps/srtm/topo15_1000_10000_aspect.tif

gdaldem slope -compute_edges -s 111120 /home/steve/maps/srtm/topo15_43200.tif /home/steve/maps/srtm/topo15_43200_tmp.tif

gdaldem roughness -compute_edges /home/steve/Projects/maps/srtm/N43W080_wgs84.tif /home/steve/maps/srtm/N43W080_wgs84_roughness.tif

gdaldem TRI -compute_edges /home/steve/Projects/maps/dem/srtm/N43W080_wgs84.tif /home/steve/Projects/maps/dem/srtm/N43W080_wgs84_tri.tif

gdaldem TPI -compute_edges /home/steve/Projects/maps/dem/srtm/N43W080_wgs84.tif /home/steve/Projects/maps/dem/srtm/N43W080_wgs84_tpi.tif

gdaldem color-relief -alpha -f 'GRIB' -of 'GTiff' tcdc.tif "white-black.txt" /vsistdout/ | gdalwarp -overwrite -dstalpha -f 'GTiff' -of 'GTiff' -s_srs 'EPSG:4326' -t_srs 'EPSG:3857' -ts 500 250 /vsistdin/ tcdc_color.tif
```

Loop terrain rasters    
```shell
zfactor=100
azimuth=315
altitude=45
gdaldem hillshade -combined -z ${zfactor} -s 111120 -az ${azimuth} -alt ${altitude} -compute_edges topo.tif topo_hillshade.tif

# loop zfactor
rm -f topo15_4320_hillshade_zfactor*
for a in $(seq 1 100 1000); do
  zfactor=${a}
  azimuth=315
  altitude=45
  gdaldem hillshade -combined -z ${zfactor} -s 111120 -az ${azimuth} -alt ${altitude} -compute_edges topo15_4320.tif topo15_4320_hillshade_zfactor${zfactor}.tif
done

# loop azimuth
rm -f topo15_4320_hillshade_azimuth*
for a in $(seq 0 10 350); do
  zfactor=1000
  azimuth=${a}
  altitude=10
  gdaldem hillshade -combined -z ${zfactor} -s 111120 -az ${azimuth} -alt ${altitude} -compute_edges topo15_4320.tif topo15_4320_hillshade_azimuth${a}.tif
done
```

Polygonize raster
```shell
# hillshade mask
gdaldem hillshade -z 1 -az 315 -alt 45 topo15_4320.tif topo15_4320_hillshade.tif
gdal_calc.py --overwrite --NoDataValue=0 -A topo15_4320_hillshade.tif --calc="A*(A<=1)" --out=topo15_4320_hillshade_mask.tif
gdal_polygonize.py topo15_4320_hillshade_mask.tif topo15_4320_hillshade_mask.gpkg hillshade_mask

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

Sample weather grid at places using *gdallocationinfo*  
```shell
echo "scalerank,name,lat,lon,rownum,temp" > ${file%.*}_places.csv
cat /home/steve/Projects/maps/places.csv | while read line; do
  coord=`echo "$line" | awk -F '\t' '{print $23,$22}'`
  temp=`gdallocationinfo -wgs84 -valonly ${file%.*}.tif $coord`
  echo -e "$line""\t""$temp" | awk -F '\t' '{print $1,$9,$22,$23,$38,$39}' OFS=',' >> ${file%.*}_places.csv
done
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

Transform from lat-long to an orthographic projection, this time using *ogr2ogr* for vectors  
```shell
file='countries.gpkg'
layer='countries'
name='Cairo'
xy=($(ogrinfo naturalearth/packages/natural_earth_vector.gpkg -sql "SELECT round(ST_X(ST_Centroid(geom))), round(ST_Y(ST_Centroid(geom))) FROM ne_10m_populated_places WHERE nameascii = '${name}'" | grep '=' | sed -e 's/^.*= //g'))
ogr2ogr -overwrite -skipfailures --config OGR_ENABLE_PARTIAL_REPROJECTION TRUE -s_srs 'EPSG:4326' -t_srs '+proj=ortho +lat_0="'${xy[1]}'" +lon_0="'${xy[0]}'" +ellps='sphere'' ${layer}_ortho_"${xy[0]}"_"${xy[1]}".gpkg ${file} ${layer}
```

Transform to ortho  
```shell
rm -rf points1/*
for x in $(seq -180 10 -160); do
  for y in $(seq -90 10 -70); do
    proj='+proj=ortho +lat_0='"${y}"' +lon_0='"${x}"' +ellps=sphere'
    ogr2ogr -overwrite -skipfailures --config OGR_ENABLE_PARTIAL_REPROJECTION TRUE -s_srs 'epsg:4326' -t_srs "${proj}" -nln points1_${x}_${y} points1/points1_${x}_${y}.gpkg points1.gpkg points1
  done
done
```

Center the orthographic projection on the centroid of a country  
```shell
file='countries.gpkg'
layer='countries'
name='Brazil'
xy=($(ogrinfo naturalearth/packages/natural_earth_vector.gpkg -sql "SELECT round(ST_X(ST_Centroid(geom))), round(ST_Y(ST_Centroid(geom))) FROM ne_110m_admin_0_countries WHERE name = '${name}'" | grep '=' | sed -e 's/^.*= //g'))
ogr2ogr -overwrite -skipfailures --config OGR_ENABLE_PARTIAL_REPROJECTION TRUE -s_srs 'EPSG:4326' -t_srs '+proj=ortho +lat_0="'${xy[1]}'" +lon_0="'${xy[0]}'" +ellps='sphere'' ${layer}_ortho_"${xy[0]}"_"${xy[1]}".gpkg ${file} ${layer}
```

Clip and reproject vector and raster data to the same extent  
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

Reproject with gcp  
```bash
file=Chicago.osm.pbf
layer=lines
extent=($(ogrinfo -so ${file} ${layer} | grep 'Extent' | sed -e 's/Extent: //g' -e 's/(\|)//g' -e 's/ - /, /g' -e 's/, / /g'))
x_min=-45
x_max=45
y_min=0
y_max=90
ogr2ogr -overwrite -gcp ${extent[0]} ${extent[1]} ${x_min} ${y_min} -gcp ${extent[0]} ${extent[3]} ${x_min} ${y_max} -gcp ${extent[2]} ${extent[3]} ${x_max} ${y_max} -gcp ${extent[2]} ${extent[1]} ${x_max} ${y_min} ${file%.osm.pbf}_${x_min}_${x_max}_${y_min}_${y_max}.gpkg ${file}
```

Rasterize vector  
```shell
gdal_rasterize PG:"dbname=osm" -l planet_osm_polygon -a levels -where "levels IS NOT NULL" -at /home/steve/Projects/maps/osm/${city}/${city}_buildings.tif

# give pixel size
gdal_rasterize -tr 1 1 -ts 1024 512 -a_nodata 0 -burn 1 -l ne_10m_land natural_earth_vector.gpkg ne_10m_land.tif

# burn examples
gdal_rasterize -at -add -burn -100 -where "highway IN ('motorway','trunk','primary')" PG:"dbname=osm" -l ${layer} ${file%.*}_360_3600_epsg3857_highways.tif

gdal_rasterize -at -add -burn -1 -sql "SELECT ST_Buffer(wkb_geometry,100) FROM ${layer} WHERE highway IN ('motorway','trunk','primary')" PG:"dbname=osm" ${file%.*}_360_3600_epsg3857_highways.tif
```

Use rasterize to grid features  
```shell
gdal_rasterize -at -tr 0.01 0.01 -l ACS_2019_5YR_TRACT ACS_2019_5YR_TRACT.gdb -a GEOID -a_nodata NA ACS_2019_5YR_TRACT_001.tif
gdal_polygonize.py -8 -f "GPKG" ACS_2019_5YR_TRACT_001.tif ACS_2019_5YR_TRACT_001.gpkg ACS_2019_5YR_TRACT_001 GEOID
```

Export features to svg  
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

# contour levels
gdal_contour -p -amin amin -amax amax -fl 100 topo15_4320_43200.tif topo15_4320_43200_polygons.gpkg

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
#==================# 
# earth-to-geojson #
#==================#

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
name="${name// /_}"
name="${name//./}"
rm -rf $(echo ${layer} | awk -F  "_" '{print $1"_"$2}')_${name}.gpkg
ogrinfo -dialect sqlite -sql "SELECT name FROM sqlite_master WHERE name LIKE '$(echo ${layer} | awk -F  "_" '{print $1"_"$2}')%'" natural_earth_vector.gpkg | grep ' = ' | sed -e 's/^.* = //g' | while read table; do
  ogr2ogr -update -append -skipfailures --config OGR_ENABLE_PARTIAL_REPROJECTION TRUE -nlt promote_to_multi -s_srs 'epsg:4326' -t_srs ${proj} -clipsrc 'natural_earth_vector.gpkg' -clipsrclayer ${layer} -clipsrcwhere "name = '${name}'" $(echo ${layer} | awk -F  "_" '{print $1"_"$2}')_${name}.gpkg natural_earth_vector.gpkg ${table}
  # drop empty tables
  case `ogrinfo -so $(echo ${layer} | awk -F  "_" '{print $1"_"$2}')_${name}.gpkg ${table} | grep 'Feature Count' | sed -e 's/^.*: //g'` in
    0)
      ogrinfo -dialect sqlite -sql "DROP TABLE ${table}" $(echo ${layer} | awk -F  "_" '{print $1"_"$2}')_${name}.gpkg
      ;;
	*)
      echo 'DONE'
      ;;
  esac
done

#===================# 
# earth-clipper-all #
#===================#

ogrinfo -sql 'SELECT name FROM ne_10m_admin_0_countries' natural_earth_vector.gpkg | grep 'NAME (String) = ' | sed -e 's/^.*= //g' | while read name; do
  filename="${name// /_}"
  filename="${filename//./}"
  filename=$(echo "${filename}" | tr '[:upper:]' '[:lower:]')
  rm -rf $(echo ${layer} | awk -F  "_" '{print $1"_"$2}')_${filename}.gpkg
  ogrinfo -dialect sqlite -sql "SELECT name FROM sqlite_master WHERE name LIKE 'ne_10m%'" natural_earth_vector.gpkg | grep ' = ' | sed -e 's/^.* = //g' | while read table; do
    ogr2ogr -update -append -skipfailures --config OGR_ENABLE_PARTIAL_REPROJECTION TRUE -nlt promote_to_multi -s_srs 'epsg:4326' -t_srs 'epsg:4326' -clipsrc 'natural_earth_vector.gpkg' -clipsrclayer ne_10m_admin_0_countries -clipsrcwhere "name = '${name}'" ${filename}.gpkg natural_earth_vector.gpkg ${table}
    # drop empty tables
    case `ogrinfo -so ${filename}.gpkg ${table} | grep 'Feature Count' | sed -e 's/^.*: //g'` in
      0)
        ogrinfo -dialect sqlite -sql "DROP TABLE ${table}" ${filename}.gpkg
        ;;
	  *)
        echo 'DONE'
        ;;
    esac
  done
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

```shell
#=====================# 
# earth-georeferencer #
#=====================#

file=natural_earth_vector.gpkg
extent=(-180 -90 180 90)
x_min=-180
x_max=180
y_min=-30
y_max=30
ogr2ogr -overwrite -gcp ${extent[0]} ${extent[1]} ${x_min} ${y_min} -gcp ${extent[0]} ${extent[3]} ${x_min} ${y_max} -gcp ${extent[2]} ${extent[3]} ${x_max} ${y_max} -gcp ${extent[2]} ${extent[1]} ${x_max} ${y_min} misc/${file%.}_${x_min}_${x_max}_${y_min}_${y_max}.gpkg ${file}
```

### OpenStreetMap

```shell
# osm data online
wget -O muenchen.osm "https://api.openstreetmap.org/api/0.6/map?bbox=11.54,48.14,11.543,48.145"

# osm poly from ogr
/home/steve/maps/ogr2poly.py -f "name" /home/steve/Downloads/ne_10m_admin_0_countries_CONTINENT_Europe.shp

# osm2pgsql
osm2pgsql --create --cache 800 --disable-parallel-indexing --unlogged --flat-nodes /home/steve/maps/osm/node.cache --slim --drop --hstore --hstore-match-only --latlong --proj 4326 --keep-coastlines -U steve -d osm /home/steve/maps/osm/planet.osm.pbf
```

Osmium  
```shell
# extent
file="/home/steve/Projects/maps/dem/srtm/N45W073_wgs84.tif"
osmium extract --overwrite -b `echo $(gdalinfo ${file} | grep "Lower Left" | sed 's/Lower Left *( //g' | sed 's/,  /,/g' | sed 's/).*$//g')$(gdalinfo ${file} | grep "Upper Right" | sed 's/Upper Right *( /,/g' | sed 's/,  /,/g' | sed 's/).*$//g')` /home/steve/Projects/maps/osm/north-america-latest.osm.pbf -o ${file%.*}.pbf
osmium extract --overwrite -b `echo $(ogrinfo -so /media/steve/thumby/superior_extent.sqlite superior_extent | grep '^Extent' | sed 's/Extent://g' | sed 's/[()]//g' | ogrinfo -so /media/steve/thumby/superior_extent.sqlite superior_extent | grep '^Extent' | sed 's/Extent://g' | sed 's/[()]//g' | sed 's/ - /,/g' | sed 's/ //g')` /home/steve/Projects/maps/osm/north-america-latest.osm.pbf -o /home/steve/Projects/maps/osm/superior.osm.pbf
# poly
osmium extract --overwrite -p /home/steve/maps/osm/poly/toronto.poly /home/steve/maps/osm/north-america-latest.osm.pbf -o /home/steve/maps/osm/toronto/toronto.pbf
# tags --omit-referenced /highway=primary w/highway /name=*Amazon /name,name:de=Kastanienallee,Kastanienstrasse a/building r/boundary n/amenity r/natural /note
osmium tags-filter --fsync --progress -O -o /home/steve/maps/osm/europe_highway.osm.pbf /home/steve/maps/osm/europe-latest.osm.pbf w/highway=primary
# export to pg
osmium export -O --verbose --progress --fsync --add-unique-id=type_id --geometry-types="linestring" -f pg -o /home/steve/maps/osm/planet_line.pg /home/steve/maps/osm/planet-latest.osm.pbf
CREATE TABLE planet_line(id VARCHAR PRIMARY KEY, geom GEOMETRY, tags JSONB);
\COPY planet_line FROM '/home/steve/maps/osm/planet_line.pg'

# merge
osmium cat `ls /home/steve/maps/osm/city/*.pbf | tr '\n' ' '` -o /home/steve/maps/osm/city.osm.pbf
```

osmconvert/osmfilter  
```shell
# list tags
osmfilter /home/steve/maps/osm/highway_primary.o5m --out-count | head
# convert
osmconvert /home/steve/maps/osm/planet_ways.o5m --out-pbf >/home/steve/maps/osm/planet_ways.osm.pbf
# filter (--ignore-dependencies)
osmfilter /home/steve/maps/osm/planet-latest.o5m --keep= --keep-ways="highway=" --out-o5m >/home/steve/maps/osm/planet_highway.o5m
```

### SRTM

Download  
```shell
wget --user --password http://e4ftl01.cr.usgs.gov/MEASURES/SRTMGL1.003/2000.02.11/N44W080.SRTMGL1.hgt.zip
```

Extract ocean and make positive for watershed analysis  
```shell
gdal_calc.py --overwrite --NoDataValue=0 -A topo15_4320.tif --outfile=topo15_4320_ocean.tif --calc="(A + 10207.5)*(A<=100)"
```

### StatsCan

Import  
```shell
ogr2ogr -overwrite -nlt promote_to_multi pg:dbname=canada lda_000b21a_e.shp
psql -d canada -c "CREATE TABLE census_profile_ontario_2021 (CENSUS_YEAR VARCHAR,DGUID VARCHAR,ALT_GEO_CODE VARCHAR,GEO_LEVEL VARCHAR,GEO_NAME VARCHAR,TNR_SF VARCHAR,TNR_LF VARCHAR,DATA_QUALITY_FLAG VARCHAR,CHARACTERISTIC_ID VARCHAR,CHARACTERISTIC_NAME VARCHAR,CHARACTERISTIC_NOTE VARCHAR,C1_COUNT_TOTAL VARCHAR,SYMBOL VARCHAR,C2_COUNT_MEN VARCHAR,SYMBOL VARCHAR,C3_COUNT_WOMEN VARCHAR,SYMBOL VARCHAR,C10_RATE_TOTAL VARCHAR,SYMBOL VARCHAR,C11_RATE_MEN VARCHAR,SYMBOL VARCHAR,C12_RATE_WOMEN VARCHAR,SYMBOL VARCHAR)"
```

### Wikipedia/Wikidata

Import
```shell
# wikitables
# convert wikipedia tables
./.local/bin/wikitables 'List_of_terrestrial_ecoregions_(WWF)' > /home/steve/wikipedia/tables/table_wwf_ecoregions.json
# split master list
cat /home/steve/wikipedia/lists_master.csv | grep -i "mountains" | csvcut --columns=2 | tr -d '"' > /home/steve/wikipedia/lists_mountains.csv
```

Wikipedia api  
```shell
# by coordinate (gscoord, gspage, gsbbox)
https://en.wikipedia.org/w/api.php?action=query&format=json&list=geosearch&gscoord=40.418670|-3.699389&gsradius=10000&gslimit=100
# by title
https://en.wikipedia.org/w/api.php?action=query&format=json&prop=coordinates|description|extracts&exintro=&explaintext=&titles=Amazon River
# search
https://en.wikipedia.org/w/api.php?action=query&list=search&srsearch=rocky mountains
# generator
https://en.wikipedia.org/w/api.php?format=json&action=query&generator=categorymembers&gcmcontinue=&gcmlimit=max&gcmtype=subcat&gcmtitle=Category:Terrestrial%20ecoregions

# P1082 population
curl 'https://www.wikidata.org/w/api.php?action=wbgetentities&sites=enwiki&format=json&fprops=claims&titles=Flatbush,_Brooklyn'

# example extract and mapdata (from wikipedia titles)
hood='Flatbush,_Brooklyn'
url=$(curl 'https://en.wikipedia.org/w/api.php?action=query&format=json&prop=extracts|mapdata&exchars=200&exlimit=max&explaintext&exintro&titles='${hood} | jq '..|.mapdata?' | grep '.map' | sed -e 's/^.*w\/api/https\:\/\/en\.wikipedia\.org\/w\/api/g' -e 's/\.map.*$/\.map/g')
curl -q ${url} | jq '.jsondata.data' > ${hood}.geojson
```

SPARQL  
```shell
# list all info
SELECT ?predicate ?object
WHERE
{
  wd:Q1339 ?predicate ?object. # Bach
}
# list all for predicate
SELECT ?subject ?subjectLabel ?object
WHERE
{
  ?subject wdt:P238 ?object.         # IATA airport code
  SERVICE wikibase:label { bd:serviceParam wikibase:language "en". }
}
ORDER BY ?object

# sitelinks
SELECT DISTINCT ?wiki ?label ?url ?geom WHERE {
  VALUES (?link_from) {(<https://en.wikipedia.org/wiki/List_of_terrestrial_ecoregions_(WWF)>)}
  ?link_from schema:name ?title .
  SERVICE wikibase:mwapi {
    bd:serviceParam wikibase:endpoint "en.wikipedia.org" ;
                      wikibase:api "Generator" ;
                      mwapi:generator "links" ;
                      mwapi:titles ?title ;
                      mwapi:inprop "url" ;
                      mwapi:redirects "true" .
    ?url wikibase:apiOutputURI "@fullurl" .
    ?wiki wikibase:apiOutputItem mwapi:item .
    ?label wikibase:apiOutput mwapi:title .
  }
FILTER (bound(?wiki))
OPTIONAL {?wiki wdt:P625 ?geom}
}

# pages
SELECT ?pageid WHERE {
    VALUES (?item) {(wd:Q123)}
    [ schema:about ?item ; schema:name ?name ;
      schema:isPartOf <https://en.wikipedia.org/> ]
     SERVICE wikibase:mwapi {
         bd:serviceParam wikibase:endpoint "en.wikipedia.org" .
         bd:serviceParam wikibase:api "Generator" .
         bd:serviceParam mwapi:generator "allpages" .
         bd:serviceParam mwapi:gapfrom ?name .
         bd:serviceParam mwapi:gapto ?name .
         ?pageid wikibase:apiOutput "@pageid" .
    }
}

# search for cheese
SELECT * WHERE {
  SERVICE wikibase:mwapi {
      bd:serviceParam wikibase:api "Search" .
      bd:serviceParam wikibase:endpoint "en.wikipedia.org" .
      bd:serviceParam mwapi:srsearch "cheese" .
      ?title wikibase:apiOutput mwapi:title .
  }
}

# places with coordinates
SELECT ?wiki (SAMPLE(?title) AS ?title) (SAMPLE(?geom) AS ?geom) WHERE {
  ?wiki wdt:P31/wdt:P279* wd:Q46831.
  ?wiki wdt:P625 ?geom.
  ?article schema:about ?wiki; schema:inLanguage ?lang; schema:name ?title.
  FILTER(?lang in ('en')) .
  FILTER(!CONTAINS(?title, ':'))
}
GROUP BY ?wiki

# mountains w elevation + image
SELECT DISTINCT ?subj ?label ?coord ?elev ?img
WHERE
{
	?subj wdt:P2044 ?elev	filter(?elev > 6000) .
    ?subj wdt:P625 ?coord .
    ?subj wdt:P18 ?img
	SERVICE wikibase:label { bd:serviceParam wikibase:language "en" . ?subj rdfs:label ?label }
}
ORDER BY DESC(?elev)

# Longest rivers in the USA
SELECT ?item ?itemLabel ?length2 ?unitLabel ?length_in_m 
WHERE
{
  ?item  wdt:P31/wdt:P279* wd:Q4022.    # rivers
  ?item  wdt:P17           wd:Q30.      # country USA
  ?item  p:P2043/psv:P2043 [            # length
     wikibase:quantityAmount     ?length;
     wikibase:quantityUnit       ?unit;
     wikibase:quantityLowerBound ?lowerbound;
     wikibase:quantityUpperBound ?upperbound;
  ]
  BIND((?upperbound-?lowerbound)/2 AS ?precision).
  BIND(IF(?precision=0, ?length, (CONCAT(str(?length), "±", str(?precision)))) AS ?length2). 

  # conversion to SI unit
  ?unit p:P2370/psv:P2370 [                # conversion to SI unit
     wikibase:quantityAmount ?conversion;
     wikibase:quantityUnit wd:Q11573;      # meter
  ]
  BIND(?length * ?conversion AS ?length_in_m).
  
  SERVICE wikibase:label { bd:serviceParam wikibase:language "en". }
} 
ORDER BY DESC(?length_in_m)
LIMIT 10

# rank by sitelinks
SELECT ?director ?director_label ?films ?sitelinks ((?films * ?sitelinks) as ?rank)
WHERE {
  {SELECT ?director (count(distinct ?film) as ?films) (count(distinct ?sitelink) as ?sitelinks)
     WHERE { 
       ?director wdt:P106 wd:Q2526255 .  				# has "film director" as occupation
	   ?film wdt:P57 ?director . 	 					# get all films directed by the director
       ?sitelink schema:about ?director .				# get all the sitelinks about the director
       } GROUP BY ?director }
SERVICE wikibase:label { 
  bd:serviceParam wikibase:language "[AUTO_LANGUAGE],en".  # Get label if it exists
?director rdfs:label ?director_label } 	
} ORDER BY DESC(?rank)
LIMIT 100

# rank by sitelinks (ancient cities)
SELECT ?wiki ?wiki_label ?sitelinks ?geom
WHERE {
  {SELECT ?wiki (count(distinct ?sitelink) as ?sitelinks) (SAMPLE(?geom) AS ?geom)
     WHERE { 
       ?wiki wdt:P31/wdt:P279* wd:Q15661340 .
       ?wiki wdt:P625 ?geom.
       ?sitelink schema:about ?wiki .
       } GROUP BY ?wiki }
SERVICE wikibase:label { 
  bd:serviceParam wikibase:language "[AUTO_LANGUAGE],en".  # Get label if it exists
?wiki rdfs:label ?wiki_label } 	
} ORDER BY DESC(?rank)

select ?person ?personLabel ?died ?sitelinks where {
  ?person wdt:P31 wd:Q5;
          wdt:P570 ?died.
  filter (?died >= "2018-01-01T00:00:00Z"^^xsd:dateTime && ?died < "2019-01-01T00:00:00Z"^^xsd:dateTime)
  ?person wikibase:sitelinks ?sitelinks.
  service wikibase:label { bd:serviceParam wikibase:language "[AUTO_LANGUAGE],en". }
}  order by desc(?sitelinks) limit 100

# countries with featured articles
SELECT ?sitelink ?itemLabel WHERE {
  ?item wdt:P31 wd:Q6256.
  ?sitelink schema:isPartOf <https://en.wikipedia.org/>;
     schema:about ?item;
     wikibase:badge wd:Q17437796 . # Sitelink is badged as a Featured Article
    SERVICE wikibase:label { bd:serviceParam wikibase:language "[AUTO_LANGUAGE],en" } .
} ORDER BY ?itemLabel

# countries
SELECT DISTINCT ?iso ?countryLabel ?population ?area
{
  ?country wdt:P31 wd:Q6256 ;
           wdt:P297 ?iso ;
           wdt:P1082 ?population .
  ?country p:P2046/psn:P2046/wikibase:quantityAmount ?area.
  SERVICE wikibase:label { bd:serviceParam wikibase:language "en" }
}

# largest cities, local name, population
SELECT DISTINCT ?city ?cityLabel_en ?cityLabel_ol ?population
WHERE
{
  ?city wdt:P31/wdt:P279* wd:Q515 .
  ?city wdt:P1082 ?population .
  ?city wdt:P37 ?officiallanguage.
  ?officiallanguage wdt:P424 ?langcode .
  ?city rdfs:label ?cityLabel_ol . FILTER(lang(?cityLabel_ol)=?langcode)
  ?city rdfs:label ?cityLabel_en . FILTER(lang(?cityLabel_en)='en')
  ?officiallanguage rdfs:label ?official_language . FILTER(lang(?official_language)='en')
  SERVICE wikibase:label {
    bd:serviceParam wikibase:language "en" .
  }
}
ORDER BY DESC(?population) LIMIT 100

#Largest cities per country
SELECT DISTINCT ?city ?cityLabel ?population ?country ?countryLabel ?loc WHERE {
  {
    SELECT (MAX(?population) AS ?population) ?country WHERE {
      ?city wdt:P31/wdt:P279* wd:Q515 .
      ?city wdt:P1082 ?population .
      ?city wdt:P17 ?country .
    }
    GROUP BY ?country
    ORDER BY DESC(?population)
  }
  ?city wdt:P31/wdt:P279* wd:Q515 .
  ?city wdt:P1082 ?population .
  ?city wdt:P17 ?country .
  ?city wdt:P625 ?loc .
  SERVICE wikibase:label {
    bd:serviceParam wikibase:language "en" .
  }
}

# population growth
SELECT ?year ?population {
  wd:Q730 p:P1082 ?p .
  ?p pq:P585 ?year ;
     ps:P1082 ?population .
  SERVICE wikibase:label { bd:serviceParam wikibase:language "en" }
}
ORDER BY ?year

# Ten largest islands in the world
SELECT DISTINCT ?island ?islandLabel ?islandImage WHERE {
  # Instances of island (or of subclasses of island)
  ?island (wdt:P31/wdt:P279*) wd:Q23442.
  # Optionally with an image
  OPTIONAL { ?island wdt:P18 ?islandImage. }
  # Get the area of the island
  # Use the psn: prefix to normalize the values to a common unit of area
  ?island p:P2046/psn:P2046/wikibase:quantityAmount ?islandArea.
  # Use the label service to automatically fill ?islandLabel
  SERVICE wikibase:label { bd:serviceParam wikibase:language "en". }
}
ORDER BY DESC(?islandArea)
LIMIT 10

#Humans born in New York City
#title: Humans born in New York City
SELECT DISTINCT ?item ?itemLabel ?itemDescription ?sitelinks
WHERE {
    ?item wdt:P31 wd:Q5;            # Any instance of a human
          wdt:P19/wdt:P131* wd:Q60; # Who was born in any value (eg. a hospital)
# that has the property of 'administrative area of' New York City or New York City itself.

# Note that using wdt:P19 wd:Q60;  # Who was born in New York City.
# Doesn't include humans with the birth place listed as a hospital
# or an administrative area or other location of New York City.

          wikibase:sitelinks ?sitelinks.
   
    SERVICE wikibase:label { bd:serviceParam wikibase:language "[AUTO_LANGUAGE],en" }
}
ORDER BY DESC(?sitelinks)

# us map
#defaultView:Map
SELECT ?item ?itemLabel ?geo WHERE {  
       ?item  wdt:P17 wd:Q30;
             wdt:P3896 ?geo .          
SERVICE wikibase:label { bd:serviceParam wikibase:language "en" }
}

# nickname
#Q30 united states
#Q1439 texas
#Q840381 flatbush
SELECT DISTINCT ?city ?cityLabel ?nickname ?anthem ?motto ?website ?portal ?geonames WHERE {
  SERVICE wikibase:label { bd:serviceParam wikibase:language "[AUTO_LANGUAGE],en". }
  VALUES ?town_or_city {
    wd:Q3957
    wd:Q515
  }
  ?city (wdt:P31/(wdt:P279*)) ?town_or_city;
    wdt:P131* wd:Q1439.
  OPTIONAL{ ?city wdt:P1449 ?nickname.}
  OPTIONAL{ ?city wdt:P85 ?anthem.}
  OPTIONAL{ ?city wdt:P1546 ?motto.}
  OPTIONAL{ ?city wdt:P856 ?website.}
  OPTIONAL{ ?city wdt:P8402 ?portal.}
  OPTIONAL{ ?city wdt:P1566 ?geonames.}
}

# logo P154

#defaultView:Table
#village - Q532
#human settlement - Q486972
PREFIX rdfs: <http://www.w3.org/2000/01/rdf-schema#>
PREFIX wikibase: <http://wikiba.se/ontology#>
PREFIX wd: <http://www.wikidata.org/entity/>
PREFIX wdt: <http://www.wikidata.org/prop/direct/>

SELECT ?lang_en ?lang_ru ?village ?population ?coordinates
WHERE {
  ?village wdt:P31/wdt:P279* wd:Q486972 .  # select items that are instance or subclass of village
  ?village wdt:P17 wd:Q813 .  # select items located in Kyrgyzstan
  ?village rdfs:label ?label_en filter (lang(?label_en) = "en").
  ?village rdfs:label ?label_ru filter (lang(?label_ru) = "ru").
  OPTIONAL { ?village wdt:P1082 ?population } .  # retrieve the population (if it exists)
  OPTIONAL { ?village wdt:P625 ?coordinates } .  # retrieve the coordinates (if they exist)
  }
ORDER BY DESC(?population)
LIMIT 10

# bridges over River Firth
#defaultView:Map
SELECT DISTINCT ?item ?itemLabel ?coordinates
WHERE {
  ?item wdt:P31/wdt:P279* wd:Q12280. 
  ?item wdt:P177 wd:Q2421.
  SERVICE wikibase:label { bd:serviceParam wikibase:language "en".  }
  OPTIONAL { ?item wdt:P625 ?coordinates }
}
```

Some useful codes  
```shell
#entities
admin1: Q10864048
biome: Q101998
drainage basin: Q166620
ecosystem: Q37813
geography of location: Q46865913
geomorphological unit: Q12766313
group of lakes: Q5926864
mountain range: Q46831
wwf ecoregion: Q6617741
wd:Q333291 ?abstract
wdt:P18 ?img
area: P2046
?wiki wdt: P1269 ?facet.
```

Wikipedia dump  
```shell
# format data dump
bzcat /home/steve/maps/wikipedia/enwiki-latest-pages-articles-multistream.xml.bz2 | perl -pe 's/<\/page>/<\/page>\a/g;' | tr -d $'\t' | tr $'\n' $'\t' | tr $'\a' $'\n' > /home/steve/maps/wikipedia/enwiki-latest-pages-articles-multistream.xml
# recompress
bzip2 -zk /home/steve/maps/wikipedia/enwiki-latest-pages-articles-multistream.xml

# create my own index
# line number
awk -F '\t' 'BEGIN {OFS="\t";} {print NR,$3,$5}' /home/steve/maps/wikipedia/enwiki-latest-pages-articles-multistream.xml | tr -s ' ' | grep '<title>' | sed -e 's/ <title>//g' -e 's/<\/title>//g' -e 's/ <id>//g' -e 's/<\/id>//g' > /home/steve/maps/wikipedia/enwiki-latest-pages-articles-multistream-index.csv
# byte offset
fgrep --byte-offset '<title>' /home/steve/maps/wikipedia/enwiki-latest-pages-articles-multistream.xml | tr -d ':' | awk -F '\t' 'BEGIN {OFS="\t";} {print $1, $3, $5}' | tr -s ' ' | sed  -e 's/ <title>//g' -e 's/<\/title>//g' -e 's/ <id>//g' -e 's/<\/id>//g' > /home/steve/maps/wikipedia/enwiki-latest-pages-articles-multistream-index.csv

# import wiki index into psql
CREATE TABLE enwiki_index(enwiki_offset bigint, enwiki_title text, enwiki_id bigint);
COPY enwiki_index FROM '/home/steve/wikipedia/enwiki-latest-pages-articles-multistream-index.csv' CSV DELIMITER E'\t';
ALTER TABLE enwiki_index ADD COLUMN fid serial PRIMARY KEY;

# xml
# with geom
mv /home/steve/Downloads/query.tsv /home/steve/maps/wikipedia/${file}.tmp
echo '<xml>' > /home/steve/maps/wikipedia/${file}.xml
sed -n '1!p' /home/steve/maps/wikipedia/${file}.tmp | while IFS=$'\t' read -a array; do echo ${array[1]}; dd if=/home/steve/maps/wikipedia/enwiki-latest-pages-articles-multistream.xml skip=$(grep $'\t'"${array[1]}"$'\t' /home/steve/maps/wikipedia/enwiki-latest-pages-articles-multistream-index.csv | awk -F$'\t' '{ print $1 }') count=1000000 iflag=skip_bytes,count_bytes | grep "<title>${array[1]}</title>" | sed "s/<\/title>/<\/title><geom>${array[2]}<\/geom><fid>${array[0]#http://www.wikidata.org/entity/}<\/fid>/g" >> /home/steve/maps/wikipedia/${file}.xml; done
echo '</xml>' >> /home/steve/maps/wikipedia/${file}.xml
# without geom
echo '<xml>' > /home/steve/maps/wikipedia/${file}.xml
sed -n '1!p' /home/steve/maps/wikipedia/${file}.tmp | while IFS=$'\t' read -a array; do echo ${array[1]}; dd if=/home/steve/maps/wikipedia/enwiki-latest-pages-articles-multistream.xml skip=$(grep $'\t'"${array[1]^}"$'\t' /home/steve/maps/wikipedia/enwiki-latest-pages-articles-multistream-index.csv | awk -F$'\t' '{ print $1 }') count=1000000 iflag=skip_bytes,count_bytes | grep "<title>${array[1]^}</title>" | sed "s/<\/title>/<\/title><fid>${array[0]}<\/fid>/g" >> /home/steve/maps/wikipedia/${file}.xml; done
echo '</xml>' >> /home/steve/maps/wikipedia/${file}.xml
# geonames
echo '<xml>' > /home/steve/maps/wikipedia/${file}.xml
cat /home/steve/maps/wikipedia/${file}.tmp | while IFS=$'\t' read -a array; do echo ${array[1]}; dd if=/home/steve/maps/wikipedia/enwiki-latest-pages-articles-multistream.xml skip=$(grep $'\t'"${array[1]^}"$'\t' /home/steve/maps/wikipedia/enwiki-latest-pages-articles-multistream-index.csv | awk -F$'\t' '{ print $1 }') count=1000000 iflag=skip_bytes,count_bytes | grep "<title>${array[1]^}</title>" | sed "s/<\/title>/<\/title><fid>${array[0]}<\/fid>/g" >> /home/steve/maps/wikipedia/${file}.xml; done
echo '</xml>' >> /home/steve/maps/wikipedia/${file}.xml

# extract intro
# raw
cat /home/steve/maps/wikipedia/${file}.xml | perl -MHTML::Entities -pe 'decode_entities($_);' -pe 's/<ref/\n<ref/g;' -pe 's/(?=<ref).*(?<=<\/ref>)//g;' -pe 's/(?=<ref).*(?<=\/>)//g;' | tr -d '\n' | tr '\t' '\n' | sed -e 's/^ *//g' -e 's/<page>/@page/g' -e 's/<title>/\a/g' -e 's/<\/title>/\t/g' -e 's/<geom>//g' -e 's/<\/geom>/\t/g' -e 's/<fid>//g' -e 's/<\/fid>/\t/g' -e 's/<text xml:space="preserve">/@text\n/g' | grep -vi -e '^$' -e '^(' -e '^{' -e '^}' -e '^|' -e '^#' -e '^\*' -e '^=' -e '^:' -e '^_' -e '^&quot;' -e '^&lt;' -e '^\[\[file' -e '^\[\[category' -e '^\[\[image' -e '^<' -e '^<\/' -e '^http:' -e '^note:' -e '^file:' -e '^url=' -e '^[0-9]' -e '^•' -e '^-' | grep -A1 -e '^@page' -e '^@text' | grep -v -e '^--' -e '^@page' -e '^@text' | tr -s " " | tr -d '\n' | tr '\a' '\n' | sed -n '1!p' > /home/steve/maps/wikipedia/${file}/${file}_intro.csv
# cleaned up
cat /home/steve/maps/wikipedia/${file}.xml | perl -MHTML::Entities -pe 'decode_entities($_);' -pe 's/<ref/\n<ref/g;' -pe 's/(?=<ref).*(?<=<\/ref>)//g;' -pe 's/(?=<ref).*(?<=\/>)//g;' | tr -d '\n' | tr '\t' '\n' | sed -e 's/^ *//g' -e 's/<page>/@page/g' -e 's/<title>/\a/g' -e 's/<\/title>/\t/g' -e 's/<geom>//g' -e 's/<\/geom>/\t/g' -e 's/<fid>//g' -e 's/<\/fid>/\t/g' -e 's/<text xml:space="preserve">/@text\n/g' | grep -vi -e '^$' -e '^(' -e '^{' -e '^}' -e '^|' -e '^#' -e '^\*' -e '^=' -e '^:' -e '^_' -e '^&quot;' -e '^&lt;' -e '^\[\[file' -e '^\[\[category' -e '^\[\[image' -e '^<' -e '^<\/' -e '^http:' -e '^note:' -e '^file:' -e '^url=' -e '^[0-9]' -e '^•' -e '^-' | grep -A1 -e '^@page' -e '^@text' | grep -v -e '^--' -e '^@page' -e '^@text' | tr -s " " | tr -d '\n' | tr '\a' '\n' | sed -n '1!p' | tr '\n' '\a' | sed -e 's/\[\[/\n\[\[/g' -e 's/\]\]/\]\]\n/g' | sed -e 's/^\[\[.*|/\[\[/g' -e 's/{{/\n{{/g' -e 's/}}[,:;]\?/}}\n/g' -e 's/ (/\nFOOBAR/g' | sed '/)\t/! s/)/FOOBAR\n/g' | grep -v '^{{\|}}' | grep -v -e 'FOOBAR' -e '^ \?[;:] \?$' | tr -d '\n' | tr '\a' '\n' | tr -s '  ' | sed -e "s/'''//g" -e 's/\[\[//g' -e 's/\]\]//g' -e 's/\bSt\./St/g' -e 's/\bU\.S\.A\./USA/g' -e 's/\bU\.S\./US/g' -e 's/c\./c/g' -e 's/ ,/,/g' > /home/steve/maps/wikipedia/${file}/${file}_intro.csv

# extract section
# raw
declare -a sections=("climat" "description" "ecolog" "fauna" "flora" "geograph")
for section in "${sections[@]}"; do cat /home/steve/maps/wikipedia/${file}.xml | perl -MHTML::Entities -pe 'decode_entities($_);' -pe 's/<ref/\n<ref/g;' -pe 's/(?=<ref).*(?<=<\/ref>)//g;' -pe 's/(?=<ref).*(?<=\/>)//g;' | tr -d '\n' | tr '\t' '\n' | sed -e 's/^ *//g' -e 's/<page>/@page/g' -e 's/<title>/\a/g' -e 's/<\/title>/\t/g' -e 's/<geom>//g' -e 's/<\/geom>/\t/g' -e 's/<fid>//g' -e 's/<\/fid>/\t/g' -e 's/^=\+.*'${section}'.*=\+$/@mysection/Ig' | grep -vi -e '^$' -e '^(' -e '^{' -e '^}' -e '^|' -e '^#' -e '^\*' -e '^=' -e '^:' -e '^_' -e '^&quot;' -e '^&lt;' -e '^\[\[file' -e '^\[\[category' -e '^\[\[image' -e '^<' -e '^<\/' -e '^http:' -e '^note:' -e '^file:' -e '^url=' -e '^[0-9]' -e '^•' -e '^-' | grep -A1 -e '^@page' -e '^@mysection' | grep -v -e '^--' -e '^@page' -e '^@mysection' | tr -s " " | tr -d '\n' | tr '\a' '\n' | sed -n '1!p' > /home/steve/maps/wikipedia/${file}/${file}_${section}.csv; done
# cleaned up
declare -a sections=("climat" "description" "ecolog" "fauna" "flora" "geograph")
for section in "${sections[@]}"; do cat /home/steve/maps/wikipedia/${file}.xml | perl -MHTML::Entities -pe 'decode_entities($_);' -pe 's/<ref/\n<ref/g;' -pe 's/(?=<ref).*(?<=<\/ref>)//g;' -pe 's/(?=<ref).*(?<=\/>)//g;' | tr -d '\n' | tr '\t' '\n' | sed -e 's/^ *//g' -e 's/<page>/@page/g' -e 's/<title>/\a/g' -e 's/<\/title>/\t/g' -e 's/<geom>//g' -e 's/<\/geom>/\t/g' -e 's/<fid>//g' -e 's/<\/fid>/\t/g' -e 's/^=\+.*'${section}'.*=\+$/@mysection/Ig' | grep -vi -e '^$' -e '^(' -e '^{' -e '^}' -e '^|' -e '^#' -e '^\*' -e '^=' -e '^:' -e '^_' -e '^&quot;' -e '^&lt;' -e '^\[\[file' -e '^\[\[category' -e '^\[\[image' -e '^<' -e '^<\/' -e '^http:' -e '^note:' -e '^file:' -e '^url=' -e '^[0-9]' -e '^•' -e '^-' | grep -A1 -e '^@page' -e '^@mysection' | grep -v -e '^--' -e '^@page' -e '^@mysection' | tr -s " " | tr -d '\n' | tr '\a' '\n' | sed -n '1!p' | tr '\n' '\a' | sed -e 's/\[\[/\n\[\[/g' -e 's/\]\]/\]\]\n/g' | sed -e 's/^\[\[.*|/\[\[/g' -e 's/{{/\n{{/g' -e 's/}}[,:;]\?/}}\n/g' -e 's/ (/\nFOOBAR/g' | sed '/)\t/! s/)/FOOBAR\n/g' | grep -v '^{{\|}}' | grep -v -e 'FOOBAR' -e '^ \?[;:] \?$' | tr -d '\n' | tr '\a' '\n' | tr -s '  ' | sed -e "s/'''//g" -e 's/\[\[//g' -e 's/\]\]//g' -e 's/\bSt\./St/g' -e 's/\bU\.S\.A\./USA/g' -e 's/\bU\.S\./US/g' -e 's/c\./c/g' -e 's/ ,/,/g' > /home/steve/maps/wikipedia/${file}/${file}_${section}.csv; done

# paste sections
# with fid + geom
echo "enwiki_title"$'\t'"geom"$'\t'"fid"$'\t'"intro"$'\t'"climat"$'\t'"description"$'\t'"ecolog"$'\t'"fauna"$'\t'"flora"$'\t'"geograph" > /home/steve/maps/wikipedia/${file}/${file}.csv
paste /home/steve/maps/wikipedia/${file}/${file}_intro.csv /home/steve/maps/wikipedia/${file}/${file}_climat.csv /home/steve/maps/wikipedia/${file}/${file}_description.csv /home/steve/maps/wikipedia/${file}/${file}_ecolog.csv /home/steve/maps/wikipedia/${file}/${file}_fauna.csv /home/steve/maps/wikipedia/${file}/${file}_flora.csv /home/steve/maps/wikipedia/${file}/${file}_geograph.csv | awk -F '\t' 'BEGIN {OFS="\t";} {print $1,$2,$3,$4,$8,$12,$16,$20,$24,$28}' >> /home/steve/maps/wikipedia/${file}/${file}.csv
# with fid
echo "enwiki_title"$'\t'"fid"$'\t'"intro"$'\t'"climat"$'\t'"description"$'\t'"ecolog"$'\t'"fauna"$'\t'"flora"$'\t'"geograph" > /home/steve/maps/wikipedia/${file}/${file}.csv
paste /home/steve/maps/wikipedia/${file}/${file}_intro.csv /home/steve/maps/wikipedia/${file}/${file}_climat.csv /home/steve/maps/wikipedia/${file}/${file}_description.csv /home/steve/maps/wikipedia/${file}/${file}_ecolog.csv /home/steve/maps/wikipedia/${file}/${file}_fauna.csv /home/steve/maps/wikipedia/${file}/${file}_flora.csv /home/steve/maps/wikipedia/${file}/${file}_geograph.csv | awk -F '\t' 'BEGIN {OFS="\t";} {print $1,$2,$3,$6,$9,$12,$15,$18,$21}' >> /home/steve/maps/wikipedia/${file}/${file}.csv

# extract links
# xml
echo '<xml>' > /home/steve/maps/wikipedia/${file}_links.xml
cat /home/steve/maps/wikipedia/${file}/${file}.csv | grep -oP '(?<=\[\[).*?(?=\||\]\])' | sort -u | while read link; do dd if=/home/steve/maps/wikipedia/enwiki-latest-pages-articles-multistream.xml skip=$(grep $'\t'"${link^}"$'\t' /home/steve/maps/wikipedia/enwiki-latest-pages-articles-multistream-index.csv | awk '{print $1}') count=1000000 iflag=skip_bytes,count_bytes | grep "<title>${link^}</title>" >> /home/steve/maps/wikipedia/${file}_links.xml; done
echo '</xml>' >> /home/steve/maps/wikipedia/${file}_links.xml
# intro
cat /home/steve/maps/wikipedia/${file}_links.xml | perl -MHTML::Entities -pe 'decode_entities($_);' -pe 's/<ref/\n<ref/g;' -pe 's/(?=<ref).*(?<=<\/ref>)//g;' -pe 's/(?=<ref).*(?<=\/>)//g;' | tr -d '\n' | tr '\t' '\n' | sed -e 's/^ *//g' -e 's/<page>/@page/g' -e 's/<title>/\a/g' -e 's/<\/title>/\t/g' -e 's/<geom>//g' -e 's/<\/geom>/\t/g' -e 's/<fid>//g' -e 's/<\/fid>/\t/g' -e 's/<text xml:space="preserve">/@text\n/g' | grep -vi -e '^$' -e '^(' -e '^{' -e '^}' -e '^|' -e '^#' -e '^\*' -e '^=' -e '^:' -e '^_' -e '^&quot;' -e '^&lt;' -e '^\[\[file' -e '^\[\[category' -e '^\[\[image' -e '^<' -e '^<\/' -e '^http:' -e '^note:' -e '^file:' -e '^url=' -e '^[0-9]' -e '^•' -e '^-' | grep -A1 '^@text' | grep -v -e '^@text' -e '^--' -e '^@page' > /home/steve/maps/wikipedia/${file}/${file}_links.tmp
# get fid
echo "fid"$'\t'"intro" > /home/steve/maps/wikipedia/wwf_ecoregion/wwf_ecoregion_links.csv
cat /home/steve/maps/wikipedia/wwf_ecoregion/wwf_ecoregion.csv | grep -noP '(?=\[\[).*?(?<=\]\])' | sed -e 's/:/\t/g' -e 's/\[\[/'"'''"'/g' -e 's/\]\]/'"'''"'/g' | while IFS=$'\t' read -a array; do fid=`sed -n "${array[0]}p" /home/steve/maps/wikipedia/wwf_ecoregion/wwf_ecoregion.csv | awk -F '\t' '{print $2}'`; def=`grep "${array[1]}" /home/steve/maps/wikipedia/wwf_ecoregion/wwf_ecoregion_links.tmp`; echo ${fid}$'\t'${def} | awk -F\t '$2' >> /home/steve/maps/wikipedia/wwf_ecoregion/wwf_ecoregion_links.csv; done

# wiki <-> geonames (geonames.rdf)
cat /home/steve/maps/geonames/all-geonames-rdf.txt | grep 'gn:wikipediaArticle' | sed -e 's/^.*gn:Feature rdf:about="http:\/\/sws\.geonames\.org\///g' -e 's/\/.*gn:wikipediaArticle rdf:resource="http:\/\/en\.wikipedia\.org\/wiki\//\t/g' -e 's/"\/>.*$//g' | grep -v "http" > /home/steve/maps/wikipedia/enwiki-geonames.csv
# psql
CREATE TABLE allcountries_wiki(geonameid int, enwiki_title text);
COPY allcountries_wiki FROM '/home/steve/maps/wikipedia/enwiki-geonames.csv' CSV DELIMITER E'\t';
ALTER TABLE allcountries ADD COLUMN enwiki_title text;
UPDATE allcountries a SET enwiki_title = b.enwiki_title FROM allcountries_wiki b WHERE a.geonameid = b.geonameid;
# convert url characters
cat /home/steve/maps/wikipedia/enwiki-geonames.csv | while read line; do urlencode -d ${line} | sed -e 's/_/ /g' -e 's/ /\t/1' >> /home/steve/maps/wikipedia/enwiki-geonames.tmp; done
```

## Misc

Common shell commands  
```shell
# disk usage
du -h --max-depth=1 /home/steve/maps | sort -h

# rename files/folders numerically
filetype=jpg
SAVEIFS=$IFS
IFS=$(echo -en "\n\b")
a=1
for i in $1/*.${filetype}; do
  new=$(printf "%04d" "$a")
  mv -- "$i" "$1/${new}.${filetype}"
  let a=a+1
done
IFS=$SAVEIFS

# replace spaces with underscores
find -name "* *" -type d | rename 's/ /_/g'    # do directories first
find -name "* *" -type f | rename 's/ /_/g'

# remove parentheses and brackets
rename -n 's/\(|\[|\]|\)//g' *
# remove characters in parentheses or brackets
rename -n 's/\(.*\)|\[.*\]//g' *
# remove spaces
rename -n 's/\(.*\)|\[.*\]| //g' *

# named or random file
passed=$1
if [ -d "${passed}" ]; then
  dir=${1}
  file1=`ls $dir/*.jpg | shuf -n1`
  file2=`ls $dir/*.jpg | shuf -n1`
else
  dir=${1}
  file1='${dir}/${2}'
  file2='${dir}/${3}'
fi

# List files in the current directory and rm with grep
files=$(ls)
files_with_word=$(echo "$files" | grep 'null')

for file in $files_with_word; do
  #rm "$file"
  echo "Removed: $file"
done

# delete empty files
find . -type f -empty -delete

# recode html to utf
perl -MHTML::Entities -pe 'decode_entities($_);'

# barcode
barcode -S -u "in" -g "2x1.25" -p "2x1.25" -b "978-1-7773458-4-6" -o barcode.svg

# convert newline to comma delimited
paste -sd,
paste -d '\t' file1.csv file2.csv > file.csv
csvcut --columns=36,37,152 /home/steve/maps/vertnet/vertnet_latest_amphibians.csv > /home/steve/maps/vertnet/vertnet_latest_amphibians_trim.csv
grep -v '^,' /home/steve/maps/vertnet/vertnet_latest_amphibians_trim.csv > /home/steve/maps/vertnet/vertnet_latest_amphibians_trim_clean.csv
ogr2ogr -f CSV -lco GEOMETRY=AS_XY /home/steve/Downloads/points001_dem.csv /home/steve/Downloads/points001_dem.shp

# sort
sort -t$'\t' -k15 -rn /home/steve/Projects/maps/geonames/cities15000.txt | head -1000 > /home/steve/Projects/maps/geonames/cities_top1000.txt
# sort unique
sort -u -t\t -k1,1 /home/steve/Downloads/wwf_ecoregion.tsv

# round time
$(echo "$(date +%H) - ($(date +%H)%3)" | bc | awk '{ printf("%02d", $1) }')

# conditional
if [[ ${file} =~ 'PRATE' ]]; then
  echo $file
fi

### searching
# between (inclusive)
grep -oP '(?=\[\[Category|\[\[File).*?(?<=\]\])'
# between (exclusive)
grep -oP '(?<=\<title\>).*?(?=\<\/title\>)'
grep -oP '(?<=\<title\>).*(?=\<\/title\>)'
# delete between parentheses
perl -p -e 's#\([^)]*\)##g'
# line after
sed -n '/^=\+ *Location/{n;p}'
# find + add
sed 's/.foo/&bar/'
```

Ascii art  
```shell
# figlet
figlet -d /usr/share/figlet/fonts -f Isometric1 seoul
```

XML  
```shell
# xmlstarlet
xmlstarlet sel -t -v xml/page/revision/text
```

JSON  
```shell
# searching
cat kg.json | jq -r '.[] | ."Population distribution"'
cat kg.json | jq '.Geography."Population distribution".text'

# print
cat tweets.json | jq '.'

# view attribute
cat tweets.json | jq '.data'
cat tweets.json | jq '.data.text'

# find key anywhere
jq '..|.mapdata?'

cat /home/steve/wikipedia/tables/table_wwf_ecoregions.json | jq '."List of terrestrial ecoregions (WWF)[0]"[0] | to_entries[]  | .key'

# convert to csv
cat /home/steve/wikipedia/tables/table_wwf_ecoregions.json | jq -r '."List of terrestrial ecoregions (WWF)[0]"[] | [.Biome, .Ecoregion, .Ecozone, .Country] | @csv' > /home/steve/wikipedia/tables/table_wwf_ecoregions.csv

# parse from api
url=$(curl 'https://en.wikipedia.org/w/api.php?action=query&format=json&prop=extracts|mapdata&exchars=200&exlimit=max&explaintext&exintro&titles='${hood} | jq '..|.mapdata?' | grep '.map' | sed -e 's/^.*w\/api/https\:\/\/en\.wikipedia\.org\/w\/api/g' -e 's/\.map.*$/\.map/g')
curl -q ${url} | jq '.jsondata.data' > ${hood}.geojson
```

vim  
```shell
# file
:e /file
:w /file

# terminal
:below term

# session
:mks! /file

# buffer
:buffers
:bwipeout 1

# split/tab
ctrl-w-v
:tabnew
```

git  
```shell
# commit
git add .
git commit -m 'update'
git push -f

# pull
git pull origin main

# reset
git reset --hard f10169783b7134ac3225c04197d7ca71272f3357
# clone with ssh (passphrase for key /home/steve/.ssh/id_ed25519)
git clone git@github.com:geographyclub/imagemagick-for-mapmakers.git
# set authentication to ssh
git remote set-url origin git@github.com:USERNAME/REPOSITORY.git
git remote set-url origin git@github.com:geographyclub/american-geography.git
```

nginx  
```shell
# for directory listing
sudo mkdir countries
sudo chown steve:steve countries
# in /etc/nginx/sites-enabled/default
location /countries/ {
  charset UTF-8;
  autoindex on;
  autoindex_exact_size off;
  autoindex_format html;
  autoindex_localtime on;
}

# for qgis-server
# in /etc/nginx/sites-enabled/default
location /qgisserver {
  gzip           off;
  include        fastcgi_params;
  fastcgi_param  QGIS_SERVER_LOG_STDERR  1;
  fastcgi_param  QGIS_SERVER_LOG_LEVEL   0;
  fastcgi_param  DISPLAY       ":99";
  fastcgi_pass   unix:/var/run/qgisserver.socket;
}
```

sqlite  
```shell
# common tings
.tables
.quit
#export
sqlite3 -header -separator $'\t' /home/steve/maps/wikipedia/index_enwiki-20190420.db "SELECT * FROM mapping;" > /home/steve/maps/wikipedia/enwiki-wikidata.csv

# import/export
.mode csv
.import 'ACSDP5Y2019.DP05_data_with_overlays_2022-07-26T145041.csv' mytable
.output mytable.sql
.dump mytable

# query
ogr2ogr -overwrite -update -f "SQLite" -dsco SPATIALITE=YES -dialect sqlite -sql "SELECT * FROM gbif WHERE countrycode='CA';" /home/steve/Projects/maps/gbif/ca.sqlite /home/steve/Projects/maps/gbif/gbif.sqlite -nln ca -nlt POINT

# snap
ogr2ogr -overwrite -update -f "SQLite" -dsco SPATIALITE=YES -dialect sqlite -sql "SELECT * FROM points;" ${file} ${file} -nlt POINT -nln points_snap
ogr2ogr -overwrite -update -f "SQLite" -dsco SPATIALITE=YES -dialect sqlite -sql "UPDATE points SET GEOMETRY = ST_SnapToGrid(GEOMETRY, 0.001);" ${file} ${file} -nln points

# grid
ogr2ogr -overwrite -update -f "SQLite" -dsco SPATIALITE=YES -dialect sqlite -sql "SELECT ST_SquareGrid(Extent(GEOMETRY), 0.001) FROM multipolygons;" ${file} ${file} -nln grid -nlt multipolygon
```

svg  
```shell
# transform
# scale
sed -i 's/matrix(1,0,0,1/matrix(2,0,0,2/g' /home/steve/Downloads/test.svg

# make tings
# bezier curve
<path d="M200,300 L400,50 L600,300 L800,550 L1000,300" fill="none" stroke="#888888" stroke-width="2" />

# filters
<filter id="f1" x="0" y="0"><feGaussianBlur in="SourceGraphic" stdDeviation="20" /></filter>

# make layers
file="/home/steve/Downloads/test.svg"
cat $file | tr '\n' ' ' | tr -s " " | sed 's/<\/g>/<\/g>\n/g' | grep '<text' > /home/steve/Downloads/tmp/layer.txt
rm -f /home/steve/Downloads/tmp/layers_id.txt
cat /home/steve/Downloads/tmp/layers.txt | while read line; do
  echo $line | sed 's/<g/<g id='\"$[ ( $RANDOM % layer_count ) + 1 ]\"'/g' >> /home/steve/Downloads/tmp/layers_id.txt
done
for ((a=1; a<=layer_count; a=a+1)); do
cat > /home/steve/Downloads/tmp/layer_${a}.svg <<- EOM
<?xml version="1.0" encoding="UTF-8" standalone="no"?>
<svg width="100%" height="100%" viewBox="0 0 3300 2550" xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" version="1.2" baseProfile="tiny">
<defs>
  <linearGradient id="SublimeVivid" x1="0" x2="0" y1="0" y2="100%" >
    <stop stop-color="#FC466B" offset="0%"/>
    <stop stop-color="#3F5EFB" offset="100%"/>
  </linearGradient>
</defs>
EOM
done
for ((a=1; a<=layer_count; a=a+1)); do
  cat /home/steve/Downloads/tmp/layers_id.txt | grep 'id='\"${a}\"'' >> /home/steve/Downloads/tmp/layer_${a}.svg
done
for ((a=1; a<=layer_count; a=a+1)); do
  echo '</svg>' >> /home/steve/Downloads/tmp/layer_${a}.svg
done

# text effects
chars=("~" "!" "@" "#" "$" "%" "^" "&" "*" "(" ")" "_" "-" "+" "=" "{" "[" "}" "]" "?")
for (( a=$(( frame_count )); a>=1; a=a-1 )); do
  cat /home/steve/Downloads/tmp/frame_${a}a.svg | grep '<text' | sed 's/^.* >//g' | sed 's/ |.*$//g' | while read place; do
    count=${#place}
    index=`shuf -i 1-$(( count )) -n 1`
    newword=`echo $place | sed "s/./${chars[$RANDOM % ${#chars[@]} ]}/${index}"`
    sed -i "s:$place:$newword:g" /home/steve/Downloads/tmp/frame_${a}a.svg
  done
done

# make frames (svg)
a=1
frame_count=24
rm -f /home/steve/Downloads/tmp/*
ls -v /home/steve/Downloads/map*.svg | while read file; do
  for (( b=1; b<=${frame_count}; b=b+1 )); do
    cat ${file} | sed 's/<defs>/<defs>\n<filter id="blur"><feGaussianBlur in="SourceGraphic" stdDeviation="10"\/><\/filter>/g' | sed 's/<path /<path filter="url(#blur)" /g' > /home/steve/Downloads/tmp/frame$(printf "%06d" ${a}).svg
    let a=a+1
  done
done

# stream0
stream=stream0
audio='/home/steve/Downloads/night vibes korean underground r&b + hiphop (14 songs).mp3'
date_metar=$(date -r $PWD/../data/metar/metar.csv)
files=$PWD/../data/places/*.svg
rm -f $PWD/../data/${stream}/*.svg
cp ${files} $PWD/../data/${stream}/
ls ${files} | while read file; do echo $(cat ${file} | grep '@' | sed -e 's/^.*>@//g' -e 's/@<.*$//g') | while read fid; do IFS=$'\t'; data=($(psql -d world -c "\COPY (SELECT a.fid, a.nameascii, round(b.temp), b.wx_full, CASE WHEN round(b.temp) < c.day1_tmin THEN round(b.temp) ELSE c.day1_tmin END, CASE WHEN round(b.temp) > c.day1_tmax THEN round(b.temp) ELSE c.day1_tmax END, c.day1_wx, c.day2_tmin, c.day2_tmax, c.day2_wx, c.day3_tmin, c.day3_tmax, c.day3_wx FROM places a, metar b, places_gdps_utc c WHERE a.metar_id = b.station_id AND a.fid = c.fid AND a.fid IN (${fid})) TO STDOUT DELIMITER E'\t';")); sed -i.bak -e 's/<svg.*$/<svg xmlns="http:\/\/www.w3.org\/2000\/svg" version="1.2" baseProfile="tiny" height="720px" width="1280px" viewBox="0 0 1280 720">\n<rect width="100%" height="100%" fill="#EDE7DC"\/>/g' -e 's/font-family="Montserrat"/font-family="Montserrat Black"/g' -e "s/@${data[0]}@/<tspan font-size=\"90\">${data[1]^^}<\/tspan><tspan font-size=\"90\" x=\"0\" dy=\"70\">${data[2]}°C ${data[3]^^}<\/tspan><tspan font-size=\"60\" x=\"0\" dy=\"55\">$(date +%^a):${data[4]}\/${data[5]}°C ${data[6]}<\/tspan><tspan font-size=\"60\" x=\"0\" dy=\"55\">$(date --date="+1 day" +%^a):${data[7]}\/${data[8]}°C ${data[9]}<\/tspan><tspan font-size=\"60\" x=\"0\" dy=\"55\">$(date --date="+2 day" +%^a):${data[10]}\/${data[11]}°C ${data[12]}<\/tspan>/g" $PWD/../data/${stream}/$(basename ${file}); done; done

# svg slideshow
ls ${files} | while read file; do echo $(cat ${file} | grep '@' | sed -e 's/^.*>@//g' -e 's/@<.*$//g') | while read fid; do IFS=$'\t'; data=($(psql -d world -c "\COPY (SELECT a.fid, a.nameascii, round(b.temp), b.wx_full, CASE WHEN round(b.temp) < c.day1_tmin THEN round(b.temp) ELSE c.day1_tmin END, CASE WHEN round(b.temp) > c.day1_tmax THEN round(b.temp) ELSE c.day1_tmax END, c.day1_wx, c.day2_tmin, c.day2_tmax, c.day2_wx, c.day3_tmin, c.day3_tmax, c.day3_wx FROM places a, metar b, places_gdps_utc c WHERE a.metar_id = b.station_id AND a.fid = c.fid AND a.fid IN (${fid})) TO STDOUT DELIMITER E'\t';")); sed -i.bak -e 's/<svg.*$/<svg xmlns="http:\/\/www.w3.org\/2000\/svg" version="1.2" baseProfile="tiny" height="720px" width="1280px" viewBox="0 0 1280 720">\n<rect width="100%" height="100%" fill="#EDE7DC"\/>/g' -e 's/font-family="Montserrat"/font-family="Montserrat Black"/g' -e "s/@${data[0]}@/<tspan font-size=\"100\" textLength=\"100%\">${data[1]^^}<\/tspan><text width=\"100%\"><tspan font-size=\"100\" textLength=\"100%\" x=\"0\" dy=\"65\">${data[2]}°C ${data[3]^^}<\/tspan><\/text><tspan font-size=\"60\" x=\"0\" dy=\"55\">$(date +%^a):${data[4]}\/${data[5]}°C ${data[6]}<\/tspan><tspan font-size=\"60\" x=\"0\" dy=\"55\">$(date --date="+1 day" +%^a):${data[7]}\/${data[8]}°C ${data[9]}<\/tspan><tspan font-size=\"60\" x=\"0\" dy=\"55\">$(date --date="+2 day" +%^a):${data[10]}\/${data[11]}°C ${data[12]}<\/tspan>/g" $PWD/data/${stream}/$(basename ${file}); done; done
ffmpeg -y -r 1/10 -i $PWD/data/${stream}/%03d.svg -i "${audio}" -shortest -c:v libx264 -c:a aac -crf 23 -pix_fmt yuv420p -preset fast -threads 0 -movflags +faststart $PWD/${stream}.mp4

# svg slideshow w scroller
ffmpeg -y -t 100 -r 24 -i '/home/steve/git/weatherchan/maps/atlas/%03d.svg' -i '/home/steve/Downloads/night vibes korean underground r&b + hiphop (14 songs).mp3' -shortest -vf drawtext="fontsize=60:fontfile=/home/steve/.fonts/fonts-master/ofl/montserrat/Montserrat-Regular.ttf:textfile=/home/steve/git/weatherchan/metar/metar_af.txt:y=h-line_h:x=-100*t" -c:v libx264 -c:a aac -crf 23 -pix_fmt yuv420p -preset fast -threads 0 -movflags +faststart "/home/steve/Downloads/test.mp4"
```

FFMPEG  
```shell
# capture screen
ffmpeg -video_size 1024x768 -framerate 25 -f x11grab -i :0.0+0+0 ~/output.mp4

# add border to video
ffmpeg -i <input> -vf "pad=iw*2:ih*2:iw/2:ih/2"
ffmpeg -i ortho_68_25_04_28_112609.mp4 -vf "pad=1920:1080:1920-256:1080-28" ortho_68_25_04_28_112609_1920x1080.mp4

# split video using scene detection
ffmpeg -i '02 Scientology.mp4' -vf "select='gt(scene,0.1)',setpts=N/FRAME_RATE/TB" -f segment -reset_timestamps 1 -map 0 output_%03d.mp4
```
