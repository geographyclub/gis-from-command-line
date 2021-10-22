# GIS FROM COMMAND LINE

This is my introduction to using open source command-line tools in Linux to make your own *Geographic Information Systems*.

<img src="images/HYP_HR_SR_OB_DR_1024_512.jpg" width="400" />

## 1. GDAL

The Geospatial Data Abstraction Library is a computer software library for reading and writing raster and vector geospatial data formats.

### 1.1 Print raster info

Printing useful info on raster dataset:

```gdalinfo_HYP_HR_SR_OB_DR_1024_512.tif```

### 1.2 Convert raster data

Converting from GeoTIFF to VRT:

```gdal_translate -if 'GTiff' -of 'VRT' HYP_HR_SR_OB_DR_1024_512.tif HYP_HR_SR_OB_DR_1024_512.vrt```

Converting from GeoTIFF to regular TIFF:

```gdalwarp -overwrite -dstalpha --config GDAL_PAM_ENABLED NO -co PROFILE=BASELINE -f 'GTiff' -of 'GTiff' HYP_HR_SR_OB_DR_1024_512.tif HYP_HR_SR_OB_DR_1024_512.tif```

Georeferencing image by extent:

```gdal_translate -of 'GTiff' -a_ullr -180 90 180 -90 HYP_HR_SR_OB_DR_1024_512.png HYP_HR_SR_OB_DR_1024_512_georeferenced.tif```

Georeferencing image by ground control points:

```gdal_translate -of 'GTiff' -gcp 0 0 -180 -90 -gcp 1024 512 180 90 -gcp 0 512 -180 90 -gcp 1024 0 180 -90 HYP_HR_SR_OB_DR_1024_512.png HYP_HR_SR_OB_DR_1024_512_georeferenced.tif```

Rasterizing selected vector features given pixel resolution:

```gdal_rasterize -at -tr 0.3 0.3 -l layername -a attribute -where "attribute IS NOT NULL" HYP_HR_SR_OB_DR_1024_512.gpkg HYP_HR_SR_OB_DR_1024_512.tif```

Gridding point layer given output size and extent:

```gdal_grid -of 'netCDF' -co WRITE_BOTTOMUP=NO -zfield 'field1' -a invdist -txe -180 180 -tye -90 90 -outsize 1000 500 -ot Float64 -l points points.vrt grid.nc```

Making mosaic layer from two or more raster images:

```gdal_merge.py -o mosaic.tif part1.tif part2.tif part3.tif part4.tif```

### 1.3 Transform coordinates

Using EPSG code to transform from lat-long to Web Mercator projection:

```gdalwarp -overwrite -s_srs 'EPSG:4326' -t_srs 'EPSG:3857' HYP_HR_SR_OB_DR_1024_512.tif HYP_HR_SR_OB_DR_1024_512_3857.tif```

Using PROJ definition to transform from lat-long to van der Grinten projection:

```gdalwarp -overwrite -s_srs 'EPSG:4326' -t_srs '+proj=vandg +lon_0=0 +x_0=0 +y_0=0 +R_A +a=6371000 +b=6371000 +units=m no_defs' HYP_HR_SR_OB_DR_1024_512.tif HYP_HR_SR_OB_DR_1024_512_vandergrinten.tif```

Customizing PROJ definition to transform from lat-long to an orthographic projection centered on Toronto:

```gdalwarp -overwrite -s_srs 'EPSG:4326' -t_srs '+proj=ortho +lat_0='43.65' +lon_0='-79.34' +ellps='sphere'' HYP_HR_SR_OB_DR_1024_512.tif HYP_HR_SR_OB_DR_1024_512_ortho_toronto.tif```

Shifting prime meridian on a 0-360° raster and a -180-180° raster:

```gdalwarp -overwrite -s_srs 'EPSG:4326' -t_srs '+proj=latlong +datum=WGS84 +pm=180dE' HYP_HR_SR_OB_DR_1024_512.tif HYP_HR_SR_OB_DR_1024_512_180pm.tif```

