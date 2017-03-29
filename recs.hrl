%% @author M Wright <201176962@student.uj.ac.za>
%% @copyright Wright, MJ 2014-2015
%% @version 1.0
%% @title MUD records
%% @doc Primary used records for erMUD
%% @end

-record(room, { title,%%name
				description,%%info text
				id,%%used for linking
				doorEast,%%doors
				doorWest,
				doorNorth,
				doorSouth,
				item=[]}).
			
%%-record(player, {name=none, socket, mode}).%%player rec
-record(player, {name=none, socket, mode, roomId = 0, health = 25, weapon=[]}).%%player rec

-record(cotd,{title,text}).
