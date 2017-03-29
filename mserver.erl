%% @author M Wright <201176962@student.uj.ac.za>
%% @copyright Wright, MJ 2014-2015
%% @version 2.2
%% @title Server Manager
%% @doc Server Manager spawns new client handler for each connecting client.
%% It supervisors client manager.
%% @end

-module(mserver).

-define(TCP_OPTIONS,[list, {packet, 0}, {active, false}, {reuseaddr, true}]).
-define(TCP_OPTIONS2,[binary, {packet, 0}, {active, false}, {reuseaddr, true}]).

-export([start_link/1]).
-export([st/0]).

-include("recs.hrl").
%%entry point for server to start, on any point defined

%%Start link for supervisor
start_link(Port)->start(Port).
	
%%Default start
st()->start(1024).

%%Primary starting method
start(Port)->
	io:fwrite("Server attempting startup... ~n"),
	random:seed(now()),
	case gen_tcp:listen(Port, ?TCP_OPTIONS) of
		{ok, LSocket}->
						io:fwrite("Server started on port: ~p~n",[Port]),
						Rooms = room:st(),
						io:fwrite("Dungeon has been loaded succesfully!~n"),
						io:fwrite("Starting Client Manager...~n"),
						Pid = spawn(fun() -> clientm:manage_clients([],Rooms) end),
						register(client_manager, Pid),%register process to clientmangager atom
						io:fwrite("Client manager started!~n"),
						io:fwrite("Starting event engine...~n"),
						Eid = spawn(fun() -> eventai:handle_events([],10000) end),
						register(event_handler, Eid),
						io:fwrite("Event engine started!~n"),
						io:fwrite("Waiting for incoming connections...~n"),
						accept_connection(LSocket);
		{error, Reason}->io:fwrite("Failed to start server: ~s~n", [Reason])
	end.



%%accepting client connections
accept_connection(LSocket) ->
    case gen_tcp:accept(LSocket) of%wait for next client to join
        {ok, Socket} ->
            spawn(fun() -> handle_client(Socket) end),%handle arbitrary no clients
            client_manager ! {connect, Socket};%send new client connected
        {error, Reason} -> io:fwrite("Socket accept error: ~s~n", [Reason])
    end,
    accept_connection(LSocket).%infinite loop

%%Handle client messages and send them to client manager
handle_client(Socket) ->%handles data recieved and for disconnects of clients
    case gen_tcp:recv(Socket, 0) of
        {ok, Data}->
            client_manager ! {data, Socket, Data},
            handle_client(Socket);
        {error, closed}->
            client_manager ! {disconnect, Socket};
		{error, Reason} -> 
			client_manager ! {error, Reason};
		{badarg, Reason}->
			client_manager ! {error, Reason}
    end.
