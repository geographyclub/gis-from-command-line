# GIS FROM COMMAND LINE

This is my introduction to using open source command-line tools in Linux to make your own *Geographic Information Systems*.

<img src="images/HYP_HR_SR_OB_DR_1024_512.jpg" width="400" />

## 1. GDAL

The Geospatial Data Abstraction Library is a computer software library for reading and writing raster and vector geospatial data formats.

### 1.1 Print raster info

Printing useful info on raster dataset:

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

### 1.2 Convert & create datasets

Converting from GeoTIFF to VRT:

```gdal_translate -if 'GTiff' -of 'VRT' HYP_HR_SR_OB_DR_1024_512.tif HYP_HR_SR_OB_DR_1024_512.vrt```

Georeferencing raster by extent:

```gdal_translate -of 'GTiff' -a_ullr -180 90 180 -90 HYP_HR_SR_OB_DR_1024_512.png HYP_HR_SR_OB_DR_1024_512_georeferenced.tif```

Georeferencing raster by ground control points:

```gdal_translate -of 'GTiff' -gcp 0 0 -180 -90 -gcp 1024 512 180 90 -gcp 0 512 -180 90 -gcp 1024 0 180 -90 HYP_HR_SR_OB_DR_1024_512.png HYP_HR_SR_OB_DR_1024_512_georeferenced.tif```

Creating vector polygon layer from raster categories:

```gdal_polygonize.py -8 -f 'GPKG' HYP_HR_SR_OB_DR_1024_512.tif HYP_HR_SR_OB_DR_1024_512_polygons.gpkg```

Creating raster from selected vector features, given pixel resolution:

```gdal_rasterize -at -tr 0.3 0.3 -l layername -a attribute -where "attribute IS NOT NULL" HYP_HR_SR_OB_DR_1024_512.gpkg HYP_HR_SR_OB_DR_1024_512.tif```

Creating regular grid raster from point layer, given output size and extent:

```gdal_grid -of 'netCDF' -co WRITE_BOTTOMUP=NO -zfield 'field1' -a invdist -txe -180 180 -tye -90 90 -outsize 1000 500 -ot Float64 -l points points.vrt grid.nc```

Creating a mosaic layer from two or more raster images:

```gdal_merge.py -o mosaic.tif part1.tif part2.tif part3.tif part4.tif```

### 1.3 Transform coordinates

Using EPSG code to transform from lat-long to Web Mercator projection:

```gdalwarp -overwrite -s_srs 'EPSG:4326' -t_srs 'EPSG:3857' HYP_HR_SR_OB_DR_1024_512.tif HYP_HR_SR_OB_DR_1024_512_3857.tif```

Using PROJ definition to transform from lat-long to van der Grinten projection:

```gdalwarp -overwrite -s_srs 'EPSG:4326' -t_srs '+proj=vandg +lon_0=0 +x_0=0 +y_0=0 +R_A +a=6371000 +b=6371000 +units=m no_defs' HYP_HR_SR_OB_DR_1024_512.tif HYP_HR_SR_OB_DR_1024_512_vandergrinten.tif```

Customizing PROJ definition to transform from lat-long to an orthographic projection centered on Toronto:

```gdalwarp -overwrite -s_srs 'EPSG:4326' -t_srs '+proj=ortho +lat_0='43.65' +lon_0='-79.34' +ellps='sphere'' HYP_HR_SR_OB_DR_1024_512.tif HYP_HR_SR_OB_DR_1024_512_ortho_toronto.tif```

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

### 1.5 Clip raster

Clipping to bounding box using `gdalwarp` or `gdal_translate`:

```gdalwarp -overwrite -dstalpha -te_srs 'EPSG:4326' -te -94 42 -82 54 HYP_HR_SR_OB_DR_1024_512.tif HYP_HR_SR_OB_DR_1024_512_clipped.tif```

```gdal_translate -projwin -94 54 -82 42 HYP_HR_SR_OB_DR_1024_512.tif HYP_HR_SR_OB_DR_1024_512_clipped.tif```

Clipping to raster mask:

```gdal_calc.py -A HYP_HR_SR_OB_DR_1024_512.tif -B HYP_HR_SR_OB_DR_1024_512_mask.tif --outfile="HYP_HR_SR_OB_DR_1024_512_clipped.tif" --overwrite --type=Float32 --NoDataValue=0 --calc="A*(B>0)"```

