#!/bin/bash
set -e
# ---------------------------------------------------------------------------
# CanVecSHP - merges canvec shapefile tiles into organized folders with names

# Copyright 2013, Donovan Cameron (sault.don@gmail.com)

# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.

# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License at (http://www.gnu.org/licenses/) for
# more details.

# Usage: CanVecSHP.sh (set exec bit before running, chmod +x CanVecSHP.sh)

# Revision history:
# 2011-05-29    Created
# ---------------------------------------------------------------------------

# Introduction
read -p "
##################################################
# Welcome to the CanVec Shapefile Maker v1	 #
# 	by Donovan Cameron (June 2011)		 #
#		http://indigenis.blogspot.com
#
# Tested on or uses the following:
#	-Ubuntu 10.04 x64 (Lucid)
#	-GDAL 1.6.3 (ogr2ogr)
#	-CanVec 8th Release (June 2011)
#		-shapefile format 
#
# This script will find and unzip all the zip
# files downloaded from Canvec from a folder
# and it's subdirectories:
#
#		ftp://ftp2.cits.rncan.gc.ca
#			- /pub/canvec/50k_shp
#   HOME 
#   ├──
#   |   GIS
#   |	├── canvec
#   |	│   ├── 50k_shp
#   |	│   │   ├── 082
#   |	│   │   │   ├── a/*.zip
#   |	│   │   │   ├── b/...
#   |	│   │   │   ├── c/...
#
# Zip files are unzipped to a folder (shp) in a
# workspace you provide. (ex, GIS/canvec/50k_shp)
#
# The files are then analyzed to determine the
# CanVec features present and then:
#		-sorted into folders
#		-renamed			 #
#		-merged (with ogr2ogr)		 #
##################################################
[ENTER]"


# Set a workspace with a user prompt
read -p "
**************************************************
* 	       Input your workspace.		 *
*						 *
*  This workspace has to be in your HOME folder. *
*						 *
*	Remember, Linux is CaSe SenSiTivE!	 *
*						 *
* 	- example: GIS/canvec/50k_shp		 *
**************************************************
workspace: " wrkspc

# Prompt user that workspace has been entered
read -p "
# Workspace set to: $wrkspc
[ENTER] to begin..."
cd "$wrkspc"

# Start time (overall)
START=$(date +%s.%N)


echo "
# Assessing zip files from: ~/$wrkspc"

# Start time for zip file search (overall)
zipasmS=$(date +%s.%N)

# Get total zip files
ziptotal=$(find . -type f -name 'canvec_*_shp.zip' | wc -l)
# Get zip file size in MB
zipmb=$(find . -type f -name "*.zip" -printf "%s\n" | awk '{total += $1} END {printf "%.2f\n", total/(1024*1024)}')
# Get zip file size in GB
zipgb=$(echo $zipmb | awk '{mb = $1} END {printf "%.2f\n", mb / 1024}')

# Finish time for zip file search (overall)
zipasmF=$(date +%s.%N)
# Compare search start/finish time (overall)
zipasmDIFF=$(echo $zipasmF $zipasmS | awk 'END {printf "%.2f\n", $1 - $2}')

echo "	* $ziptotal files found ($zipgb GB / $zipmb MB)
		* finished in $zipasmDIFF s"

# Create required folders
echo "
# Creating required folders..."
  # Create folder: shp
  mkdir shp
echo "	* made folder: shp"

# Create folders: pt, ln and ply inside shp folder
for i in pt \ln ply
do
  mkdir shp/$i
  echo "		* subfolder: /$i"
done


# Unzipping begins

# Unzip start time (overall)
unzipS=$(date +%s.%N)
echo "
# Unzipping $ziptotal zip files into folder: ~/$wrkspc/shp"

# Unzip start time (individual)
zipS=$(date +%s.%N)

# For loop finds all zip files and unzips them
count=0
for i in `find . -type f -name "canvec_*_shp.zip" | sort`
do
  # Unzip command
	# -j junk zip folders/dirs, -o force overwrite, -q quiet mode
	# items that follow an '*' are the only file types extracted
