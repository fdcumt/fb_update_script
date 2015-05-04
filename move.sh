#!/bin/sh



start_list=`find . -name start.sh |grep -v "\./tool/start.sh"`
for file in $start_list 
do 
	tagdir=${file%/*}
	cp -rf ./tool/start.sh $tagdir
done


