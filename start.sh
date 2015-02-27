#!/bin/sh

cur_dir="$(dirname `readlink -f "$0"`)"  

root_dir=${cur_dir%/*}
project_name=${root_dir##*/}
project_start_erl=`cat $root_dir/releases/start_erl.data`
project_erts_vsn=${project_start_erl% *}
cur_app_vsn=${project_start_erl#* }
app_name="first_app"
erl_cal_path="/usr/local/erl/lib/erlang/lib/erl_interface-3.7.18/bin/erl_call"
#启动时间超级长,至少是5秒,反正我测试的时候5秒没启动成功
start_wait_time="8"

cd "$root_dir""/tool"
awk -F ' ' 'BEGIN  { 
	  if($1=="-name")  { print 	"node_name=\""$2"\"" ;} 
	  else if($1=="-setcookie") { print "node_cookie=\""$2"\"" ;}
	} END ' vm.args >VAR.TXT
	
#node_name="first_app@127.0.0.1"
#node_cookie="first_app"
while read line 
do 
	eval $line
done < VAR.TXT

rm -rf VAR.TXT

status()
{
	local smp_pid=`ps axu | grep -w $root_dir | grep -v "grep" | grep -w "beam.smp"`
	if [ "$smp_pid" != "" ]; then
		return 0
	else 
		return 1
	fi 
}

show_status()
{
	status
	if [ $? -eq 0 ]; then
		echo "$app_name is running........."
	else 
		echo "$app_name is not running........."
	fi 
}

get_status()
{
	status
	if [ $? -eq 0 ]; then
		exit 0
	else 
		exit 1
	fi 
}

test_stop() 
{
    #关闭服务器中的gen_server
    sed -i '3s/^.*$/%%! -smp enable -name '"temp_""$node_name"'/' rpc.escript 
    escript rpc.escript "$node_name" "$node_cookie"
}

 
start_server()
{
	local smp_pid=`ps axu | grep -w $root_dir | grep -v "grep" | grep -w "beam.smp"`
	local erlexec_pid=`ps axu | grep -w $root_dir | grep -v "grep" | grep -w "erlexec"`
	local server_status=""
	
	if [ "$erlexec_pid" != "" ]; then 
		echo "Server is starting ................"
		exit 1
	elif [  "$smp_pid" != "" ]; then 
		echo "Server already start ................"
		exit 1
	else 
		echo "Start Server ................"
		cat /dev/null > "$root_dir/config/.server_status.txt"
	fi 
	
	cd "$root_dir"
    (nohup ./erts-"$project_erts_vsn"/bin/erl -args_file ./tool/vm.args -boot ./releases/"$cur_app_vsn"/"$app_name"  >./game_log/nohup.out	2>&1 )&
	
	local count=0
	while [ $count -lt $start_wait_time ]
	do
		smp_pid=`ps axu | grep -w $root_dir | grep -v "grep" | grep -w "beam.smp"`
		erlexec_pid=`ps axu | grep -w $root_dir | grep -v "grep" | grep -w "erlexec"`
		cd "$root_dir/config"
		server_status=`cat "$root_dir/config/.server_status.txt"`
		echo "server_status:::""$server_status"
		if [ "$server_status" != "" ]; then
			echo  "$project_name start ok......"
			exit 0
		else 
			sleep 1
			let "count = count + 1"	
			echo "time:::already wait $count""s"
		fi
	done
	echo "$project_name start timeout ......"
	exit 1
}

test_call() 
{
	"$erl_cal_path" -name "$node_name" -c "$node_cookie" -a 'gate_app window_start []'
}

pre_clean()
{
	cd "$root_dir"
	rm -rf bin 
	rm -rf erts-6.2
	rm -rf lib 
	rm -rf releases
	cd tool 
	rm -rf version.txt
}

