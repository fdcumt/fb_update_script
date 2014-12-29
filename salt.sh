#!/bin/sh

start_all()
{
	salt '192.168.100.130' cmd.run 'sh /home/fuzongqiong/first_blood_project/first_blood_tool/control.sh start_all'
}


stop_all()
{
	salt '192.168.100.130' cmd.run 'sh /home/fuzongqiong/first_blood_project/first_blood_tool/control.sh stop_all'
}


main()
{
	case "$1" in 
		start_all) start_all;;
		stop_all)  stop_all;;
	esac 
} 



main $1










