#!/bin/sh

cur_dir="$(dirname `readlink -f "$0"`)"  

root_dir=${cur_dir%/*}
project_name=${root_dir##*/}
project_start_erl=`cat $root_dir/releases/start_erl.data`
project_erts_vsn=${project_start_erl% *}
cur_app_vsn=${project_start_erl#* }
#启动时间超级长,至少是5秒,反正我测试的时候5秒没启动成功
start_wait_time="20"



awk -F ' ' '
	BEGIN {  }
	{ 
	  if($1=="-name")  { print 	"first_blood_name=\""$2"\"" ;} 
	  else if($1=="-setcookie") { print "first_blood_cookie=\""$2"\"" ;}
	}
	END {} ' vm.args >VAR.TXT
	
#first_blood_app_name="first_app"
#first_blood_version="22"
while read line 
do 
	eval $line
done < version.txt

#first_blood_name="first_app@127.0.0.1"
#first_blood_cookie="first_app"

while read line 
do 
	eval $line
done < VAR.TXT




 
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
    (nohup ./erts-"$project_erts_vsn"/bin/erl -args_file ./tool/vm.args -boot ./releases/"$cur_app_vsn"/"$first_blood_app_name" 	2>&1 )&
	
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

pre_clean()
{
	cd "$root_dir"
	rm -rf bin 
	rm -rf erts-6.2
	rm -rf lib 
	rm -rf releases
	cd tool 
	rm -rf version.txt  VAR.TXT 
}

generate_new_version_project()
{
	pre_clean
	local release_package_name="$first_blood_app_name""_$first_blood_version"
	/bin/cp  -rf "$root_dir"/../first_blood_package/concise_package/"$release_package_name"/*  "$root_dir"/
	echo "$first_blood_version"
}



install_upgrade() 
{
	cd "$root_dir"
	local content=""
	local content_error=""
	local release_package="$first_blood_app_name""_$first_blood_version"".tar.gz"
	local release_package_name="$first_blood_app_name""_$first_blood_version"
	cp ../first_blood_package/upgrade_package/"$release_package" ./releases/
	/usr/local/erl/lib/erlang/lib/erl_interface-3.7.18/bin/erl_call -name "$first_blood_name" -c "$first_blood_cookie" -a 'release_handler unpack_release ["'"$release_package_name"'"]' |tee .unpack_release
	content=`cat .unpack_release |grep "error" `
	content_error=`cat .unpack_release |grep "error" `
	if [ content_error != "" ]; then 
		echo "$content"
		rm -rf .unpack_release
		exit 1
	fi 
	/usr/local/erl/lib/erlang/lib/erl_interface-3.7.18/bin/erl_call -name "$first_blood_name" -c "$first_blood_cookie" -a 'release_handler install_release ["'"$first_blood_version"'"]' | tee .unpack_release
	content=`cat .unpack_release |grep "error" `
	content_error=`cat .unpack_release |grep "error" `
	if [ content_error != "" ]; then 
		echo "$content"
		rm -rf .unpack_release
		exit 1
	fi 
	
	/usr/local/erl/lib/erlang/lib/erl_interface-3.7.18/bin/erl_call -name "$first_blood_name" -c "$first_blood_cookie" -a 'release_handler make_permanent ["'"$first_blood_version"'"]' | tee .unpack_release
	content=`cat .unpack_release |grep "error" `
	content_error=`cat .unpack_release |grep "error" `
	if [ content_error != "" ]; then 
		echo "$content"
		rm -rf .unpack_release
		exit 1
	fi 
	echo "upgrade_package ok ............"
	rm -rf .unpack_release
}

stop()
{
	local smp_pid=`ps axu | grep -w $root_dir | grep -v "grep" | grep -w "beam.smp"`
	if [ "$smp_pid" == "" ]; then 
		echo "$project_name is not start ....."
		exit 0
	fi 
	/usr/local/erl/lib/erlang/lib/erl_interface-3.7.18/bin/erl_call -name "$first_blood_name" -c "$first_blood_cookie" -a 'gate_app test []'
	#while [ $count -lt $WAIT_COUNT ]
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
	#现在直接杀死
	local smp_pid=`ps axu | grep -w $root_dir | grep -v "grep" | grep -w "beam.smp" | awk -F " " '{ print $2 }'`
	kill "$smp_pid"
	echo "$project_name has killed ......"
}

start_test()
{
	cd "$root_dir"
	./erts-"$project_erts_vsn"/bin/erl -args_file ./tool/vm.args -boot ./releases/"$cur_app_vsn"/"$first_blood_app_name" 
}
 

main() 
{
	case "$1" in 
		start) 
			start_server;;
		stop) 
			stop;;
		install_upgrade) 
			install_upgrade;;
		generate_new_version_project)
			generate_new_version_project;;
		start_test)
			start_test;;
	esac
}


#####################################################

main $1


#####################################################





