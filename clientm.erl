%% @author M Wright <201176962@student.uj.ac.za>
%% @copyright Wright, MJ 2014-2015
%% @version 2.2
%% @title Client_Manager
%% @doc Client manager handles all the client based requests, messages and events.
%% Closely coupled with the server manager
%% @end

-module(clientm).
-export([manage_clients/2]).

-include("recs.hrl").
%%modes are as follows:
%% connect-> need to get name  \r\n for 

manage_clients(Players, Rooms)->
	receive %%recieve message from handle_client in mwerver.erl 
		{connect, Socket} ->%conider this as connection to server
			 Player = #player{socket=Socket, mode=connect, roomId = 1},%set up a new player
			 io:fwrite("\r\nA new player has connected: ~w~n", [Player]),
			 send_prompt(Player),%send prompt as mode:connect
			 NewPlayers =  [Player | Players],%add player to list
			 manage_clients(NewPlayers, Rooms);
		{data, Socket, Data} ->
            Player = find_player(Socket, Players),%get player who sent the data
			NewPlayers = parse_data(Player, Players, Data, Rooms),
			manage_clients(NewPlayers, Rooms);
		{move, Player, DirID}->%%moving
			NPlayer = Player#player{roomId = DirID},
			NPlayers = [NPlayer | delete_player(Player, Players)],
			updaterooms(Player, NPlayers, NPlayer, Rooms),
			manage_clients(NPlayers, Rooms);
		{pickupw, Player, ORoom}->%%player is picking up the weapon
			NRoom = ORoom#room{item=empty},%%room is now empty
			NPlayer=Player#player{weapon=ORoom#room.item},%%give player the item
			NPlayers=[NPlayer | delete_player(Player, Players)],
			NRooms=[NRoom | delete_room(ORoom, Rooms)],
			send_update(NPlayer, NRooms, itemfound),
			manage_clients(NPlayers, NRooms);
		{attacka, Player, NAPlayer, Attacktype, Damage}->
			NPlayers = [NAPlayer | delete_player(NAPlayer, Players)],%%change player state
			aupdate_on_attack(NPlayers, Player, NAPlayer, Attacktype, Damage),
			manage_clients(NPlayers, Rooms);%%back to normal
		{attackd, Player, NAPlayer, Attacktype, Damage}->
			ResetPlayer = NAPlayer#player{roomId = 1, health = 25, weapon=[]},%%reset player back to waiting room
			NewPlayers = [ResetPlayer | delete_player(NAPlayer, Players)],%%change data for players
			dupdate_on_attack(NewPlayers, Player, NAPlayer, Attacktype, Damage),
			manage_clients(NewPlayers, Rooms);%%back to normal
		{disconnect, Socket} ->
            Player = find_player(Socket, Players),%get player that has disconnected
            io:fwrite("Player has disconnected: ~w~n", [Player]),
            NewPlayers = lists:delete(Player, Players),%delete from list
            sendmsgtopinroom(aCol:addcol({red,[Player#player.name]})++" "++aCol:addcol({white,["has left the dungeon.\r\n"]}), NewPlayers, "",Player#player.roomId), 
			manage_clients(NewPlayers, Rooms);
		{error, Reason}->
			io:fwrite("Unexpected error has occured: ~s~n", [Reason]),
			manage_clients(Players, Rooms);
		{updateme}->
			event_handler ! {update,[{Players, Rooms}]},
			manage_clients(Players, Rooms);
		{watchplayer, Msg, WPlayer}->
			case WPlayer#player.mode of
				active->send_update(WPlayer, Msg, watchedplayer);
				_->ok
			end,
			manage_clients(Players, Rooms);
		{watchroom, Msg, Id}->
			sendmsgtopinroom(Msg, Players, "",Id),
			manage_clients(Players, Rooms)
		 end.
		 
		 
%%Update players of the attack on each other, noone dies here!			
aupdate_on_attack(NPlayers, Player, NAPlayer, Attacktype, Damage)->
	sendmsgtopinroom(aCol:addcol({magenta,[Player#player.name]})++aCol:addcol({yellow," attacks "})++aCol:addcol({magenta,[NAPlayer#player.name]})++"!!\r\n",NPlayers,"",Player#player.roomId),
	%%send update to attacker
	case Attacktype of
		{hit}->
			gen_tcp:send(Player#player.socket,aCol:addcol({yellow,"\r\nYour attack hits "})++aCol:addcol({magenta,NAPlayer#player.name})++".\r\n"++aCol:addcol({yellow,"You inflict "})++aCol:addcol({red,integer_to_list(Damage)})++aCol:addcol({yellow," damage!\r\n"})++">"),
			gen_tcp:send(NAPlayer#player.socket,"\r\n"++aCol:addcol({magenta,Player#player.name})++" attack hits!\r\n"++aCol:addcol({yellow,"It inflicts "})++aCol:addcol({red,integer_to_list(Damage)})++aCol:addcol({yellow," damage!\r\n"}));
		{fumble}->
			gen_tcp:send(Player#player.socket,aCol:addcol({yellow,"\r\nYou fumble the attack against "})++aCol:addcol({magenta,NAPlayer#player.name})++"\r\n"++aCol:addcol({yellow,"You still inflict "})++aCol:addcol({red,integer_to_list(Damage)})++aCol:addcol({yellow," damage!\r\n"})++">"),
			gen_tcp:send(NAPlayer#player.socket,"\r\n"++aCol:addcol({magenta,Player#player.name})++" fumbles the attack!\r\n"++aCol:addcol({yellow,"They still hit you and inflict "})++aCol:addcol({red,integer_to_list(Damage)})++aCol:addcol({yellow," damage!\r\n"}));
		{smallc}->
			gen_tcp:send(Player#player.socket,aCol:addcol({yellow,"\r\nYou land a critical hit against "})++aCol:addcol({magenta,NAPlayer#player.name})++"\r\n"++aCol:addcol({yellow,"You inflict "})++aCol:addcol({red,integer_to_list(Damage)})++aCol:addcol({yellow," damage!\r\n"})++">"),
			gen_tcp:send(NAPlayer#player.socket,"\r\n"++aCol:addcol({magenta,Player#player.name})++" attacks you and lands a critical hit!\r\n"++aCol:addcol({yellow,"It causes "})++aCol:addcol({red,integer_to_list(Damage)})++aCol:addcol({yellow," damage!\r\n"}));
		{bigc}->
			gen_tcp:send(Player#player.socket,aCol:addcol({yellow,"\r\nYou land a DEVASTATING BLOW on "})++aCol:addcol({magenta,NAPlayer#player.name})++"\r\n"++aCol:addcol({yellow,"You inflict a massive "})++aCol:addcol({red,integer_to_list(Damage)})++aCol:addcol({yellow," damage!\r\n"})++">"),
			gen_tcp:send(NAPlayer#player.socket,"\r\n"++aCol:addcol({magenta,Player#player.name})++" lands a DEVASTAING BLOW!.\r\n"++aCol:addcol({yellow,"They inflict "})++aCol:addcol({red,integer_to_list(Damage)})++aCol:addcol({yellow," damage on you!\r\n"}));
		{miss}->
			gen_tcp:send(Player#player.socket,aCol:addcol({yellow,"\r\nYou miss your attack! \r\nYou inflict 0 damage!\r\n"})++">"),
			gen_tcp:send(NAPlayer#player.socket,"\r\n"++aCol:addcol({magenta,Player#player.name})++" misses their attack.\r\n"++aCol:addcol({yellow,"They inflict 0 damage!\r\n"})++">");
		_->error
	end,
	gen_tcp:send(NAPlayer#player.socket,"\r\n"++aCol:addcol({green,"Health Left:"})++aCol:addcol({red,integer_to_list(NAPlayer#player.health)})++"\r\n>").%%update health

	
%%Update players of the attack on each other, someone dies here!	
dupdate_on_attack(NPlayers, Player, NAPlayer, Attacktype, Damage)->
	sendmsgtopinroom(aCol:addcol({magenta,[Player#player.name]})++aCol:addcol({red," attacks "})++aCol:addcol({magenta,[NAPlayer#player.name]})++"!!\r\n",NPlayers,"",Player#player.roomId),
	%%send update to attacker
	case Attacktype of
		{hit}->
			gen_tcp:send(Player#player.socket,aCol:addcol({yellow,"\r\nYour attack hits "})++aCol:addcol({magenta,NAPlayer#player.name})++".\r\n"++aCol:addcol({yellow,"You inflict "})++aCol:addcol({red,integer_to_list(Damage)})++aCol:addcol({yellow," damage!\r\n"})++">"),
			gen_tcp:send(NAPlayer#player.socket,"\r\n"++aCol:addcol({magenta,Player#player.name})++" attack hits!\r\n"++aCol:addcol({yellow,"It inflicts "})++aCol:addcol({red,integer_to_list(Damage)})++aCol:addcol({yellow," damage!\r\n"})++">");
		{fumble}->
			gen_tcp:send(Player#player.socket,aCol:addcol({yellow,"\r\nYou fumble the attack against "})++aCol:addcol({magenta,NAPlayer#player.name})++"\r\n"++aCol:addcol({yellow,"You still inflict "})++aCol:addcol({red,integer_to_list(Damage)})++aCol:addcol({yellow," damage!\r\n"})++">"),
			gen_tcp:send(NAPlayer#player.socket,"\r\n"++aCol:addcol({magenta,Player#player.name})++" fumbles the attack!.\r\n"++aCol:addcol({yellow,"They still hit you and inflict "})++aCol:addcol({red,integer_to_list(Damage)})++aCol:addcol({yellow," damage!\r\n"})++">");
		{smallc}->
			gen_tcp:send(Player#player.socket,aCol:addcol({yellow,"\r\nYou land a critical hit against "})++aCol:addcol({magenta,NAPlayer#player.name})++"\r\n"++aCol:addcol({yellow,"You inflict "})++aCol:addcol({red,integer_to_list(Damage)})++aCol:addcol({yellow," damage!\r\n"})++">"),
			gen_tcp:send(NAPlayer#player.socket,"\r\n"++aCol:addcol({magenta,Player#player.name})++" attacks you and lands a critical hit!\r\n"++aCol:addcol({yellow,"It causes "})++aCol:addcol({red,integer_to_list(Damage)})++aCol:addcol({yellow," damage!\r\n"})++">");
		{bigc}->
			gen_tcp:send(Player#player.socket,aCol:addcol({yellow,"\r\nYou land a DEVASTATING BLOW on "})++aCol:addcol({magenta,NAPlayer#player.name})++"\r\n"++aCol:addcol({yellow,"You inflict a massive "})++aCol:addcol({red,integer_to_list(Damage)})++aCol:addcol({yellow," damage!\r\n"})++">"),
			gen_tcp:send(NAPlayer#player.socket,"\r\n"++aCol:addcol({magenta,Player#player.name})++" lands a DEVASTAING BLOW!.\r\n"++aCol:addcol({yellow,"It inflicts "})++aCol:addcol({red,integer_to_list(Damage)})++aCol:addcol({yellow," damage on you!\r\n"})++">");
		_->error
	end,
	sendmsgtopinroom(aCol:addcol({magenta,[NAPlayer#player.name]})++" has "++aCol:addcol({red, "died!\r\n"}),NPlayers,"",Player#player.roomId),%%notify of death all players
	sendmsgtopinroom(aCol:addcol({magenta,[NAPlayer#player.name]})++aCol:addcol({yellow," has left the room\r\n"}),NPlayers,"",Player#player.roomId),
	gen_tcp:send(NAPlayer#player.socket,aCol:addcol({red,"\r\nYou die as a result of the attack!\r\n"})++aCol:addcol({yellow,"You have been sent back to the waiting room.\r\nYou loose everything in the process!\r\n"})++">"),%%notify player of their death
	gen_tcp:send(Player#player.socket,aCol:addcol({red,"\r\nYour attack kills your target!\r\n"})++aCol:addcol({yellow,"They have been sent back to the waiting room!\r\n"})++">"),%%notify player of their kill
	sendmsgtopinroom(aCol:addcol({magenta,[NAPlayer#player.name]})++aCol:addcol({yellow," has joined the room.\r\n"}),NPlayers,"",1).%%notify of death all players waiting rooms
	
%%Update rooms of moving players	
updaterooms(Player, NPlayers, NPlayer, Rooms)->
	%%Update old room
	try sendmsgtopinroom(aCol:addcol({magenta,[Player#player.name]})++aCol:addcol({yellow," has left the room\r\n"}),NPlayers,"",Player#player.roomId) of
		_->ok
	catch
		_->error
	end,
	%%update new room
	try sendmsgtopinroom(aCol:addcol({blue,[NPlayer#player.name]})++" "++aCol:addcol({yellow,["has joined the room.\r\n"]}), NPlayers, "",NPlayer#player.roomId) of
		_->ok
	catch
		_->error
	end,
	send_update(NPlayer, Rooms, basicrinfo).


%%first parse of data sent by client	
parse_data(Player, Players, Data, Rooms) ->
    case Player#player.mode of
        connect ->%%add name to player list and delete old record
            UPlayer = Player#player{name=util:strp(Data), mode=active},%%add rooms
            Nplayers = [UPlayer | delete_player(Player, Players)],
            sendmsgtopinroom(aCol:addcol({blue,[UPlayer#player.name]})++" "++aCol:addcol({yellow,["has joined the room.\r\n"]}), Nplayers, "",Player#player.roomId),
			send_update(Player, Rooms, basicrinfo),
            Nplayers;
            
        active ->%%now accepting commands so gotta parse them
			case util:usercmdatom(Data) of
				{error, empty} -> ok;%%erronous input
				{ok, Cmd, Rest}->parse_largecmd(Player, Cmd, Rest, Players, Rooms);
				{ok, Cmd}->parse_singlecmd(Player,Cmd, Players, Rooms);
				{error, badinput}->send_update(Player,badinput);%%erronous input
				_Other->send_update(Player,erronous)%%erronous input
			end,
			 Players
    end.
    
%%Parse large multi-tuple commands from client
parse_largecmd(Player,Cmd, Msg, Players, Rooms)->
	LCmd =  string:to_lower(Cmd),
	case LCmd of
		"say"->Prefix = "\r\n"++aCol:addcol({blue,[Player#player.name ++ " says:"]}), sendmsgtopinroom(Prefix, Players, util:addinspaces(Msg),Player#player.roomId);
		"look"->lookaround(Player, Msg, Rooms);
		"msg"->whisperplayer(Player, Msg, Players);
		"move"->moveplayer(Player, Msg, Rooms);
		"go"->moveplayer(Player, Msg, Rooms);
		"attack"->playerattack(Player, Msg, Players);
		_->send_update(Player,erronous)%%unknown input
	end.
	
%%basic single commands parsing from client
parse_singlecmd(Player,Cmd, Players, Rooms)->
		LCmd =  string:to_lower(Cmd),
		case LCmd of
			"quit"->send_update(Player, quitcode);
			"help"->send_update(Player, help);
			"listp"->listplayers(Player,Players);
			"sleep"->sendmsgtopinroom("\r\n"++aCol:addcol({magenta,[Player#player.name ++ " goes to sleep, zzzz!\r\n"]}),Players,"",Player#player.roomId);
			"dance"->sendmsgtopinroom("\r\n"++aCol:addcol({magenta,[Player#player.name ++ " attempts to shake his/her booty!\r\n"]}),Players,"",Player#player.roomId);
			"smile"->sendmsgtopinroom("\r\n"++aCol:addcol({magenta,[Player#player.name ++ " smiles at everyone :)\r\n"]}),Players,"",Player#player.roomId);
			"wink"->sendmsgtopinroom("\r\n"++aCol:addcol({magenta,[Player#player.name ++ " winks at everyone ;)\r\n"]}),Players,"",Player#player.roomId);
			"tired"->sendmsgtopinroom("\r\n"++aCol:addcol({magenta,[Player#player.name ++ " is tired, yawn!:0\r\n"]}),Players,"",Player#player.roomId);
			"lol"->sendmsgtopinroom("\r\n"++aCol:addcol({magenta,[Player#player.name ++ " lols in everyones general direction\r\n"]}),Players,"",Player#player.roomId);
			"laugh"->sendmsgtopinroom("\r\n"++aCol:addcol({magenta,[Player#player.name ++ " laughs in everyones general direction\r\n"]}),Players,"",Player#player.roomId);
			"cry"->sendmsgtopinroom("\r\n"++aCol:addcol({magenta,[Player#player.name ++ " cries, what a baby!!\r\n"]}),Players,"",Player#player.roomId);
			"info"->send_update(Player, Rooms, info);
			"whereami"->send_update(Player, Rooms, wai);
			"search"->searchroom(Player, Rooms, Players);
			"inv"->send_update(Player, inv);
			"inventory"->send_update(Player, inv);
			"self"->send_update(Player, inv);
			"attack"->send_update(Player, attackf);
			"go"->send_update(Player, gof);
			"move"->send_update(Player, movef);
			"say"->send_update(Player, sayf);
			"look"->send_update(Player, lookf);
			_->send_update(Player,erronous)%%unknown input
		end.
			
			
%%Attacking
%%player attempts to attack other players
%%random chances of damage and hit
playerattack(Player, Msg, Players)->%%attack player by name
		%%check if name is valid
		case Msg of
			[]->send_update(Player, Msg, attackf);%%failed attack
			[Mplayer]->case find_playerbyname(Mplayer, Players) of
						[]-> send_update(Player, Msg, attackpf);%%failed attack2
						APlayer when (APlayer/=Player) and (APlayer#player.roomId==Player#player.roomId) ->attacksequence(Player, APlayer);%%player found, attack commence
						APlayer when (APlayer==Player)->send_update(Player, attacks);
						_->send_update(Player, attacksnf)
					end
		end.
				
%%General attack sequence		
attacksequence(Player, APlayer)->
	case inv:calcAttack(Player, APlayer) of
		{alive, NAPlayer, Attacktype, AD}->self() ! {attacka, Player, NAPlayer, Attacktype, AD};
		{dead, NAPlayer, Attacktype, AD}->self() ! {attackd, Player, NAPlayer, Attacktype, AD};
		_->error
	end.
		
	
%%Room search may result in updates
%%player needs to search the room first to find item
%%change based finding purely random
searchroom(Player, Rooms, Players)->
			case room:getItemSearchSuccess(Player, Rooms) of
				-1->send_update(Player, searchn);%%room is empty
				1->send_update(Player, searchun);%%something in room but failed to find it
				2->send_update(Player, searchum),%%something in room but failed to find it loose health?
				   sendmsgtopinroom("\r\n"++aCol:addcol({magenta,[Player#player.name ++ " slips and falls while searching the room.\r\nHow embarrassing!\r\n"]}),Players,"",Player#player.roomId);
				3->%%found the item, update server
					ORoom = room:getRoom(Player#player.roomId, Rooms),%%get old room
					self() ! {pickupw, Player, ORoom}
			end.
			

%%Send updates to the player based upon what they have done

send_update(Player, attackwr)->gen_tcp:send(Player#player.socket,aCol:addcol({yellow,"\r\nAttacking in the waiting room is "})++aCol:addcol({yellow," Prohibited!\r\n"})++">");
send_update(Player, attacksnf)->gen_tcp:send(Player#player.socket,aCol:addcol({yellow,"\r\nCannot attack an unknown player!\r\n"})++">");
send_update(Player, attacks)->gen_tcp:send(Player#player.socket,aCol:addcol({yellow,"\r\nAttacking yourself is not a good idea!\r\n"})++">");
send_update(Player, lookf)->gen_tcp:send(Player#player.socket,aCol:addcol({yellow,"\r\nYou look at nothing.\r\nIt astounds you!\r\nIts as though you are looking at a mirror...\r\n"})++">");
send_update(Player, sayf)->gen_tcp:send(Player#player.socket,aCol:addcol({yellow,"\r\nYou attempt to say nothing!\r\n"})++">");
send_update(Player, movef)->gen_tcp:send(Player#player.socket,aCol:addcol({yellow,"\r\nMove where?\r\n"})++">");
send_update(Player, gof)->gen_tcp:send(Player#player.socket,aCol:addcol({yellow,"\r\nGo where?\r\n"})++">");
send_update(Player, attackf)->gen_tcp:send(Player#player.socket,aCol:addcol({yellow,"\r\nAttacking nothing is a useless pursuit!\r\nTry attacking a player instead...\r\n"})++">");
send_update(Player, inv)->gen_tcp:send(Player#player.socket,inv:getINV(Player)++"\r\n>");
send_update(Player, searchum)->gen_tcp:send(Player#player.socket,aCol:addcol({yellow,"\r\nWhile searching you slip and fall over embarrassingly\r\nYou pick your self up and decide its best to move on\r\nYou hope noone saw that..."}));
send_update(Player, searchun)->gen_tcp:send(Player#player.socket,aCol:addcol({yellow,"\r\nYou search the room and notice something shiny...\r\nIt turns out to be just some broken glass\r\nWhat a waste of time...\r\n"})++">");
send_update(Player, searchn)->gen_tcp:send(Player#player.socket,aCol:addcol({yellow,"\r\nAfter rummaging through rubbish you find nothing.\r\nIt appears this room has been picked clean...\r\n"})++">");
send_update(Player, help)->gen_tcp:send(Player#player.socket,aCol:addcol({green,"\r\n<---Help--->\r\n"})++aCol:addcol({magenta,"Commands available:\r\n"})++" quit, listp, info, wherami\r\n say <msg>, msg <player> <msg> \r\n move <location>, look <location>\r\n attack <player>, search\r\n inv, self\r\n"++">");				 
send_update(Player, quitcode)->gen_tcp:send(Player#player.socket,aCol:addcol({red,"\r\nGoodBye, Hope to see you again!\r\n"})),
			gen_tcp:close(Player#player.socket);%%close socket
send_update(Player, erronous)->gen_tcp:send(Player#player.socket, aCol:addcol({white,"\r\nUnknown command!\r\n"})++">");
send_update(Player, badinput)->gen_tcp:send(Player#player.socket, aCol:addcol({white,"\r\nBad input!\r\n"})++">");
send_update(_Player,[])->ok.

send_update(Player1,Player2 , Msg, whisper)->
	ToSend = "\r\n"++aCol:addcol({red,[Player1#player.name ]})++ " whispers:",
	gen_tcp:send(Player1#player.socket,aCol:addcol({red,["\r\n"++aCol:addcol({yellow,"Message to "})++Player2#player.name++aCol:addcol({yellow," sent!\r\n"})]})++">"),
	gen_tcp:send(Player2#player.socket, ToSend++aCol:addcol({cyan,Msg})++">").%%send to player 2
	
	
send_update(Player, _Rooms, itemfound)->gen_tcp:send(Player#player.socket,aCol:addcol({yellow,"\r\nWhile searching the room you notice something shiny...\r\n"})++aCol:addcol({green,"It seems you found something!\r\n"})++inv:getItemS(Player#player.weapon)++"\r\n"++">");
send_update(Player, Rooms, basicrinfo)->gen_tcp:send(Player#player.socket,room:getRoomBasicInfo(Player, Rooms)++">");	
send_update(Player, Rooms, info)->gen_tcp:send(Player#player.socket,room:getRoomInfo(Player,Rooms)++inv:getPlayerStatsInfo(Player)++"\r\n>");
send_update(Player, Rooms, wai)->gen_tcp:send(Player#player.socket,"\r\n"++aCol:addcol({yellow,"You are currently in the "})++aCol:addcol({cyan,room:getRoomTitle(Player,Rooms)})++"\r\n>");
send_update(Player, Dir, failmove)->gen_tcp:send(Player#player.socket,aCol:addcol({magenta,"\r\nYou attempt to move "++Dir++" and slam into a wall!\r\n"})++aCol:addcol({red,"Ouch!"})++"\r\n>");
send_update(Player, Msg, attackpf)->gen_tcp:send(Player#player.socket,aCol:addcol({yellow,"\r\nAttacking "})++aCol:addcol({magenta,Msg})++"\r\n"++aCol:addcol({yellow,"Attack failed...\r\nNo such thing found...\r\n"})++">");
send_update(Player, Msg, watchedplayer)->gen_tcp:send(Player#player.socket,Msg++">").


%%Compund commands finilization before reply to client
lookaround(Player, Msg, Rooms)->
	LMsg = string:to_lower(Msg),
	[{DE,DW,DN,DS}] = [{DE,DW,DN,DS} || {room, _Title, _Descrpt, ID, DE, DW, DN, DS, _ITEMS}<-Rooms, ID==Player#player.roomId],
	case LMsg of%%take note of the brackets!!! may break code later
		["north"]->gen_tcp:send(Player#player.socket,room:lookDir("North",DN,Rooms)++">");
		["south"]->gen_tcp:send(Player#player.socket,room:lookDir("South",DS,Rooms)++">");
		["east"]->gen_tcp:send(Player#player.socket,room:lookDir("East",DE,Rooms)++">");
		["west"]->gen_tcp:send(Player#player.socket,room:lookDir("West",DW,Rooms)++">");
		["around"]->gen_tcp:send(Player#player.socket,room:getDescript(Player,Rooms)++">");
		_->gen_tcp:send(Player#player.socket,aCol:addcol({green,"\r\nWhere am i supposed to look? \r\n"})++">")
	end.
	
whisperplayer(Player, Msg, Players)->
	case Msg of
		[_Mplayer|[]]->gen_tcp:send(Player#player.socket, aCol:addcol({black,"\r\nNo valid message\r\nUsage: Msg <Player> <Message>\r\n"})++">");%%no message to send
		[Mplayer|Mes]->
			case find_playerbyname(Mplayer, Players) of
				[]->gen_tcp:send(Player#player.socket, aCol:addcol({black,"\r\nNo unique players found with that name\r\n"})++">");%%send to player
				Prec->send_update(Player, Prec, util:addinspaces(Mes),whisper)
			end;
		_Error->gen_tcp:send(Player#player.socket, aCol:addcol({black,"\r\nError invalid parameters\r\nUsage: Msg <Player> <Message>\r\n"})++">")%%default case
	end.
	
listplayers(Player, Players)->
		Result = util:addinchar([X#player.name||X<-Players,(X#player.mode==active) and (X#player.roomId==Player#player.roomId)],","),%%getting names, dont hate me ^^
		case Result of
			[]->gen_tcp:send(Player#player.socket, aCol:addcol({yellow,"\r\nNo Players in this room!\r\n"})++">");
			_->gen_tcp:send(Player#player.socket, aCol:addcol({yellow,"\r\nPlayers currently in room:\r\n"})++Result++">")
		end.
		
		
%%attempt to move player		
attemptmove(Dir, Player, DirID)->
	case DirID of
		-1->send_update(Player,Dir, failmove);
		_-> self() ! {move, Player, DirID}%%move player to another room
	end.
		
%%Movement
moveplayer(Player, Msg, Rooms)->
	LMsg = string:to_lower(Msg),
	[{DE,DW,DN,DS}] = [{DE,DW,DN,DS} || {room, _Title, _Descrpt, ID, DE, DW, DN, DS, _ITEMS}<-Rooms, ID==Player#player.roomId],
	case LMsg of
		["north"]->attemptmove("North", Player, DN);
		["south"]->attemptmove("South", Player, DS);
		["east"]->attemptmove("East", Player, DE);
		["west"]->attemptmove("West", Player, DW);
		_->gen_tcp:send(Player#player.socket,aCol:addcol({red,"\r\nNot sure how to move "})++aCol:addcol({green,LMsg})++"!\r\n>")
	end.
		
	
%%Auxillary commands		
find_playerbyname(Name, List)-> 
	Rez = [X||X<-List, X#player.name==Name],
	case Rez of
		[]->[];
		[Play|[]]->Play;
		[Play1|_Play2]->Play1;
		_->[]
	end.

	

find_player(Socket, Players) ->%find player in record struct
    {value, Player} = lists:keysearch(Socket, #player.socket, Players),
    Player.

	
%% Player Deletion
%% deletes the player from the list based on the socket, sockets cant be duped, names can
delete_player(Player, Players) ->
    lists:keydelete(Player#player.socket, #player.socket, Players).

%% Room deletion
%% ID used. 
delete_room(Room, Rooms) ->
    lists:keydelete(Room#room.id, #room.id, Rooms).
	
	
%%Intro Prompt
send_prompt(Player) ->
    case Player#player.mode of
        connect ->
			gen_tcp:send(Player#player.socket, util:connectintro()),%intro to MUD
			%%gen_tcp:send(Player#player.socket, aCol:actioncol("Lets get started, Please begin by providing some details")),
			gen_tcp:send(Player#player.socket, aCol:addcol({yellow,"Lets get started, Please begin by providing some details\r\n"})),
            gen_tcp:send(Player#player.socket, aCol:addcol({green,"Please Enter Your Character Name: "}));
        active ->
            ok
    end.
    
  
%% Sends the given data to all players in active mode.
sendmsgtopinroom(Name, Players, Data,RoomID) ->
    ActivePlayers = [X||X<-Players, (X#player.mode==active) and (X#player.roomId==RoomID)],
    TheMessage = aCol:oldline(Name ++ Data++">"),%%formatting
    lists:foreach(fun(P) -> gen_tcp:send(P#player.socket,TheMessage) end,
                  ActivePlayers),
    ok.
	
%%old defunct version	
sendmsgtoallold(Name, Players, Data) ->
    ActivePlayers = lists:filter(fun(P) -> P#player.mode == active end,Players),
    TheMessage = aCol:oldline(Name ++ Data++">"),%%formatting
    lists:foreach(fun(P) -> gen_tcp:send(P#player.socket,TheMessage) end,
                  ActivePlayers),
    ok.


