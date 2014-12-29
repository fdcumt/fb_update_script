#!/bin/env escript

%%! -smp enable -sname factorial -mnesia debug verbose




main(List) ->
	io:format("==================>>>>>>>>>>>>>> Execute ~p begin\n", [escript:script_name()]),
	Lib_dirs = lists:nth(1,List),
	AppName = lists:nth(2,List),
	Version = lists:nth(3,List),
	DepList = lists:nth(4,List),
	SubDir  = lists:nth(5,List),
	FileName = lists:nth(6,List),
	SrcName  = lists:nth(7,List),

	%更改app.src的版本号
	{ok, AppSrcContent} = file:consult(SrcName),
	NewAppContent = fn_rewrite_app_src_version(Version, AppSrcContent),
	{ok, IOAppSrcContent} = file:open(SrcName,write),
	fn_write_new_content(IOAppSrcContent, NewAppContent),
	file:close(IOAppSrcContent),
	RelDepList = fn_get_rel_dep_list(DepList),
	{ok, ContentList} = file:consult(FileName),
	ContentList1 = fn_rewrite_lib_dirs(ContentList, Lib_dirs),
	ContentList2 = fn_rewrite_rel(ContentList1, AppName, Version, RelDepList),
	ContentList3 = fn_rewrite_app_sub_dir(ContentList2, AppName, SubDir),
	NewContentList = ContentList3,
	{ok, IO} = file:open(FileName,write),
	fn_write_new_content(IO, NewContentList),
	file:close(IO),
	io:format("==================>>>>>>>>>>>>>> Execute ~p end\n", [escript:script_name()]).

fn_rewrite_app_src_version(Version, AppSrcContent) ->
	[{application, _AppName, AppSrcList}] = AppSrcContent,
	NewAppList = fn_rewrite_app_src_version_tuple(AppSrcList, Version, []),
	NewAppContent = [{application, _AppName, NewAppList}],
	NewAppContent.

fn_rewrite_app_src_version_tuple([{vsn,_OldVersion}|Tail], NewVersion, NewSrcList) ->
	List  = lists:append(NewSrcList, [{vsn, NewVersion}]),
	ResultList = lists:append(List, Tail),
	ResultList;
fn_rewrite_app_src_version_tuple([Ele|Tail], NewVersion, NewSrcList) ->
	ResultSrcList  = lists:append(NewSrcList, [Ele]),
	fn_rewrite_app_src_version_tuple(Tail, NewVersion, ResultSrcList).


fn_get_rel_dep_list([], DepList) ->
	DepList;
fn_get_rel_dep_list([Ele|Tail], DepList) ->
	Atom = list_to_atom(Ele),
	NewDepList = lists:append(DepList, [Atom]),
	fn_get_rel_dep_list(Tail, NewDepList).

fn_get_rel_dep_list(DepList) ->
	StrList = string:tokens(DepList, " "),
	AtomDepList = fn_get_rel_dep_list(StrList, []),
	AtomDepList.


fn_rewrite_lib_dirs(ContentList,Lib_dirs) ->
	{sys, SysTupleList} = lists:keyfind(sys,1,ContentList),
	{lib_dirs,Lib_dirsTupleList} = lists:keyfind(lib_dirs,1,SysTupleList),
	NewLib_dirsTupleList = fn_add_lib_dir(Lib_dirsTupleList, Lib_dirs, []),
	NewSysTupleList = lists:keyreplace(lib_dirs,1,SysTupleList,{lib_dirs, NewLib_dirsTupleList}),
	NewContentList = lists:keyreplace(sys,1,ContentList,{sys, NewSysTupleList}),
	NewContentList.

fn_add_lib_dir([], NewDir, PreLibDir) ->
	NewLibDir = lists:append(PreLibDir,[NewDir]),
	NewLibDir;
fn_add_lib_dir([NewDir|Tail], NewDir, PreLibDir) ->
	NewLibDir = lists:append(PreLibDir,[NewDir]),
	ResultLibDir = lists:append(NewLibDir,Tail),
	ResultLibDir;