generate_new_version_project()
{
	pre_clean
	local release_package_name=$1
	/bin/cp  -rf "$root_dir"/../first_blood_package/concise_package/"$release_package_name"/*  "$root_dir"/
}



install_upgrade() 
{
	cd "$root_dir"
	local content_error=""
	local release_package=$1
	echo "$release_package"
	local app_vsn=${release_package##*_} 
	app_vsn=${app_vsn%.*}
	app_vsn=${app_vsn%.*}
	local release_package_name="$app_name""_$app_vsn"
	/bin/cp ../first_blood_package/upgrade_package/"$release_package" ./releases/
	/usr/local/erl/lib/erlang/lib/erl_interface-3.7.17/bin/erl_call -name "$node_name" -c "$node_cookie" -a 'release_handler unpack_release ["'"$release_package_name"'"]' |tee .unpack_release
	content_error=`cat .unpack_release |grep "error" |wc -l`
	cat .unpack_release
	if [ ! "$content_error" -eq 0 ]; then 
		rm -rf .unpack_release
		exit 1
	fi 
	/usr/local/erl/lib/erlang/lib/erl_interface-3.7.17/bin/erl_call -name "$node_name" -c "$node_cookie" -a 'release_handler install_release ["'"$app_vsn"'"]' | tee .unpack_release
	content_error=`cat .unpack_release |grep "error" |wc -l`
	cat .unpack_release
	if [ ! "$content_error" -eq 0 ]; then 
		rm -rf .unpack_release
		exit 1
	fi 
	
	/usr/local/erl/lib/erlang/lib/erl_interface-3.7.17/bin/erl_call -name "$node_name" -c "$node_cookie" -a 'release_handler make_permanent ["'"$app_vsn"'"]' | tee .unpack_release
	content_error=`cat .unpack_release |grep "error" |wc -l`
	cat .unpack_release
	if [ ! "$content_error" -eq 0 ]; then 
		rm -rf .unpack_release
		exit 1
	fi 
	rm -rf .unpack_release
	echo "upgrade_package ok ............"
	
}
stop()
{
	local smp_pid=`ps axu | grep -w $root_dir | grep -v "grep" | grep -w "beam.smp"`
	if [ "$smp_pid" == "" ]; then 
		echo "$project_name is not start ....."
		exit 0
	fi 
    
    
	#"$erl_cal_path" -name "$node_name" -c "$node_cookie" -a 'kick_manager stop_server []'
    #关闭服务器中的gen_server
    cd "$root_dir"
    
    sed -i '3s/^.*$/%%! -smp enable -name '"rpc_""$node_name"'/' ./tool/rpc.escript 
    ./erts-6.2/bin/escript ./tool/rpc.escript  "$node_name" "$node_cookie" stop_server
	#local count=0
	#local wait_times=5
	#while [ $count -lt $start_wait_time ]
	#do
	#	local pid=`ps axu | grep -w $root_dir | grep -v "grep"`
	#	if [ "$pid" == "" ]
	#	then
	#		echo  "$project_name stop ok"
	#		exit 0
	#	fi
    #
	#	sleep 1 
	#	let "count = count + 1"	
	#done
	#然后直接杀死
	local smp_pid=`ps axu | grep -w $root_dir | grep -v "grep" | grep -w "beam.smp" | awk -F " " '{ print $2 }'`
	kill "$smp_pid"
	echo "$project_name has killed ......"
}

start_test()
{
	cd "$root_dir"
	./erts-"$project_erts_vsn"/bin/erl -args_file ./tool/vm.args -boot ./releases/"$cur_app_vsn"/"$app_name" 
}
 
 
 show_version()
 {
	cd "$root_dir"
    sed -i '3s/^.*$/%%! -smp enable -name '"temp_""$node_name"'/' ./tool/rpc.escript 
    ./erts-6.2/bin/escript ./tool/rpc.escript  "$node_name" "$node_cookie" show_version

 }
 
 
attach()
{
	cd "$root_dir"
	erl -setcookie "$node_cookie" -name "attach_""$node_name" -remsh "$node_name"
}

main() 
{
	case "$1" in 
		start) 
			start_server;;
		stop) 
			stop;;
		test_call) 
			test_call;;
		test_stop) 
            test_stop;;
		install_upgrade) 
			install_upgrade $2;;
		generate_new_version_project)
			generate_new_version_project;;
		start_test)
			start_test;;
		attach) attach;;
		version) show_version;;
		get_status)   get_status;;
		show_status)  show_status;;
	esac
}


#####################################################

main $1 $2


#####################################################






