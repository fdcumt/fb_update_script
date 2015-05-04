#!/bin/sh

cur_dir="$(dirname `readlink -f "$0"`)"  
run_dir=${cur_dir%/*}

server_list="first_blood_1 first_blood_2 first_blood_3"

start_all()
{
	#启动服务器
	for server in "$server_list" ;do
		sh $run_dir/$server/tool/start.sh start 
        if [ ! $? -eq 0 ]; then
            stop_all
            echo "found errors when start server .............."
            exit 1
        fi 
	done 
}

install_upgrade()
{
    local upgrade_package_full_path=$1
    for server in "$server_list" ;do
		sh $run_dir/$server/tool/start.sh install_upgrade upgrade_package_full_path
	done 
}

install_simplify()
{
    local simplify_package_full_path=$1
    for server in "$server_list" ;do
		sh $run_dir/$server/tool/start.sh install_simplify_release $simplify_package_full_path
	done 
}

stop_all()
{
	#启动服务器
	for server in "$server_list" ;do
		sh $run_dir/$server/tool/start.sh stop 
	done 
}

clean() 
{
	#清理资源
	for server in "$server_list" ;do
		sh $run_dir/$server/tool/start.sh clean 
	done 
}


main() 
{
    case "$1" in 
		start_all) start_all;;
		stop_all)  stop_all;;
		upgrade_server)  upgrade_server $2;;
	esac 
}

main $1 $2

