#!/usr/bin/env escript
%% -*- erlang -*-
%%! -smp enable -name temp_
main(Args) ->
    {[Node, Cookie, Operate], RemainList} = lists:split(3,Args),
    auth:set_cookie(list_to_atom(Cookie)),
	AtomOperate = list_to_atom(Operate),
    AtomNode = list_to_atom(Node),
    execute_operate({AtomNode, RemainList}, AtomOperate).
    
    
    

execute_operate({AtomNode, []}, show_version) ->
    Ret = rpc:call(AtomNode, application, which_applications, []),
    io:format("version is ~p~n", [Ret]);
execute_operate({AtomNode, [PackageName, App_vsn]}, upgrade) ->
    Ret1 = rpc:call(AtomNode, release_handler, unpack_release,  [PackageName]),
    io:format("unpack_release ret is ~p~n", [Ret1]),
    {ok, _} = Ret1,
    Ret2 = rpc:call(AtomNode, release_handler, install_release, [App_vsn]),
    io:format("install_release ret is ~p~n", [Ret2]),
    {ok, _, _} = Ret2,
    Ret3 = rpc:call(AtomNode, release_handler, make_permanent,  [App_vsn]),
    io:format("make_permanent ret is ~p~n", [Ret3]),
    ok = Ret3,
    io:format("install upgrade ok!!!~n");
execute_operate({AtomNode, []}, stop_server) ->
    Ret = rpc:call(AtomNode, kick_manager, stop_server, []),
    io:format("stop server ret is ~p~n", [Ret]).
    