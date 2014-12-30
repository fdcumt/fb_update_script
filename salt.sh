#!/bin/sh

cur_dir="$(dirname `readlink -f "$0"`)"  
root_dir=${cur_dir%/*}
root_dir="$root_dir/"

start_all()
{
	salt '192.168.100.130' cmd.run 'sh /home/fuzongqiong/first_blood_project/first_blood_tool/control.sh start_all'
}


stop_all()
{
	salt '192.168.100.130' cmd.run 'sh /home/fuzongqiong/first_blood_project/first_blood_tool/control.sh stop_all'
}

make_update()
{
	cd "$root_dir"
	cd first_blood_tool
	local lc_app_vsn=$1
	sh compile.sh make_update "$lc_app_vsn"
}

install_update()
{
	local lc_upgrade_package=$1
	salt '192.168.100.130' cmd.run 'sh /home/fuzongqiong/first_blood_project/first_blood_tool/control.sh upgrade_server $lc_upgrade_package '
}

main()
{
	case "$1" in 
		start_all) start_all;;
		stop_all)  stop_all;;
		make_update)  make_update $2;;
		install_update)  install_update $2;;
	esac 
} 



main $1 $2










