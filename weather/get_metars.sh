#!/bin/bash

### download metars
# https://aviationweather.gov/data/cache/metars.cache.xml.gz
curl "https://aviationweather.gov/data/cache/metars.cache.csv.gz" | gunzip -c | sed '1,5d' > metars.csv

### make vrt file
cat > metars.vrt <<- EOM
<OGRVRTDataSource>
  <OGRVRTLayer name='metars'>
    <SrcDataSource>metars.csv</SrcDataSource>
    <LayerSRS>EPSG:4326</LayerSRS>
    <GeometryType>wkbPoint</GeometryType>
    <GeometryField encoding="PointFromColumns" x="longitude" y="latitude"/>
    <Field name="raw_text" type="String"/>
    <Field name="station_id" type="String"/>
    <Field name="observation_time" type="String"/>
    <Field name="latitude" type="Real"/>
    <Field name="longitude" type="Real"/>
    <Field name="temp_c" type="Real"/>
    <Field name="dewpoint_c" type="Real"/>
    <Field name="wind_dir_degrees" type="Real"/>
    <Field name="wind_speed_kt" type="Real"/>
    <Field name="wind_gust_kt" type="Real"/>
    <Field name="visibility_statute_mi" type="Real"/>
    <Field name="altim_in_hg" type="Real"/>
    <Field name="sea_level_pressure_mb" type="Real"/>
    <Field name="quality_control_flags" type="String"/>
    <Field name="wx_string" type="String"/>
    <Field name="sky_condition" type="String"/>
    <Field name="flight_category" type="String"/>
    <Field name="three_hr_pressure_tendency_mb" type="Real"/>
    <Field name="maxT_c" type="Real"/>
    <Field name="minT_c" type="Real"/>
    <Field name="maxT24hr_c" type="Real"/>
    <Field name="minT24hr_c" type="Real"/>
    <Field name="precip_in" type="Real"/>
    <Field name="pcp3hr_in" type="Real"/>
    <Field name="pcp6hr_in" type="Real"/>
    <Field name="pcp24hr_in" type="Real"/>
    <Field name="snow_in" type="Real"/>
    <Field name="vert_vis_ft" type="Real"/>
    <Field name="metar_type" type="String"/>
    <Field name="elevation_m" type="Real"/>
    <SrcSQL>SELECT * FROM metars WHERE temp_c != ''</SrcSQL>
  </OGRVRTLayer>
</OGRVRTDataSource>
EOM

### use vrt to convert to points
ogr2ogr -overwrite -s_srs 'EPSG:4326' -t_srs 'EPSG:4326' metars_point.gpkg metars.vrt

### import to psql
ogr2ogr -overwrite -s_srs 'EPSG:4326' -t_srs 'EPSG:4326' PG:dbname=world -nln metars metars.vrt