count=$(expr $count + 1)
  unzip -joq "$i" -d shp *.shp *.shx *.prj *.dbf
# Unzip finish time (individual)
zipF=$(date +%s.%N)
# Compare unzip start/finish time (individual)
zipDIFF=$(echo $zipF $zipS | awk 'END {printf "%.2f\n", $1 - $2}')
echo -ne "\r	[$count/$ziptotal]	%`echo $count $ziptotal | awk 'END {printf "%.2f\n", ($1/$2)*100}'`	`basename $i .zip`: $zipDIFF s"
done
echo ""

# Unzip finish time (overall)
unzipF=$(date +%s.%N)
# Get unzip time in seconds (overall)
unzipSEC=$(echo $unzipF $unzipS | awk 'END {printf "%.2f\n", $1 - $2}')
# Get unzip time in minutes (overall)
unzipMIN=$(echo $unzipSEC | awk 'END {printf "%.2f\n", $1/60}')

# Get total files extracted
ftotal=$(find shp -maxdepth 1 -type f | wc -l)
# Get total extracted file size in MB
ftotalmb=$(find shp -maxdepth 1 -type f -printf "%s\n" | awk '{total += $1} END {printf "%.2f\n", total/(1024*1024)}')
# Get total extracted file size in GB
ftotalgb=$(echo $ftotalmb | awk '{mb = $1} END {printf "%.2f\n", mb / 1024}')

echo "	* extracted $ftotal files ($ftotalgb GB / $ftotalmb MB)	
		* finished in $unzipMIN m / $unzipSEC s"


# Shapfile parts search
echo "
# Assessing Shapefile format..."
# Shapefile parts start time (overall)
shpsumS=$(date +%s.%N)

echo "
	PART	SIZE(MB)"
# For loop that finds all the shapefile parts and their size in MB
for i in shp shx dbf prj
do
  echo "	$i	`find shp -type f -name "*.$i" -printf "%s\n" | awk '{total += $1} END {printf "%.2f\n", total/(1024*1024)}'`"
done

# Shapefile parts finish time (overall)
shpsumF=$(date +%s.%N)
# Get shapefile part breakdown time in seconds
ssDIFF=$(echo $shpsumF $shpsumS | awk 'END {printf "%.2f\n", $1 - $2}')

echo "		* finished in $ssDIFF s!"


# COUNT HOW MANY UNIQUE points, lines AND polygons THERE ARE
echo "
# Filtering CanVec features...
"
echo "	TOTAL	UNIQUE	GEOM	time"
ptwasS=$(date +%s.%N)
ptwas=$(ls shp | grep _0.shp | rev | cut -c -16 | rev | sort | wc -l)
ptis=$(ls shp | grep _0.shp | rev | cut -c -16 | rev | sort -u | wc -l)
ptwasF=$(date +%s.%N)
ptwasDIFF=$(echo $ptwasF $ptwasS | awk 'END {printf "%.2f\n", $1 - $2}')
echo " 	$ptwas	$ptis	Point	$ptwasDIFF s"

lnwasS=$(date +%s.%N)
lnwas=$(ls shp | grep _1.shp | rev | cut -c -16 | rev | sort | wc -l)
lnis=$(ls shp | grep _1.shp | rev | cut -c -16 | rev | sort -u | wc -l)
lnwasF=$(date +%s.%N)
lnwasDIFF=$(echo $lnwasF $lnwasS | awk 'END {printf "%.2f\n", $1 - $2}')
echo " 	$lnwas	$lnis	Line	$lnwasDIFF s"

plywasS=$(date +%s.%N)
plywas=$(ls shp | grep _2.shp | rev | cut -c -16 | rev | sort | wc -l)
plyis=$(ls shp | grep _2.shp | rev | cut -c -16 | rev | sort -u | wc -l)
plywasF=$(date +%s.%N)
plywasDIFF=$(echo $plywasF $plywasS | awk 'END {printf "%.2f\n", $1 - $2}')
echo " 	$plywas	$plyis	Polygon	$plywasDIFF s"


