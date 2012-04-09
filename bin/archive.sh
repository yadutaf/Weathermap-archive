#!/bin/bash

###
# Copyright jtlebi.fr <admin@jtlebi.fr> and other contributors.
#
# Permission is hereby granted, free of charge, to any person obtaining a
# copy of this software and associated documentation files (the
# "Software"), to deal in the Software without restriction, including
# without limitation the rights to use, copy, modify, merge, publish,
# distribute, sublicense, and/or sell copies of the Software, and to permit
# persons to whom the Software is furnished to do so, subject to the
# following conditions:
#
# The above copyright notice and this permission notice shall be included
# in all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
# OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
# MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN
# NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM,
# DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR
# OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE
# USE OR OTHER DEALINGS IN THE SOFTWARE.
###

BASEDIR="/home/weathermaps"
DATE=`date +%Y-%m-%d`
FILENAME=`date +%Hh%M`".png"

for archivescripts in `ls ./archive.d`; do
  if [ -x "./archive.d/$archivescripts" ]; then
    MAPS=`./archive.d/$archivescripts`
    for map in $MAPS; do
      map=(${map//;/ })
      echo "create dir: "$BASEDIR"/"${archivescripts%%.*}"/"${map[0]}"/"$DATE
      echo "download from: "${map[1]}
      echo "download to: "$BASEDIR"/"${archivescripts%%.*}"/"${map[0]}"/"$DATE"/"$FILENAME
      echo "-----------------------------------------------------------------"
      #mkdir -p $BASEDIR"/"${archivescripts%%.*}"/"${map[0]}"/"$DATE
      #wget -q ${map[1]} -O $BASEDIR"/"${archivescripts%%.*}"/"${map[0]}"/"$DATE"/"$FILENAME
    done
  fi
done

MAPS="europe usa backbone p19 rbx rbx2 rbx3 rbx4 sbg1 bhs1 services voip p19_mutu hg pcc vps cdn isp paris ams fra ldn bru mad mil zur pra vie var gsw th dc1 euratechnologies"
BASEURL="http://weathermap.ovh.net/schemes/weathermap_"


#for m in $MAPS; do
#  echo "Getting map "$m"..."
#  mkdir -p $BASEDIR"/"$m"/"$DATE
#  wget -q $BASEURL$m".png" -O $BASEDIR"/"$m"/"$DATE"/"$FILENAME
#done
