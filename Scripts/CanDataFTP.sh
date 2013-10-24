#!/bin/bash
set -e
# ---------------------------------------------------------------------------
# CanDataFTP - downloads canvec tiles and geobase dems from a preformatted csv
#              file (ie, single column with no header or special chars)

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

# Usage: CanDataFTP.sh (set exec bit before running, chmod +x CanDataFTP.sh)

# Revision history:
# 2011-06-11    Created
# ---------------------------------------------------------------------------

########################
#	Introduction
########################
echo -e "\n\n##################################################
# Welcome to CanDataFTP_v1
#
# This script will take a list of NTS sheets in a CSV...
#		001A
#		001B
#		002C etc
#	* can also be a 50k sheet!
#
# ...format them properly and download the matching
# zip files from a choice of...
#		[1] CanVec 1:50,000
#		[2] Geobase DEM 1:50,000
#		[3] Geobase DEM 1:250,000
#
# ...into a workspace you specify!
##################################################\n"

########################
#	Ask for workspace, create if needed,
########################
read -p "*****************************************
* What/where is your desired workspace?
* If it doesn't exist, it will be made for you.
*****************************************
workspace: " WRK

read -p "# ${WRK} will be checked... [ENTER]"

echo -e "* Looking for ${WRK}\n"

if [[ -d "${WRK}" && ! -L "${WRK}" ]]; then
	echo -e "* Workspace is already there, great!\n"
  else
	echo -e "* Doesn't exist, creating: ${WRK}\n"
	mkdir "${WRK}"
fi

########################
# 	Ask for CSV file.
# 	Be sure to include directory and filename.
#	Check to see if it exists and contains no suspect characters!
########################
read -p "*****************************************
* Where did you save your NTS list (.csv)?
* 	Include the directory,
*
*	eg, Documents/tables/nts.csv
*****************************************
csv: " NTS

read -p "# ` basename "${NTS}"` will be error checked (minimal)... [ENTER]"

echo -e "* Checking for ${NTS}\n"
########################
#	Check validity of CSV (minimal!)
#	-if file exists AND ends in .csv, then
########################
if [[ -f "${NTS}" && "${NTS}" == *.csv ]]; then
    echo -e "* CSV file found!\n"
    echo -e "# Checking for validity..."
  ########################
  # 	Check for invalid characters!
  #	Close the script if any are found
  ########################
  if [[ `cat "${NTS}"` == *[[:punct:]]* ]]; then
	echo "* Invalid characters found!
* These may include: \" ' or even spaces!
* Correct these before trying again.
*
* Script exiting..."
	exit 1
  else
	echo -e "* No invalid characters! Good job!"
  fi
  ########################
  # 	Verify NTS formatting and table type: 50k/250k
  #	Assign indicator based on table found.
  #	
  #	This indicator is used in a test expression for wget
  #	to decide what formatting to use for the table!
  #	
  #	Where 50k = 50 and 250k = 250
  ########################
  if [[ `cat "${NTS}" | head -1` =~ ^[0-9][0-9][0-9][A-Pa-p]$ ]]; then
	echo "* and this looks like a list of 250k sheets!"
	NTSK=250
  elif [[ `cat "${NTS}" | head -1` =~ ^[0-9][0-9][0-9][A-Pa-p][01][0-6]$ ]]; then
	echo "* and this looks like a list of 50k sheets!"
	NTSK=50
  ########################
  #	If CSV formatting cannot be verified, close the script
  ########################
  else
	echo -e "\n* This might not be a list of NTS sheets!
* Or is improperly formatted!
*	
*   eg, 50k: 001A01
*      250k: 001A
*
# Script exiting..."
	exit 1
  fi
########################
#	If CSV cannot be verified, close the script
########################
else
    echo "* CSV file not found!
* Maybe it's not there or isn't even a CSV file?
# Script exiting..."
    exit 1
fi

########################
#	Copy CSV to workspace, and then go there!
########################
cp "${NTS}" "${WRK}/"
echo -e "\n* CSV copied to workspace!"
cd "${WRK}"
echo "* We are now in workspace: `pwd`"

########################
# 	Ask which set of data to download.
########################
echo "*****************************************
* What dataset are you after?
* Only the NTS sheets found in the CSV list you provided will be d/loaded!
*
* Make a selection:
*	[1] CanVec 1:50,000
*	[2] Geobase DEM 1:50,000
*	[3] Geobase DEM 1:250,000
*
* Downloads will begin immediately!
*****************************************"
read -p "Enter [1-3]: "

########################
#	Download start time
########################
SCRS=$(date +%s.%N)

