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
start_wait_time="10"

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
	# 删除以前所有出配置日志信息以外的文件
	rm -rf $root_dir/bin  $root_dir/erts-6.1 $root_dir/lib $root_dir/releases $root_dir/resource
	# 将删除的文件拷贝过来
	cp -rft $root_dir $tag_release/bin  $tag_release/erts-6.1 $tag_release/lib $tag_release/releases $tag_release/resource
    echo "install simplify ok !!!!"
}

# 更新resource
updata_resource()
{
	local tag_release=$1
	# 删除以前的资源文件
	rm -rf $root_dir/resource
	# 拷贝新的资源文件
	cp -rft $root_dir $tag_release/resource
    echo "updata resource ok !!!!"
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

# 显示所有信息
info() 
{
	echo "================ show begin ================"
	echo "$root_dir"
	check_server_status
    rpc_call show_version
	cat $root_dir/config/server_config.txt
	cat $root_dir/tool/vm.args
	echo "================ show  over ================"
}

start_test() 
{
    cd $root_dir/tool
    awk -F ' ' '{ 
        if($1=="-mode" )  { } 
        else if($1=="-detached") { }
        else { print $0}
    }' vm.args >vm_test.args
    cd $root_dir
    ./$erts_name/bin/erl -args_file ./tool/vm_test.args -boot ./releases/"$app_vsn"/"$app_name"
}

attach()
{
    check_server_status
	$root_dir/$erts_name/bin/erl -setcookie "$node_cookie" -name "attach_""$node_name" -remsh "$node_name"
}

project_list() 
{
    cd $root_dir
    # 获取目录列表
    find . -type d |grep -v "^./tool$" |grep -v "^./tool/" |grep -v "^./config$" |grep -v "^./config/" |grep -v "^./game_log$" |grep -v "^./game_log/"|grep -v "^./log$" |grep -v "^./log/" |grep -v "^./record$" |grep -v "^./record/" |sort -d > run_dir_list.txt
    # 获取文件列表
    find . -type f |grep -v "^./tool/" |grep -v "^./config/" |grep -v "^./game_log/"|grep -v "^./log/" |grep -v "^./record/" |xargs md5sum |awk -F ' ' '{print $2" "$1}' |grep -v "run_file_list.txt" |sort -d >run_file_list.txt
    
    mv run_file_list.txt ./tool
    mv run_dir_list.txt ./tool
}

reload_zdb() 
{
	 rpc_call reload_zdb
}

clean() 
{
	cd $root_dir/install_package
	rm -rf *
	mkdir hot_release  release  resource  simplify_release
}

show_help() 
{
	echo "[start|start_test|stop|update|install_upgrade|attach|version|status|reloadzdb|project_list|info|help]"
}
not_found() 
{
	echo "not found this commond please call help !!!"
}


main() 
{
	case "$1" in 
		start) 
			start_server;;
		stop) 
			stop;;
		update)  install_simplify_release $2;;
		install_upgrade)  install_upgrade $2;;
		attach) attach;;
		version) show_version;;
		status)  status;;
		clean)  clean;;
		start_test)  start_test;;
		reloadzdb)   reload_zdb;;
		project_list)  project_list;;
		info)  info;;
		help) show_help;;
		* )  ;;
	esac
}


#####################################################

main $1 $2


#####################################################






