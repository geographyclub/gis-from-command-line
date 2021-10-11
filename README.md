# GIS FROM COMMAND LINE

This is my introduction to using open source command-line tools in Linux to make your own *Geographic Information Systems*.

## GDAL

The Geospatial Data Abstraction Library is a computer software library for reading and writing raster and vector geospatial data formats.

### 1. Print raster info

```gdalinfo HYP_HR_SR_OB_DR.tif```

### 2. Convert & create datasets

Converting from GeoTIFF to VRT:

```gdal_translate -if 'GTiff' -of 'VRT' HYP_HR_SR_OB_DR.tif HYP_HR_SR_OB_DR.vrt```

Converting an image into a georeferenced raster by extent:

```gdal_translate -of 'GTiff' -a_ullr -180 90 180 -90 HYP_HR_SR_OB_DR.png HYP_HR_SR_OB_DR_georeferenced.tif```

Converting an image into a georeferenced raster by ground control points:

```gdal_translate -of 'GTiff' -gcp 0 0 -180 -90 -gcp 360 180 180 90 -gcp 0 180 -180 90 -gcp 360 0 180 -90 HYP_HR_SR_OB_DR.png HYP_HR_SR_OB_DR_georeferenced.tif```

Creating vector polygon layer from raster categories:

```gdal_polygonize.py -8 -f 'GPKG' HYP_HR_SR_OB_DR.tif HYP_HR_SR_OB_DR.gpkg```

Creating raster from selected vector features:

```gdal_rasterize -at -l layername -a attribute -where "attribute IS NOT NULL" HYP_HR_SR_OB_DR.gpkg HYP_HR_SR_OB_DR.tif```

Creating regular grid raster from point layer:

```gdal_grid -of 'netCDF' -co WRITE_BOTTOMUP=NO -zfield 'field1' -a invdist -txe -180 180 -tye -90 90 -outsize 1000 500 -ot Float64 -l points points.vrt grid.nc```

Creating a mosaic layer from two or more raster images:

```gdal_merge.py -o mosaic.tif part1.tif part2.tif part3.tif part4.tif```

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

Smoothing DEM by scaling down then scaling up by the same factor:

```gdalwarp -of 'VRT' -ts `echo $(gdalinfo HYP_HR_SR_OB_DR.tif | grep "Size is" | sed 's/Size is //g' | sed 's/,.*$//g')/10 | bc` 0 -r cubicspline HYP_HR_SR_OB_DR.tif /vsistdout/ | gdalwarp -overwrite -ts `echo $(gdalinfo HYP_HR_SR_OB_DR.tif | grep "Size is" | sed 's/Size is //g' | sed 's/,.*$//g')` 0 -r cubicspline -t_srs 'EPSG:4326' /vsistdin/ HYP_HR_SR_OB_DR_smooth.tif```

Using different resampling methods:

```gdalwarp -overwrite -ts 4000 0 -r near -t_srs "EPSG:4326" HYP_HR_SR_OB_DR.tif HYP_HR_SR_OB_DR_near.tif```

```gdalwarp -overwrite -ts 4000 0 -r cubicspline -t_srs "EPSG:4326" HYP_HR_SR_OB_DR.tif HYP_HR_SR_OB_DR_cubicspline.tif```

### 5. Clip raster

Clipping to bounding box using `gdalwarp` or `gdal_translate`:

```gdalwarp -overwrite -dstalpha -te_srs 'EPSG:4326' -te -94 42 -82 54 HYP_HR_SR_OB_DR.tif HYP_HR_SR_OB_DR_clipped.tif```

```gdal_translate -projwin -94 54 -82 42 HYP_HR_SR_OB_DR.tif HYP_HR_SR_OB_DR_clipped.tif```

Clipping to raster mask:

```gdal_calc.py -A HYP_HR_SR_OB_DR.tif -B HYP_HR_SR_OB_DR_mask.tif --outfile="HYP_HR_SR_OB_DR_clipped.tif" --overwrite --type=Float32 --NoDataValue=0 --calc="A*(B>0)"```

Clipping to vector features selected by SQL:

```gdalwarp -overwrite -dstalpha -crop_to_cutline -cutline 'natural_earth_vector.gpkg' -csql 'SELECT geom FROM ne_110m_ocean' HYP_HR_SR_OB_DR.tif HYP_HR_SR_OB_DR_clipped.tif```

### 6. Calculate

Creating empty raster with same size and resolution as another:

```gdal_calc.py --overwrite -A HYP_HR_SR_OB_DR_A.tif --outfile=HYP_HR_SR_OB_DR_empty.tif --calc="0"```

Creating raster mask by setting values greater than 0 to 1:

```gdal_calc.py --overwrite --type=Int16 --NoDataValue=0 -A HYP_HR_SR_OB_DR_A.tif --outfile=HYP_HR_SR_OB_DR_mask.tif --calc="1*(A>0)"```

Creating raster mask by keeping values greater than 0:

```gdal_calc.py --overwrite --NoDataValue=0 -A HYP_HR_SR_OB_DR_A.tif --outfile=HYP_HR_SR_OB_DR_nulled.tif --calc="A*(A>0)"```

Using logical operator to keep values greater than 100 and less than 150:

```gdal_calc.py --overwrite -A HYP_HR_SR_OB_DR_A.tif --outfile=HYP_HR_SR_OB_DR_100_150.tif --calc="A*logical_and(A>100,A<150)"```

Rounding values to 3 significant digits:

```gdal_calc.py --overwrite --type=Int16 -A HYP_HR_SR_OB_DR_A.tif --outfile=HYP_HR_SR_OB_DR_rounded.tif --calc="A*0.001"```

Adding two rasters together where raster A is greater than zero:

```gdal_calc.py --overwrite -A HYP_HR_SR_OB_DR_A.tif -B HYP_HR_SR_OB_DR_B.tif --outfile=HYP_HR_SR_OB_DR_A_B.tif --calc="((A>0)*A)+B"```



### Miscellaneous raster operations

Compress:

```gdalwarp -overwrite -co COMPRESS=LZW HYP_HR_SR_OB_DR.tif HYP_HR_SR_OB_DR_3857_compressed.tif```

Tile:

```gdalwarp -overwrite -co TILED=YES HYP_HR_SR_OB_DR.tif HYP_HR_SR_OB_DR_3857_tiled.tif```