```gdalwarp -overwrite -s_srs 'EPSG:4326' -t_srs '+proj=longlat +ellps=WGS84 +pm=-360 +datum=WGS84 +no_defs +lon_wrap=360 +over' HYP_HR_SR_OB_DR_1024_512.tif HYP_HR_SR_OB_DR_1024_512_180pm.tif```

Piping `gdal_translate` to `gdalwarp` to georeference and transform an image in one step:

```gdal_translate -of 'GTiff' -a_ullr -180 90 180 -90 HYP_HR_SR_OB_DR_1024_512.png /vsistdout/ | gdalwarp -overwrite -f 'GTiff' -of 'GTiff' -t_srs 'EPSG:4326' /vsistdin/ HYP_HR_SR_OB_DR_1024_512_crs.tif```

### 1.4 Rescale raster

Rescaling to output pixel resolution:

```gdalwarp -overwrite -tr 1 1 HYP_HR_SR_OB_DR_1024_512.tif HYP_HR_SR_OB_DR_1024_512_1xres_1yres.tif```

Rescaling to output raster width:

```gdalwarp -overwrite -ts 4000 0 HYP_HR_SR_OB_DR_1024_512.tif HYP_HR_SR_OB_DR_1024_512_4000w.tif```

Smoothing DEM by scaling down then scaling up by the same factor:

```gdalwarp -of 'VRT' -ts `echo $(gdalinfo HYP_HR_SR_OB_DR_1024_512.tif | grep "Size is" | sed 's/Size is //g' | sed 's/,.*$//g')/10 | bc` 0 -r cubicspline HYP_HR_SR_OB_DR_1024_512.tif /vsistdout/ | gdalwarp -overwrite -ts `echo $(gdalinfo HYP_HR_SR_OB_DR_1024_512.tif | grep "Size is" | sed 's/Size is //g' | sed 's/,.*$//g')` 0 -r cubicspline -t_srs 'EPSG:4326' /vsistdin/ HYP_HR_SR_OB_DR_1024_512_smooth.tif```

Using different resampling methods:

```gdalwarp -overwrite -ts 4000 0 -r near -t_srs "EPSG:4326" HYP_HR_SR_OB_DR_1024_512.tif HYP_HR_SR_OB_DR_1024_512_near.tif```

```gdalwarp -overwrite -ts 4000 0 -r cubicspline -t_srs "EPSG:4326" HYP_HR_SR_OB_DR_1024_512.tif HYP_HR_SR_OB_DR_1024_512_cubicspline.tif```

### 1.5 Select raster data

Clipping to bounding box using `gdalwarp` or `gdal_translate`:

```gdalwarp -overwrite -dstalpha -te_srs 'EPSG:4326' -te -94 42 -82 54 HYP_HR_SR_OB_DR_1024_512.tif HYP_HR_SR_OB_DR_1024_512_clipped.tif```

```gdal_translate -projwin -94 54 -82 42 HYP_HR_SR_OB_DR_1024_512.tif HYP_HR_SR_OB_DR_1024_512_clipped.tif```

Clipping to vector features selected by SQL:

```gdalwarp -overwrite -dstalpha -crop_to_cutline -cutline 'natural_earth_vector.gpkg' -csql 'SELECT geom FROM ne_110m_ocean' HYP_HR_SR_OB_DR_1024_512.tif HYP_HR_SR_OB_DR_1024_512_clipped.tif```

Making empty raster with same size and resolution as another:

```gdal_calc.py --overwrite -A HYP_HR_SR_OB_DR_1024_512_A.tif --outfile=HYP_HR_SR_OB_DR_1024_512_empty.tif --calc="0"```

Making raster mask by setting values greater than 0 to 1:

```gdal_calc.py --overwrite --type=Int16 --NoDataValue=0 -A HYP_HR_SR_OB_DR_1024_512_A.tif --outfile=HYP_HR_SR_OB_DR_1024_512_mask.tif --calc="1*(A>0)"```

Making raster mask by keeping values greater than 0:

```gdal_calc.py --overwrite --NoDataValue=0 -A HYP_HR_SR_OB_DR_1024_512_A.tif --outfile=HYP_HR_SR_OB_DR_1024_512_nulled.tif --calc="A*(A>0)"```