# Create lists of the unique features found.
echo "
# Generating filtered features list..."

ptmb=$(find shp -maxdepth 1 -type f -name "*_0.*" -printf "%s\n" | awk '{total += $1} END {printf "%.2f\n", total/(1024*1024)}')
echo "
	*******
	Points ($ptmb MB):
	*******"
lsftS=$(date +%s.%N)
ls shp | grep _0.shp | rev | cut -c -16 | cut -c 5- | rev | sort | uniq -c

lnmb=$(find shp -maxdepth 1 -type f -name "*_1.*" -printf "%s\n" | awk '{total += $1} END {printf "%.2f\n", total/(1024*1024)}')
echo "
	******
	Lines ($lnmb MB):
	******"
ls shp | grep _1.shp | rev | cut -c -16 | cut -c 5- | rev | sort | uniq -c

plymb=$(find shp -maxdepth 1 -type f -name "*_2.*" -printf "%s\n" | awk '{total += $1} END {printf "%.2f\n", total/(1024*1024)}')
echo "
	*********
	Polygons ($plymb MB):
	*********"
ls shp | grep _2.shp | rev | cut -c -16 | cut -c 5- | rev | sort | uniq -c

lsftF=$(date +%s.%N)
lsftDIFF=$(echo $lsftF $lsftS | awk 'END {printf "%.2f\n", $1-$2}')

echo "		* finished in $lsftDIFF s"


# STORE THE UNIQUE CANVEC FEATURES AS VARIABLES FOR A for LOOP LATER
echo "
# Storing filtered features as variables..."
qptS=$(date +%s.%N)
uniqpt=$(ls shp | grep _0.shp | rev | cut -c -16 | cut -c 5- | rev | sort -u)
qptF=$(date +%s.%N)
qptDIFF=$(echo $qptF $qptS | awk 'END {printf "%.2f\n", $1 - $2}')
echo "	* $ptis CanVec points in $qptDIFF s"
qlnS=$(date +%s.%N)
uniqln=$(ls shp | grep _1.shp | rev | cut -c -16 | cut -c 5- | rev | sort -u)
qlnF=$(date +%s.%N)
qlnDIFF=$(echo $qlnF $qlnS | awk 'END {printf "%.2f\n", $1 - $2}')
echo "	* $lnis CanVec lines in $qlnDIFF s"
qplyS=$(date +%s.%N)
uniqply=$(ls shp | grep _2.shp | rev | cut -c -16 | cut -c 5- | rev | sort -u)
qplyF=$(date +%s.%N)
qplyDIFF=$(echo $qplyF $qplyS | awk 'END {printf "%.2f\n", $1 - $2}')
echo "	* $plyis CanVec polygons in $qplyDIFF s"


# LOOP THROUGH UNIQUE FEATURES VARIABLE AND PLACE THE FIRST SHAPEFILE IT FINDS OF THAT CATEGORY INTO A FOLDER
echo "
# Sorting required shapefiles for ogr2ogr merge..."

echo "	* moving $ptis CanVec pt shapefiles..."
mvptS=$(date +%s.%N)
findpt=$(for i in $uniqpt
do
find shp -name "*$i*" | sort | head -4
done)
mv -f $findpt shp/pt
mvptF=$(date +%s.%N)
mvptDIFF=$(echo $mvptF $mvptS | awk 'END {printf "%.2f\n", $1-$2}')
mvptmb=$(find shp/pt -maxdepth 1 -type f -printf "%s\n" | awk '{total += $1} END {printf "%.2f\n", total/(1024*1024)}')
echo "		* $mvptmb MB transferred in $mvptDIFF s"

echo "	* moving $lnis CanVec ln shapefiles..."
count=0
mvlnS=$(date +%s.%N)
findln=$(for i in $uniqln
do
find shp -name "*$i*" | sort | head -4
done)
mv -f $findln shp/\ln
mvlnF=$(date +%s.%N)
mvlnDIFF=$(echo $mvlnF $mvlnS | awk 'END {printf "%.2f\n", $1-$2}')
mvlnmb=$(find shp/\ln -maxdepth 1 -type f -printf "%s\n" | awk '{total += $1} END {printf "%.2f\n", total/(1024*1024)}')
echo "		* $mvlnmb MB transferred in $mvlnDIFF s"

