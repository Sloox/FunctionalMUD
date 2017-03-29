%% @author M Wright <201176962@student.uj.ac.za>
%% @copyright Wright, MJ 2014-2015
%% @version 1.2
%% @title Room module
%% @doc All room based operations exist here.
%% Rooms are initialized, parsed and ordered here.
%% @end

-module(room).

-compile(export_all).

-include("recs.hrl").

%%basic start
st()->initrooms("room.conf").

%%load and setup rooms, parse items
initrooms(FilePath)->%%construct rooms
	Result = file:consult(FilePath),
	case Result of
		{error, Error} -> io:fwrite("Failed to load rooms! ~p~n",[Error]);
		{ok, Rooms} -> %%parse items into atoms here!
			RoomList = [#room{title=Title,description=Descrpt,id=ID,doorEast=DE,doorWest=DW,doorNorth=DN,doorSouth=DS, item = parseRoomItems(ITEMS)} || {room, Title, Descrpt, ID, DE, DW, DN, DS, ITEMS}<-Rooms],
			RoomList
	end.
	
%%Get various information on rooms for players
getRoomDesc(Player, Rooms)->%%gets description of current room
	[Descrpt || {room, _Title, Descrpt, ID, _DE, _DW, _DN, _DS, _ITEMS}<-Rooms,ID==Player#player.roomId].
	
getRoomInfo(Player, Rooms)->
	["\r\n"++aCol:addcol({green,"Location:"})++aCol:addcol({cyan,getRoomTitle(Player, Rooms)})++"\r\n"++getRoomDesc(Player, Rooms)++getDoorDescript(Player, Rooms)].
	
getRoomTitle(Player, Rooms)->%%title of room
	[Title || {room, Title, _Descrpt, ID, _DE, _DW, _DN, _DS, _ITEMS}<-Rooms,ID==Player#player.roomId].

getRoomTfromID(RID, Rooms)->[Title || {room, Title, _Descrpt, ID, _DE, _DW, _DN, _DS, _ITEMS}<-Rooms,ID==RID].

getRoomBasicInfo(Player, Rooms)->
	["\r\n"++aCol:addcol({cyan,getRoomTitle(Player, Rooms)})++"\r\n"++getRoomDesc(Player, Rooms)++"\r\n"++getDoorDescript(Player, Rooms)++"\r\n"].

	
getDescript(Player, Rooms)->
	["\r\n"++aCol:addcol({green,"Location:"})++aCol:addcol({cyan,getRoomTitle(Player, Rooms)})++"\r\n"++getDoorDescript(Player, Rooms)].

getDoorDescript(Player, Rooms)->%%Construct all moveable locations from current room
	[{DE,DW,DN,DS}] = [{DE,DW,DN,DS} || {room, _Title, _Descrpt, ID, DE, DW, DN, DS, _ITEMS}<-Rooms, ID==Player#player.roomId],
	["\r\n"++aCol:addcol({yellow,"Taking a look around you see that you can move: \r\n"})]++getDD("East", DE, Rooms)++getDD("West", DW, Rooms)++getDD("North", DN, Rooms)++getDD("South", DS, Rooms).

	getDD(Dir, ID, Rooms)->%%helper
	case ID of
		-1->[];
		_->[aCol:addcol({red,Dir})++" to the "++aCol:addcol({green,getRoomTfromID(ID, Rooms)})++"\r\n"]
	end.

getValidDoors(Player, Rooms)->
	[{DE,DW,DN,DS}] = [{DE,DW,DN,DS} || {room, _Title, _Descrpt, ID, DE, DW, DN, DS, _ITEMS}<-Rooms, ID==Player#player.roomId],
	[getRoomTfromID(X, Rooms) || X <- [DE,DW,DN,DS], X > -1].

	

lookDir(Dir, DirID, Rooms)->
	case DirID of
		-1->["\r\nYou see nothing to the " ++ aCol:addcol({red,Dir})++"\r\n"];
		_->["\r\nLooking to the " ++ aCol:addcol({red,Dir}) ++ " you see the " ++aCol:addcol({green,getRoomTfromID(DirID, Rooms)})++"\r\n"]
	end.

	
%%Auxillary functions
getItemSearchSuccess(Player, Rooms)->
	ITEMS = [ITEMS || {room, _Title, _Descrpt, ID, _DE, _DW, _DN, _DS, ITEMS}<-Rooms,ID==Player#player.roomId],
	case ITEMS of
			[empty]->-1;
			_->random:uniform(3)		
		end.	

	
parseRoomItems(ItemCodes)->
	case ItemCodes of
		[]->empty;
		[1]->shitsword;
		[2]->sword;
		[3]->goodsword;
		[4]->axe;
		[5]->pike;
		[6]->dagger;
		[7]->knucklesandwitch;
		_->empty
	end.
	
	
getRoom(RID, Rooms)->
	 {value, Room} = lists:keysearch(RID, #room.id, Rooms),
	 Room.
	
	
	