#!/bin/bash
set -e

#  wgetURL URL that contains remote files
#+ variables with an asterisk (*) should be modified if needed
#+ WRKSPC* Workspace in HOME folder
wgetURL="ftp://ftp2.cits.rncan.gc.ca/pub/geobase/official/cgn/250k_shp_eng/"
#                                                             ^^^^^^^^^^^^
WRKSPC=${HOME}/Downloads/geonames
#              ^^^^^^^^^^^^^^^^^^^^^^^


#  Create workspace if it doesn't exist:
if [ ! -d ${WRKSPC} ]; then
    mkdir -p ${WRKSPC}
fi


#  Retrieve index.html files and place them in their own folders
#+ Update --cut-dirs as needed
#wget -N -P ${WRKSPC} ${wgetURL} && wget -N -x -nH --cut-dirs=5 -P ${WRKSPC} --force-html -i ${WRKSPC}/index.html
#                                                            ^

#  Extract urls using awk:
#+ ...see www.unix.com/302462271-post4.html
echo "Extracting urls with crazy awk command..."
urlRIP=$(find ${WRKSPC}/*/ -type f -name index.html -exec awk 'BEGIN{ RS="<a *href *= *\""} NR>2 {sub(/".*/,"");print; }' '{}' \;)


#  Get ready for creating empty feature to merge with others
#+ ...see gis.stackexchange.com/a/16510/1297
#+
#+ inZIP     single remote zip with data to use as template
#+ BASENM    remove pathname from filename
#+ SUFX      suffix for filename ending
#+ INPUT*    prepare filename to search for inside remote zip file
#+ FLDR*     output folder
#+ OUTPUT    output filename
#+ VSI*      command where zip is nested in curl
VSI=/vsizip/vsicurl
#    ^^^^^^^^^^^^^^
inZIP=$(for i in ${urlRIP}; do echo ${i}; done | head -1)
SUFX="geoname.shp"
#     ^^^^^^^^^^^
BASENM=$(basename ${inZIP})
INPUT=${BASENM:4:5}${SUFX}
#              ^^^
FLDR=${WRKSPC}/merged
#              ^^^^^^
OUTPUT=${FLDR}/${SUFX}


#  Create output folder if it doesn't exist:
if [ ! -d ${FLDR} ]; then
    mkdir -p ${FLDR}
fi


#echo "Assessing feature..."
#ogrinfo -ro -al -so ${VSI}/${inZIP}/${INPUT}
echo "Creating empty feature..."
ogr2ogr -f "ESRI Shapefile" ${OUTPUT} ${VSI}/${inZIP}/${INPUT} -progress -fid "< 0"

#  Modify below for a batch merge, this example uses echo as an example:
for i in ${urlRIP}
 do 
     BASENM=$(basename ${i})
     INPUT=${BASENM:4:5}${SUFX}
#                   ^^^
     echo "Merging: ${INPUT} ..."
     ogr2ogr -f "ESRI Shapefile" ${OUTPUT} -update -append -progress ${VSI}/${i}/${INPUT}
done

exit