echo "	* moving $plyis CanVec ply shapefiles..."
mvplyS=$(date +%s.%N)
findply=$(for i in $uniqply
do
find shp -name "*$i*" | sort | head -4
done)
mv -f $findply shp/ply
mvplyF=$(date +%s.%N)
mvplyDIFF=$(echo $mvplyF $mvplyS | awk 'END {printf "%.2f\n", $1-$2}')
mvplymb=$(find shp/ply -maxdepth 1 -type f -printf "%s\n" | awk '{total += $1} END {printf "%.2f\n", total/(1024*1024)}')
echo "		* $mvplymb MB transferred in $mvplyDIFF s"


#BATCH RENAME ATTEMPT...
echo "
# Batch renaming required shapefiles..."

rnS=$(date +%s.%N)

rnptS=$(date +%s.%N)
echo "	* Renaming points..."
count=0
ptrnT=$(find shp/pt -type f | wc -l)
for i in `find shp/pt -type f`
do
count=$(expr $count + 1)
newpt=`echo $i | rev | cut -c -16 | rev`
mv -f $i shp/pt/$newpt
rnptF=$(date +%s.%N)
rnptDIFF=$(echo $rnptF $rnptS | awk 'END {printf "%.2f\n", $1-$2}')
echo -ne "\r	[$count/$ptrnT] %`echo $count $ptrnT | awk 'END {printf "%.2f\n", ($1/$2)*100}'` $newpt renamed: $rnptDIFF s"
done
echo ""

rnlnS=$(date +%s.%N)
echo "	* Renaming lines..."
count=0
lnrnT=$(find shp/\ln -type f | wc -l)
for i in `find shp/\ln -type f`
do
count=$(expr $count + 1)
newln=`echo $i | rev | cut -c -16 | rev`
mv -f $i shp/\ln/$newln
rnlnF=$(date +%s.%N)
rnlnDIFF=$(echo $rnlnF $rnlnS | awk 'END {printf "%.2f\n", $1-$2}')
echo -ne "\r	[$count/$lnrnT] %`echo $count $lnrnT | awk 'END {printf "%.2f\n", ($1/$2)*100}'` $newln renamed: $rnlnDIFF s"
done
echo ""

rnplyS=$(date +%s.%N)
echo "	* Renaming polygons..."
count=0
plyrnT=$(find shp/ply -type f | wc -l)
for i in `find shp/ply -type f`
do
count=$(expr $count + 1)
newply=`echo $i | rev | cut -c -16 | rev`
mv -f $i shp/ply/$newply
rnplyF=$(date +%s.%N)
rnplyDIFF=$(echo $rnplyF $rnplyS | awk 'END {printf "%.2f\n", $1-$2}')
echo -ne "\r	[$count/$plyrnT] %`echo $count $plyrnT | awk 'END {printf "%.2f\n", ($1/$2)*100}'` $newply renamed: $rnplyDIFF s"
done
echo ""

rnF=$(date +%s.%N)
rnDIFF=$(echo $rnF $rnS | awk 'END {printf "%.2f\n", $1-$2}')
rnmb=$(find shp/pt shp/\ln shp/ply -maxdepth 1 -type f -printf "%s\n" | awk '{total += $1} END {printf "%.2f\n", total/(1024*1024)}')

echo "		* Successfully renamed $rnmb MB of shapefiles in $rnDIFF s!"

#BATCH ogr2ogr SHAPEFILE CREATION...
echo "
# Batch merging with ogr2ogr!
"

mrgS=$(date +%s.%N)

echo "	* Merging Points...
	FEATURE		MERGED	(MB)	CLEAN	(m)"	