Clipping to vector features selected by SQL:

```gdalwarp -overwrite -dstalpha -crop_to_cutline -cutline 'natural_earth_vector.gpkg' -csql 'SELECT geom FROM ne_110m_ocean' HYP_HR_SR_OB_DR_1024_512.tif HYP_HR_SR_OB_DR_1024_512_clipped.tif```

### 1.6 Calculate

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

## 2. OGR

Vector programs provided by GDAL.

### 2.1 Print vector info

Printing layers in vector dataset:

```ogrinfo natural_earth_vector.gpkg```

<pre>
INFO: Open of `natural_earth_vector.gpkg'
      using driver `GPKG' successful.
1: ne_10m_admin_0_antarctic_claim_limit_lines (Line String)
2: ne_10m_admin_0_antarctic_claims (Polygon)
3: ne_10m_admin_0_boundary_lines_disputed_areas (Line String)
4: ne_10m_admin_0_boundary_lines_land (Line String)
5: ne_10m_admin_0_boundary_lines_map_units (Line String)
6: ne_10m_admin_0_boundary_lines_maritime_indicator (Line String)
7: ne_10m_admin_0_countries (Polygon)
8: ne_10m_admin_0_countries_lakes (Polygon)
9: ne_10m_admin_0_disputed_areas (Polygon)
10: ne_10m_admin_0_disputed_areas_scale_rank_minor_islands (Polygon)
11: ne_10m_admin_0_label_points (Point)
12: ne_10m_admin_0_map_subunits (Polygon)
13: ne_10m_admin_0_map_units (Polygon)
14: ne_10m_admin_0_pacific_groupings (Line String)
15: ne_10m_admin_0_scale_rank (Polygon)
16: ne_10m_admin_0_scale_rank_minor_islands (Polygon)
17: ne_10m_admin_0_seams (Line String)
18: ne_10m_admin_0_sovereignty (Polygon)
19: ne_10m_admin_1_label_points (Point)
20: ne_10m_admin_1_label_points_details (Point)
21: ne_10m_admin_1_seams (Line String)
22: ne_10m_admin_1_states_provinces (Polygon)
23: ne_10m_admin_1_states_provinces_lakes (Polygon)
24: ne_10m_admin_1_states_provinces_lines (Line String)
25: ne_10m_admin_1_states_provinces_scale_rank (Polygon)
26: ne_10m_admin_1_states_provinces_scale_rank_minor_islands (Polygon)
27: ne_10m_airports (Point)
28: ne_10m_parks_and_protected_lands_area (Polygon)
29: ne_10m_parks_and_protected_lands_line (Line String)
30: ne_10m_parks_and_protected_lands_point (Point)
31: ne_10m_parks_and_protected_lands_scale_rank (Polygon)
32: ne_10m_populated_places (Point)
33: ne_10m_populated_places_simple (Point)
34: ne_10m_ports (Point)
35: ne_10m_railroads (Line String)
36: ne_10m_railroads_north_america (Line String)
37: ne_10m_roads (Line String)
38: ne_10m_roads_north_america (Line String)
39: ne_10m_time_zones (Polygon)
40: ne_10m_urban_areas (Polygon)
41: ne_10m_urban_areas_landscan (Polygon)
42: ne_10m_antarctic_ice_shelves_lines (Line String)
43: ne_10m_antarctic_ice_shelves_polys (Polygon)
44: ne_10m_coastline (Line String)
45: ne_10m_geographic_lines (Line String)
46: ne_10m_geography_marine_polys (Polygon)
47: ne_10m_geography_regions_elevation_points (Point)
48: ne_10m_geography_regions_points (Point)
49: ne_10m_geography_regions_polys (Polygon)
50: ne_10m_glaciated_areas (Polygon)
51: ne_10m_lakes (Polygon)
52: ne_10m_lakes_europe (Polygon)
53: ne_10m_lakes_historic (Polygon)
54: ne_10m_lakes_north_america (Polygon)
55: ne_10m_lakes_pluvial (Polygon)
56: ne_10m_land (Polygon)
57: ne_10m_land_ocean_label_points (Point)
58: ne_10m_land_ocean_seams (Line String)
59: ne_10m_land_scale_rank (Polygon)
60: ne_10m_minor_islands (Polygon)
61: ne_10m_minor_islands_coastline (Line String)
62: ne_10m_minor_islands_label_points (Point)
63: ne_10m_ocean (Polygon)
64: ne_10m_ocean_scale_rank (Polygon)
65: ne_10m_playas (Polygon)
66: ne_10m_reefs (Line String)
67: ne_10m_rivers_europe (Line String)
68: ne_10m_rivers_lake_centerlines (Line String)
69: ne_10m_rivers_lake_centerlines_scale_rank (Line String)
70: ne_10m_rivers_north_america (Line String)
71: ne_50m_admin_0_boundary_lines_disputed_areas (Line String)
72: ne_50m_admin_0_boundary_lines_land (Line String)
73: ne_50m_admin_0_boundary_lines_maritime_indicator (Line String)
74: ne_50m_admin_0_boundary_map_units (Line String)
75: ne_50m_admin_0_breakaway_disputed_areas (Polygon)
76: ne_50m_admin_0_breakaway_disputed_areas_scale_rank (Polygon)
77: ne_50m_admin_0_countries (Polygon)
78: ne_50m_admin_0_countries_lakes (Polygon)
79: ne_50m_admin_0_map_subunits (Polygon)
80: ne_50m_admin_0_map_units (Polygon)
81: ne_50m_admin_0_pacific_groupings (Line String)
82: ne_50m_admin_0_scale_rank (Polygon)
83: ne_50m_admin_0_sovereignty (Polygon)
84: ne_50m_admin_0_tiny_countries (Point)
85: ne_50m_admin_0_tiny_countries_scale_rank (Point)
86: ne_50m_admin_1_states_provinces (Polygon)
87: ne_50m_admin_1_states_provinces_lakes (Polygon)
88: ne_50m_admin_1_states_provinces_lines (Line String)
89: ne_50m_admin_1_states_provinces_scale_rank (Polygon)
90: ne_50m_airports (Point)
91: ne_50m_populated_places (Point)
92: ne_50m_populated_places_simple (Point)
93: ne_50m_ports (Point)
94: ne_50m_urban_areas (Polygon)
95: ne_50m_antarctic_ice_shelves_lines (Line String)
96: ne_50m_antarctic_ice_shelves_polys (Polygon)
97: ne_50m_coastline (Line String)
98: ne_50m_geographic_lines (Line String)
99: ne_50m_geography_marine_polys (Polygon)
100: ne_50m_geography_regions_elevation_points (Point)
101: ne_50m_geography_regions_points (Point)
102: ne_50m_geography_regions_polys (Polygon)
103: ne_50m_glaciated_areas (Polygon)
104: ne_50m_lakes (Polygon)
105: ne_50m_lakes_historic (Polygon)
106: ne_50m_land (Polygon)
107: ne_50m_ocean (Polygon)
108: ne_50m_playas (Polygon)
109: ne_50m_rivers_lake_centerlines (Line String)
110: ne_50m_rivers_lake_centerlines_scale_rank (Line String)
111: ne_110m_admin_0_boundary_lines_land (Line String)
112: ne_110m_admin_0_countries (Polygon)
113: ne_110m_admin_0_countries_lakes (Polygon)
114: ne_110m_admin_0_map_units (Polygon)
115: ne_110m_admin_0_pacific_groupings (Line String)
116: ne_110m_admin_0_scale_rank (Polygon)
117: ne_110m_admin_0_sovereignty (Polygon)
118: ne_110m_admin_0_tiny_countries (Point)
119: ne_110m_admin_1_states_provinces (Polygon)
120: ne_110m_admin_1_states_provinces_lakes (Polygon)
121: ne_110m_admin_1_states_provinces_lines (Line String)
122: ne_110m_admin_1_states_provinces_scale_rank (Polygon)
123: ne_110m_populated_places (Point)
124: ne_110m_populated_places_simple (Point)
125: ne_110m_coastline (Line String)
126: ne_110m_geographic_lines (Line String)
127: ne_110m_geography_marine_polys (Polygon)
128: ne_110m_geography_regions_elevation_points (Point)
129: ne_110m_geography_regions_points (Point)
130: ne_110m_geography_regions_polys (Polygon)
131: ne_110m_glaciated_areas (Polygon)
132: ne_110m_lakes (Polygon)
133: ne_110m_land (Polygon)
134: ne_110m_ocean (Polygon)
135: ne_110m_rivers_lake_centerlines (Line String)
</pre>

