#!/bin/bash
# get all filename in specified path

path=$1
files=$(ls $path)
rm -f filename.txt
for filename in $files
do
   echo "* ["$filename"]("$path"/"$filename")" >> filename.txt
done