Clipping to raster mask:

```gdal_calc.py -A HYP_HR_SR_OB_DR_1024_512.tif -B HYP_HR_SR_OB_DR_1024_512_mask.tif --outfile="HYP_HR_SR_OB_DR_1024_512_clipped.tif" --overwrite --type=Float32 --NoDataValue=0 --calc="A*(B>0)"```

Selecting values greater than 100 and less than 150:

```gdal_calc.py --overwrite -A HYP_HR_SR_OB_DR_1024_512_A.tif --outfile=HYP_HR_SR_OB_DR_1024_512_100_150.tif --calc="A*logical_and(A>100,A<150)"```

Rounding values to 3 significant digits:

```gdal_calc.py --overwrite --type=Int16 -A HYP_HR_SR_OB_DR_1024_512_A.tif --outfile=HYP_HR_SR_OB_DR_1024_512_rounded.tif --calc="A*0.001"```

Adding two rasters together where raster A is greater than zero:

```gdal_calc.py --overwrite -A HYP_HR_SR_OB_DR_1024_512_A.tif -B HYP_HR_SR_OB_DR_1024_512_B.tif --outfile=HYP_HR_SR_OB_DR_1024_512_A_B.tif --calc="((A>0)*A)+B"```

## 2. OGR

Vector programs provided by GDAL.

### 2.1 Print vector info

Printing layers in vector dataset:

```ogrinfo natural_earth_vector.gpkg```

Printing summary of vector layer:

```ogrinfo -so natural_earth_vector.gpkg ne_110m_admin_0_countries```

### 2.2 Convert vector data

Converting dataset from SHP to GPKG with UTF encoding:

```ogr2ogr -overwrite -lco ENCODING=UTF-8 natural_earth_vector.gpkg natural_earth_vector.shp```

Converting from CSV to GeoJSON:

```ogr2ogr -overwrite -f 'GeoJSON' -oo X_POSSIBLE_NAMES=longitude -oo Y_POSSIBLE_NAMES=latitude -nln metars metars.geojson metars.cache.csv```

Converting from GPKG to SQLite/Spatialite database layer:

```ogr2ogr -overwrite -f 'SQLite' -dsco SPATIALITE=YES natural_earth_vector.sqlite natural_earth_vector.gpkg ne_110m_admin_0_countries```

Adding M or Z field to dataset:

```ogr2ogr -overwrite -f 'GPKG' -dim XYM -zfield 'CATCH_SKM' /home/steve/maps/wwf/hydroatlas/RiverATLAS_v10_xym.gpkg /home/steve/maps/wwf/hydroatlas/RiverATLAS_v10.gdb RiverATLAS_v10```

```ogr2ogr -overwrite -f 'GPKG' -dim XYZ -zfield 'CATCH_SKM' /home/steve/maps/wwf/hydroatlas/RiverATLAS_v10_xyz.gpkg /home/steve/maps/wwf/hydroatlas/RiverATLAS_v10.gdb RiverATLAS_v10```

Exporting vector layer as SVG:

```ogrinfo -sql 'SELECT AsSVG(geom,1) FROM ne_110m_admin_0_countries' natural_earth_vector.gpkg```

Polygonizing raster:

```gdal_polygonize.py -8 -f 'GPKG' HYP_HR_SR_OB_DR_1024_512.tif HYP_HR_SR_OB_DR_1024_512_polygons.gpkg```

Making contour lines or polygons from raster:

```gdal_contour -f "GPKG" -a 'elevation' -i 100 topo15_4000_40000.tif topo15_4000_40000_100m.gpkg```

```gdal_contour -p -f "GPKG" -a 'elevation' -i 100 topo15_4000_40000.tif topo15_4000_40000_100m.gpkg```

### 2.3 Transform coordinates

Transforming from lat-long to azimuthal equidistant projection with spatial query:

```ogr2ogr -overwrite -skipfailures --config OGR_ENABLE_PARTIAL_REPROJECTION TRUE -spat -180 -80 180 80 -s_srs 'EPSG:4326' -t_srs '+proj=aeqd +lat_0=45 +lon_0=-80 +a=1000000 +b=1000000 +over +no_defs' ne_110m_admin_0_countries_aeqd.gpkg natural_earth_vector.gpkg ne_110m_admin_0_countries```

