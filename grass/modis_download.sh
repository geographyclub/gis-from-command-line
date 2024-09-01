# remove old data
rm $PWD/*

##### npp #####
# get subdirectory names
myDirectories=`lynx -dump -crawl ftp://e4ftl01.cr.usgs.gov/MOLT/MOD17A3.004/ | awk '{print $5'} | awk '/./'`

# get filenames
rm links_npp.txt
for a in $myDirectories; do
	lynx -dump ftp://e4ftl01.cr.usgs.gov/MOLT/MOD17A3.004/$a | grep -E 'h11|h12|h13' | grep -E 'v02|v03|v04' | grep -E '.hdf$' | awk '{print $2'} >> links_npp.txt
done
chmod 777 links_npp.txt

# download npp
wget -w 10 -nd -P $PWD -i links_npp.txt

##### ndvi #####
# get subdirectory names
myDirectories=`lynx -dump -crawl ftp://e4ftl01.cr.usgs.gov/MOLT/MOD13A3.005/ | awk '{print $5'} | awk '/./'`

# get filenames
rm links_ndvi.txt
for a in $myDirectories; do
	lynx -dump ftp://e4ftl01.cr.usgs.gov/MOLT/MOD13A3.005/$a | grep -E 'h11|h12|h13' | grep -E 'v02|v03|v04' | grep -E '.hdf$' | grep -E 'A2000|A2001|A2002|A2003|A2004|A2005|A2006' | awk '{print $2'} >> links_ndvi.txt
done
chmod 777 links_ndvi.txt

# download ndvi
wget -w 10 -nd -P $PWD -i links_ndvi.txt

##### lc #####
# get subdirectory names
myDirectories=`lynx -dump -crawl ftp://e4ftl01.cr.usgs.gov/MOLT/MOD12Q1.004/ | awk '{print $5'} | awk '/./'`

# get filenames
rm links_lc.txt
for a in $myDirectories; do
	lynx -dump ftp://e4ftl01.cr.usgs.gov/MOLT/MOD12Q1.004/$a | grep -E 'h11|h12|h13' | grep -E 'v02|v03|v04' | grep -E '.hdf$' | awk '{print $2'} >> links_lc.txt
done
chmod 777 links_lc.txt

# download lc
wget -w 10 -nd -P $PWD -i links_lc.txt