fn_add_lib_dir([Ele|Tail], NewDir, PreLibDir) ->
	NewLibDir = lists:append(PreLibDir,[Ele]),
	fn_add_lib_dir(Tail, NewDir, NewLibDir).


fn_rewrite_rel(ContentList, AppName, NewVersion, DepList) ->
	{sys, SysTupleList} = lists:keyfind(sys,1,ContentList),
	{{rel, AppName, _OldVersion, _OldDeps }, Pos, RemainList } = fn_take_rel_app_tuple(SysTupleList, AppName, [], 1),
	NewSysTupleList = fn_put_rel_app_tuple(RemainList, {rel, AppName, NewVersion, DepList }, Pos, 1, []),
	NewContentList = lists:keyreplace(sys,1,ContentList,{sys, NewSysTupleList}),
	NewContentList.

fn_put_rel_app_tuple(List, Tuple, Pos, Pos, PreList) ->
	List1 = lists:append(PreList, [Tuple]),
	List2 = lists:append(List1, List),
	List2;
fn_put_rel_app_tuple([Element|Tail], Tuple, Pos, CurPos, PreList) ->
	List1 = lists:append(PreList, [Element]),
	fn_put_rel_app_tuple(Tail, Tuple, Pos, CurPos+1, List1).


fn_take_rel_app_tuple([{rel, AppName, Version, Deps }|Tail], AppName, RemainList, Pos) ->
	NewRemainList = lists:append(RemainList, Tail),
	{{rel, AppName, Version, Deps }, Pos, NewRemainList };
fn_take_rel_app_tuple([Element|Tail], AppName, RemainList, Pos) ->
	NewPos = Pos+1,
	fn_take_rel_app_tuple(Tail, AppName, [Element|RemainList], NewPos).


fn_rewrite_app_sub_dir(ContentList, AppName, SubDir) ->
	{sys, SysTupleList} = lists:keyfind(sys,1,ContentList),
	AtomAppName = list_to_atom(AppName),
	{{app, AtomAppName, AppConfigList }, Pos, RemainList } = fn_take_app_tuple(SysTupleList, AtomAppName, [], 1),
	NewAppConfigList = fn_rewrite_app_config_list(AppConfigList, SubDir, []),
	NewSysTupleList = fn_put_app_tuple(RemainList, Pos, 1, {app, AtomAppName, NewAppConfigList }, []),
	NewContentList = lists:keyreplace(sys,1,ContentList,{sys, NewSysTupleList}),
	NewContentList.

fn_put_app_tuple(List, Pos, Pos, Tuple, PreList) ->
	NewPreList = lists:append(PreList, [Tuple]),
	RetList    = lists:append(NewPreList, List),
	RetList;
fn_put_app_tuple([Element|Tail], Pos, CurPos, Tuple, PreList) ->
	NewPreList = lists:append(PreList, [Element]),
	fn_put_app_tuple(Tail, Pos, CurPos+1, Tuple, NewPreList).


fn_take_app_tuple([{app, AppName, List}|Tail ], AppName, RemainList, Pos) ->
	NewRemainList = lists:append(RemainList, Tail),
	{{app, AppName, List}, Pos, NewRemainList};
fn_take_app_tuple([Element|Tail], AppName, PreList, Pos ) ->
	NewRemainList = lists:append(PreList, [Element]),
	fn_take_app_tuple(Tail, AppName, NewRemainList, Pos+1 ).

fn_rewrite_app_config_list([], SubDir, PreList) ->
	NewList = lists:append(PreList, [{lib_dir, SubDir}]),
	NewList;
fn_rewrite_app_config_list([{lib_dir,_Dir}|Tail], SubDir, PreList) ->
	NewList1 = lists:append(PreList, [{lib_dir, SubDir}]),
	NewList = lists:append(NewList1, Tail),
	NewList;
fn_rewrite_app_config_list([Element|Tail], SubDir, PreList) ->
	NewList = lists:append(PreList, [Element]),
	fn_rewrite_app_config_list(Tail, SubDir, NewList).



fn_write_new_content(_Io, []) ->
	ok;
fn_write_new_content(Io, [NewContent|Tail]) ->
	io:format(Io,"~p.~n",[NewContent]),
	fn_write_new_content(Io, Tail).


