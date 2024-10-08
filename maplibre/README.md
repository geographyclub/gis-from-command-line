# maplibre-lab
Experiments in web mapping with MapLibre.  

Use a cors server (like cors_server.py) to test this on a local machine.  

### How I make MVT vector tiles

You will need BASH, GDAL and PostgreSQL/PostGIS installed.  

Night lights from OpenStreetMap points:  
```
#!/bin/bash

cd ~/maplibre
rm -rf vector-tiles-nightlight

ogr2ogr -f MVT vector-tiles-nightlight PG:dbname=osm -sql "SELECT name, highway AS type, 1 + floor(random() * 10) AS radius, 1 + floor(random() * 9) AS color, (ST_DumpPoints(wkb_geometry)).geom::geometry(POINT,3857) wkb_geometry FROM toronto_lines WHERE highway IS NOT NULL UNION ALL SELECT name, 'amenity' AS type, 1 + floor(random() * 10) AS radius, 1 + floor(random() * 18) AS color, wkb_geometry FROM toronto_points WHERE other_tags LIKE '%amenity%'" -nlt POINT -nln points -dsco MINZOOM=10 -dsco MAXZOOM=15 -dsco COMPRESS=NO

cp nightlight.json vector-tiles-nightlight
cp cors_server.py vector-tiles-nightlight
cd vector-tiles-nightlight
./cors_server.py
```

Block world from polygon grid and dem raster:  
```
### prep in psql
# elevation
ALTER TABLE grid1 ADD COLUMN dem_mean INT;
UPDATE grid1 a SET dem_mean = (ST_SummaryStats(rast)).mean FROM topo15_4320 b WHERE ST_Intersects(b.rast, a.geom);

### bash
cd ~/maplibre
rm -rf vector-tiles-blockworld

ogr2ogr -f MVT -s_srs 'epsg:4326' -t_srs 'epsg:3857' vector-tiles-blockworld pg:dbname=world -sql "SELECT dem_mean, geom FROM grid1" -nlt MULTIPOLYGON -nln blockworld -clipsrc -180 -90 180 90 -dsco MINZOOM=2 -dsco MAXZOOM=3 -dsco COMPRESS=NO

cp blockworld.json vector-tiles-blockworld
cp cors_server.py vector-tiles-blockworld
cd vector-tiles-blockworld
./cors_server.py
```

