#!/bin/sh

#根目录
root_dir="/home/fuzongqiong/new_test"

#项目名称
app_name="first_app"
#项目依赖项
app_lib="kernel stdlib sasl cowboy cowlib emysql ranch logserver"
app_lib="$app_lib ""$app_name"

#当前目录
cur_dir="$(dirname `readlink -f "$0"`)"  
cur_dir=${cur_dir%/*}

echo $cur_dir
#检测目录设置是否正确
if [ $root_dir != $cur_dir ]; then
    echo "please set root dir"
    exit 1
fi 


#生成源码目录
generate_src_dir() 
{
	cd "$root_dir"
	if [ -d src ]; then 
		rm -rf src 
	fi 
	
	mkdir src 
	svn co http://192.168.100.120/svn_firstblood3d/resource/trunk ./src/resource
	svn co http://192.168.100.120/svn_firstblood3d/program/trunk/server ./src/server
}


#更新源码
update_src() 
{
	cd "$root_dir/src"
	svn update resource 
	svn update server
}

#生成编译目录结构
generate_compile_dir() 
{
	cd "$root_dir"
	if [ -d compile ]; then 
		rm -rf compile 
	fi 
	
	mkdir -p ./compile/$app_name/src
	mkdir -p ./compile/rel
    
    cd "compile/rel"
	rebar create-node nodeid="$app_name"
}

#清理编译目录
clean_compile_dir() 
{
    generate_compile_dir
}

#生成release目录
generate_release_dir()
{
	cd "$root_dir"
	if [ ! -d release ]; then 
		mkdir ./release
	fi 
}

#编译前清理
compile_pre_clean() 
{
    cd "$root_dir"
    cd ./compile/$app_name/src
	mv  ./top_start/* .
    
    #删除依赖项目中的源码,src目录
    local deps_dir_list=`ls $root_dir/compile/$app_name/src/deps`
    cd $root_dir/compile/$app_name/src/deps
    for dir in $deps_dir_list 
    do
        if [ -d "$dir/src" ]; then 
            rm -rf $dir/src
        fi 
    done
}

#编译后设置
compile_post_clean() 
{
    local lc_release_dir="$root_dir/compile/rel/$app_name"
    cp -rf "$root_dir/src/resource" "$lc_release_dir/"
    cp -rf "$root_dir/src/server/config" "$lc_release_dir/"
    mkdir -p "$lc_release_dir/game_log" "$lc_release_dir/record" "$lc_release_dir/tool"
    
    local start_rel=`cat $root_dir/compile/rel/$app_name/releases/start_erl.data`
	local erts_version=${start_rel% *}
	local app_vsn=${start_rel#* }
    cp -rf "$root_dir/tool/vm.args"  "$root_dir/compile/rel/$app_name/tool"
    cp -rf "$root_dir/tool/start.sh" "$root_dir/compile/rel/$app_name/tool"
    cp -rf "$root_dir/tool/erl" "$root_dir/compile/rel/$app_name/erts-$erts_version/bin/erl"
    chmod +x "$root_dir/compile/rel/$app_name/erts-$erts_version/bin/erl"
}

#生成rebar.config
generate_rebar_config()
{
	cd "$root_dir/compile"
	local rebar_sub_dirs="{sub_dirs, [\"$app_name\",\"rel\"]}."
	local rebar_clean="{clean_files, [\"$app_name/ebin\"]}."
	cat /dev/null >rebar.config
	echo "$rebar_sub_dirs" >> rebar.config
	echo "$rebar_clean"    >> rebar.config
}

#生成reltool.config并且修改first_app.app.src的版本号
generate_reltool_config()
{
    local app_svn=$1
    local rel_dir="$root_dir/compile/rel"
    local dep_dir="../$app_name/src/deps"
    local lib_dir="../$app_name"
    local reltool_config_name="$root_dir/compile/rel/reltool.config"
    local app_src_name="$root_dir/compile/$app_name/src/$app_name.app.src"
    cd "$root_dir/tool"
    escript generate_reltool_config.escript "$dep_dir" "$app_name" "$app_svn" "$app_lib" "$lib_dir" "$reltool_config_name" "$app_src_name"
}

#将源码拷贝到编译目录
copy_src_to_compile() 
{
	cd "$root_dir"
	rm -rf ./compile/$app_name/src/*
	if [ -d ./compile/$app_name/ebin ]; then 
		rm -rf ./compile/$app_name/ebin
	fi 
	
	cp -rf ./src/server/* ./compile/$app_name/src/
    compile_pre_clean
}

#生成目录结构
generate_project_structure()
{
    generate_compile_dir
    generate_src_dir
    generate_release_dir
}



#生成新版本
generate_new_version() 
{
    if [ ! $# -eq 1 ]; then 
		echo "please set version number"
		exit 1
	fi
    copy_src_to_compile
    generate_rebar_config
    generate_reltool_config $1
    cd "$root_dir/compile"
    rebar compile
	rebar generate
    compile_post_clean
}


main() 
{
    case "$1" in 
		svn) 
			update_src;;
        generate_project_structure)
            generate_project_structure;;
		clean_compile) 
			clean_compile_dir;;
		generate_compile_dir) 
			generate_compile_dir;;
		generate_src_dir) 
            generate_src_dir;;
        generate_new_version)
            generate_new_version $2;;
        copy_src_to_compile)
            copy_src_to_compile;;
		generate_release_dir) 
			generate_release_dir ;;
        generate_rebar_config)
            generate_rebar_config;;
        generate_reltool_config)
            generate_reltool_config $2;;
	esac
} 


main $1 $2 $3 $4 $5


