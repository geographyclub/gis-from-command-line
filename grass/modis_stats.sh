##### process npp data #####
g.mapset npp
g.mapsets addmapset=fri,modis,final
g.region rast=ndvi@modis
g.mremove rast=* -f
g.mremove vect=* -f

# study site extent
ymax=5447047.136
ymin=5400387.136
xmax=680137.04 
xmin=630257.04

# transform and clip npp data
for a in `ls $PWD | grep Npp | grep tif`; do
	gdalwarp -t_srs '+proj=utm +zone=15 +datum=nad83' -tr 1000 1000 -te $xmin $ymin $xmax $ymax $a npp${a:13:4}
done

# import annual npp (gC/m2/year)
for a in `ls $PWD | grep npp`; do
	r.in.gdal in=$a out=$a --overwrite
done

# process npp data
for a in `g.mlist rast pattern=npp*`; do
	r.mapcalc $a="if($a>30000,0,$a)"
	r.mapcalc $a="$a*0.1"
done

# create mean annual ndvi
for a in 2000 2001 2002 2003 2004 2005 2006; do
	r.mapcalc ndvi$a="(`g.mlist rast pattern=MOD13Q1.A$a*NDVI* sep="+"`)/(`g.mlist rast pattern=MOD13Q1.A$a*NDVI* | wc -l`)"
done

# get time series npp stats
for a in average minimum maximum stddev slope offset detcoeff min_raster max_raster; do
	r.series in=`g.mlist rast pattern=npp200* mapset=npp sep=","` out=npp_$a method=$a --overwrite
done

# get time series ndvi stats
for a in average minimum maximum stddev slope offset detcoeff min_raster max_raster; do
	r.series in=`g.mlist rast pattern=ndvi200* mapset=npp sep=","` out=ndvi_$a method=$a --overwrite
done

# get year-to-year npp slope
year=(npp2000 npp2001 npp2002 npp2003 npp2004 npp2005 npp2006)
for a in {0..5}; do
	b=$((a+1))
	r.series in=${year[$a]},${year[$b]} out=${year[a]}${year[b]} method=slope --overwrite
done

# get total npp
r.mapcalc npp_total="npp2000+npp2001+npp2002+npp2003+npp2004+npp2005+npp2006"

# compute neighborhood averages (neighbor size = 33)
for a in npp2000 npp2001 npp2002 npp2003 npp2004 npp2005 npp2006; do
	r.neighbors -c in=$a out=$a"_avg" method=average size=33 --overwrite
done

# extract third quartile of npp_average as optimal areas (neighbor size = 33)
for a in npp2000 npp2001 npp2002 npp2003 npp2004 npp2005 npp2006; do
	eval `r.univar -ge map=$a"_avg"`
	r.mapcalc $a"_opt"="if($a"_avg">=$third_quartile,npp_average,null())"
done

# create binary maps for landscape analysis (neighbor size = 33)
for a in npp2000 npp2001 npp2002 npp2003 npp2004 npp2005 npp2006; do
	r.mapcalc $a"_bin"="if($a"_opt">=0,1,0)"; r.null map=$a"_bin" null=0
done

# vectorize optimal areas for display (neighbor size = 33)
for a in `g.mlist -r rast pattern=opt mapset=npp`; do
	r.mapcalc temp="if($a>=0,1,null())"
	r.to.vect -s in=temp out=area_$a feature=area --overwrite
	v.type in=area_$a out=line_$a type=boundary,line --overwrite
done

# for slope, compute neighborhood averages (neighbor size = 33)
for a in npp2000npp2001 npp2001npp2002 npp2002npp2003 npp2003npp2004 npp2004npp2005 npp2005npp2006; do
	r.neighbors -c in=$a out=$a"_avg" method=average size=33 --overwrite
done

# for slope, extract third quartile of npp_total as optimal areas (neighbor size = 33)
for a in npp2000npp2001 npp2001npp2002 npp2002npp2003 npp2003npp2004 npp2004npp2005 npp2005npp2006; do
	eval `r.univar -ge map=$a"_avg"`
	r.mapcalc $a"_opt"="if($a"_avg">=$third_quartile,npp_average,null())"
done

# for slope, create binary maps for landscape analysis (neighbor size = 33)
for a in npp2000npp2001 npp2001npp2002 npp2002npp2003 npp2003npp2004 npp2004npp2005 npp2005npp2006; do
	r.mapcalc $a"_bin"="if($a"_opt">=0,1,0)"; r.null map=$a"_bin" null=0
done

# for slope, vectorize optimal areas for display (neighbor size = 33)
for a in `g.mlist rast pattern=npp*npp*opt mapset=npp`; do
	r.mapcalc temp="if($a>=0,1,null())"
	r.to.vect -s in=temp out=area_$a feature=area --overwrite
	v.type in=area_$a out=line_$a type=boundary,line --overwrite
done

# combine optimal areas for npp and slope (2006)
r.mapcalc npp2006_include="if(npp2005npp2006_bin+npp2006_bin==2,1,0)"
r.to.vect -s in=npp2006_include out=area_npp2006_include feature=area --overwrite
v.type in=area_npp2006_include out=line_npp2006_include type=boundary,line --overwrite

r.mapcalc npp2006_exclude="if(npp2005npp2006_bin+npp2006_bin==2,0,1)"
r.to.vect -s in=npp2006_exclude out=area_npp2006_exclude feature=area --overwrite
v.type in=area_npp2006_exclude out=line_npp2006_exclude type=boundary,line --overwrite

