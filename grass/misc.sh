
# create new location (with epsg)
grass -c epsg:4326 /home/steve/grassdata/world

### set up
grass -text /home/steve/grass/osm/PERMANENT
g.mapset --overwrite mapset=PERMANENT location=world_3857
g.region --overwrite raster=topo15

g.remove -f type=all pattern="*"
g.remove -f type=raster pattern="*-000*"

g.region -s e=180 w=-180 n=90 s=-90
g.region -s e=20037508.3427892 w=-20037508.3427892 n=20037508.3427892 s=-20037508.3427892
r.region map=topo e=180 w=-180 n=90 s=-90

# import osm
g.extension v.in.osm
v.in.osm --overwrite -o in=/home/steve/Projects/maps/osm/toronto.pbf out=toronto

# convert
r.to.vect --overwrite -s in=direction out=direction_vect type=area
r.to.vect --overwrite -s in=direction_cubic out=direction_cubic_vect type=area

# export
v.out.ogr --overwrite type=area in=direction_vect out=topo15_${filename}_3000_direction.gpkg format=GPKG
v.out.ogr --overwrite type=area in=direction_cubic_vect out=topo15_${filename}_300_3000_direction.gpkg format=GPKG
v.out.ogr --overwrite type=line in=stream_network out=topo15_${filename}_3000_stream_network.gpkg format=GPKG
v.out.ogr --overwrite type=line in=stream_network_cubic out=topo15_${filename}_300_3000_stream_network.gpkg format=GPKG

# select mask
place='Thailand'
r.mask --overwrite vector=ne_10m_admin_0_map_subunits where="name='${place}'"
# cleanup
r.mask -r --overwrite

### common stuff
v.db.select map=countries columns=sovereignt
r.shade --overwrite shade=relief color=topo15 out=topo_relief
v.db.addcolumn rivers col="scalerank_100 int"
v.db.update rivers col=scalerank_100 qcol="scalerank*10"
v.colors rule="/home/steve/maps/cpt-city/ggr/Deep_Sea.pg" use=attr column=scalerank_100 map=rivers
v.extract --overwrite in=countries out=${country} where="(iso_a2 = '${country}')"
v.buffer --overwrite in=${country} out=${country}_buffer distance=2

# summary stats
r.univar $layer

# terrain
r.geomorphon --overwrite elevation=topo15_004 forms=topo15_004_forms
r.param.scale --overwrite in=topo15_4320_43200_epsg3857 output=topo15_4320_43200_epsg_3857_morphology method=feature size=9 zscale=1000
r.out.gdal --overwrite in=topo15_4320_43200_epsg_3857_morphology out=~/maps/srtm/topo15_4320_43200_epsg_3857_morphology.tif

# tile
g.region -p rast=topo15_4320_43200
r.tile input=topo15_4320_43200 output=topo15_4320_43200 width=21600 height=10800

# watershed
r.watershed --overwrite -m elevation=topo15 threshold=100 accumulation=accum_${place} basin=basin_${place} drainage=dir_${place} half_basin=halfbasin_${place}
#r.thin --overwrite input=dir_${place} output=dir_thin_${place} iterations=200
r.to.vect --overwrite -s input=dir_${place} output=dir_polygon_${place} type=area column=dir

r.watershed --overwrite elevation=topo15_${filename}_3000.1@PERMANENT threshold=10 accumulation=accum drainage=direction stream=streams
r.watershed --overwrite elevation=topo15_${filename}_300_3000.1@PERMANENT threshold=10 accumulation=accum_cubic drainage=direction_cubic stream=streams_cubic
r.stream.order --overwrite stream_rast=streams@PERMANENT direction=direction@PERMANENT elevation=topo15_${filename}_3000.1@PERMANENT accumulation=accum@PERMANENT stream_vect=stream_network
r.stream.order --overwrite stream_rast=streams_cubic@PERMANENT direction=direction_cubic@PERMANENT elevation=topo15_${filename}_300_3000.1@PERMANENT accumulation=accum_cubic@PERMANENT stream_vect=stream_network_cubic

### topo15 example

file=topo15_4320.tif
r.in.gdal input=~/maps/srtm/${file} band=1 output=${file%.*} --overwrite -o



# watershed for bathymetry
# grass -c epsg:4326 /home/steve/grassdata/bathymetry
g.remove -f type=all pattern="*"


file=topo15_4320_ocean.tif
r.in.gdal input=${file} band=1 output=${file%.*} --overwrite -o

g.proj 
g.region n=90.00208333333333 s=-90.0 e=180.00208333333333 w=-180.00208333333333 res=0.08333429783950617

