#!/bin/sh


program_list=`ps aux|grep erl | grep beam.smp | grep name |grep setcookie`

#echo $program_list

echo "$program_list" | while read program 
do 
	path=`echo $program |awk -F' ' ' {print $11}' `
	root_dir=${path%/*/*/*}
	echo $root_dir
	cat $root_dir/config/server_config.txt |grep 'mysql_host\|mysql_port\|mysql_database\|ranch_port'
	echo ""
done 
