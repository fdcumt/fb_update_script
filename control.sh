#!/bin/sh

cur_dir="$(dirname `readlink -f "$0"`)"  
run_dir=${cur_dir%/*}
run_dir="$run_dir/"

start_server_list="first_blood_1"


show_version()
{
	for first_blood_server in "$start_server_list"
	do
		cd "$run_dir""$first_blood_server/tool/"
		if [ $? -eq 0 ]; then 
			echo -e "\e[1;32m$first_blood_server detail version \e[0m"
			sh start.sh show_version 
		else 
			echo -e "\e[40;31m$first_blood_server is not running\e[0m"
		fi 
	done 
}

show_status()
{
	for first_blood_server in "$start_server_list"
	do
		cd "$run_dir""$first_blood_server/tool/"
		sh start.sh status 
	done 
}

stop_all()
{
	#启动服务器
	for first_blood_server in "$start_server_list"
	do
		cd "$run_dir""$first_blood_server/tool/"
		sh start.sh stop 
	done 
}

start_all() 
{
	#启动服务器
	for first_blood_server in "$start_server_list"
	do
		cd "$run_dir""$first_blood_server/tool"
		sh start.sh start 
		if [ ! $? -eq 0 ]; then
			stop_all 
			return 1
		fi
	done 
}

upgrade_server()
{
	local lc_upgrade_package=$1
	for first_blood_server in "$start_server_list"
	do
		cd "$run_dir""$first_blood_server/tool"
		sh start.sh install_upgrade "$lc_upgrade_package"
		if [ ! $? -eq 0 ]; then
			echo "$first_blood_server upgrade faild"
			exit 1
		fi
	done 
}


main()
{
	case "$1" in 
		start_all) start_all;;
		stop_all)  stop_all;;
		upgrade_server)  upgrade_server $2;;
		show_version)  show_version ;;
	esac 
} 




main $1 $2













