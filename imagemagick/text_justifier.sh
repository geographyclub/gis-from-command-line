#!/bin/bash

file='/home/steve/data/tmp/select.csv'
rm -f /home/steve/data/tmp/*.ppm

# select data
psql -d world -c "\COPY (SELECT a.field_2, a.field_3, a.field_4, a.field_5, round(a.field_7), round(a.field_8) FROM airports a WHERE a.scalerank IN (2)) TO STDOUT DELIMITER E'\t'" > ${file}

# make captions
cat ${file} | while IFS=$'\t' read -a array; do 
  name=($(echo ${array[0]} | tr '-' ' '))
  for ((a=0; a<${#name[@]}; a=a+1)); do
    convert -background White -fill Black -font '/home/steve/.fonts/fonts-master/ofl/ibmplexmono/IBMPlexMono-SemiBold.ttf' -size 1000x -interline-spacing 0 label:${name[a]^^} -trim +repage -resize 1000x -bordercolor White -border 10 /home/steve/data/tmp/${array[3]}${a}.ppm
  done
  convert -append $(ls -v /home/steve/data/tmp/${array[3]}*.ppm) /home/steve/data/tmp/${array[3]}_name.ppm
done

cat ${file} | while IFS=$'\t' read -a array; do 
  convert -background White -fill Black -font '/home/steve/.fonts/fonts-master/ofl/ibmplexmono/IBMPlexMono-SemiBold.ttf' -size 1000x -interline-spacing 0 label:${array[3]^^} -trim +repage -resize 1000x -bordercolor White -border 10 /home/steve/data/tmp/${array[3]}_id.ppm
  convert -append /home/steve/data/tmp/${array[3]}_id.ppm /home/steve/data/tmp/${array[3]}_name.ppm /home/steve/data/tmp/${array[3]}_final.ppm
done

# vectorize
potrace --progress -b svg --alphamax 1.0 --color \#000000 --opttolerance 0.2 --turdsize 0 --turnpolicy min --unit 10 --output ${dir}/id_${id}.svg /home/steve/data/tmp/id_${id}.ppm

# color
rm -f ${dir}/*b.svg
ls ${dir}/*.svg | while read file; do 
  cat ${file} | sed 's/fill=\"#000000\"/fill=\"#ffffff\"/g' | sed 's/stroke=\"none\"/stroke=\"#000000\" stroke-width=\"10\" vector-effect=\"non-scaling-stroke\"/g' > ${file%.svg}b.svg
done
