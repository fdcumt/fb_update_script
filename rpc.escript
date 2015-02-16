#!/usr/bin/env escript
%% -*- erlang -*-
%%! -smp enable -name first_blood@127.0.0.1
main([Node, Cookie, Operate]) ->
    auth:set_cookie(list_to_atom(Cookie)),
	AtomOperate = list_to_atom(Operate),
    AtomNode = list_to_atom(Node),
    
    execute_operate(AtomNode, AtomOperate).
    
    
    
execute_operate(AtomNode, stop_server) ->
    Ret = rpc:call(AtomNode, kick_manager, stop_server, []),
    io:format("stop server ret is ~p~n", [Ret]);
execute_operate(AtomNode, show_version) ->
    Ret = rpc:call(AtomNode, application, which_applications, []),
    io:format("version is ~n ~p~n", [Ret]).
    