r.watershed --overwrite elevation=${file%.*} threshold=100 convergence=5 memory=300 basin=basins 2>/dev/null

 accumulation=accumulation13ec72dda72149fcafbb48eef8d1746d drainage=drainage13ec72dda72149fcafbb48eef8d1746d basin=basin13ec72dda72149fcafbb48eef8d1746d stream=stream13ec72dda72149fcafbb48eef8d1746d half_basin=half_basin13ec72dda72149fcafbb48eef8d1746d length_slope=length_slope13ec72dda72149fcafbb48eef8d1746d slope_steepness=slope_steepness13ec72dda72149fcafbb48eef8d1746d tci=tci13ec72dda72149fcafbb48eef8d1746d spi=spi13ec72dda72149fcafbb48eef8d1746d 



r.in.gdal -lo --overwrite in=~/maps/srtm/${file} out=${layer}
g.region -p rast=${layer}
r.mapcalc --overwrite "${layer} = if(${layer} <= 100, ${layer} + 10207.5, null())"

# create ocean mask
#r.mapcalc --overwrite "mask = if(${layer} <= 100, 1, null())"
#r.mask --overwrite rast=mask

r.fill.dir input=${layer} output=${layer}_filled direction=${layer}_dir

r.watershed --overwrite -m elevation=${layer}_filled threshold=100 accumulation=accum basin=basins drainage=dir half_basin=halfbasins stream=streams 2>/dev/null
#r.stream.order --overwrite stream_rast=stream direction=dir elevation=${layer} accumulation=accum stream_vect=stream_network
r.contour --overwrite in=${layer} out=${layer}_100m step=100

r.to.vect --overwrite -s input=basin output=basin_polygon type=area column=dir
r.to.vect --overwrite -s input=halfbasin output=halfbasin_polygon type=area column=dir
r.to.vect --overwrite -s input=stream output=stream_polygon type=area column=dir



r.mask -r

### hydroatlas
# import
r.in.gdal -l --overwrite in=~/maps/srtm/topo15_004_lev01.tif out=topo15_004_lev01
v.in.ogr --overwrite in=~/maps/wwf/hydroatlas/RiverATLAS_v10.gdb out=rivers
v.in.ogr --overwrite in="PG:dbname=world user=steve" layer=basinatlas_v10_lev01 out=basins_lev01 type=boundary
# apply mask
#r.mask -r --overwrite
#r.mask --overwrite vect=basins_lev01
r.mask --overwrite rast=topo15_004_lev01

# relief
r.relief --overwrite zscale=200 altitude=45 azimuth=315 in=topo15_004_lev01 out=topo15_004_relief
r.mapcalc.simple --overwrite a=topo15_004_relief out=topo15_004_relief_mask exp="1*(A<=2)"
# loop relief
for a in 0 90 180 270; do
  r.relief --overwrite zscale=200 altitude=45 azimuth=${a} in=topo15_004 out=topo15_004_relief${a}
  r.mapcalc.simple --overwrite a=topo15_004_relief${a} out=topo15_004_relief${a}_mask exp="1*(A<=2)"
done

# slope, aspect
r.slope.aspect --overwrite -en precision=CELL elevation=topo15_004_lev01 slope=topo15_004_slope aspect=topo15_004_aspect

# convert rivers and calculate distance raster
v.extract --overwrite in=rivers out=rivers1000 where="upland_skm>=1000" type=line
v.to.rast --overwrite in=rivers1000 out=rivers1000_rast use=val value=1
r.grow.distance -m --overwrite input=rivers1000_rast distance=rivers1000_distance metric=geodesic
#r.contour --overwrite in=rivers1000_distance out=rivers1000_distance_contour1000 step=1000

# mask
r.mapcalc.simple --overwrite a=rivers1000_distance b=topo15_004_0004_lev01_hillshade_mask out=rivers1000_distance_mask exp="A*(B>0)"

# export
r.out.gdal --overwrite in=topo15_004_relief_mask out=~/maps/srtm/topo15_004_relief_mask.tif
r.out.gdal --overwrite in=rivers1000_distance_mask out=~/maps/wwf/hydroatlas/rivers1000_distance_mask.tif

### srtm
r.in.gdal -o --overwrite in=topo15.grd out=topo15
r.region map=topo15 e=180 w=-180 n=90 s=-90
g.region -s rast=topo15

# resample
g.region -a res=0.4
r.mask --overwrite vect=basins_lev01

r.resamp.interp --overwrite in=topo15 out=topo15_04 method=nearest
r.relief --overwrite zscale=10000000 scale=111120 altitude=45 azimuth=315 in=topo15_04 out=topo15_04_relief

r.out.gdal --overwrite in=topo15_04_relief out=~/maps/srtm/topo15_04_relief.tif

#cleanup
#r.mask -r --overwrite
#g.region rast=topo15