########################
#	Check to see if input is within range 1-3!
########################
if [[ "${REPLY}" =~ ^[1-3]$ ]]; then
  ########################
  #	If it is was for 50k CanVec!
  ########################
  if [[ "${REPLY}" == 1 ]]; then
	echo -e "# You chose CanVec 1:50,000\n"
	FTP1="ftp://ftp2.cits.rncan.gc.ca/pub/canvec/50k_shp/"
	NTS1=$(\
		cat `basename "${NTS}"` | \
		tr [:upper:] [:lower:] | \
		sed 's/[a-p]/\/&\//'\
	      )
    ########################
    #	If a 50k list was used, format for 50k CanVec!
    ########################
    if [[ "${NTSK}" == 50 ]]; then
	echo "# Formatting a 50k NTS list for this operation..."
	echo "# Transfer beginning..."
		for nts in ${NTS1}; do
		   ZIP1="canvec_${nts////}_shp.zip"
		   echo "${FTP1}${nts:0:6}${ZIP1}"
		done | \
		   wget \
		   --no-directories \
		   --wait=1 \
		   --tries=5 \
		   --timeout=60 \
		   --input-file=-
	echo "# Transfer done!"
    ########################
    #	Or, if a 250k list, format for 50k CanVec!
    ########################
    elif [[ "${NTSK}" == 250 ]]; then
	echo "# Formatting a 250k NTS list for this operation..."
	echo -e "# Transfer beginning...\n! You could refine your d/load by using a 50k list"
	ZIP1="canvec_*_shp.zip"
		for nts in ${NTS1}; do
		   wget --no-directories \
			--wait=1 \
			--tries=5 \
			--timeout=60 \
			-i ${FTP1}${nts}${ZIP1}
		done
	echo "# Transfer done!"
    fi
  ########################
  #	If it was for Geobase 50k DEMs!
  ########################
  elif [[ "${REPLY}" == 2 ]]; then
	echo "# You chose Geobase DEM 1:50,000
# Downloads will now begin..."
	FTP1="ftp://ftp2.cits.rncan.gc.ca/pub/geobase/official/cded/50k_dem/"
	NTS1=$(\
		cat `basename "${NTS}"` | \
		tr [:upper:] [:lower:] \
	      )
    ########################
    #	If a 50k list was used, format for 50k DEMs!
    ########################
    if [[ "${NTSK}" == 50 ]]; then
	echo "# Formatting a 50k NTS list for this operation..."
	echo "# Transfer beginning..."
		for nts in ${NTS1}; do
		   echo "${FTP1}${nts:0:3}/${nts}.zip"
		done | \
		   wget --no-directories \
			--wait=1 \
			--tries=5 \
			--timeout=60 \
			--input-file=-
	echo "# Transfer done!"
    ########################
    #	Or is a 250k list was used, format for 50k DEMs!
    ########################
    elif [[ "${NTSK}" == 250 ]]; then
	echo "# Formatting a 250k NTS list for this operation..."
	echo -e "# Transfer beginning...\n! You could refine your d/load by using a 50k list"
		for nts in ${NTS1}; do
		   echo "${FTP1}${nts:0:3}/${nts}*.zip"
		done | \
		   wget --no-directories \
			--wait=1 \
			--tries=5 \
			--timeout=60 \
			--input-file=-
	echo "# Transfer done!"
    fi
  ########################
  # Check if it is was for 250k DEMs!
  ########################
  elif [[ "${REPLY}" == 3 ]]; then
	echo "# You chose Geobase DEM 1:250,000
# Downloads will now begin..."
	FTP1="ftp://ftp2.cits.rncan.gc.ca/pub/geobase/official/cded/250k_dem/"
	NTS1=$(\
		cat `basename "${NTS}"` | \
		tr [:upper:] [:lower:] \
	      )
    ########################
    #	If a 50k list was used, format for 250k DEMs!
    ########################
    if [[ "${NTSK}" == 50 ]]; then
	echo "# Formatting a 50k NTS list for this operation..."
	echo "# Transfer beginning..."
		for nts in ${NTS1}; do
		   echo "${FTP1}${nts:0:3}/${nts:0:4}.zip"
		done | \
		   sort -u | \
		   wget --no-directories \
			--wait=1 \
			--tries=5 \
			--timeout=60 \
			--input-file=-
	echo "# Transfer done!"
    ########################
    #	Or is a 250k list was used, format for 250k DEMs!
    ########################
    elif [[ "${NTSK}" == 250 ]]; then
	echo "# Formatting a 250k NTS list for this operation..."
	echo "# Transfer beginning..."
		for nts in ${NTS1}; do
		   echo "${FTP1}${nts:0:3}/${nts}.zip"
		done | \
		   wget --no-directories \
			--wait=1 \
			--tries=5 \
			--timeout=60 \
			--input-file=-
	echo "# Transfer done!"
    fi
  else
    echo "# Something is wrong... call Batman & Robin..."
    exit 1
  fi
#######################
#	If input is out of range 1-3, close the script
########################
else
    echo -e "\n# Invalid option, exiting!
# No downloads for you!"
    exit 1
fi

########################
#	Download finish time.
########################
SCRF=$(date +%s.%N)

########################
# Output total files, size, directory and total download time.
########################
DIFF=$(echo $SCRF $SCRS | awk 'END {printf "%.2f\n", $1-$2}')
echo "# Script finished in ${DIFF} s"