for i in `ls shp/pt | grep .shp | sort`
do
ptlayer=`echo $i | rev | cut -c 5- | rev`
mgptS=$(date +%s.%N)
find shp -maxdepth 1 -name "*$i" -exec ogr2ogr -f 'ESRI Shapefile' -update -append shp/pt/$i '{}' -nln $ptlayer \;
mgptF=$(date +%s.%N)
mgptDIFF=$(echo $mgptF $mgptS | awk 'END {printf "%.2f\n", ($1-$2)/60}')
mgptmb=$(find shp -type f -name "*$ptlayer*" -printf "%s\n" | awk '{total += $1} END {printf "%.2f\n", total/(1024*1024)}')
find shp -maxdepth 1 -type f -name "*$ptlayer*" | xargs rm -f 
echo "	`basename $i .shp`	[OK]	$mgptmb	[OK]	$mgptDIFF"
done
echo ""

echo "	* Merging Lines...
	FEATURE		MERGED	(MB)	CLEAN	(m)"
for i in `ls shp/\ln | grep .shp | sort`
do
lnlayer=`echo $i | rev | cut -c 5- | rev`
mglnS=$(date +%s.%N)
find shp -maxdepth 1 -name "*$i" -exec ogr2ogr -f 'ESRI Shapefile' -update -append shp/\ln/$i '{}' -nln $lnlayer \;
mglnF=$(date +%s.%N)
mglnDIFF=$(echo $mglnF $mglnS | awk 'END {printf "%.2f\n", ($1-$2)/60}')
mglnmb=$(find shp -type f -name "*$lnlayer*" -printf "%s\n" | awk '{total += $1} END {printf "%.2f\n", total/(1024*1024)}')
find shp -maxdepth 1 -type f -name "*$lnlayer*" | xargs rm -f 
echo "	`basename $i .shp`	[OK]	$mglnmb	[OK]	$mglnDIFF"
done
echo ""

echo "	* Merging Polygons...
	FEATURE		MERGED	(MB)	CLEAN	(m)"
for i in `ls shp/ply | grep .shp | sort`
do
plylayer=`echo $i | rev | cut -c 5- | rev`
mgplyS=$(date +%s.%N)
find shp -maxdepth 1 -name "*$i" -exec ogr2ogr -f 'ESRI Shapefile' -update -append shp/ply/$i '{}' -nln $plylayer \;
mgplyF=$(date +%s.%N)
mgplyDIFF=$(echo $mgplyF $mgplyS | awk 'END {printf "%.2f\n", ($1-$2)/60}')
mgplymb=$(find shp -type f -name "*$plylayer*" -printf "%s\n" | awk '{total += $1} END {printf "%.2f\n", total/(1024*1024)}')
find shp -maxdepth 1 -type f -name "*$plylayer*" | xargs rm -f 
echo "	`basename $i .shp`	[OK]	$mgplymb	[OK]	$mgplyDIFF"
done

mrgF=$(date +%s.%N)
mrgDIFF=$(echo $mrgF $mrgS | awk 'END {printf "%.2f\n", $1-$2}')


echo "
####################
# SCRIPT FINISHED! #
####################"

END=$(date +%s.%N)
DIFF=$(echo $END $START | awk 'END {printf "%.2f\n", $1-$2}')

DIFFm=$(echo $DIFF | awk 'END {printf "%.2f\n", $1/60}')
DIFFh=$(echo $DIFF | awk 'END {printf "%.2f\n", ($1/60)/60}')

prcZ=$(echo $DIFF $unzipSEC | awk 'END {printf "%.2f\n", ($2/$1)*100}')
prcM=$(echo $DIFF $mrgDIFF | awk 'END {printf "%.2f\n", ($2/$1)*100}')
prcR=$(echo $DIFF $mrgDIFF $unzipSEC | awk 'END {printf "%.2f\n", (($1-$2-$3)/$1)*100}')

echo "Entire script finished in:
		$DIFFh hr
		$DIFFm min
 		$DIFF sec

Time (%) for tasks:
	$prcZ% unzipping
	$prcM% merging
	$prcR% others"

exit
