#!/bin/sh

#��Ŀ¼
root_dir="/home/fuzongqiong/new_test"

#��Ŀ����
app_name="first_app"
#��Ŀ������
app_lib="kernel stdlib sasl cowboy cowlib emysql ranch logserver"
app_lib="$app_lib ""$app_name"
share_dir="/home/fuzongqiong/client_3d_share/share/"
zdb_dir="/home/fuzongqiong/new_test/src/resource/zdb"

#��ǰĿ¼
cur_dir="$(dirname `readlink -f "$0"`)"  
cur_dir=${cur_dir%/*}

#���Ŀ¼�����Ƿ���ȷ
if [ $root_dir != $cur_dir ]; then
    echo "please set root dir"
    exit 1
fi 

#�汾�Ų���
step_size=0.1
#���ɰ汾���б�
if [ ! -f $root_dir/tool/version.txt ]; then 
    echo "1.0" > $root_dir/tool/version.txt
fi
# �ݴ�
app_version=`cat version.txt `
if [ "$app_version" = "" ]; then 
    echo "1.0" >$root_dir/tool/version.txt
fi 

# ��ǰ�汾��
app_version=`cat $root_dir/tool/version.txt `


#����Դ��Ŀ¼
generate_src_dir() 
{
	cd "$root_dir"
	rm -rf src 
	mkdir src 
	svn co http://192.168.100.120/svn_firstblood3d/resource/trunk ./src/resource
	svn co http://192.168.100.120/svn_firstblood3d/program/trunk/server ./src/server
}

#����Դ��
update_src() 
{
	cd "$root_dir/src"
	svn update resource 
	svn update server
}

#���ɱ���Ŀ¼�ṹ
generate_compile_dir() 
{
	cd "$root_dir"
	rm -rf compile 
	
	mkdir -p ./compile/$app_name/src
	mkdir -p ./compile/rel
    
    cd "compile/rel"
	rebar create-node nodeid="$app_name"
}

#�������Ŀ¼
clean_compile_dir() 
{
    generate_compile_dir
}

#����releaseĿ¼
generate_release_dir()
{
	cd "$root_dir"
	if [ ! -d release ]; then 
		mkdir ./release
	fi 
}

#����ͣ������release��Ŀ¼
generate_simplify_release_dir()
{
	cd "$root_dir"
	if [ ! -d simplify_release ]; then 
		mkdir simplify_release
	fi 
}

#�����ȸ���release��Ŀ¼
generate_hot_release_dir()
{
	cd "$root_dir"
	if [ ! -d hot_release ]; then 
		mkdir hot_release
	fi 
}

#����ǰ����
compile_pre_clean() 
{
    cd "$root_dir"
    cd ./compile/$app_name/src
	mv  ./top_start/* .
    rm -rf $root_dir/compile/rel/$app_name

    #ɾ��������Ŀ�е�Դ��,srcĿ¼
    local deps_dir_list=`ls $root_dir/compile/$app_name/src/deps`
    cd $root_dir/compile/$app_name/src/deps
    for dir in $deps_dir_list 
    do
        if [ -d "$dir/src" ]; then 
            rm -rf $dir/src
        fi 
    done
}

#���������
compile_post_clean() 
{
    cd $root_dir/compile/rel/$app_name
    cp -rft . $root_dir/src/resource $root_dir/src/server/config
    mkdir game_log record tool
    
    local start_rel=`cat $root_dir/compile/rel/$app_name/releases/start_erl.data`
	local erts_version=${start_rel% *}
	local app_vsn=${start_rel#* }
    cp -rft $root_dir/compile/rel/$app_name/tool  $root_dir/tool/vm.args $root_dir/tool/start.sh $root_dir/tool/rpc.escript 
	cp -rft $root_dir/compile/rel/$app_name/bin/  /usr/local/erl/lib/erlang/bin/start.boot
    cp -rf "$root_dir/tool/erl" "$root_dir/compile/rel/$app_name/erts-$erts_version/bin/erl"
    chmod +x "$root_dir/compile/rel/$app_name/erts-$erts_version/bin/erl"
    cd $root_dir/compile/rel/$app_name
    find . -name ".*" |grep -v "^.$" | xargs rm -rf
    rm -rf $root_dir/release/$app_name"_$app_vsn"
    mv $root_dir/compile/rel/$app_name $root_dir/release/$app_name"_$app_vsn"
}

#����rebar.config
generate_rebar_config()
{
	cd "$root_dir/compile"
	local rebar_sub_dirs='{sub_dirs, ["'"$app_name"'","rel"]}.'
	local rebar_clean='{clean_files, ["'"$app_name"'/ebin"]}.'
	local rebar_def="{erl_opts, [{d,'RELEASE',already_def}]}. "
	cat /dev/null >rebar.config
	echo "$rebar_sub_dirs" >> rebar.config
	echo "$rebar_clean"    >> rebar.config
	echo "$rebar_def"    >> rebar.config
}

#����reltool.config�����޸�first_app.app.src�İ汾��
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

#��Դ�뿽��������Ŀ¼
copy_src_to_compile() 
{
	cd "$root_dir"
	rm -rf ./compile/$app_name/src/* ./compile/$app_name/ebin
	cp -rf ./src/server/* ./compile/$app_name/src/
    compile_pre_clean
}

#����Ŀ¼�ṹ
generate_project_structure()
{
    generate_compile_dir
    generate_src_dir
    generate_release_dir
    generate_simplify_release_dir
    generate_hot_release_dir
}

#�����°汾
generate_new_version() 
{
    copy_src_to_compile
    generate_rebar_config
    generate_reltool_config $app_version
    cd "$root_dir/compile"
    rebar compile
	rebar generate
    compile_post_clean
	
	# ������һ���汾��
	local next_app_version=$(echo "$app_version+$step_size"|bc)
	echo $next_app_version > $root_dir/tool/version.txt
}

#�����ȸ��°汾
generate_hot_release() 
{
    if [ ! $# -eq 2 ]; then 
        echo "please input the right arguments"
        exit 1
    fi
    local pre_vsn=$1
    local cur_vsn=$2
    cd $root_dir/compile/rel
    rm -rf $app_name $pre_vsn $cur_vsn
    cp -rft $root_dir/compile/rel $root_dir/release/$cur_vsn $root_dir/release/$pre_vsn
    mv $cur_vsn $app_name
    local start_rel=`cat $root_dir/compile/rel/$app_name/releases/start_erl.data`
	local app_vsn=${start_rel#* }
    generate_reltool_config $app_vsn
    cd $root_dir/compile/rel
    rebar generate-appups   previous_release="$pre_vsn"
	rebar generate-upgrade  previous_release="$pre_vsn"
    rm -rf $pre_vsn $app_vsn
    mv $cur_vsn.tar.gz $root_dir/hot_release
}

show_version_list()
{
    ls $root_dir/release
}

make_release_share() 
{
    local lc_tar_project=$1
    rm -rf $share_dir/release/$lc_tar_project.tar.gz 
    rm -rf $root_dir/release/$lc_tar_project.tar.gz
    cd $root_dir/release/$lc_tar_project 
    tar -zcvf $lc_tar_project.tar.gz * > /dev/null
    mv $root_dir/release/$lc_tar_project/$lc_tar_project.tar.gz $share_dir/release/$lc_tar_project.tar.gz  
}

#����ͣ�����°汾
generate_simplify_release() 
{
	local lc_app_version=`cat $root_dir/tool/version.txt `
	local lc_pre_version=$(echo "$lc_app_version-$step_size"|bc)
	local lc_tar_project=$app_name"_$lc_pre_version"
	rm -rf $share_dir/simplify_release/first_blood.tar.gz $root_dir/simplify_release/first_blood.tar.gz $root_dir/simplify_release/first_blood  $root_dir/simplify_release/$lc_tar_project

    cp -rf $root_dir/release/$lc_tar_project $root_dir/simplify_release/$lc_tar_project
	cd $root_dir/simplify_release
	mv $lc_tar_project first_blood
	tar -zcvf first_blood.tar.gz first_blood > /dev/null
	echo 'make tar ok !!!'
	mv first_blood.tar.gz $share_dir/simplify_release/first_blood.tar.gz
	echo 'generate_simplify_release ok !!!'
}

make_hot_release_share() 
{
    local lc_tar_project=$1
    mv $root_dir/hot_release/$lc_tar_project $share_dir/hot_release/$lc_tar_project
}

create_lvup_package() 
{
    if [ ! $# -eq 4 ]; then 
        echo "please input the right arguments"
        exit 1
    fi
    local lc_run_file_list=$1
    local lc_run_dir_list=$2
    local lc_new_file_list=$3
    local lc_new_dir_list=$4
    #���ɶԱ��ļ�
    awk -F ' ' ' BEGIN { i = 0}
    { 
        if(NR==FNR) { 
            a[$1]=$2 ;
            b[i++]=$1;
        } else if(a[$1]==$2){ 
            a[$1] = "";
        }else {
            print "+f "$1;
        }  
    } END { for(k=0;k<i;++k){ if(a[b[k]]!="") {print "-f "b[k]}}}' $lc_run_file_list  $lc_new_file_list  >lvup_file_result.txt
    
    awk  ' BEGIN {i=0}
    { 
        if(NR==FNR) { 
            a[$1]=$1 ;
            b[i++]=$1;
        } else if(a[$1]==""){ 
            print "+d "$1;
        }else {
            a[$1]=0 ;
        }  
    } END { for(k=0;k<i; ++k){ if(a[b[k]]!=0) {print "-d "b[k]}}} ' $lc_run_dir_list  $lc_new_dir_list >>lvup_file_result.txt
    
    #����ͣ��������������  
}

make_resource() 
{
	cd "$root_dir/src"
	svn update resource 
	tar -zcf resource.tar.gz resource/ 
	mv -f resource.tar.gz ../resource
	
}

info() 
{
	echo '[svn|update|release|upgrade|resource|show_version_list]'
}

main() 
{
    case "$1" in 
		svn) 
			update_src;;
		update)
            generate_simplify_release ;;
        release)
            generate_new_version ;;
		upgrade)
            make_hot_release_share $2;;
		resource)
            make_resource ;;
        generate_project_structure)
            generate_project_structure;;
		clean_compile) 
			clean_compile_dir;;
		generate_compile_dir) 
			generate_compile_dir;;
		generate_src_dir) 
            generate_src_dir;;
        generate_hot_release)
            generate_hot_release $2 $3;;
        copy_src_to_compile)
            copy_src_to_compile;;
		generate_release_dir) 
			generate_release_dir ;;
        generate_rebar_config)
            generate_rebar_config;;
        show_version_list)
            show_version_list;;
        make_release_share)
            make_release_share $2 $3;;
        generate_reltool_config)
            generate_reltool_config $2;;
		help)
            info $2;;
		*)
            info $2;;
	esac
} 


main $1 $2 $3


