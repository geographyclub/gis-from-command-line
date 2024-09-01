# maplibre-lab
Experiments in web mapping with MapLibre.  

### How I make MVT vector tiles

You will need BASH, GDAL and PostgreSQL/PostGIS.  

Night lights from OpenStreetMap points:  
```
#!/bin/bash

cd ~/maplibre-testing
rm -rf vector-tiles-nightlight

ogr2ogr -f MVT vector-tiles-nightlight PG:dbname=osm -sql "SELECT name, highway AS type, 1 + floor(random() * 10) AS radius, 1 + floor(random() * 9) AS color, (ST_DumpPoints(wkb_geometry)).geom::geometry(POINT,3857) wkb_geometry FROM toronto_lines WHERE highway IS NOT NULL UNION ALL SELECT name, 'amenity' AS type, 1 + floor(random() * 10) AS radius, 1 + floor(random() * 18) AS color, wkb_geometry FROM toronto_points WHERE other_tags LIKE '%amenity%'" -nlt POINT -nln points -dsco MINZOOM=10 -dsco MAXZOOM=15 -dsco COMPRESS=NO

cp nightlight.json vector-tiles-nightlight
cp cors_server.py vector-tiles-nightlight
cd vector-tiles-nightlight
./cors_server.py
```

Block world from SRTM and HydroATLAS:  
```
### prep in psql
# elevation
ALTER TABLE grid1 ADD COLUMN dem_mean INT;
UPDATE grid1 a SET dem_mean = (ST_SummaryStats(rast)).mean FROM topo15_4320 b WHERE ST_Intersects(b.rast, a.geom);

# slope
ALTER TABLE grid1 ADD COLUMN slope_mean INT;
UPDATE grid1 a SET slope_mean = (ST_SummaryStats(rast)).mean FROM topo15_4320_slope b WHERE ST_Intersects(b.rast, a.geom);

# flow accumulation
ALTER TABLE grid1 ADD COLUMN up_area INT;
UPDATE grid1 a SET up_area = b.up_area FROM basinatlas_v10_lev12 b WHERE ST_Intersects(a.geom, b.shape) AND ST_DWithin(a.geom, b.shape, 1);

# snow percentage
ALTER TABLE grid1 ADD COLUMN snw_pc_syr INT;
UPDATE grid1 a SET snw_pc_syr = b.snw_pc_syr FROM basinatlas_v10_lev12 b WHERE ST_Intersects(a.geom, b.shape) AND ST_DWithin(a.geom, b.shape, 1);

# climate moisture index
ALTER TABLE grid1 ADD COLUMN cmi_ix_syr INT;
UPDATE grid1 a SET cmi_ix_syr = b.cmi_ix_syr FROM basinatlas_v10_lev12 b WHERE ST_Intersects(a.geom, b.shape) AND ST_DWithin(a.geom, b.shape, 1);

### bash
cd ~/maplibre-testing
rm -rf vector-tiles-blockworld

ogr2ogr -f MVT -s_srs 'epsg:4326' -t_srs 'epsg:3857' vector-tiles-blockworld pg:dbname=world -sql "SELECT dem_mean, slope_mean, up_area, snw_pc_syr, cmi_ix_syr, geom FROM grid1" -nlt MULTIPOLYGON -nln blockworld -clipsrc -180 -90 180 90 -dsco MINZOOM=2 -dsco MAXZOOM=3 -dsco COMPRESS=NO

cp blockworld.json vector-tiles-blockworld
cp cors_server.py vector-tiles-blockworld
cd vector-tiles-blockworld
./cors_server.py
```