Printing summary of vector layer:

```ogrinfo -so natural_earth_vector.gpkg ne_110m_admin_0_countries```

<pre>
INFO: Open of `natural_earth_vector.gpkg'
      using driver `GPKG' successful.

Layer name: ne_110m_admin_0_countries
Metadata:
  DBF_DATE_LAST_UPDATE=2018-05-21
Geometry: Polygon
Feature Count: 177
Extent: (-180.000000, -90.000000) - (180.000000, 83.645100)
Layer SRS WKT:
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
    USAGE[
        SCOPE["Horizontal component of 3D system."],
        AREA["World."],
        BBOX[-90,-180,90,180]],
    ID["EPSG",4326]]
Data axis to CRS axis mapping: 2,1
FID Column = fid
Geometry Column = geom
featurecla: String (15.0)
scalerank: Integer (0.0)
LABELRANK: Integer (0.0)
SOVEREIGNT: String (32.0)
SOV_A3: String (3.0)
ADM0_DIF: Integer (0.0)
LEVEL: Integer (0.0)
TYPE: String (17.0)
ADMIN: String (35.0)
ADM0_A3: String (3.0)
GEOU_DIF: Integer (0.0)
GEOUNIT: String (35.0)
GU_A3: String (3.0)
SU_DIF: Integer (0.0)
SUBUNIT: String (35.0)
SU_A3: String (3.0)
BRK_DIFF: Integer (0.0)
NAME: String (24.0)
NAME_LONG: String (35.0)
BRK_A3: String (3.0)
BRK_NAME: String (32.0)
BRK_GROUP: String (80.0)
ABBREV: String (10.0)
POSTAL: String (4.0)
FORMAL_EN: String (52.0)
FORMAL_FR: String (35.0)
NAME_CIAWF: String (33.0)
NOTE_ADM0: String (22.0)
NOTE_BRK: String (36.0)
NAME_SORT: String (35.0)
NAME_ALT: String (14.0)
MAPCOLOR7: Integer (0.0)
MAPCOLOR8: Integer (0.0)
MAPCOLOR9: Integer (0.0)
MAPCOLOR13: Integer (0.0)
POP_EST: Integer64 (0.0)
POP_RANK: Integer (0.0)
GDP_MD_EST: Real (0.0)
POP_YEAR: Integer (0.0)
LASTCENSUS: Integer (0.0)
GDP_YEAR: Integer (0.0)
ECONOMY: String (26.0)
INCOME_GRP: String (23.0)
WIKIPEDIA: Integer (0.0)
FIPS_10_: String (3.0)
ISO_A2: String (3.0)
ISO_A3: String (3.0)
ISO_A3_EH: String (3.0)
ISO_N3: String (3.0)
UN_A3: String (4.0)
WB_A2: String (3.0)
WB_A3: String (3.0)
WOE_ID: Integer (0.0)
WOE_ID_EH: Integer (0.0)
WOE_NOTE: String (167.0)
ADM0_A3_IS: String (3.0)
ADM0_A3_US: String (3.0)
ADM0_A3_UN: Integer (0.0)
ADM0_A3_WB: Integer (0.0)
CONTINENT: String (23.0)
REGION_UN: String (23.0)
SUBREGION: String (25.0)
REGION_WB: String (26.0)
NAME_LEN: Integer (0.0)
LONG_LEN: Integer (0.0)
ABBREV_LEN: Integer (0.0)
TINY: Integer (0.0)
HOMEPART: Integer (0.0)
MIN_ZOOM: Real (0.0)
MIN_LABEL: Real (0.0)
MAX_LABEL: Real (0.0)
NE_ID: Integer64 (0.0)
WIKIDATAID: String (7.0)
NAME_AR: String (57.0)
NAME_BN: String (93.0)
NAME_DE: String (40.0)
NAME_EN: String (35.0)
NAME_ES: String (41.0)
NAME_FR: String (44.0)
NAME_EL: String (88.0)
NAME_HI: String (97.0)
NAME_HU: String (40.0)
NAME_ID: String (39.0)
NAME_IT: String (36.0)
NAME_JA: String (36.0)
NAME_KO: String (33.0)
NAME_NL: String (42.0)
NAME_PL: String (47.0)
NAME_PT: String (39.0)
NAME_RU: String (86.0)
NAME_SV: String (28.0)
NAME_TR: String (41.0)
NAME_VI: String (56.0)
NAME_ZH: String (33.0)
</pre>