Transforming from lat-long to lambert azimuthal equal area projection with spatial query:

```ogr2ogr -overwrite -skipfailures --config OGR_ENABLE_PARTIAL_REPROJECTION TRUE -spat -160 -90 160 90 -s_srs 'EPSG:4326' -t_srs '+proj=laea +lat_0=0 +lon_0=0 +x_0=0 +y_0=0 +datum=WGS84 +units=m +no_defs' ne_110m_admin_0_countries_laea.gpkg natural_earth_vector.gpkg ne_110m_admin_0_countries```

Transforming from lat-long to a stereographic projection around indicated coordinates:

```ogr2ogr -overwrite -skipfailures --config OGR_ENABLE_PARTIAL_REPROJECTION TRUE -s_srs 'EPSG:4326' -t_srs '+proj=stere +lon_0=-119 +lat_0=36 +lat_ts=36' ne_110m_admin_0_countries_stere.gpkg natural_earth_vector.gpkg ne_110m_admin_0_countries```

Shifting prime meridian from 0° to 180°:

```ogr2ogr -overwrite -skipfailures --config OGR_ENABLE_PARTIAL_REPROJECTION TRUE -s_srs 'EPSG:4326' -t_srs '+proj=longlat +ellps=WGS84 +pm=-360 +datum=WGS84 +no_defs +lon_wrap=360 +over' countries_110m_180pm.gpkg countries_110m.gpkg```

### 2.4 Select vector data

Exporting clip or spatial query:

```ogr2ogr -overwrite -clipsrc -94 54 -82 42 natural_earth_vector_clip.gpkg natural_earth_vector.gpkg```

```ogr2ogr -overwrite -spat -180 -80 180 80 natural_earth_vector_spat.gpkg natural_earth_vector.gpkg```

Exporting features with logical operators:

```ogr2ogr -overwrite -sql 'SELECT * FROM ne_110m_admin_0_countries WHERE area >= 1000000' -nln largecountries natural_earth_vector_largecountries.gpkg natural_earth_vector.gpkg```

```ogr2ogr -overwrite -sql 'SELECT * FROM ne_110m_admin_0_countries WHERE name LIKE 'A%'' -nln acountries natural_earth_vector_acountries.gpkg natural_earth_vector.gpkg```

```ogr2ogr -overwrite -sql 'SELECT * FROM ne_110m_admin_0_countries WHERE name IN ('North Korea','South Korea')' -nln korea natural_earth_vector_korea.gpkg natural_earth_vector.gpkg```

Exporting features after operating on values:

```ogr2ogr -overwrite -sql 'SELECT name, ROUND(area/1000) AS area_km FROM ne_110m_admin_0_countries' -nln countries natural_earth_vector_largecountries.gpkg natural_earth_vector.gpkg```

## 3. POSTGRESQL / POSTGIS

PostGIS is a spatial database extender for PostgreSQL object-relational database. It adds support for geographic objects allowing location queries to be run in SQL.

### 3.1 Import data

Importing CSV file:

```psql -d world -c "COPY geonames FROM 'allCountries.tsv' DELIMITER E'\t' CSV HEADER;"```

Importing GDAL raster:

```raster2pgsql -d -s 4326 -I -C -M HYP_HR_SR_OB_DR_1024_512.tif -F -t auto HYP_HR_SR_OB_DR_1024_512 | psql -d world```

Two ways of importing OGR layer:

```ogr2ogr -overwrite -f 'PostgreSQL' PG:dbname=world -lco precision=NO -nlt PROMOTE_TO_MULTI -nlt MULTIPOLYGON -nln countries natural_earth_vector.gpkg ne_110m_admin_0_countries```

```ogr2ogr -f PGDump -lco precision=NO -nlt PROMOTE_TO_MULTI -nlt MULTIPOLYGON -nln countries --config PG_USE_COPY YES /vsistdout/ natural_earth_vector.gpkg ne_110m_admin_0_countries | psql -d world -f -```
