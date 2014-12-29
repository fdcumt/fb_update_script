#!/bin/sh

cur_dir="$(dirname `readlink -f "$0"`)"  
run_dir=${cur_dir%/*}

start_server_list="first_blood_1 first_blood_2 first_blood_3 first_blood_4 "

project_version=""



stop_all()
{
	#启动服务器
	for first_blood_server in "$start_server_list"
	do
		sh "$run_dir/$first_blood_server/tool/start.sh" stop 
	fi
	done 
}

start_all() 
{
	#启动服务器
	for first_blood_server in "$start_server_list"
	do
		sh "$run_dir/$first_blood_server/tool/start.sh" start 
		if [ ! $? -eq 0 ]; then
			stop_all 
		return 1
	fi
	done 
}

stop_server_upgrade()
{
	
}

main()
{
	case "$1" in 
		start_all) start_all;;
		stop_all)  stop_all;;
	esac 
} 


















