# GIS FROM COMMAND LINE

This is my introduction to using open source command-line tools in Linux to make your own *Geographic Information Systems*.

## GDAL

The Geospatial Data Abstraction Library is a computer software library for reading and writing raster and vector geospatial data formats.

### 1. Print raster info

Print useful info about raster dataset:

<img src="images/HYP_HR_SR_OB_DR_1024_512.jpg" width="400" />

```gdalinfo_HYP_HR_SR_OB_DR_1024_512.tif```

<pre>
Driver: GTiff/GeoTIFF
Files: HYP_HR_SR_OB_DR_1024_512.tif
Size is 1024, 512
Coordinate System is:
GEOGCRS["WGS 84",
    DATUM["World Geodetic System 1984",
        ELLIPSOID["WGS 84",6378137,298.257223563,
            LENGTHUNIT["metre",1]]],
    PRIMEM["Greenwich",0,
        ANGLEUNIT["degree",0.0174532925199433]],
    CS[ellipsoidal,2],
        AXIS["geodetic latitude (Lat)",north,
            ORDER[1],
            ANGLEUNIT["degree",0.0174532925199433]],
        AXIS["geodetic longitude (Lon)",east,
            ORDER[2],
            ANGLEUNIT["degree",0.0174532925199433]],
    ID["EPSG",4326]]
Data axis to CRS axis mapping: 2,1
Origin = (-180.000000000000000,90.000000000000014)
Pixel Size = (0.351562500000070,-0.351562500000070)
Metadata:
  AREA_OR_POINT=Area
  TIFFTAG_DATETIME=2014:10:18 12:06:24
  TIFFTAG_RESOLUTIONUNIT=2 (pixels/inch)
  TIFFTAG_SOFTWARE=Adobe Photoshop CC 2014 (Macintosh)
  TIFFTAG_XRESOLUTION=72
  TIFFTAG_YRESOLUTION=72
Image Structure Metadata:
  INTERLEAVE=PIXEL
