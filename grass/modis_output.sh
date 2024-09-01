##### prepare modis data #####
# npp -- strip url
sed "s|ftp.*MOD||" links_npp.txt > files_npp.txt

# npp -- group, mosaic & transform
for year in 2000 2001 2002 2003 2004 2005 2006; do
	cat files_npp.txt | grep -E .*A$year.* > tmp.txt
	mrtmosaic -i tmp.txt -o mosaic_npp$year.hdf -s "1"
	echo -e "input_filename=mosaic_npp$year.hdf\noutput_filename=npp$year.hdf\nresampling_type=NN\noutput_projection_type=UTM\nutm_zone=15\ndatum=WGS84"  > tmp.prm
	resample -p tmp.prm
done

# ndvi -- strip url
sed "s|ftp.*MOD||" links_ndvi.txt > files_ndvi.txt

# ndvi -- find doy
sed "s|ftp.*MOD13A3.A||" links_ndvi.txt > tmp.txt
sed -i "s|.h.*.hdf||" tmp.txt
doy=`uniq tmp.txt`

# ndvi -- group, mosaic & transform
for a in $doy; do
	cat files_ndvi.txt | grep -E .*A$a.* > tmp.txt
	mrtmosaic -i tmp.txt -o mosaic_ndvi$a.hdf -s "1"
	echo -e "input_filename=mosaic_ndvi$a.hdf\noutput_filename=ndvi$a.hdf\nresampling_type=NN\noutput_projection_type=UTM\nutm_zone=15\ndatum=WGS84" > tmp.prm
	resample -p tmp.prm
done

# lc -- strip url
sed "s|ftp.*MOD||" links_lc.txt > files_lc.txt

# lc -- group, mosaic & transform
for year in 2001 2002 2003 2004; do
	cat files_lc.txt | grep -E .*A$year.* > tmp.txt
	mrtmosaic -i tmp.txt -o mosaic_lc$year.hdf -s "1"
	echo -e "input_filename=mosaic_lc$year.hdf\noutput_filename=lc$year.hdf\nresampling_type=NN\noutput_projection_type=UTM\nutm_zone=15\ndatum=WGS84" > tmp.prm
	resample -p tmp.prm
done

##### import base data #####
g.mapset mapset=thesis_geo location=ontario_geo
g.mremove rast=* -f
g.mremove vect=* -f

# import boundary
v.in.e00 file=grnf035r02a_e.e00 type=area vect=boundary --overwrite
g.region vect=boundary

# import roads
v.in.e00 file=gsrn035r02a_e.e00 type=line vect=roads --overwrite

##### import modis data #####
g.mapset mapset=thesis_utm location=ontario_utm
g.mremove rast=* -f
g.mremove vect=* -f

# import annual npp
for file in `ls $PWD | grep -E ^npp`; do
	r.in.gdal in=$file out=${file%.*} --overwrite
done

# import ndvi
for file in `ls $PWD | grep -E ^ndvi`; do
	r.in.gdal in=$file out=${file%.*} --overwrite
done

# import landcover
for file in `ls $PWD | grep -E ^lc`; do
	r.in.gdal in=$file out=${file%.*} --overwrite
done

# create atikokan site
v.edit map=atikokan type=point tool=create --overwrite
v.build atikokan
echo "P 1 1
604417 5409666
1 1" | v.edit -n tool=add map=atikokan

##### process data #####
g.mapset mapset=thesis_utm location=ontario_utm

# transform roads & boundary
v.proj in=roads location=ontario_geo mapset=thesis_geo --overwrite
v.proj in=ont location=ontario_geo mapset=thesis_geo --overwrite
g.region vect=ont

# merge boundary
v.extract -d in=ont out=ontario type=area new=1 --overwrite

# convert boundary to raster
v.to.rast in=ontario out=ontario_rast use=val value=1 --overwrite

# apply modis multipliers (npp: kg/m2/year)
for b in `g.mlist rast pattern=*`; do
#	if [[ $b == ndvi* ]]; then r.mapcalc $b="if($b<-2000,null(),$b)"; r.mapcalc $b="if($b>10000,null(),$b)"; r.mapcalc $b=$b*0.0001; fi;
	if [[ $b == npp* ]]; then r.mapcalc $b="if($b<0,null(),$b)"; r.mapcalc $b="if($b>30000,null(),$b)"; r.mapcalc $b=$b*0.0001; fi;
done

##### do some analysis #####

##### stats #####
# output fri stats
echo 'bio bio1 bio2 bio3 bio4 bio5 vol wg age sc stkg cai' > fri.txt
r.stats -1 in=bio,bio1,bio2,bio3,bio4,bio5,vol,wg,age,sc,stkg,cai >> fri.txt

# output modis stats
echo npp2001 npp2002 npp2003 npp2004 npp2005 npp2006 npp_total npp_average npp_slope ndvi2001 ndvi2002 ndvi2003 ndvi2004 ndvi2005 ndvi2006 ndvi_average 2001-2002 2002-2003 2003-2004 2004-2005 2005-2006 > modis.txt
r.stats -1 in=npp2001,npp2002,npp2003,npp2004,npp2005,npp2006,npp_total,npp_average,npp_slope,ndvi2001,ndvi2002,ndvi2003,ndvi2004,ndvi2005,ndvi2006,ndvi_average,npp2001npp2002,npp2002npp2003,npp2003npp2004,npp2004npp2005,npp2005npp2006 >> modis.txt

# output optimal stats
echo bo3 bo33 bo63 no3 no33 no63 ppo3 nppo33 nppo63 npp_slope_opt63 cai6_opt63 > opt.txt
r.stats -1 in=bio_opt3,bio_opt33,bio_opt63,ndvi_opt3,ndvi_opt33,ndvi_opt63,npp_opt3,npp_opt33,npp_opt63,npp_slope_opt63,cai6_opt63 >> opt.txt

##### output maps #####
map=()
d.mon start=x0
d.erase; d.rast $map; d.legend $map -s; d.out.file -c out=$map --overwrite
d.mon stop=x0

# output optimal maps (current)
d.mon start=x0
for a in 3 33 63; do
	d.erase; d.rast bio_avg$a; d.vect line_bio_opt$a type=line; d.legend bio_avg$a; d.out.file -c out=bio$a --overwrite
	d.erase; d.rast ndvi_avg$a; d.vect line_ndvi_opt$a type=line; d.legend ndvi_avg$a; d.out.file -c out=ndvi$a --overwrite
	d.erase; d.rast npp_avg$a; d.vect line_npp_opt$a type=line; d.legend npp_avg$a; d.out.file -c out=npp$a --overwrite
done
d.mon stop=x0

# output optimal maps (projected)
d.mon start=x0
d.erase; d.rast npp_slope_avg63; d.vect line_npp_slope_opt63 type=line; d.legend npp_slope_avg63; d.out.file -c out=npp_slope63 --overwrite
d.erase; d.rast cai6_avg63; d.vect line_cai6_opt63 type=line; d.legend cai6_avg63; d.out.file -c out=cai6 --overwrite
d.mon stop=x0

