# GIS FROM COMMAND LINE

All the software and scripts you need to make Linux a complete *Geographic Information System* from command line.

## TABLE OF CONTENTS

### Sections
1. [GDAL](#GDAL)  
   •gdalinfo •gdalwarp •gdal_translate •gdal_contour •gdaldem •gdal_polygonize.py •gdal_rasterize •gdal_calc.py •gdal_grid •gdallocationinfo
2. [OGR](#OGR)  
   •ogrinfo •ogr2ogr •ogrmerge.py
3. [SAGA-GIS](#saga-gis)  
4. [Dataset Examples](#dataset-examples)  
5. [Misc](#misc)  

### Scripts  
1. [GRASS scripts](https://github.com/gis-from-command-line/grass)   
2. [R scripts](https://github.com/gis-from-command-line/r)   
3. [Animating weather](https://github.com/gis-from-command-line/weather)   

### Other Repos  
1. [PostGIS Cookbook](https://github.com/geographyclub/postgis-cookbook)
2. [US Census](https://github.com/geographyclub/american-geography)

## GDAL

### gdalinfo

Lists information about a raster dataset. Read the [docs](https://gdal.org/programs/gdalinfo.html).

```
gdalinfo [--help] [--help-general]
         [-json] [-mm] [-stats | -approx_stats] [-hist]
         [-nogcp] [-nomd] [-norat] [-noct] [-nofl]
         [-checksum] [-listmdd] [-mdd <domain>|all]
         [-proj4] [-wkt_format {WKT1|WKT2|<other_format>}]...
         [-sd <subdataset>] [-oo <NAME>=<VALUE>]... [-if <format>]...
         <datasetname>
```

**Example**

Print histogram:  
```
file='topo15_4320.tif'
gdalinfo -hist ${file} | grep -A1 'buckets from' | tail -1 | xargs
```

Print width and height:  
```
file='topo15_4320.tif'
gdalinfo ${file} | grep "Size is" | sed 's/Size is //g' | sed 's/, / /g'
```

Print extent:  
```
file='topo15_4320.tif'
gdalinfo ${file} | grep -E '^Lower Left|^Upper Right' | sed -e 's/Upper Left  (//g' -e 's/Lower Left  (//g' -e 's/Upper Right (//g' -e 's/Lower Right (//g' -e 's/).*$//g' -e 's/,//g' | xargs
```

### gdalwarp

Image reprojection and warping utility. Read the [docs](https://gdal.org/programs/gdalwarp.html).

```
gdalwarp [--help] [--long-usage] [--help-general]
         [--quiet] [-overwrite] [-of <output_format>] [-co <NAME>=<VALUE>]... [-s_srs <srs_def>]
         [-t_srs <srs_def>]
         [[-srcalpha]|[-nosrcalpha]]
         [-dstalpha] [-tr <xres> <yres>|square] [-ts <width> <height>] [-te <xmin> <ymin> <max> <ymaX]
         [-te_srs <srs_def>] [-r near|bilinear|cubic|cubicspline|lanczos|average|rms|mode|min|max|med|q1|q3|sum]
         [-ot Byte|Int8|[U]Int{16|32|64}|CInt{16|32}|[C]Float{32|64}]
         <src_dataset_name>... <dst_dataset_name>

Advanced options:
         [-wo <NAME>=<VALUE>]... [-multi] [-s_coord_epoch <epoch>] [-t_coord_epoch <epoch>] [-ct <string>]
         [[-tps]|[-rpc]|[-geoloc]]
         [-order <1|2|3>] [-refine_gcps <tolerance> [<minimum_gcps>]] [-to <NAME>=<VALUE>]...
         [-et <err_threshold>] [-wm <memory_in_mb>] [-srcnodata <value>[ <value>...]]
         [-dstnodata <value>[ <value>...]] [-tap] [-wt Byte|Int8|[U]Int{16|32|64}|CInt{16|32}|[C]Float{32|64}]
         [-cutline <datasource>|<WKT>] [-cutline_srs <srs_def>] [-cwhere <expression>]
         [[-cl <layername>]|[-csql <query>]]
         [-cblend <distance>] [-crop_to_cutline] [-nomd] [-cvmd <meta_conflict_value>] [-setci]
         [-oo <NAME>=<VALUE>]... [-doo <NAME>=<VALUE>]... [-ovr <level>|AUTO|AUTO-<n>|NONE]
         [[-vshift]|[-novshiftgrid]]
         [-if <format>]... [-srcband <band>]... [-dstband <band>]...
```

**Example**

Resize raster:  
```
# assign new width and keep aspect ratio
file='topo15.grd'
width=4320
gdalwarp -overwrite -ts ${width} 0 -r cubicspline ${file} ${file%.*}_${width}.tif

# assign new resolution
file='HYP_HR_SR_OB_DR.tif'
xres=1
yres=1
gdalwarp -overwrite -tr ${xres} ${yres} -r cubicspline ${file} ${file%.*}_xres${xres}_yres${yres}.tif

# scale by a factor of original width
file='topo15_4320.tif'
factor=10
new_width=$(echo $(gdalinfo ${file}| grep "Size is" | sed 's/Size is //g' | sed 's/,.*$//g')/${factor} | bc)
gdalwarp -overwrite -ts ${new_width} 0 -r cubicspline ${file} ${file%.*}_${new_width}.tif
```

Reproject raster:  
```
# with epsg code, setting extent between -85° and 80° latitude for web mercator
file='hyp.tif'
proj='epsg:3857'
gdalwarp -overwrite -dstalpha --config OGR_ENABLE_PARTIAL_REPROJECTION TRUE -s_srs 'EPSG:4326' -t_srs ${proj} -te -180 -85 180 80 -te_srs 'EPSG:4326' ${file} ${file%.*}_epsg"${proj//:/_}".tif

# with proj definition
file='hyp.tif'
proj='+proj=times'
gdalwarp -overwrite -dstalpha --config OGR_ENABLE_PARTIAL_REPROJECTION TRUE -s_srs 'EPSG:4326' -t_srs "${proj}" ${file} ${file%.*}_"$(echo ${proj} | sed -e 's/+proj=//g' -e 's/ +.*$//g')".tif

# with custom proj definition using place name from natural earth
file='hyp.tif'
file_naturalearth='/home/steve/maps/naturalearth/packages/natural_earth_vector.gpkg'
name='Seoul'
xy=($(ogrinfo ${file_naturalearth} -sql "SELECT round(ST_X(ST_Centroid(geom))), round(ST_Y(ST_Centroid(geom))) FROM ne_10m_populated_places WHERE nameascii = '${name}'" | grep '=' | sed -e 's/^.*= //g'))
gdalwarp -overwrite -dstalpha --config OGR_ENABLE_PARTIAL_REPROJECTION TRUE -s_srs 'EPSG:4326' -t_srs '+proj=ortho +lat_0="'${xy[1]}'" +lon_0="'${xy[0]}'" +ellps='sphere'' ${file} ${file%.*}_ortho_"${xy[0]}"_"${xy[1]}".tif

# with custom proj definition using country centroid from natural earth
file='hyp.tif'
file_naturalearth='/home/steve/maps/naturalearth/packages/natural_earth_vector.gpkg'
name='Ukraine'
xy=($(ogrinfo ${file_naturalearth} -sql "SELECT round(ST_X(ST_Centroid(geom))), round(ST_Y(ST_Centroid(geom))) FROM ne_110m_admin_0_countries WHERE name = '${name}'" | grep '=' | sed -e 's/^.*= //g'))
gdalwarp -overwrite -dstalpha --config OGR_ENABLE_PARTIAL_REPROJECTION TRUE -s_srs 'EPSG:4326' -t_srs '+proj=ortho +lat_0="'${xy[1]}'" +lon_0="'${xy[0]}'" +ellps='sphere'' ${file} ${file%.*}_ortho_"${xy[0]}"_"${xy[1]}".tif
```

Some popular map projections and their PROJ definitions. Read the [docs](https://proj.org/en/9.4/operations/projections/index.html).  
| Name | PROJ |
|------|-------|
| Azimuthal Equidistant | +proj=aeqd +lat_0=45 +lon_0=-80 +a=1000000 +b=1000000 +over |
| Lambert Azimuthal Equal Area | +proj=laea +lat_0=0 +lon_0=0 +x_0=0 +y_0=0 +datum=WGS84 +units=m |
| Lambert Conformal Conic | +proj=lcc +lon_0=-90 +lat_1=33 +lat_2=45 |
| Stereographic | +proj=stere +lon_0=-119 +lat_0=36 +lat_ts=36 |
| Van der Grinten | +proj=vandg +lon_0=0 +x_0=0 +y_0=0 +R_A +a=6371000 +b=6371000 +units=m |
| Near perspective | +proj=nsper +h=300000 +lat_0=14 +lon_0=101 |
| Tilted Perspective | +proj=tpers +lat_0=40 +lon_0=0 +h=5500000 +tilt=45 +azi=0 |

Clip raster:  
```
# clip to extent of vector geometry and reproject
file='hyp.tif'
file_naturalearth='/home/steve/maps/naturalearth/packages/natural_earth_vector.gpkg'
name='North America'
extent=($(ogrinfo ${file_naturalearth} -sql "SELECT ROUND(ST_MinX(geom)), ROUND(ST_MinY(geom)), ROUND(ST_MaxX(geom)), ROUND(ST_MaxY(geom)) FROM (SELECT ST_Union(geom) geom FROM ne_110m_admin_0_countries WHERE CONTINENT = '${name}')" | grep '=' | sed -e 's/^.*= //g'))
gdalwarp -te ${extent[*]} ${file} /vsistdout/ | gdalwarp -overwrite -dstalpha --config OGR_ENABLE_PARTIAL_REPROJECTION TRUE -s_srs 'EPSG:4326' -t_srs 'ESRI:102010' /vsistdin/ ${file%.*}_extent_$(echo "${extent[@]}" | sed 's/ /_/g').tif

# clip to indian ocean and reproject
file='hyp.tif'
file_naturalearth='/home/steve/maps/naturalearth/packages/natural_earth_vector.gpkg'
name='INDIAN OCEAN'
xy=($(ogrinfo ${file_naturalearth} -sql "SELECT round(ST_X(ST_Centroid(geom))), round(ST_Y(ST_Centroid(geom))) FROM ne_110m_geography_marine_polys WHERE name = '${name}'" | grep '=' | sed -e 's/^.*= //g'))
gdalwarp -dstalpha -crop_to_cutline -cutline 'naturalearth/packages/natural_earth_vector.gpkg' -csql "SELECT geom FROM ne_110m_geography_marine_polys WHERE name = '${name}'" ${file} /vsistdout/ | gdalwarp -overwrite -dstalpha --config OGR_ENABLE_PARTIAL_REPROJECTION TRUE -s_srs 'EPSG:4326' -t_srs '+proj=ortho +lat_0="'${xy[1]}'" +lon_0="'${xy[0]}'" +ellps='sphere'' /vsistdin/ ${file%.*}_ortho_"${xy[0]}"_"${xy[1]}".tif

# clip to himalayas and reproject
file='hyp_hillshade.tif'
name='HIMALAYAS'
xy=($(ogrinfo naturalearth/packages/natural_earth_vector.gpkg -sql "SELECT round(ST_X(ST_Centroid(geom))), round(ST_Y(ST_Centroid(geom))) FROM ne_110m_geography_regions_polys WHERE name = '${name}'" | grep '=' | sed -e 's/^.*= //g'))
gdalwarp -overwrite -dstalpha --config OGR_ENABLE_PARTIAL_REPROJECTION TRUE -ts 1920 0 -s_srs 'EPSG:4326' -t_srs '+proj=ortho +lat_0="'${xy[1]}'" +lon_0="'${xy[0]}'" +ellps='sphere'' ${file} ${file%.*}_ortho_"${xy[0]}"_"${xy[1]}".tif
```

Set prime meridian:  
```
# for 0° to 360° raster
file='topo15_4320.tif'
pm=-360
gdalwarp -overwrite -s_srs 'EPSG:4326' -t_srs "+proj=longlat +ellps=WGS84 +pm=${pm} +datum=WGS84 +no_defs +lon_wrap=360 +over" ${file} ${file%.*}_${pm}pm.tif

# for -180° to 180° raster
file='topo15_4320.tif'
pm=180
gdalwarp -overwrite -ts 1920 0 -s_srs 'EPSG:4326' -t_srs "+proj=latlong +datum=WGS84 +pm=${pm}dE" ${file} ${file%.*}_${pm}pm.tif

# assign prime meridian by place name from natural earth
file='topo15_4320.tif'
file_naturalearth='/home/steve/maps/naturalearth/packages/natural_earth_vector.gpkg'
name='Toronto'
pm=$(ogrinfo ${file_naturalearth} -sql "SELECT round(ST_X(ST_Shift_Longitude(geom))) FROM ne_10m_populated_places WHERE nameascii = '${name}'" | grep '=' | sed -e 's/^.*= //g')
gdalwarp -overwrite -s_srs 'EPSG:4326' -t_srs "+proj=latlong +datum=WGS84 +pm=${pm}dE" ${file} ${file%.*}_${pm}pm.tif
```

Use *gdalwarp* to convert from GeoTIFF to regular TIFF (use with programs like imagemagick):  
```
gdalwarp -overwrite -dstalpha --config GDAL_PAM_ENABLED NO -co PROFILE=BASELINE -ts 1920 0 -f 'GTiff' -of 'GTiff' hyp.tif hyp_nogeo.tif
```

### gdal_translate

Converts raster data between different formats. Read the [docs](https://gdal.org/programs/gdal_translate.html).

```
gdal_translate [--help] [--help-general] [--long-usage]
   [-ot {Byte/Int8/Int16/UInt16/UInt32/Int32/UInt64/Int64/Float32/Float64/
         CInt16/CInt32/CFloat32/CFloat64}] [-strict]
   [-if <format>]... [-of <format>]
   [-b <band>] [-mask <band>] [-expand {gray|rgb|rgba}]
   [-outsize <xsize>[%]|0 <ysize>[%]|0] [-tr <xres> <yres>]
   [-ovr <level>|AUTO|AUTO-<n>|NONE]
   [-r {nearest,bilinear,cubic,cubicspline,lanczos,average,mode}]
   [-unscale] [-scale[_bn] [<src_min> <src_max> [<dst_min> <dst_max>]]]... [-exponent[_bn] <exp_val>]...
   [-srcwin <xoff> <yoff> <xsize> <ysize>] [-epo] [-eco]
   [-projwin <ulx> <uly> <lrx> <lry>] [-projwin_srs <srs_def>]
   [-a_srs <srs_def>] [-a_coord_epoch <epoch>]
   [-a_ullr <ulx> <uly> <lrx> <lry>] [-a_nodata <value>]
   [-a_gt <gt0> <gt1> <gt2> <gt3> <gt4> <gt5>]
   [-a_scale <value>] [-a_offset <value>]
   [-nogcp] [-gcp <pixel> <line> <easting> <northing> [<elevation>]]...
   |-colorinterp{_bn} {red|green|blue|alpha|gray|undefined}]
   |-colorinterp {red|green|blue|alpha|gray|undefined},...]
   [-mo <META-TAG>=<VALUE>]... [-dmo "DOMAIN:META-TAG=VALUE"]... [-q] [-sds]
   [-co <NAME>=<VALUE>]... [-stats] [-norat] [-noxmp]
   [-oo <NAME>=<VALUE>]...
   <src_dataset> <dst_dataset>
```

**Example**

Georeference raster:  
```
# to global extent
file='HYP_HR_SR_OB_DR_1024_512.png'
gdal_translate -a_ullr -180 90 180 -90 ${file} ${file%.*}_georeferenced.tif

# to specified extent
file=topo15_4320.tif
extent=($(gdalinfo ${file} | grep -E '^Lower Left|^Upper Right' | sed -e 's/Upper Left  (//g' -e 's/Lower Left  (//g' -e 's/Upper Right (//g' -e 's/Lower Right (//g' -e 's/).*$//g' -e 's/,//g' | xargs))
x_min=-180
x_max=180
y_min=-90
y_max=90
gdal_translate -gcp ${extent[0]} ${extent[1]} ${x_min} ${y_min} -gcp ${extent[0]} ${extent[3]} ${x_min} ${y_max} -gcp ${extent[2]} ${extent[3]} ${x_max} ${y_max} -gcp ${extent[2]} ${extent[1]} ${x_max} ${y_min} ${file} ${file%.*}_${x_min}_${x_max}_${y_min}_${y_max}.tif

# using ground control points
file='HYP_HR_SR_OB_DR_1024_512.png'
gdal_translate -gcp 0 0 -180 -90 -gcp 1024 512 180 90 -gcp 0 512 -180 90 -gcp 1024 0 180 -90 ${file} ${file%.*}_georeferenced.tif

# georeference and transform in one step
file='HYP_HR_SR_OB_DR_1024_512.png'
gdal_translate -a_ullr -180 90 180 -90 ${file} /vsistdout/ | gdalwarp -overwrite -s_srs 'EPSG:4326' -t_srs 'EPSG:3857' /vsistdin/ ${file%.*}_crs.tif
```

Clip raster using *gdal_translate* and reproject:  
```
file='HYP_HR_SR_OB_DR_1024_512.png'
gdal_translate -projwin -180 90 180 0 ${file} /vsistdout/ | gdalwarp -overwrite -dstalpha --config OGR_ENABLE_PARTIAL_REPROJECTION TRUE -s_srs 'EPSG:4326' -t_srs '+proj=stere +lat_0=90 +lat_ts_0' /vsistdin/ ${file%.*}_clipped_reprojected.tif
```

Resize and convert all tifs in the folder to JPEG2000:  
```
# without metadata
width=1920
ls *.tif | while read file; do
  gdal_translate -ot Int16 -of 'JP2OpenJPEG' -outsize ${width} 0 ${file} ${file%.*}.jp2
done

# with metadata
width=1920
ls *.tif | while read file; do
  gdal_translate -ot Int16 -of 'JP2OpenJPEG' -mo "ATTRIBUTION_LICENSE=CC BY-SA 4.0" -outsize 1920 0 ${file} ${file%.*}.jp2
done
```

### gdal_contour

Builds vector contour lines from a raster elevation model. Read the [docs](https://gdal.org/programs/gdal_contour.html).

```
gdal_contour [--help] [--help-general]
             [-b <band>] [-a <attribute_name>] [-amin <attribute_name>] [-amax <attribute_name>]
             [-3d] [-inodata] [-snodata <n>] [-f <formatname>] [-i <interval>]
             [-dsco <NAME>=<VALUE>]... [-lco <NAME>=<VALUE>]...
             [-off <offset>] [-fl <level> <level>...] [-e <exp_base>]
             [-nln <outlayername>] [-q] [-p]
             <src_filename> <dst_filename>
```

**Example**

Make contours from topo:  
```
# polygons
file='/home/steve/maps/srtm/topo15.grd'
interval=100
gdal_contour -p -f "GPKG" -amin amin -amax amax -i ${interval} ${file} ${file%.*}_${interval}m_polygon.gpkg

# set interval
file='/home/steve/maps/srtm/topo15.grd'
interval=100
gdal_contour --config GDAL_CACHEMAX 500 -f "GPKG" -a meters -i ${interval} ${file} ${file%.*}_${interval}m.gpkg

# set interval and export to postgis
file='/home/steve/maps/srtm/topo15.grd'
interval=100
gdal_contour --config GDAL_CACHEMAX 500 -f "PostgreSQL" -a elev -i 10 ${file} PG:dbname=world ${file%.*}_${interval}m

# set level and export to csv
file='/home/steve/maps/srtm/topo15.grd'
level=500
gdal_contour --config GDAL_CACHEMAX 500 -lco GEOMETRY=AS_WKT -f "CSV" -a elev -fl ${level} ${file} ${file%.*}_${level}m.csv
```

### gdaldem

Tools to analyze and visualize DEMs. Read the [docs](https://gdal.org/programs/gdaldem.html).  

### gdaldem hillshade

Generate a shaded relief map.

```
gdaldem hillshade <input_dem> <output_hillshade>
            [-z <zfactor>] [-s <scale>]
            [-az <azimuth>] [-alt <altitude>]
            [-alg ZevenbergenThorne] [-combined | -multidirectional | -igor]
            [-compute_edges] [-b <Band>] [-of <format>] [-co <NAME>=<VALUE>]... [-q]
```

**Example**

```
file='topo15_4320.tif'
zfactor=100
azimuth=315
altitude=45
gdaldem hillshade -combined -z ${zfactor} -s 111120 -az ${azimuth} -alt ${altitude} -compute_edges ${file} ${file%.*}_hillshade.tif
```

Loop hillshade:  
```
file='topo15_4320.tif'
for a in $(seq 0 10 90); do
  zfactor=100
  azimuth=315
  altitude=${a}
  gdaldem hillshade -combined -z ${zfactor} -s 111120 -az ${azimuth} -alt ${altitude} -compute_edges ${file} ${file%.*}_altitude${a}.tif
done
```

### gdaldem slope

Generate a slope map.
  
```
gdaldem slope <input_dem> <output_slope_map>
            [-p] [-s <scale>]
            [-alg ZevenbergenThorne]
            [-compute_edges] [-b <band>] [-of <format>] [-co <NAME>=<VALUE>]... [-q]
```

**Example**

```
file='/home/steve/maps/srtm/topo15_43200.tif'
gdaldem slope -compute_edges -s 111120 ${file} ${file%.*}_slope.tif
```

### gdaldem aspect

Generate an aspect map, outputs a 32-bit float raster with pixel values from 0-360 indicating azimuth.

```
gdaldem aspect <input_dem> <output_aspect_map>
            [-trigonometric] [-zero_for_flat]
            [-alg ZevenbergenThorne]
            [-compute_edges] [-b <band>] [-of format] [-co <NAME>=<VALUE>]... [-q]
```

**Example**

```
file='/home/steve/maps/srtm/topo15.grd'
gdaldem aspect -compute_edges ${file} ${file%.*}_aspect.tif
```

### gdaldem color-relief

Generate a color relief map.

```
gdaldem color-relief <input_dem> <color_text_file> <output_color_relief_map>
             [-alpha] [-exact_color_entry | -nearest_color_entry]
             [-b <band>] [-of format] [-co <NAME>=<VALUE>]... [-q]

where color_text_file contains lines of the format "elevation_value red green blue"
```

**Example**

Color DEM with color file, eg. white-black.txt:  
```
file='/home/steve/Projects/maps/srtm/N43W080_wgs84.tif'
gdaldem color-relief -alpha -f 'GRIB' -of 'GTiff' ${file} "white-black.txt" /vsistdout/ | gdalwarp -overwrite -dstalpha -f 'GTiff' -of 'GTiff' -s_srs 'EPSG:4326' -t_srs 'EPSG:3857' -ts 500 250 /vsistdin/ ${file%.*}_color.tif
```

### gdal_polygonize.py

Produces a polygon feature layer from a raster. Read the [docs](https://gdal.org/programs/gdal_polygonize.html).  

```
gdal_polygonize.py [--help] [--help-general]
                   [-8] [-o <name>=<value>]... [-nomask]
                   [-mask <filename>] <raster_file> [-b <band>]
                   [-q] [-f <ogr_format>] [-lco <name>=<value>]...
                   [-overwrite] <out_file> [<layer>] [<fieldname>]
```

**Example**

```
file='topo15_4320_hillshade_mask.tif'
gdal_polygonize.py ${file} ${file%.*}.gpkg ${file%.*}

# with mask
file='topo15_432.tif'
rm -rf ${file%.*}.gpkg
gdal_polygonize.py -mask ~/maps/naturalearth/packages/misc/land_mask.tif ${file} ${file%.*}.gpkg ${file%.*}

# polygonize label image then union letters
gdal_polygonize.py toronto_labels.tif toronto_labels.gpkg 
ogr2ogr -overwrite toronto_labels_union.gpkg -sql 'SELECT ST_Union(geom) geom FROM out' toronto_labels.gpkg
```

### gdal_rasterize

Burns vector geometries into a raster. Read the [docs](https://gdal.org/programs/gdal_rasterize.html).

```
gdal_rasterize [--help] [--help-general]
    [-b <band>]... [-i] [-at]
    [-oo <NAME>=<VALUE>]...
    {[-burn <value>]... | [-a <attribute_name>] | [-3d]} [-add]
    [-l <layername>]... [-where <expression>] [-sql <select_statement>|@<filename>]
    [-dialect <dialect>] [-of <format>] [-a_srs <srs_def>] [-to <NAME>=<VALUE>]...
    [-co <NAME>=<VALUE>]... [-a_nodata <value>] [-init <value>]...
    [-te <xmin> <ymin> <xmax> <ymax>] [-tr <xres> <yres>] [-tap] [-ts <width> <height>]
    [-ot {Byte/Int8/Int16/UInt16/UInt32/Int32/UInt64/Int64/Float32/Float64/
         CInt16/CInt32/CFloat32/CFloat64}] [-optim {AUTO|VECTOR|RASTER}] [-q]
    <src_datasource> <dst_filename>
```

**Example**

Rasterize vectors:  
```
gdal_rasterize PG:"dbname=osm" -l planet_osm_polygon -a levels -where "levels IS NOT NULL" -at /home/steve/Projects/maps/osm/${city}/${city}_buildings.tif

# give pixel size
gdal_rasterize -tr 1 1 -ts 1024 512 -a_nodata 0 -burn 1 -l ne_10m_land natural_earth_vector.gpkg ne_10m_land.tif

# burn examples
gdal_rasterize -at -add -burn -100 -where "highway IN ('motorway','trunk','primary')" PG:"dbname=osm" -l ${layer} ${file%.*}_360_3600_epsg3857_highways.tif

gdal_rasterize -at -add -burn -1 -sql "SELECT ST_Buffer(wkb_geometry,100) FROM ${layer} WHERE highway IN ('motorway','trunk','primary')" PG:"dbname=osm" ${file%.*}_360_3600_epsg3857_highways.tif
```

Use rasterize to grid features:  
```
gdal_rasterize -at -tr 0.01 0.01 -l ACS_2019_5YR_TRACT ACS_2019_5YR_TRACT.gdb -a GEOID -a_nodata NA ACS_2019_5YR_TRACT_001.tif
gdal_polygonize.py -8 -f "GPKG" ACS_2019_5YR_TRACT_001.tif ACS_2019_5YR_TRACT_001.gpkg ACS_2019_5YR_TRACT_001 GEOID
```

Use rasterize to create a binary mask  
```
gdal_rasterize -burn 1 -ts 432 216 -l ne_110m_land ~/maps/naturalearth/packages/natural_earth_vector.gpkg ~/maps/naturalearth/packages/misc/land_mask.tif
```

### gdal_calc.py

Command line raster calculator with numpy syntax. Read the [docs](https://gdal.org/programs/gdal_calc.html).

```
gdal_calc.py [--help] [--help-general]
             --calc=expression --outfile=<out_filename> [-A <filename>]
             [--A_band=<n>] [-B...-Z <filename>] [<other_options>]
```

**Example**

Raster math with *gdal_calc*:  
```
# create empty raster
gdal_calc.py --overwrite -A N43W080_3857.tif --outfile="empty.tif" --calc="0"

# add rasters
gdal_calc.py --overwrite -A ${dem%_wgs84.tif}_3857.tif -B ${city}/${city}_buildings.tif --outfile="${city}/${city}_dembuildings.tif" --calc="((A>=0)*A)+((A<0)*A*-0.1)+(B*20)"
gdal_calc.py --overwrite -A N43W080_3857.tif -B buildings.tif --outfile="N43W080_3857_buildings.tif" --calc="A+(B*20)"

# slice raster
gdal_calc.py --overwrite --NoDataValue=0 -A topo15_43200_slope.tif --outfile topo15_43200_slope1.tif --calc="A*(A>=1)"
gdal_calc.py -A input.tif --outfile=result.tif --calc="A*logical_and(A>100,A<150)"
# slicing with a loop
for a in $(seq 1 100 5000); do
  gdal_calc.py --NoDataValue=0 -A ${dem} --outfile ${dir}/$(basename ${dem%.*}_${a}.tif) --calc="0*(A<0)" --calc="${a}*(A>=${a})"
done

# round values
gdal_calc.py --overwrite -A topo15_43200.tif --outfile topo15_43200_rounded1000.tif --type 'Int16' --calc="A*0.001"

# create raster mask
gdal_calc.py -A worldclim/wc2.0_bio_30s_15.tif --outfile=wc2.0_bio_30s_15_mask.tif --overwrite --type=Int16 --NoDataValue=0 --calc="1*(A>0)"
gdal_calc.py -A topo15_43200_tmp.tif -B worldclim/wc2.0_bio_30s_15_mask.tif --outfile=topo15_43200_slope.tif --overwrite --type=Float32 --NoDataValue=0 --co=TILED=YES --co=COMPRESS=LZW --calc="A*(B>0)"

# create binary raster
gdal_calc.py -A topo15_004_0004_lev01_hillshade.tif --outfile=topo15_004_0004_hillshade_binary.tif --overwrite --type=Int16 --calc="1*(A<2)"

# create binary raster (null)
gdal_calc.py -A topo15_004_0004_lev01_hillshade.tif --outfile=topo15_004_0004_hillshade_mask.tif --overwrite --type=Int16 --NoDataValue=0 --calc="1*(A<2)"

# misc
gdal_calc.py --overwrite -A topo15_down.tif --outfile dem.tif --NoDataValue=0 --calc="0*(A<0)" --calc="(A/A)*(A>=0)"
gdal_calc.py --overwrite -A temp.nc -B dem.tif --outfile temp_calc.tif --calc="trunc(A/${denominator})*(B==1)"
```

Multiply Natural Earth with shaded relief rasters:  
```
gdal_calc.py --overwrite -A topo_hillshade.tif -B hyp.tif --allBands B --outfile=hyp_hillshade.tif --calc="((A - numpy.min(A)) / (numpy.max(A) - numpy.min(A))) * B"
```

### gdal_grid

Creates regular grid from the scattered data. Read the [docs](https://gdal.org/programs/gdal_grid.html).

```
gdal_grid [--help] [--help-general]
          [-ot {Byte/Int16/UInt16/UInt32/Int32/Float32/Float64/
          CInt16/CInt32/CFloat32/CFloat64}]
          [-oo <NAME>=<VALUE>]...
          [-of <format>] [-co <NAME>=<VALUE>]...
          [-zfield <field_name>] [-z_increase <increase_value>] [-z_multiply <multiply_value>]
          [-a_srs <srs_def>] [-spat <xmin> <ymin> <xmax> <ymax>]
          [-clipsrc <xmin> <ymin> <xmax> <ymax>|<WKT>|<datasource>|spat_extent]
          [-clipsrcsql <sql_statement>] [-clipsrclayer <layer>]
          [-clipsrcwhere <expression>]
          [-l <layername>]... [-where <expression>] [-sql <select_statement>]
          [-txe <xmin> <xmax>] [-tye <ymin> <ymax>] [-tr <xres> <yres>] [-outsize <xsize> <ysize>]
          [-a {<algorithm>[[:<parameter1>=<value1>]...]}] [-q]
          <src_datasource> <dst_filename>
```

**Example**

Make grid from points using VRT and gdal_grid:  
```
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

### gdallocationinfo

Raster query tool. Read the [docs](https://gdal.org/programs/gdallocationinfo.html).

```
Usage: gdallocationinfo [--help] [--help-general]
                        [-xml] [-lifonly] [-valonly]
                        [-E] [-field_sep <sep>] [-ignore_extra_input]
                        [-b <band>]... [-overview <overview_level>]
                        [[-l_srs <srs_def>] | [-geoloc] | [-wgs84]]
                        [-oo <NAME>=<VALUE>]... <srcfile> [<x> <y>]
```

**Example**

Sample weather grid at coordinates in csv file:  
```
grid='/home/steve/maps/srtm/topo15.grd'
coordinates='/home/steve/maps/places.csv'
echo "scalerank,name,lat,lon,rownum,temp" > ${coordinates%.*}_values.csv
cat ${file} | while read line; do
  coord=`echo "$line" | awk -F '\t' '{print $23,$22}'`
  temp=`gdallocationinfo -wgs84 -valonly ${grid} $coord`
  echo -e "$line""\t""$temp" | awk -F '\t' '{print $1,$9,$22,$23,$38,$39}' OFS=',' >> ${file%.*}_values.csv
done
```

## OGR

### ogrinfo

Lists information about an OGR-supported data source. With SQL statements it is also possible to edit data. Read the [docs](https://gdal.org/programs/ogrinfo.html).

```
ogrinfo [--help] [--help-general]
        [-if <driver_name>] [-json] [-ro] [-q] [-where <restricted_where>|@f<ilename>]
        [-spat <xmin> <ymin> <xmax> <ymax>] [-geomfield <field>] [-fid <fid>]
        [-sql <statement>|@<filename>] [-dialect <sql_dialect>] [-al] [-rl]
        [-so|-features] [-limit <nb_features>] [-fields={YES|NO}]]
        [-geom={YES|NO|SUMMARY|WKT|ISO_WKT}] [-oo <NAME>=<VALUE>]...
        [-nomd] [-listmdd] [-mdd <domain>|all]...
        [-nocount] [-nogeomtype] [[-noextent] | [-extent3D]]
        [-wkt_format WKT1|WKT2|<other_values>]
        [-fielddomain <name>]
        <datasource_name> [<layer> [<layer> ...]]
```

**Example**

Print tables/layers:  
```
# list tables using *sqlite_master* or *sqlite_schema*
ogrinfo -dialect sqlite -sql 'SELECT tbl_name FROM sqlite_master' natural_earth_vector.gpkg
ogrinfo -dialect sqlite -sql 'SELECT tbl_name FROM sqlite_schema' natural_earth_vector.gpkg

# list tables with sql wildcard
ogrinfo -sql "SELECT tbl_name FROM sqlite_master WHERE name like 'ne_10m%'" natural_earth_vector.gpkg

# list tables prettily
ogrinfo -so natural_earth_vector.gpkg | grep '^[0-9]' | grep 'ne_110m' | sed -e 's/^.*: //g' -e 's/ .*$//g'

# list tables with certain geom type
ogrinfo -sql "SELECT name FROM sqlite_master WHERE name like 'ne_50m%'" natural_earth_vector.gpkg | grep '=' | sed -e 's/^.*= //g' | while read table; do geomtype=$(ogrinfo -sql "SELECT GeometryType(geom) FROM ${table};" natural_earth_vector.gpkg | grep '=' | sed 's/^.*= //g'); if [[ ${geomtype} =~ 'POLYGON' ]]; then echo ${table}; fi; done
```

Operations with *ogrinfo*:  
```
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

Export with *ogrinfo*:  
```
ogrinfo --config SPATIALITE_SECURITY=relaxed -dialect Spatialite -sql "SELECT ExportGeoJSON2('ne_110m_admin_0_countries', 'geom', 'ne_110m_admin_o_countries.geojson')" natural_earth_vector.gpkg
```

Export features to svg using *ogrinfo*:  
```
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

Convert all 50m polygon layers:  
```
name='ne_50m_admin_0'
mkdir svg
ogrinfo -sql "SELECT name FROM sqlite_master WHERE name like '${name}%'" natural_earth_vector.gpkg | grep '=' | sed -e 's/^.*= //g' | while read layer; do
  geomtype=$(ogrinfo -sql "SELECT GeometryType(geom) FROM ${layer};" natural_earth_vector.gpkg | grep '=' | sed 's/^.*= //g')
  if [[ ${geomtype} =~ 'POLYGON || MULTIPOLYGON' ]]; then
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

### ogr2ogr

Converts simple features data between file formats. Read the [docs](https://gdal.org/programs/ogr2ogr.html).

```
ogr2ogr [--help] [--long-usage] [--help-general]
        [-of <output_format>] [-dsco <NAME>=<VALUE>]... [-lco <NAME>=<VALUE>]...
        [[-append]|[-upsert]|[-overwrite]]
        [-update] [-sql <statement>|@<filename>] [-dialect <dialect>] [-spat <xmin> <ymin> <xmax> <ymax>]
        [-where <restricted_where>|@<filename>] [-select <field_list>] [-nln <name>] [-nlt <type>]...
        [-s_srs <srs_def>]
        [[-a_srs <srs_def>]|[-t_srs <srs_def>]]
        <dst_dataset_name> <src_dataset_name> [<layer_name>]...

Field related options:
       [-addfields] [-relaxedFieldNameMatch] [-fieldTypeToString All|<type1>[,<type2>]...]
       [-mapFieldType <srctype>|All=<dsttype>[,<srctype2>=<dsttype2>]...] [-fieldmap <field_1>[,<field_2>]...]
       [-splitlistfields] [-maxsubfields <n>] [-emptyStrAsNull] [-forceNullable] [-unsetFieldWidth]
       [-unsetDefault] [-resolveDomains] [-dateTimeTo UTC|UTC(+|-)<HH>|UTC(+|-)<HH>:<MM>] [-noNativeData]

Advanced geometry and SRS related options:
       [-dim layer_dim|2|XY|3|XYZ|XYM|XYZM] [-s_coord_epoch <epoch>] [-a_coord_epoch <epoch>]
       [-t_coord_epoch <epoch>] [-ct <pipeline_def>] [-spat_srs <srs_def>] [-geomfield <name>]
       [-segmentize <max_dist>] [-simplify <tolerance>] [-makevalid] [-wrapdateline]
       [-datelineoffset <val_in_degree>]
       [-clipsrc [<xmin> <ymin> <xmax> <ymax>]|<WKT>|<datasource>|spat_extent]
       [-clipsrcsql <sql_statement>] [-clipsrclayer <layername>] [-clipsrcwhere <expression>]
       [-clipdst [<xmin> <ymin> <xmax> <ymax>]|<WKT>|<datasource>] [-clipdstsql <sql_statement>]
       [-clipdstlayer <layername>] [-clipdstwhere <expression>] [-explodecollections] [-zfield <name>]
       [-gcp <ungeoref_x> <ungeoref_y> <georef_x> <georef_y> [<elevation>]]...
       [-tps] [-order 1|2|3]
       [-xyRes <val>[ m|mm|deg]] [-zRes <val>[ m|mm]] [-mRes <val>] [-unsetCoordPrecision]

Other options:
       [--quiet] [-progress] [-if <format>]... [-oo <NAME>=<VALUE>]... [-doo <NAME>=<VALUE>]...
       [-fid <FID>] [-preserve_fid] [-unsetFid]
       [[-skipfailures]|[-gt <n>|unlimited]]
       [-limit <nb_features>] [-ds_transaction] [-mo <NAME>=<VALUE>]... [-nomd]
```

**Example**

Pipe to ogrinfo:  
```
ogr2ogr -overwrite -skipfailures --config OGR_ENABLE_PARTIAL_REPROJECTION TRUE -f GeoJSON -s_srs 'epsg:4326' -t_srs "+proj=ortho" /vsistdout/ -nln ${layer1} PG:dbname=world ${layer1} | ogrinfo -dialect sqlite -sql "SELECT X(Centroid(geometry)), Y(Centroid(geometry)) FROM ${layer1}" /vsistdin/
```

Select layer:  
```
ogr2ogr -overwrite -f 'GPKG' -s_srs 'EPSG:4326' -t_srs 'EPSG:4326' countries.gpkg naturalearth/packages/ne_110m_admin_0_boundary_lines_land_coastline_split1.gpkg countries
```

Transform from lat-long to ortho projection:  
```
file='countries.gpkg'
layer='countries'
name='Cairo'
xy=($(ogrinfo naturalearth/packages/natural_earth_vector.gpkg -sql "SELECT round(ST_X(ST_Centroid(geom))), round(ST_Y(ST_Centroid(geom))) FROM ne_10m_populated_places WHERE nameascii = '${name}'" | grep '=' | sed -e 's/^.*= //g'))
ogr2ogr -overwrite -skipfailures --config OGR_ENABLE_PARTIAL_REPROJECTION TRUE -s_srs 'EPSG:4326' -t_srs '+proj=ortho +lat_0="'${xy[1]}'" +lon_0="'${xy[0]}'" +ellps='sphere'' ${layer}_ortho_"${xy[0]}"_"${xy[1]}".gpkg ${file} ${layer}
```

Loop ortho projection:  
```
rm -rf points1/*
for x in $(seq -180 10 -160); do
  for y in $(seq -90 10 -70); do
    proj='+proj=ortho +lat_0='"${y}"' +lon_0='"${x}"' +ellps=sphere'
    ogr2ogr -overwrite -skipfailures --config OGR_ENABLE_PARTIAL_REPROJECTION TRUE -s_srs 'epsg:4326' -t_srs "${proj}" -nln points1_${x}_${y} points1/points1_${x}_${y}.gpkg points1.gpkg points1
  done
done
```

Center the orthographic projection on the centroid of given country:  
```
file='countries.gpkg'
layer='countries'
name='Brazil'
xy=($(ogrinfo naturalearth/packages/natural_earth_vector.gpkg -sql "SELECT round(ST_X(ST_Centroid(geom))), round(ST_Y(ST_Centroid(geom))) FROM ne_110m_admin_0_countries WHERE name = '${name}'" | grep '=' | sed -e 's/^.*= //g'))
ogr2ogr -overwrite -skipfailures --config OGR_ENABLE_PARTIAL_REPROJECTION TRUE -s_srs 'EPSG:4326' -t_srs '+proj=ortho +lat_0="'${xy[1]}'" +lon_0="'${xy[0]}'" +ellps='sphere'' ${layer}_ortho_"${xy[0]}"_"${xy[1]}".gpkg ${file} ${layer}
```

Clip and reproject vector and raster data to the same extent:  
```
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

Perform spatial operation using sql:  
```
ogr2ogr -overwrite -f "SQLite" -dsco SPATIALITE=YES -lco OVERWRITE=YES -dialect sqlite -sql "SELECT elev, ST_MakePolygon(GEOMETRY) FROM topo15_43200 WHERE elev IN (-10000,-9000,-8000,-7000,-6000,-5000,-4000,-3000,-2000,-1000,-900,-800,-700,-600,-500,-400,-300,-200,-100,0,100,200,300,400,500,600,700,800,900,1000,1500,2000,2500,3000,3500,4000,4500,5000,5500,6000,6500,7000,7500,8000);" /home/steve/maps/srtm/srtm15/topo15_43200_polygon.sqlite -t_srs "EPSG:4326" -nlt POLYGON -nln topo15_43200_polygon -explodecollections /home/steve/maps/srtm/srtm15/topo15_43200.sqlite
```

Add m values:  
```
ogr2ogr -f 'GPKG' -dim XYM -zfield 'CATCH_SKM' /home/steve/maps/wwf/hydroatlas/RiverATLAS_v10_xym.gpkg /home/steve/maps/wwf/hydroatlas/RiverATLAS_v10.gdb RiverATLAS_v10
```

Reproject with gcp (city-on-a-globe):  
```
file=Chicago.osm.pbf
layer=lines
extent=($(ogrinfo -so ${file} ${layer} | grep 'Extent' | sed -e 's/Extent: //g' -e 's/(\|)//g' -e 's/ - /, /g' -e 's/, / /g'))
x_min=-20
x_max=20
y_min=80
y_max=90
ogr2ogr -overwrite -gcp ${extent[0]} ${extent[1]} ${x_min} ${y_min} -gcp ${extent[0]} ${extent[3]} ${x_min} ${y_max} -gcp ${extent[2]} ${extent[3]} ${x_max} ${y_max} -gcp ${extent[2]} ${extent[1]} ${x_max} ${y_min} ${file%.osm.pbf}_${x_min}_${x_max}_${y_min}_${y_max}.gpkg ${file}
```

Reproject with gcp (match extent from layer):  
```
table1=toronto
table2=newyork
layer=lines

# query psql
extent1=($(psql -d osm -c "COPY (SELECT ST_XMin(ST_Extent(wkb_geometry)), ST_XMax(ST_Extent(wkb_geometry)), ST_YMin(ST_Extent(wkb_geometry)), ST_YMax(ST_Extent(wkb_geometry)) FROM ${table1}_${layer} WHERE "highway" IS NOT NULL) TO STDOUT DELIMITER E'\t'"))
extent2=($(psql -d osm -c "COPY (SELECT ST_XMin(ST_Extent(wkb_geometry)), ST_XMax(ST_Extent(wkb_geometry)), ST_YMin(ST_Extent(wkb_geometry)), ST_YMax(ST_Extent(wkb_geometry)) FROM ${table2}_${layer} WHERE "highway" IS NOT NULL) TO STDOUT DELIMITER E'\t'"))

ogr2ogr -overwrite -gcp ${extent2[0]} ${extent2[1]} ${extent1[0]} ${extent1[1]} -gcp ${extent2[0]} ${extent2[3]} ${extent1[0]} ${extent1[3]} -gcp ${extent2[2]} ${extent2[3]} ${extent1[2]} ${extent1[3]} -gcp ${extent2[2]} ${extent2[1]} ${extent1[2]} ${extent1[1]} pg:dbname=osm -nln ${table1}_${table2}_${layer} pg:dbname=osm ${table2}_${layer}
```

Create vector tiles (MVT):  
```
# single layer
# -lco TILE_FEATURE_LIMIT=5000
ogr2ogr -f MVT vector-tiles PG:dbname=world -sql "SELECT upland_skm, ST_ChaikinSmoothing(shape, 1) shape FROM riveratlas_v10 WHERE upland_skm >= 1000" -nlt LINESTRING -nln rivers -dsco MINZOOM=0 -dsco MAXZOOM=15 -dsco COMPRESS=NO -dsco SIMPLIFICATION=0.0 -dsco SIMPLIFICATION_MAX_ZOOM=0.0 -explodecollections

# multiple layers at different zoom levels
ogr2ogr -f MVT vector-tiles-10000 PG:dbname=world -sql "SELECT upland_skm, ST_ChaikinSmoothing(shape, 1) shape FROM riveratlas_v10 WHERE upland_skm >= 10000" -nlt LINESTRING -nln rivers -dsco MINZOOM=0 -dsco MAXZOOM=2 -dsco COMPRESS=NO -dsco SIMPLIFICATION=0.0 -dsco SIMPLIFICATION_MAX_ZOOM=0.0 -explodecollections
ogr2ogr -f MVT vector-tiles-1000 PG:dbname=world -sql "SELECT upland_skm, ST_ChaikinSmoothing(shape, 1) shape FROM riveratlas_v10 WHERE upland_skm >= 1000" -nlt LINESTRING -nln rivers -dsco MINZOOM=3 -dsco MAXZOOM=4 -dsco COMPRESS=NO -dsco SIMPLIFICATION=0.0 -dsco SIMPLIFICATION_MAX_ZOOM=0.0 -explodecollections
ogr2ogr -f MVT vector-tiles-100 PG:dbname=world -sql "SELECT upland_skm, ST_ChaikinSmoothing(shape, 1) shape FROM riveratlas_v10 WHERE upland_skm >= 100" -nlt LINESTRING -nln rivers -dsco MINZOOM=5 -dsco MAXZOOM=6 -dsco COMPRESS=NO -dsco SIMPLIFICATION=0.0 -dsco SIMPLIFICATION_MAX_ZOOM=0.0 -explodecollections
```

### ogrmerge.py

Merge several vector datasets into a single one. Read the [docs](https://gdal.org/programs/ogrmerge.html).

```
ogrmerge.py [--help] [--help-general]
            -o <out_dsname> <src_dsname> [<src_dsname>]...
            [-f format] [-single] [-nln <layer_name_template>]
            [-update | -overwrite_ds] [-append | -overwrite_layer]
            [-src_geom_type <geom_type_name>[,<geom_type_name>]...]
            [-dsco <NAME>=<VALUE>]... [-lco <NAME>=<VALUE>]...
            [-s_srs <srs_def>] [-t_srs <srs_def> | -a_srs <srs_def>]
            [-progress] [-skipfailures] [--help-general]
```

**Example**

Merge layers with VRT file:  
```
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
```
saga_cmd --cores 1
```

Classify  
```
saga_cmd imagery_classification 1 -NCLUSTER 20 -MAXITER 0 -METHOD 1 -GRIDS N43W080_wgs84_500_5000.tif -CLUSTER N43W080_wgs84_500_5000_cluster.tif
```

Watershed  
```
saga_cmd imagery_segmentation 0 -OUTPUT 0 -DOWN 1 -JOIN 0 -THRESHOLD 0 -EDGE 1 -BBORDERS 0 -GRID N43W080_wgs84_500.tif -SEGMENTS N43W080_wgs84_500_segments.tif

saga_cmd ta_channels 5 -THRESHOLD 1 -DEM N43W080_wgs84_500.tif -SEGMENTS N43W080_wgs84_500_segments.shp -BASINS N43W080_wgs84_500_basins.shp
```

Raster to polygons  
```
saga_cmd shapes_grid 6 -GRID N43W080_wgs84.tif -POLYGONS N43W080_wgs84.shp
```

Raster values to vector  
```
saga_cmd shapes_grid 0

saga_cmd shapes_grid 1
```

Arrows  
```
saga_cmd shapes_grid 15 -SURFACE N43W080_wgs84_500.tif -VECTORS N43W080_wgs84_500_gradient.shp
```

Vector processing  
```
saga_cmd shapes_lines

saga_cmd shapes_points

saga_cmd shapes_polygons
```

Smoothing  
```
saga_cmd shapes_lines 7 -SENSITIVITY 3 -ITERATIONS 10 -PRESERVATION 10 -SIGMA 2 -LINES_IN N43W080_wgs84_500_segments.shp -LINES_OUT N43W080_wgs84_500_segments_smooth.shp
```

Landscape  
```
saga_cmd ta_compound 0 -THRESHOLD 1 -ELEVATION N43W080_wgs84_500.tif -SHADE N43W080_wgs84_500_shade.tif -CHANNELS N43W080_wgs84_500_channels.shp -BASINS N43W080_wgs84_500_basins.shp
```

Terrain  
```
saga_cmd ta_morphometry 16 -DEM N43W080_wgs84_500.tif -TRI N43W080_wgs84_500_tri.shp

saga_cmd ta_morphometry 17 -DEM N43W080_wgs84_500.tif -VRM N43W080_wgs84_500_vrm.tif

saga_cmd ta_morphometry 18 -DEM N43W080_wgs84_500.tif -TPI N43W080_wgs84_500_tpi.tif
```

TIN  
```
saga_cmd tin_tools 0 -GRID N48W092_N47W092_N48W091_N47W091_smooth.tif -TIN N48W092_N47W092_N48W091_N47W091_tin.shp

saga_cmd tin_tools 3 -TIN N48W092_N47W092_N48W091_N47W091_tin.shp -POLYGONS N48W092_N47W092_N48W091_N47W091_poly.shp
```

## Dataset Examples

### ALOS
```
# download from https://www.eorc.jaxa.jp/ALOS/en/dataset/aw3d30/aw3d30_e.htm

# alos merge directory
dir=N005E095_N010E100
gdal_merge.py `ls ${dir}/*_DSM.tif` -o ${dir}.tif

# smooth
gdalwarp -s_srs 'EPSG:4326' -t_srs 'EPSG:4326' -ts $(echo $(gdalinfo ${dir}.tif | grep "Size is" | sed 's/Size is //g' | sed 's/,.*$//g')/10 | bc) 0 -r cubicspline ${dir}.tif /vsistdout/ | gdalwarp -overwrite -s_srs 'EPSG:4326' -t_srs 'EPSG:4326' -ts $(echo $(gdalinfo ${dir}.tif | grep "Size is" | sed 's/Size is //g' | sed 's/,.*$//g') | bc) 0 -r cubicspline /vsistdin/ ${dir}_smooth.tif

# contours
gdal_contour -a meters -i 10 ${dir}.tif ${dir}_contours.gpkg -nln contours
gdal_contour -p -amin amin -amax amax -i 10 ${dir}.tif ${dir}_contours_polygons.gpkg -nln contours

# contour slices
gdal_contour -p -amin amin -amax amax -fl 100 topo15_4320_43200.tif topo15_4320_43200_polygons.gpkg

# hillshade
gdaldem hillshade -z 1 -az 315 -alt 45 ${dir}.tif ${dir}_hillshade.tif
gdal_calc.py --overwrite --NoDataValue=0 -A ${dir}_hillshade.tif --calc="1*(A<=2)" --out=${dir}_hillshade_mask.tif
gdal_polygonize.py ${dir}_hillshade_mask.tif ${dir}_hillshade_polygon.gpkg hillshade_polygon
```

### Natural Earth  

OGR/BASH scripts to work with Natural Earth vectors (download the data here: https://naciscdn.org/naturalearth/packages/natural_earth_vector.gpkg.zip)  
```
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

```
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

```
#==================# 
# earth-to-geojson #
#==================#

### select layer to convert ###
layer=ne_110m_admin_0_countries

### convert ###
ogr2ogr -f GeoJSON ${layer}.geojson natural_earth_vector.gpkg ${layer}
```

```
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

```
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

```
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

```
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

```
# osm data online
wget -O muenchen.osm "https://api.openstreetmap.org/api/0.6/map?bbox=11.54,48.14,11.543,48.145"

# osm poly from ogr
/home/steve/maps/ogr2poly.py -f "name" /home/steve/Downloads/ne_10m_admin_0_countries_CONTINENT_Europe.shp

# osm2pgsql
osm2pgsql --create --cache 800 --disable-parallel-indexing --unlogged --flat-nodes /home/steve/maps/osm/node.cache --slim --drop --hstore --hstore-match-only --latlong --proj 4326 --keep-coastlines -U steve -d osm /home/steve/maps/osm/planet.osm.pbf
```

Osmium  
```
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
```
# list tags
osmfilter /home/steve/maps/osm/highway_primary.o5m --out-count | head
# convert
osmconvert /home/steve/maps/osm/planet_ways.o5m --out-pbf >/home/steve/maps/osm/planet_ways.osm.pbf
# filter (--ignore-dependencies)
osmfilter /home/steve/maps/osm/planet-latest.o5m --keep= --keep-ways="highway=" --out-o5m >/home/steve/maps/osm/planet_highway.o5m
```

Map-to-query script to get data from bounding box of raster  
```
#!/bin/bash
file=toronto5.png

# get extent
extent_info=$(gdalinfo ${file} | grep "Upper Left\|Lower Right")
ul_x=$(echo $extent_info | grep -oP 'Upper Left\s+\(\s*\K[0-9\.\-]+')
ul_y=$(echo $extent_info | grep -oP 'Upper Left\s+\(\s*[0-9\.\-]+\s*,\s*\K[0-9\.\-]+')
lr_x=$(echo $extent_info | grep -oP 'Lower Right\s+\(\s*\K[0-9\.\-]+')
lr_y=$(echo $extent_info | grep -oP 'Lower Right\s+\(\s*[0-9\.\-]+\s*,\s*\K[0-9\.\-]+')

# calculate margins
width=$(echo "$lr_x - $ul_x" | bc)
height=$(echo "$ul_y - $lr_y" | bc)
new_width=$(echo "$width / 4" | bc)
new_height=$(echo "$height / 4" | bc)

ul_x_new=$(echo "$ul_x + $new_width" | bc)
ul_y_new=$(echo "$ul_y - $new_height" | bc)
lr_x_new=$(echo "$lr_x - $new_width" | bc)
lr_y_new=$(echo "$lr_y + $new_height" | bc)

# query
psql -d osm -c "SELECT other_tags FROM toronto_polygons WHERE other_tags IS NOT NULL AND ST_Intersects(wkb_geometry, (ST_Envelope('LINESTRING($ul_x_new $ul_y_new, $lr_x_new $lr_y_new)'::geometry)::geometry(POLYGON,3857)))"
```

### SRTM

Download  
```
wget --user --password http://e4ftl01.cr.usgs.gov/MEASURES/SRTMGL1.003/2000.02.11/N44W080.SRTMGL1.hgt.zip
```

Extract ocean and make positive for watershed analysis  
```
gdal_calc.py --overwrite --NoDataValue=0 -A topo15_4320.tif --outfile=topo15_4320_ocean.tif --calc="(A + 10207.5)*(A<=100)"
```

Raster labels to 3d (using gdal_calc to add to dem) 
```
# first export labels as tif
gdal_calc.py --overwrite -A topo15_432.tif -B labels_432.tif --outfile="topo15_432_labels.tif" --calc="A + 3000*(B > 0)" 
# convert to vector (optional)
rm -rf topo15_432_labels.gpkg
gdal_polygonize.py topo15_432_labels.tif topo15_432_labels.gpkg
```

Raster labels to 3d (using intersection with topo polygons)  
```
psql -d world -c "DROP TABLE IF EXISTS labels_4320;"
gdal_polygonize.py labels_4320.tif pg:dbname=world labels_4320

# intersect with topo15 polygons
psql -d world -c "DROP TABLE IF EXISTS labels_topo15_4320; CREATE TABLE labels_topo15_4320 AS SELECT a.dn, b.dn as dem, ST_Intersection(a.wkb_geometry, b.geom) geom FROM labels_4320 a, topo15_4320_polygons b WHERE ST_Intersects(a.wkb_geometry, b.geom);"
```

### StatsCan

Import  
```
ogr2ogr -overwrite -nlt promote_to_multi pg:dbname=canada lda_000b21a_e.shp
psql -d canada -c "CREATE TABLE census_profile_ontario_2021 (CENSUS_YEAR VARCHAR,DGUID VARCHAR,ALT_GEO_CODE VARCHAR,GEO_LEVEL VARCHAR,GEO_NAME VARCHAR,TNR_SF VARCHAR,TNR_LF VARCHAR,DATA_QUALITY_FLAG VARCHAR,CHARACTERISTIC_ID VARCHAR,CHARACTERISTIC_NAME VARCHAR,CHARACTERISTIC_NOTE VARCHAR,C1_COUNT_TOTAL VARCHAR,SYMBOL VARCHAR,C2_COUNT_MEN VARCHAR,SYMBOL VARCHAR,C3_COUNT_WOMEN VARCHAR,SYMBOL VARCHAR,C10_RATE_TOTAL VARCHAR,SYMBOL VARCHAR,C11_RATE_MEN VARCHAR,SYMBOL VARCHAR,C12_RATE_WOMEN VARCHAR,SYMBOL VARCHAR)"
```

### Wikipedia/Wikidata

Wikidata query output  
```
cat ecoregions.tsv | awk -F '\t' '{print $3}' | while read url; do
  echo ${url}
  w3m -dump "${url}" | awk '/^Physical\[edit\]/,/Climate\[edit\]/' || break
done

cat ecoregions.tsv | awk -F '\t' '{print $3}' | while read url; do w3m -dump "${url}"; done


lynx -dump ${url}
```

Import wikidata query results into psql  
```
psql -d world -c "DROP TABLE IF EXISTS wiki_ecoregions; CREATE TABLE wiki_ecoregions($(head -1 ecoregions.tsv | sed -e 's/\t/ VARCHAR,/g' -e 's/$/ VARCHAR/g'));"
psql -d world -c "\COPY wiki_ecoregions FROM 'ecoregions.tsv' WITH (FORMAT csv, DELIMITER E'\t', HEADER true);"
```

Wikitables
```
# convert wikipedia tables
./.local/bin/wikitables 'List_of_terrestrial_ecoregions_(WWF)' > /home/steve/wikipedia/tables/table_wwf_ecoregions.json
# split master list
cat /home/steve/wikipedia/lists_master.csv | grep -i "mountains" | csvcut --columns=2 | tr -d '"' > /home/steve/wikipedia/lists_mountains.csv
```

Wikipedia api  
```
# by pagename
https://en.wikipedia.org/w/api.php?action=parse&page=Atlantic_Equatorial_coastal_forests&format=json

# by coordinate (gscoord, gspage, gsbbox)
https://en.wikipedia.org/w/api.php?action=query&format=json&list=geosearch&gscoord=40.418670|-3.699389&gsradius=10000&gslimit=100

# by title
https://en.wikipedia.org/w/api.php?action=query&format=json&prop=coordinates|description|extracts&exintro=&explaintext=&titles=Amazon River

# search
https://en.wikipedia.org/w/api.php?action=query&list=search&srsearch=rocky mountains

# generator
https://en.wikipedia.org/w/api.php?format=json&action=query&generator=categorymembers&gcmcontinue=&gcmlimit=max&gcmtype=subcat&gcmtitle=Category:Terrestrial%20ecoregions

# example extract and mapdata (from wikipedia titles)
hood='Flatbush,_Brooklyn'
url=$(curl 'https://en.wikipedia.org/w/api.php?action=query&format=json&prop=extracts|mapdata&exchars=200&exlimit=max&explaintext&exintro&titles='${hood} | jq '..|.mapdata?' | grep '.map' | sed -e 's/^.*w\/api/https\:\/\/en\.wikipedia\.org\/w\/api/g' -e 's/\.map.*$/\.map/g')
curl -q ${url} | jq '.jsondata.data' > ${hood}.geojson

# wikidata
curl 'https://www.wikidata.org/w/api.php?action=wbgetentities&sites=enwiki&format=json&fprops=claims&titles=Flatbush,_Brooklyn'
```

SPARQL  

```sparql
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
SELECT DISTINCT ?eco_id ?wiki ?label ?url ?geom WHERE {
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
  OPTIONAL {?wiki wdt:P1294 ?eco_id}  # Add this line to fetch the WWF eco_id
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

# for longer queries
LIMIT 10
OFFSET 10
```

Some useful codes  
```sparql
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

# properties
wd:Q333291 ?abstract
wdt:P18 ?img
wdt: P1269 ?facet.
area: P2046
logo: P154
```

Wikipedia dump  
```
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

### WWF Ecoregions

Clip raster to ecoregions  
```
ecoregion='Guianan Highlands moist forests'
dem='topo15.grd'
gdalwarp -s_srs 'EPSG:4326' -t_srs 'EPSG:4326' -crop_to_cutline -cutline PG:dbname=world -csql "SELECT (ST_Union(a.shape))::geometry(MULTIPOLYGON,4326) geom FROM basinatlas_v10_lev12 a JOIN wwf_terr_ecos b ON ST_Intersects(a.shape, b.wkb_geometry) WHERE b.eco_name = '${ecoregion}'" ${dem} ${dem%.*}_clip.tif
```

## Misc

Common shell commands  
```
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

# list fonts
fc-list 

# list font families
fc-list : family | sort | uniq
```

ascii art  
```
# jp2a
jp2a --color --html --html-fontsize=10 --width=150 --background=light --output=frame_000007.html frame_000007.jpg

# figlet
figlet -d /usr/share/figlet/fonts -f Isometric1 seoul
```

xmlstarlet  
```
# xmlstarlet
xmlstarlet sel -t -v xml/page/revision/text
```

jq  
```
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
```
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
```
# commit
git add .
git commit -m 'update'
git push -f

# pull
git pull origin main

# reset
git reset --hard *commit hash*
# clone with ssh (passphrase for key /home/steve/.ssh/id_ed25519)
git clone git@github.com:geographyclub/imagemagick-for-mapmakers.git
# set authentication to ssh
git remote set-url origin git@github.com:USERNAME/REPOSITORY.git
git remote set-url origin git@github.com:geographyclub/american-geography.git
```

nginx  
```
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
```
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
```
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

ffmpeg  
```
# capture screen
ffmpeg -video_size 1024x768 -framerate 25 -f x11grab -i :0.0+0+0 ~/output.mp4

# add border to video
ffmpeg -i <input> -vf "pad=iw*2:ih*2:iw/2:ih/2"
ffmpeg -i ortho_68_25_04_28_112609.mp4 -vf "pad=1920:1080:1920-256:1080-28" ortho_68_25_04_28_112609_1920x1080.mp4

# split video using scene detection
ffmpeg -i '02 Scientology.mp4' -vf "select='gt(scene,0.1)',setpts=N/FRAME_RATE/TB" -f segment -reset_timestamps 1 -map 0 output_%03d.mp4
```

Create vector tiles (MVT) for maplibre:  
```
# set up
cd ~/maplibre-testing
rm -rf vector-tiles

# make tiles in directories
ogr2ogr -f MVT vector-tiles PG:dbname=world -sql "SELECT upland_skm, ST_ChaikinSmoothing(shape, 1) shape FROM riveratlas_v10 WHERE upland_skm >= 1000" -nlt LINESTRING -nln rivers -dsco MINZOOM=0 -dsco MAXZOOM=15 -dsco COMPRESS=NO -dsco SIMPLIFICATION=0.0 -dsco SIMPLIFICATION_MAX_ZOOM=0.0 -explodecollections

# sample tiles.json
{
   "tiles":[
      "http://localhost:8000/{z}/{x}/{y}.pbf"
   ],
   "id":"hydroatlas",
   "name":"hydroatlas",
   "format":"pbf",
   "type":"vector",
   "description":"osm",
   "bounds":[-180,-90,180,90],
   "center":[0,0],
   "minzoom":0,
   "maxzoom":15,
   "vector_layers":[
      {
         "id":"rivers",
         "fields":{
            "upland_skm":"Number"
         },
         "minzoom":0,
         "maxzoom":15
      }
   ],
   "tilejson":"2.0.0"
}

# sample maplibre script
const map = new maplibregl.Map({
	container: 'map',
	style: {
		version: 8,
		sources: {
			'raster-tiles': {
				type: 'raster',
				tiles: ['https://a.tile.openstreetmap.org/{z}/{x}/{y}.png'],
				tileSize: 256,
				attribution: '&copy; OpenStreetMap Contributors',
			},
			'vector-tiles': {
				type: 'vector',
				url: 'http://localhost:8000/tiles.json' // Path to your tiles.json file
			}
		},
		layers: [
			{
				id: 'raster-layer',
				type: 'raster',
				source: 'raster-tiles'
			},
			{
				id: 'hydroatlas',
				type: 'line',
				source: 'vector-tiles',
				'source-layer': 'rivers',
				paint: {
					'line-color': [
						'interpolate',
						['linear'],
						['get', 'upland_skm'],
						100, 'rgba(170, 211, 223, 1)',
						10000, 'rgba(170, 211, 223, 1)'                    
					],
					'line-width': [
						'interpolate',
						['linear'],
						['get', 'upland_skm'],
						100, 1,
						10000, 4
					]
				}
			}
		]
	},
	center: [-91.84124143565003, 32.907178792281],
	zoom: 4
});

# run cors server (optional)
./cors_server.py
```

Query features in image using gdalinfo and psql  
```
file=bestwestern.png
# get extent
extent_info=$(gdalinfo ${file} | grep "Upper Left\|Lower Right")
ul_x=$(echo $extent_info | grep -oP 'Upper Left\s+\(\s*\K[0-9\.\-]+')
ul_y=$(echo $extent_info | grep -oP 'Upper Left\s+\(\s*[0-9\.\-]+\s*,\s*\K[0-9\.\-]+')
lr_x=$(echo $extent_info | grep -oP 'Lower Right\s+\(\s*\K[0-9\.\-]+')
lr_y=$(echo $extent_info | grep -oP 'Lower Right\s+\(\s*[0-9\.\-]+\s*,\s*\K[0-9\.\-]+')
# calculate for margins
width=$(echo "$lr_x - $ul_x" | bc)
height=$(echo "$ul_y - $lr_y" | bc)
new_width=$(echo "$width / 4" | bc)
new_height=$(echo "$height / 4" | bc)
ul_x_new=$(echo "$ul_x + $new_width" | bc)
ul_y_new=$(echo "$ul_y - $new_height" | bc)
lr_x_new=$(echo "$lr_x - $new_width" | bc)
lr_y_new=$(echo "$lr_y + $new_height" | bc)
# query
psql -d osm -c "SELECT other_tags FROM toronto_polygons WHERE building IS NOT NULL AND other_tags IS NOT NULL AND ST_Intersects(wkb_geometry, (ST_Envelope('LINESTRING($ul_x_new $ul_y_new, $lr_x_new $lr_y_new)'::geometry)::geometry(POLYGON,3857)))" > ${file%.*}.txt
```

Create a POVray scene from a dem heightmap  
```shell
// scene.pov

// Camera setup
camera {
  location <0.5, 0.5, -0.001> // Position of the camera
  look_at <0.5, 0, 0.25>       // Camera looks at the origin
  angle 45                    // Field of view angle (smaller value zooms in)
}

// Light source setup
light_source {
  <-1000, 2000, -1000>        // Position of the light source (Northwest)
  color rgb <1, 1, 1>        // Color of the light
//  spotlight                  // Optional: Adds a spotlight effect
//  radius 100000               // Radius of the spotlight
//  falloff 0                // Light falloff
//  tightness 0              // Tightness of the spotlight
}

// Height field setup
height_field {
  png "topo15_432.png"
  scale <1, 0.03, 0.5> // Adjust scale based on data range
  texture {
    pigment {color rgb <0.9, 0.9, 0.9>} // Terrain color
    finish {
      ambient 0.2
      diffuse 0.8
      specular 0.5
    }
  }
  normal {
    bumps 0 // Add surface detail
  }
}

// Additional scene elements
```
