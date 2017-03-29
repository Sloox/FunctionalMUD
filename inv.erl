%% @author M Wright <201176962@student.uj.ac.za>
%% @copyright Wright, MJ 2014-2015
%% @version 1.0
%% @title inventory manager
%% @doc A simple inventory Manager that handles MUD inventory and attack based events
%% Helps get important information to players that is formatted.
%% @end
-module(inv).

-compile(export_all).

-include("recs.hrl").

%%Get player information of inventory and atacks
getPlayerInvDSimple(Player)->
	case Player#player.weapon of
		[]->[aCol:addcol({yellow,"\r\nYou have no weapon in your inventory!\r\n"})];
		Other->[aCol:addcol({yellow,"\r\nYou have the "})++getItemS(Other)++aCol:addcol({yellow," equipped\r\n"})]
	end.

getItemS(Item)->
	case Item of
		shitsword->aCol:addcol({blue,"Old Rusty Sword"});
		sword->aCol:addcol({blue,"Basic Sword"});
		goodsword->aCol:addcol({blue,"Katana"});
		axe->aCol:addcol({blue,"Axe of legends"});
		pike->aCol:addcol({blue,"Danger Pike"});
		dagger->aCol:addcol({blue,"Blink Dagger"});
		knucklesandwitch->aCol:addcol({blue,"Good old fashioned fists"});
		empty->aCol:addcol({blue,"Nothing"});
		[]->aCol:addcol({blue,"Your fists"});
		_->aCol:addcol({blue,"Hacker!"})
	end.

getItemD(Item)->
	case Item of
		shitsword->aCol:addcol({blue,"Old Rusty Sword, +1"});
		sword->aCol:addcol({blue,"Basic Sword, +2"});
		goodsword->aCol:addcol({blue,"Katana, +3"});
		axe->aCol:addcol({blue,"Axe of legends, +5"});
		pike->aCol:addcol({blue,"Danger Pike, +2"});
		dagger->aCol:addcol({blue,"Blink Dagger, +3"});
		knucklesandwitch->aCol:addcol({blue,"Good old fashioned fists, +1"});
		empty->aCol:addcol({blue,"Nothing, +0"});
		[]->aCol:addcol({blue,"Your fists, +1"});
		_->aCol:addcol({blue,"Hacker!, -9000"})
	end.

%%Attacking functions
%1 miss, 2 hit, 3 hit, 4 fumble, 5 crit
attemptattack()->
	case random:uniform(5) of
		1->{miss};
		2->{hit};
		3->{hit};
		4->{fumble};
		5-> case random:uniform(3) of
				1->{smallc};
				2->{smallc};
				3->{bigc}
			end
	end.
	
getWeapDamage(Weapon)->
	case Weapon of
		shitsword->1;
		sword->2;
		goodsword->3;
		axe->5;
		pike->2;
		dagger->3;
		knucklesandwitch->1;
		_->0
	end.

getAttackD(Player, Attack)->
	case Attack of
		{hit}->getWeapDamage(Player#player.weapon)+random:uniform(3);
		{fumble}->random:uniform(3)-1;%%fumble the attack: 0-2 
		{smallc}->getWeapDamage(Player#player.weapon)+random:uniform(2)+3;
		{bigc}->getWeapDamage(Player#player.weapon)+random:uniform(4)+3;
		{miss}->0
	end.
	
calcAttack(Player, APlayer)->
	Amod = attemptattack(),
	AD = getAttackD(Player, Amod),
	NPlayer = APlayer#player{health = APlayer#player.health-AD},
	case (NPlayer#player.health > 0) of
		true->{alive, NPlayer, Amod, AD};
		false->{dead, NPlayer, Amod, AD}
	end.
	
%%inventory info
	
getPlayerStatsInfo(Player)->
	["\r\n"++aCol:addcol({magenta,"Player Info"})++"\r\n"++aCol:addcol({green,"Health:"})++aCol:addcol({red,integer_to_list(Player#player.health)})++"\r\n"++aCol:addcol({green,"Item:"})++getItemS(Player#player.weapon)++"\r\n"].
	
getINV(Player)->
	["\r\n"++aCol:addcol({green,"--Player Information--"})++"\r\n"++aCol:addcol({yellow,"Name:"})++aCol:addcol({magenta,Player#player.name})++"\r\n"++aCol:addcol({yellow,"Current Health:"})++aCol:addcol({red,integer_to_list(Player#player.health)})++"\r\n"++aCol:addcol({yellow,"Current Item:"})++getItemD(Player#player.weapon)++"\r\n"].	
	
	
	
	
	
	
		