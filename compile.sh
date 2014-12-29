#!/bin/sh

##########################      项目相关配置  begin   #############################
first_blood_root_dir="/home/fuzongqiong/first_blood_project/"
first_blood_app_name="first_app"
first_blood_version="60"
first_blood_lib="kernel stdlib sasl cowboy cowlib emysql ranch "
first_blood_lib="$first_blood_lib""$first_blood_app_name"
first_blood_version_list="first_blood_version_list.txt"
##########################      项目相关配置   end   #############################

######################    项目编译环境配置  begin   ################
cur_dir="$(dirname `readlink -f "$0"`)"  
root_dir=${cur_dir%/*}
root_dir="$root_dir/"

##设置软硬件资源,最大句柄,core文件限制
#ulimit -S -c unlimited > /dev/null 2>&1
#ulimit -SH -n 65535
######################    项目编译环境配置   end   ################

#目录检测
if [ "$root_dir" != "$first_blood_root_dir" ]; then 
	echo "请设置构建环境目录:first_blood_root_dir "
	exit 1
fi 

###############   文件位置  begin   ####################
#fd_version_list.txt 在first_blood_tool文件夹下
version_list="fd_version_list.txt"

###############   文件位置   end    ####################



#生成测试起始目录
generate_compile_struct() 
{
	cd "$root_dir"
	mkdir first_blood_build
	mkdir first_blood_src
	mkdir first_blood_package
	
	cd first_blood_src
	mkdir resource src
	
	cd "$root_dir""first_blood_package"
	mkdir upgrade_package project_package concise_package
}


###显示编译过的版本列表
show_version_list()
{
	cd  "$root_dir""first_blood_tool"
	cat "$version_list"
}

generate_consise_project()
{
	#传入参数:$1=项目目录
	#local release_package_name="$first_blood_app_name""_$first_blood_version"
	local release_package_name=$1
	local lc_project_dir="$root_dir""first_blood_package/project_package"
	local lc_concise_dir="$root_dir""first_blood_package/concise_package"
	
	if [ ! -d "$lc_project_dir/release_package_name" ]; then 
		echo "没找到项目目录,请进行查证"
		exit 1
	fi 
	
	cd "$lc_concise_dir"
	if [ -d "$lc_concise_dir/$release_package_name" ]; then 
		rm -rf "$lc_concise_dir/$release_package_name"
	fi 

	cp -rf "$lc_project_dir/$release_package_name" "$lc_concise_dir"
	cd "$lc_concise_dir/$release_package_name"
	rm -rf config 
	rm -rf game_log
	rm -rf log
	rm -rf record
	rm -rf resource
	cd tool
	rm -rf start.sh
	rm -rf vm.args
}

pre_clean() 
{
	cd "$root_dir""first_blood_build/$first_blood_app_name/src/"
	mv ./top_start/* .
}

generate_rebar_config()
{
	cd "$root_dir""first_blood_build"
	local rebar_sub_dirs="{sub_dirs, [\"$first_blood_app_name\",\"rel\"]}."
	local rebar_clean="{clean_files, [\"$first_blood_app_name/ebin\"]}."
	cat /dev/null >rebar.config
	echo "$rebar_sub_dirs" >> rebar.config
	echo "$rebar_clean"    >> rebar.config
}

copy_src() 
{
	cd "$root_dir"
	cp -rf ./first_blood_src/src/* "./first_blood_build/$first_blood_app_name/src/"
	pre_clean
}

#生成编译目录结构
create_build_dir_struct()
{
	cd "$root_dir""first_blood_build"
	mkdir "$first_blood_app_name"
	mkdir rel
	
	cd "$first_blood_app_name"
	mkdir src
	
	cd "$root_dir""first_blood_build/rel"
	rebar create-node nodeid="$first_blood_app_name"
	generate_rebar_config
}

rewrite_reltool_config()
{
	local rel_dir="$root_dir""first_blood_build/rel"
	local first_blood_deps_dir="../$first_blood_app_name/src/deps"
	local app_lib_dir="../$first_blood_app_name"
	local app_reltool_name="$root_dir""first_blood_build/rel/reltool.config"
	local app_src="$root_dir""first_blood_build/$first_blood_app_name/src/$first_blood_app_name.app.src"
	cd "$root_dir""first_blood_tool"
	escript rewrite_version_and_reltool.escript "$first_blood_deps_dir" "$first_blood_app_name" "$first_blood_version" "$first_blood_lib" "$app_lib_dir" "$app_reltool_name" "$app_src"
}

copy_resource() 
{
	local release_dir="$root_dir""first_blood_build/rel/$first_blood_app_name"
	if [ -d "$release_dir/resource" ]; then 
		rm -rf "$release_dir/resource"
	fi 
	cp -rf "$root_dir""first_blood_src/resource" "$release_dir"
}

get_pre_version()
{
	cd "$root_dir""first_blood_build"
	local lc_pre_version=0
	local project_version_pwd="$root_dir""first_blood_tool/$first_blood_version_list"
	if [ ! -f "$project_version_pwd" ]; then 
		echo "没有找到版本列表 $project_version_pwd"
		exit 1
	fi 
	awk -v awk_cur_version="$first_blood_version" -v awk_pre_version="$lc_pre_version" -v exist_cur_version=0 '
		BEGIN{} 
		{if(awk_cur_version!=$2) {awk_pre_version=$2;}  
		else {exist_cur_version=1; exit}
		} 
		END {printf(" awk_pre_version=%d\n exist_cur_version=%d\n", awk_pre_version, exist_cur_version)}' "$project_version_pwd" > pre_version.temp_version
	while read line 
	do 
		eval $line
	done < pre_version.temp_version
	rm -rf pre_version.temp_version
	if [ $exist_cur_version -eq 0 ] ; then 
		echo "没有找到当前版本的数据"
		exit 1
	fi 
	if [ "$awk_pre_version" -eq 0 ]; then 
		echo "没有找到上一个版本的数据"
		exit 1
	fi 
	
	return "$awk_pre_version"
}

generate_upgrade_tar()
{
	get_pre_version
	local lc_pre_version=$?
	local lc_pre_project="$root_dir""first_blood_package/project_package/$first_blood_app_name""_""$lc_pre_version"
	local lc_cur_project="$root_dir""first_blood_package/project_package/$first_blood_app_name""_""$first_blood_version"
	local lc_release_dir="$root_dir""first_blood_build/rel"
	
	#删除rel目录下以前生成的项目
	if [ -d "$lc_release_dir/$first_blood_app_name" ]; then 
		rm -rf "$lc_release_dir/$first_blood_app_name"
	fi 
	
	if [ -d "$lc_release_dir/$first_blood_app_name""_""$lc_pre_version" ]; then 
		rm -rf "$lc_release_dir/$first_blood_app_name""_""$lc_pre_version"
	fi 
	
	cp -rf "$lc_pre_project" "$lc_release_dir/$first_blood_app_name""_""$lc_pre_version"
	cp -rf "$lc_cur_project" "$lc_release_dir/$first_blood_app_name"
	
	cd "$lc_release_dir"
	rebar generate-appups previous_release="$first_blood_app_name""_$lc_pre_version"
	rebar generate-upgrade  previous_release="$first_blood_app_name""_$lc_pre_version"
	
	local lc_upgrade_package="$root_dir""first_blood_package/upgrade_package/"
	cd "$lc_upgrade_package"
	if [ -f "$first_blood_app_name""_$first_blood_version.tar.gz" ];then 
		local lc_cur_time=`date "+%Y_%m_%d_%H_%M_%S"`
		mv "$first_blood_app_name""_$first_blood_version.tar.gz" "$first_blood_app_name""_$first_blood_version.tar.gz""_$lc_cur_time" 
	fi 
	cd "$lc_release_dir"
	mv "$first_blood_app_name""_$first_blood_version.tar.gz"  "$root_dir""first_blood_package/upgrade_package"
	echo "first_blood_version=\"$first_blood_version\"" >"$root_dir""first_blood_package/upgrade_package/version.txt"
	echo "first_blood_app_name=\"$first_blood_app_name\"" >>"$root_dir""first_blood_package/upgrade_package/version.txt"
	rm -rf "$lc_release_dir/$first_blood_app_name"
	rm -rf "$lc_release_dir/$first_blood_app_name""_""$lc_pre_version"
}


generate_post() 
{
	local build_dir="$root_dir""first_blood_build"
	local build_release_dir="$build_dir/rel/$first_blood_app_name"
	local build_src_dir="$build_dir/$first_blood_app_name"
	local project_src_dir="$root_dir""first_blood_src"
	cp -rf "$project_src_dir/resource" "$build_release_dir/"
	cp -rf "$build_src_dir/src/config" "$build_release_dir/"
	cd "$build_release_dir"
	mkdir game_log record
	
	cd "$root_dir""first_blood_build"
	local start_rel=`cat ./rel/$first_blood_app_name/releases/start_erl.data`
	local erts_version=${start_rel% *}
	local erts_bin_dir="$root_dir""first_blood_build/rel/$first_blood_app_name/erts-$erts_version/bin"
	rm -rf "$erts_bin_dir/erl"
	cp $root_dir""first_blood_tool/erl $erts_bin_dir
	chmod +x "$erts_bin_dir/erl"
	
	local lc_project_package_dir="$root_dir""first_blood_package/project_package"
	local lc_app_name_with_version="$first_blood_app_name""_""$first_blood_version"
	
	if [ -d "$lc_project_package_dir/$lc_app_name_with_version" ]; then 
		cd "$lc_project_package_dir"
		local lc_cur_time=`date "+%Y_%m_%d_%H_%M_%S"`
		mv "$lc_app_name_with_version" "$lc_app_name_with_version""_""$lc_cur_time"
	fi 
	
	cd "$root_dir""first_blood_build/rel/$first_blood_app_name"
	mkdir tool
	echo "first_blood_version=\"$first_blood_version\"" >./tool/version.txt
	echo "first_blood_app_name=\"$first_blood_app_name\"" >>./tool/version.txt
	cp "$root_dir""first_blood_tool/vm.args" ./tool
	cp "$root_dir""first_blood_tool/start.sh" ./tool
	
	cd "$root_dir""first_blood_build/rel"
	mv "$first_blood_app_name" "$lc_project_package_dir/$first_blood_app_name""_""$first_blood_version"	
}


generate_first_blood_project()
{
	cd "$root_dir""first_blood_build"
	rebar compile
	rebar generate
	generate_post
	
	local project_version_pwd="$root_dir""first_blood_tool/$first_blood_version_list"
	local cur_time=`date "+%Y-%m-%d_%H:%M:%S"`
	echo "$cur_time $first_blood_version" >> "$project_version_pwd"
	echo "$first_blood_app_name""_""$first_blood_version generates ok .........."
}

clear_build_dir()
{
	cd "$root_dir""first_blood_build"
	rm -rf *
	echo "now first_blood_build is empty "
}

generate_new_version() 
{
	copy_src
	rewrite_reltool_config
	generate_first_blood_project
}



rebuild()
{
	clear_build_dir
	create_build_dir_struct
	copy_src
	rewrite_reltool_config
	generate_first_blood_project
}


svn_update()
{
	cd "$root_dir"
	svn update "$root_dir""first_blood_src/src"
	echo " server update ok............"
	svn update "$root_dir""first_blood_src/resource"
	echo " resource update ok............"
}

############   打包  begin ########
make_full_package()
{
	cd "$root_dir"
	local lc_project_dir="$root_dir""first_blood_package/project_package"
	local lc_project_name="$first_blood_app_name""_$first_blood_version"
	local lc_package_dir="$root_dir""first_blood_package/package"
	rm -rf "$lc_package_dir/*"
	cd "$lc_project_dir"
	tar -zcvf "$lc_package_dir"/"$lc_project_name"".tar.gz" "$lc_project_name"
	cd "$lc_package_dir"
	md5sum "$lc_project_name"".tar.gz" > "$lc_project_name""_Md5".txt
}

make_concision_package()
{
	echo ""
}



make_upgrade_package()
{
	echo ""
}


############   打包  end ########
main() 
{
	case "$1" in 
		generate_compile_struct)      
			generate_compile_struct;;
		create_build_dir_struct)   
			create_build_dir_struct;;
		clear_build_dir)
			clear_build_dir;;
		copy_resource)
			copy_resource;;
		generate_new_version)
			generate_new_version;;
		get_pre_version)
			get_pre_version;;
		generate_upgrade_tar)
			generate_upgrade_tar;;
		generate_consise_project)
			generate_consise_project $2;;
		svn )
			svn_update;;
		make_full_package ) make_full_package;;
		transmit ) transmit;;
		show_version_list ) show_version_list;;
		-h)   			 echo '';;
		*)               echo 'nothing to match,please "-h" for help!';;
	esac
}



#####################################################


main $1 $2


#####################################################






