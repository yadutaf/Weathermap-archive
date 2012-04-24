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

## Script configuration goes here ##
BASEDIR="/home/weathermaps"

## Nothing to be modified past this point ##
DATE=`date +%Y-%m-%d`
FILENAME=`date +%Hh%M`".png"

cd archive.d

for archivescripts in `ls ./5min.d`; do
  if [ -x "./5min.d/$archivescripts" ]; then
    MAPS=`./5min.d/$archivescripts`
    for map in $MAPS; do
      map=(${map//;/ })
      mkdir -p $BASEDIR"/"${archivescripts%%.*}"/"${map[0]}"/"$DATE
      wget -q ${map[1]} -O $BASEDIR"/"${archivescripts%%.*}"/"${map[0]}"/"$DATE"/"$FILENAME
    done
  fi
done
