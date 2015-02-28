#!/bin/sh

cur_dir="$(dirname `readlink -f "$0"`)"  

app_name="first_app"

root_dir=${cur_dir%/*}
project_name=${root_dir##*/}
start_erl=`cat $root_dir/releases/start_erl.data`
erts_vsn=${start_erl% *}
app_vsn=${start_erl#* }
erts_name="erts-$erts_vsn"

#启动时间超级长,至少是5秒,反正我测试的时候5秒没启动成功
start_wait_time="8"

cd $root_dir/tool
awk -F ' ' '{ 
	if($1=="-name")  { print 	"node_name=\""$2"\"" ;} 
	else if($1=="-setcookie") { print "node_cookie=\""$2"\"" ;}
}' vm.args >var.txt
	
#node_name="first_app@127.0.0.1"
#node_cookie="first_app"
while read line 
do 
	eval $line
done < var.txt
rm -rf var.txt

status()
{
	server_status
	if [ $? -eq 0 ]; then
		echo "$app_name is running........."
	else 
		echo "$app_name is stoped........."
	fi 
}

server_status()
{
	local smp_pid=`ps axu | grep -w $root_dir | grep -v "grep" |grep -w "beam.smp" `
	if [ "$smp_pid" != "" ]; then
		return 0
	else 
		return 1
	fi 
}

#如果服务器没有启动就退出
check_server_status()
{
    server_status
    if [ ! $? -eq 0 ]; then
		echo "$app_name is stoped........."
        exit 1
	fi 
}

rpc_call()
{
    check_server_status
    cd $root_dir/tool
    sed -i '3s/^.*$/%%! -smp enable -name '"temp_""$node_name"'/' rpc.escript 
    escript rpc.escript "$node_name" "$node_cookie" $1 $2 $3
}

start_server()
{
	local smp_pid=`ps axu | grep -w $root_dir | grep -v "grep" | grep -w "beam.smp"`
	local erlexec_pid=`ps axu | grep -w $root_dir | grep -v "grep" | grep -w "erlexec"`
	local server_status=""
    local count=0
    
	if [ "$erlexec_pid" != "" ]; then 
		echo "Server is starting ................"
		exit 1
	elif [  "$smp_pid" != "" ]; then 
		echo "Server already start ................"
		exit 1
	else 
		cat /dev/null > $root_dir/config/.server_status.txt
	fi 
	
	cd $root_dir
    (nohup ./$erts_name/bin/erl -args_file ./tool/vm.args -boot ./releases/"$app_vsn"/"$app_name"  >./game_log/nohup.out 2>&1 )&
	
	while [ $count -lt $start_wait_time ]
	do
		smp_pid=`ps axu | grep -w $root_dir | grep -v "grep" | grep -w "beam.smp"`
		erlexec_pid=`ps axu | grep -w $root_dir | grep -v "grep" | grep -w "erlexec"`
		server_status=`cat $root_dir/config/.server_status.txt`
		if [ "$server_status" != "" ]; then
			echo  "$project_name start ok......"
			exit 0
		else 
			sleep 1
			let "count = count + 1"	
			echo "time already wait $count""s"
		fi
	done
	echo "$project_name start timeout ......"
	exit 1
}

#停服更新版本
install_simplify_release()
{
    local tag_release=$1
    local tag_dir_list=`ls $1`
    for dir in $tag_dir_list ;do 
        rm -rf  $root_dir/$dir
        cp -rf $tag_release/$dir $root_dir
    done  
    echo "install simplify ok !!!!"
}

install_upgrade() 
{
    local package_full_path=$1
	local release_package=${package_full_path##*/}
	local upgrade_app_name=${release_package%.tar.gz}
	local upgarde_app_vsn=${upgrade_app_name##*_}
    cp -rf $package_full_path $root_dir/releases
	rpc_call upgrade $upgrade_app_name $upgarde_app_vsn
}
stop()
{
	local smp_pid=`ps axu | grep -w $root_dir | grep -v "grep" | grep -w "beam.smp" `
	if [ "$smp_pid" == "" ]; then 
		echo "$project_name is not start ....."
		exit 0
	fi 
    
    #关闭服务器中的gen_server
    rpc_call stop_server
   
	local smp_pid=`ps axu | grep -w $root_dir | grep -v "grep" | grep -w "beam.smp" | awk -F " " '{ print $2 }'`
	kill "$smp_pid"
	echo "$project_name has killed ......"
}

#显示版本信息
show_version()
{
    check_server_status
    rpc_call show_version
}
 
 
attach()
{
    check_server_status
	$root_dir/$erts_name/bin/erl -setcookie "$node_cookie" -name "attach_""$node_name" -remsh "$node_name"
}

main() 
{
	case "$1" in 
		start) 
			start_server;;
		stop) 
			stop;;
		install_simplify_release) 
            install_simplify_release $2;;
		install_upgrade) 
			install_upgrade $2;;
		attach) attach;;
		version) show_version;;
		status)  status;;
	esac
}


#####################################################

main $1 $2


#####################################################






