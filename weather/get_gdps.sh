#!/bin/bash

##### download #####
#dir=$PWD/../data/gdps/utc$(date -u +"%Y%m%d")
#mydate=$(date -u +"%Y%m%d")
modelhour=12
dir=/home/steve/data/gdps
mydate=$(date +"%Y%m%d")
rm -f ${dir}/*
for a in $(seq -f "%03g" 0 3 24); do
#for a in $(seq -f "%03g" 0 3 240); do
  wget -P ${dir} https://dd.weather.gc.ca/model_gem_global/15km/grib2/lat_lon/${modelhour}/${a}/CMC_glb_PRATE_SFC_0_latlon.15x.15_${mydate}${modelhour}_P${a}.grib2
  wget -P ${dir} https://dd.weather.gc.ca/model_gem_global/15km/grib2/lat_lon/${modelhour}/${a}/CMC_glb_PRMSL_MSL_0_latlon.15x.15_${mydate}${modelhour}_P${a}.grib2
  wget -P ${dir} https://dd.weather.gc.ca/model_gem_global/15km/grib2/lat_lon/${modelhour}/${a}/CMC_glb_TCDC_SFC_0_latlon.15x.15_${mydate}${modelhour}_P${a}.grib2
  wget -P ${dir} https://dd.weather.gc.ca/model_gem_global/15km/grib2/lat_lon/${modelhour}/${a}/CMC_glb_TMP_TGL_2_latlon.15x.15_${mydate}${modelhour}_P${a}.grib2;
done

##### extract #####
#psql -d world -c "COPY (SELECT * FROM ne_10m_populated_places) TO STDOUT;" > /home/steve/data/places.csv
#echo "extracting gribs..."
#for a in TMP PRATE TCDC; do
#  ls ${dir}/*${a}*.grib2 | while read file; do
#    hour=`echo ${file} | sed 's/^.*_P//g' | sed 's/.grib2//g'`
#    /home/steve/data/grib2/wgrib2/wgrib2 ${file} `cat /home/steve/data/places.csv | sed -n '1,2000p' | awk -F '\t' '{print "-lon",$23,$22}' | tr '\n' ' '` | tr ':' '\n' | grep 'val=' | sed -e 's/^.*val=//g' > ${dir}/${a}${hour}.txt
#    /home/steve/data/grib2/wgrib2/wgrib2 ${file} `cat /home/steve/data/places.csv | sed -n '2001,4000p' | awk -F '\t' '{print "-lon",$23,$22}' | tr '\n' ' '` | tr ':' '\n' | grep 'val=' | sed -e 's/^.*val=//g' >> ${dir}/${a}${hour}.txt
#    /home/steve/data/grib2/wgrib2/wgrib2 ${file} `cat /home/steve/data/places.csv | sed -n '4001,7343p' | awk -F '\t' '{print "-lon",$23,$22}' | tr '\n' ' '` | tr ':' '\n' | grep 'val=' | sed -e 's/^.*val=//g' >> ${dir}/${a}${hour}.txt
#  done
#done
#awk -F '\t' '{print $1}' $PWD/../data/places.csv | paste - $(ls -v ${dir}/TMP*.txt | tr '\n' ' ') $(ls -v ${dir}/PRATE*.txt | tr '\n' ' ') $(ls -v ${dir}/TCDC*.txt | tr '\n' ' ') > ${dir}/gdps_places.csv
