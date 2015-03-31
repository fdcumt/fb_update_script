#!/bin/sh

cur_dir="$(dirname `readlink -f "$0"`)"  
run_dir=${cur_dir%/*}

server_list="first_blood_1 first_blood_2 first_blood_3"
share_dir="/root/3d/3d_share"

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

show_package() 
{
    tree $share_dir -L 2
}

# 创建新服
create_server() 
{
    if [ ! $# -eq 2 ]; then 
        echo "please input the right arguments"
        exit 1
    fi
    local lc_source_package=$1
    local lc_project_dir=$2
    if [ -d $run_dir/$lc_project_dir ]; then 
        echo "$lc_project_dir dir is not empty, please check again!!!"
        exit 1
    fi 
    mkdir -p $run_dir/$lc_project_dir
    cp -rf $share_dir/release/$lc_source_package  $run_dir/$lc_project_dir
    cd $run_dir/$lc_project_dir
    tar -zxvf $lc_source_package > /dev/null
    rm -rf $lc_source_package
    cd $run_dir/$lc_project_dir/tool
    mv vm.args vm_test.args
    awk -F ' ' '{ 
        if($1=="-name" )  { print "-name $lc_project_dir@127.0.0.1";} 
        else { print $0}
    }' vm_test.args >vm.args
    rm -rf vm_test.args
    
    echo " generate $lc_project_dir ok, please set the config !!!"
}


main() 
{
    case "$1" in 
		start_all) start_all;;
		stop_all)  stop_all;;
		upgrade_server)  upgrade_server $2;;
		create_server)  create_server $2 $3;;
		show_package)  show_package ;;
	esac 
}

main $1 $2 $3

