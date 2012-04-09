#!/bin/bash

#Produce a list of "$MAP;$URL" to archive for "ovh" on stdout for further processing

BASEURL="http://weathermap.ovh.net/schemes/weathermap_"
MAPS="europe usa backbone p19 rbx rbx2 rbx3 rbx4 sbg1 bhs1 services voip p19_mutu hg pcc vps cdn isp paris ams fra ldn bru mad mil zur pra vie var gsw th dc1 euratehnologies"

for m in $MAPS; do
  echo $m";"$BASEURL$m".png"
done
