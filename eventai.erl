%% @author M Wright <201176962@student.uj.ac.za>
%% @copyright Wright, MJ 2014-2015
%% @version 1.1
%% @title Event Managers
%% @doc A simple Event Manager that handles MUD events
%% Used for sending messages to client to create atmosphere.
%% @end
-module(eventai).

-export([handle_events/2]).

-include("recs.hrl").


%%--------------------------------------------------------------------
%% @doc
%% Main message loop
%% Handles all messages to and from client_manager
%% @spec handle_events(Data, T) -> ok
%% @end
%%--------------------------------------------------------------------
handle_events(Data, T)->
	random:seed(now()),%%randomize asap
	receive
		{update, NData}->
			handle_events(NData, 12000);%%super speed timeout to try ensure data not old
		{exit, Reason}->
			 io:fwrite("\r\nEvent manager closing: ~w~n", [Reason]),
			 ok
	after T->
			attemptevent(Data),
			handle_events([], 12000)%%clear data so that update is forced before next event
	end.
	
%%--------------------------------------------------------------------
%% @doc
%% Attempts to Create event to propgate to player or rooms of players
%% 
%% @spec attemptevent(Data)-> ok
%% @end
%%--------------------------------------------------------------------
attemptevent(Data)->
	case Data of
		[]->updateme();
		[{[], Rooms}] when length(Rooms)/=0 ->updateme();
		[{[],[]}]->updateme();
		[{_Players, _Rooms}]->case echance(random:uniform(100)) of%% 25% to do event after 5 seconds 
							true->createevent(Data);
							false->ok
						end
	end.
	
%%--------------------------------------------------------------------
%% @doc
%% Propogtaes message to client_manager to send an update message back to event manager
%% 
%% @end
%%--------------------------------------------------------------------
	
updateme()-> client_manager ! {updateme}.

%%--------------------------------------------------------------------
%% @doc
%% Creates an event and propgates it to the clientmanager
%% 
%% @spec createevent(Data)-> ok
%% @end
%%--------------------------------------------------------------------
createevent(Data)->%%event types
	case random:uniform(2) of%%
		1->%%Watching a player
			watchplayer(Data);
		2->%%notify room of activity
			watchroom(Data);
		_->ok
	end.

watchplayer(Data)->
		[{Players, _Rooms}]=Data,
		WPlayer = pickrandomfromList(Players),
		Msg = "\r\n"++aCol:actioncol(pickrandomfromList(playerwatchlist()))++"\r\n",
		client_manager ! {watchplayer, Msg, WPlayer}.

watchroom(Data)->%%pick a player then do room broadcast, that way always get atleast some1
		[{Players, Rooms}]=Data,
		WPlayer = pickrandomfromList(Players),
		WRooms = pickrandomfromList(room:getValidDoors(WPlayer, Rooms)),
		Msg = "\r\n"++aCol:actioncol(pickrandomfromList(roomactivitylist()))++aCol:addcol({green, WRooms})++"\r\n",
		client_manager ! {watchroom, Msg, WPlayer#player.roomId}.
		
pickrandomfromList(List)->
	Length = length(List),
	lists:nth(random:uniform(Length), List).
	
	
	
echance(Val) when (Val<25) and (Val>0) ->
	true;
echance(_Val) ->
	false.

roomactivitylist()->
		["A noise can be heard from the ", "A strange scuffling noise is heard to the ", "You feel a dark presence near the ", "It feels as though you are being watched from the ", "A loud crash can be heard from the ", "Something is laughing near the "].
playerwatchlist()->
		["You feel a strange presence in the room...", "It feels as though something is watching you...", "A dark shadow glances past you...", "You hear a faint whispering noise...", "Something tugs on your foot..."].