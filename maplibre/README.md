# maplibre-lab
Experiments in web mapping with MapLibre.  

Use a cors server (like cors_server.py) to test this on a local machine.  

### How I make MVT vector tiles

You will need BASH, GDAL and PostgreSQL/PostGIS installed.  

Night lights from OpenStreetMap points:  
```
cd ~/maplibre-testing
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
cd ~/maplibre-testing
rm -rf vector-tiles-blockworld

ogr2ogr -f MVT -s_srs 'epsg:4326' -t_srs 'epsg:3857' vector-tiles-blockworld pg:dbname=world -sql "SELECT dem_mean, geom FROM grid1" -nlt MULTIPOLYGON -nln blockworld -clipsrc -180 -90 180 90 -dsco MINZOOM=2 -dsco MAXZOOM=3 -dsco COMPRESS=NO

cp blockworld.json vector-tiles-blockworld
cp cors_server.py vector-tiles-blockworld
cd vector-tiles-blockworld
./cors_server.py
```

OpenStreetMap buildings  
```
cd ~/maplibre-testing
rm -rf osm_polygons

ogr2ogr -f MVT -t_srs 'epsg:3857' osm_polygons pg:dbname=osm -sql "SELECT osm_id, name, building, other_tags, COALESCE(split_part(regexp_replace(hstore(other_tags)->'height', '[^0-9.]', '', 'g'), '.', 1)::INT, split_part(regexp_replace(hstore(other_tags)->'levels', '[^0-9.]', '', 'g'), '.', 1)::INT * 10, 10) AS height, wkb_geometry FROM toronto_polygons WHERE building IS NOT NULL" -nlt POLYGON -nln osm_polygons -dsco MINZOOM=16 -dsco MAXZOOM=18 -dsco COMPRESS=NO

cp osm_polygons.json osm_polygons
cp cors_server.py osm_polygons
cd osm_polygons
./cors_server.py
```

OpenStreetMap lines
```
cd ~/maplibre-testing
rm -rf osm_lines

# -dsco BUFFER=100 -dsco MAX_SIZE=1000000 -dsco MAX_FEATURES=2000000
ogr2ogr -f MVT -t_srs 'epsg:3857' osm_lines pg:dbname=osm -sql "SELECT osm_id, name, highway, other_tags, wkb_geometry FROM toronto_lines" -nlt LINESTRING -nln osm_lines -dsco MINZOOM=16 -dsco MAXZOOM=18 -dsco COMPRESS=NO

cp osm_lines.json osm_lines
cp cors_server.py osm_lines
cd osm_lines
./cors_server.py 8001
```

OpenStreetMap points
```
cd ~/maplibre-testing
rm -rf osm_points

# -dsco BUFFER=100 -dsco MAX_SIZE=1000000 -dsco MAX_FEATURES=2000000
ogr2ogr -f MVT -t_srs 'epsg:3857' osm_points pg:dbname=osm -sql "SELECT osm_id, name, highway, place, other_tags, ST_ClusterDBSCAN(wkb_geometry, eps:=10, minpoints:=5) OVER () AS clusterid, wkb_geometry FROM toronto_points" -nlt POINT -nln osm_points -dsco MINZOOM=15 -dsco MAXZOOM=15 -dsco COMPRESS=NO

cp osm_points.json osm_points
cp cors_server.py osm_points
cd osm_points
./cors_server.py
```
