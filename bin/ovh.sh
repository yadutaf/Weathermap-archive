#!/bin/bash

MAPS="europe usa backbone p19 rbx rbx2 rbx3 rbx4 sbg1 bhs1 services voip p19_mutu hg pcc vps cdn isp paris ams fra ldn bru mad mil zur pra vie var gsw th dc1 euratechnologies"
BASEDIR="/home/weathermaps/ovh/"
BASEURL="http://weathermap.ovh.net/schemes/weathermap_"

DATE=`date +%Y-%m-%d`
FILENAME=`date +%Hh%M`".png"

for m in $MAPS; do
#  echo "Getting map "$m"..."
  mkdir -p $BASEDIR"/"$m"/"$DATE
  wget -q $BASEURL$m".png" -O $BASEDIR"/"$m"/"$DATE"/"$FILENAME
done
