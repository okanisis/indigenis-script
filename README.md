# indigenis @ github

## Description:
Linux command line GIS related shell/bash scripts that I have published at indiGenIS to assist in repetitive tasks.

They include:
    - CanDataFTP.sh
    - CanVecSHP.sh
    - geonamerge.sh

The scripts use [GDAL](http://www.gdal.org/) with a combination of [wget](http://www.gnu.org/s/wget/) to download free or public GIS spatial data about Canada from various sources and output them in a usable format for a GIS. 

Currently, they favor the shapefile. That could change as I grow accustom to spatial database formats like [postgresql](http://www.postgresql.org/) with [postgis](http://postgis.refractions.net/).

## General Usage:

Prior to executing the script it will need to be made executable with the following:
    $ chmod +x CanDataFTP.sh

Each script contains a small description, so view them in your text editor for details.

I will fill out the wiki on usage and screenshots/videos to help understand how they work, but for now I have formatted them fairly nicely and included comments.

## License:
Images/scripts are shared via git under a [GNU General Public License (GPLv3)](http://www.gnu.org/licenses/gpl-3.0.txt)