Corner Coordinates:
Upper Left  (-180.0000000,  90.0000000) (180d 0' 0.00"W, 90d 0' 0.00"N)
Lower Left  (-180.0000000, -90.0000000) (180d 0' 0.00"W, 90d 0' 0.00"S)
Upper Right ( 180.0000000,  90.0000000) (180d 0' 0.00"E, 90d 0' 0.00"N)
Lower Right ( 180.0000000, -90.0000000) (180d 0' 0.00"E, 90d 0' 0.00"S)
Center      (   0.0000000,  -0.0000000) (  0d 0' 0.00"E,  0d 0' 0.00"S)
Band 1 Block=1024x2 Type=Byte, ColorInterp=Red
  Mask Flags: PER_DATASET ALPHA 
Band 2 Block=1024x2 Type=Byte, ColorInterp=Green
  Mask Flags: PER_DATASET ALPHA 
Band 3 Block=1024x2 Type=Byte, ColorInterp=Blue
  Mask Flags: PER_DATASET ALPHA 
Band 4 Block=1024x2 Type=Byte, ColorInterp=Alpha
</pre>

### 2. Convert & create datasets

Converting from GeoTIFF to VRT:

```gdal_translate -if 'GTiff' -of 'VRT' HYP_HR_SR_OB_DR_1024_512.tif HYP_HR_SR_OB_DR_1024_512.vrt```

Converting an image into a georeferenced raster by extent:

```gdal_translate -of 'GTiff' -a_ullr -180 90 180 -90 HYP_HR_SR_OB_DR_1024_512.png HYP_HR_SR_OB_DR_1024_512_georeferenced.tif```

Converting an image into a georeferenced raster by ground control points:

```gdal_translate -of 'GTiff' -gcp 0 0 -180 -90 -gcp 360 180 180 90 -gcp 0 180 -180 90 -gcp 360 0 180 -90 HYP_HR_SR_OB_DR_1024_512.png HYP_HR_SR_OB_DR_1024_512_georeferenced.tif```

Creating vector polygon layer from raster categories:

```gdal_polygonize.py -8 -f 'GPKG' HYP_HR_SR_OB_DR_1024_512.tif HYP_HR_SR_OB_DR_1024_512_polygons.gpkg```

Creating raster from selected vector features, given pixel resolution:

```gdal_rasterize -at -tr 0.3 0.3 -l layername -a attribute -where "attribute IS NOT NULL" HYP_HR_SR_OB_DR_1024_512.gpkg HYP_HR_SR_OB_DR_1024_512.tif```

Creating regular grid raster from point layer, given output size and extent:

```gdal_grid -of 'netCDF' -co WRITE_BOTTOMUP=NO -zfield 'field1' -a invdist -txe -180 180 -tye -90 90 -outsize 1000 500 -ot Float64 -l points points.vrt grid.nc```

Creating a mosaic layer from two or more raster images:

```gdal_merge.py -o mosaic.tif part1.tif part2.tif part3.tif part4.tif```

### 3. Transform coordinates

Using EPSG code to transform from lat-long to Web Mercator projection:

```gdalwarp -overwrite -s_srs 'EPSG:4326' -t_srs 'EPSG:3857' HYP_HR_SR_OB_DR_1024_512.tif HYP_HR_SR_OB_DR_1024_512_3857.tif```

Using PROJ definition to transform from lat-long to van der Grinten projection:

```gdalwarp -overwrite -s_srs 'EPSG:4326' -t_srs '+proj=vandg +lon_0=0 +x_0=0 +y_0=0 +R_A +a=6371000 +b=6371000 +units=m no_defs' HYP_HR_SR_OB_DR_1024_512.tif HYP_HR_SR_OB_DR_1024_512_vandergrinten.tif```

Customizing PROJ definition to transform from lat-long to an orthographic projection centered on Toronto:

```gdalwarp -overwrite -s_srs 'EPSG:4326' -t_srs '+proj=ortho +lat_0='43.65' +lon_0='-79.34' +ellps='sphere'' HYP_HR_SR_OB_DR_1024_512.tif HYP_HR_SR_OB_DR_1024_512_ortho_toronto.tif```

Piping `gdal_translate` to `gdalwarp` to georeference and transform an image in one step:

```gdal_translate -of 'GTiff' -a_ullr -180 90 180 -90 HYP_HR_SR_OB_DR_1024_512.png /vsistdout/ | gdalwarp -overwrite -f 'GTiff' -of 'GTiff' -t_srs 'EPSG:4326' /vsistdin/ HYP_HR_SR_OB_DR_1024_512_crs.tif```

### 4. Rescale raster

Rescaling to output pixel resolution:

```gdalwarp -overwrite -tr 1 1 HYP_HR_SR_OB_DR_1024_512.tif HYP_HR_SR_OB_DR_1024_512_1xres_1yres.tif```

Rescaling to output raster width:

```gdalwarp -overwrite -ts 4000 0 HYP_HR_SR_OB_DR_1024_512.tif HYP_HR_SR_OB_DR_1024_512_4000w.tif```

Smoothing DEM by scaling down then scaling up by the same factor:

```gdalwarp -of 'VRT' -ts `echo $(gdalinfo HYP_HR_SR_OB_DR_1024_512.tif | grep "Size is" | sed 's/Size is //g' | sed 's/,.*$//g')/10 | bc` 0 -r cubicspline HYP_HR_SR_OB_DR_1024_512.tif /vsistdout/ | gdalwarp -overwrite -ts `echo $(gdalinfo HYP_HR_SR_OB_DR_1024_512.tif | grep "Size is" | sed 's/Size is //g' | sed 's/,.*$//g')` 0 -r cubicspline -t_srs 'EPSG:4326' /vsistdin/ HYP_HR_SR_OB_DR_1024_512_smooth.tif```

Using different resampling methods:

```gdalwarp -overwrite -ts 4000 0 -r near -t_srs "EPSG:4326" HYP_HR_SR_OB_DR_1024_512.tif HYP_HR_SR_OB_DR_1024_512_near.tif```

```gdalwarp -overwrite -ts 4000 0 -r cubicspline -t_srs "EPSG:4326" HYP_HR_SR_OB_DR_1024_512.tif HYP_HR_SR_OB_DR_1024_512_cubicspline.tif```

### 5. Clip raster

Clipping to bounding box using `gdalwarp` or `gdal_translate`:

```gdalwarp -overwrite -dstalpha -te_srs 'EPSG:4326' -te -94 42 -82 54 HYP_HR_SR_OB_DR_1024_512.tif HYP_HR_SR_OB_DR_1024_512_clipped.tif```

```gdal_translate -projwin -94 54 -82 42 HYP_HR_SR_OB_DR_1024_512.tif HYP_HR_SR_OB_DR_1024_512_clipped.tif```

Clipping to raster mask:

```gdal_calc.py -A HYP_HR_SR_OB_DR_1024_512.tif -B HYP_HR_SR_OB_DR_1024_512_mask.tif --outfile="HYP_HR_SR_OB_DR_1024_512_clipped.tif" --overwrite --type=Float32 --NoDataValue=0 --calc="A*(B>0)"```

Clipping to vector features selected by SQL:

```gdalwarp -overwrite -dstalpha -crop_to_cutline -cutline 'natural_earth_vector.gpkg' -csql 'SELECT geom FROM ne_110m_ocean' HYP_HR_SR_OB_DR_1024_512.tif HYP_HR_SR_OB_DR_1024_512_clipped.tif```

### 6. Calculate

Creating empty raster with same size and resolution as another:

```gdal_calc.py --overwrite -A HYP_HR_SR_OB_DR_1024_512_A.tif --outfile=HYP_HR_SR_OB_DR_1024_512_empty.tif --calc="0"```

Creating raster mask by setting values greater than 0 to 1:

```gdal_calc.py --overwrite --type=Int16 --NoDataValue=0 -A HYP_HR_SR_OB_DR_1024_512_A.tif --outfile=HYP_HR_SR_OB_DR_1024_512_mask.tif --calc="1*(A>0)"```

Creating raster mask by keeping values greater than 0:

```gdal_calc.py --overwrite --NoDataValue=0 -A HYP_HR_SR_OB_DR_1024_512_A.tif --outfile=HYP_HR_SR_OB_DR_1024_512_nulled.tif --calc="A*(A>0)"```

Using logical operator to keep values greater than 100 and less than 150:

```gdal_calc.py --overwrite -A HYP_HR_SR_OB_DR_1024_512_A.tif --outfile=HYP_HR_SR_OB_DR_1024_512_100_150.tif --calc="A*logical_and(A>100,A<150)"```

Rounding values to 3 significant digits:

```gdal_calc.py --overwrite --type=Int16 -A HYP_HR_SR_OB_DR_1024_512_A.tif --outfile=HYP_HR_SR_OB_DR_1024_512_rounded.tif --calc="A*0.001"```

Adding two rasters together where raster A is greater than zero:

```gdal_calc.py --overwrite -A HYP_HR_SR_OB_DR_1024_512_A.tif -B HYP_HR_SR_OB_DR_1024_512_B.tif --outfile=HYP_HR_SR_OB_DR_1024_512_A_B.tif --calc="((A>0)*A)+B"```

## OGR

Vector programs provided by GDAL.

### 1. Print vector info


