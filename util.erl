%% @author M Wright <201176962@student.uj.ac.za>
%% @copyright Wright, MJ 2014-2015
%% @version 1.3
%% @title Utillity Module
%% @doc A Utility module with important functions
%% @end

-module(util).


-export([strp/1,connectintro/0,usercmdatom/1,addinspaces/1,addinchar/2]).
-include("recs.hrl").



%%MOTD
connectintro()->
	Result = file:consult("data.conf"),
	case Result of
		{ok, Message}->  
				case lists:keysearch(cotd, 1, Message) of
				{value, Recmotd}->Cotd = aCol:addcol({red,Recmotd#cotd.title})++Recmotd#cotd.text, Cotd;
				{badmatch, false}-> Cotd = "Welcome to a basic MUD server \r\n Enjoy the stay!", Cotd%better a message than no message
				end;
				
		{error, Error} -> {fail, Error}
	end.
	
%%Command parsing	
usercmdatom(Input)->
			case string:len(Input) of
				0->{error, empty};%%no input string
				_->splitstring(Input)
			end.

splitstring(Input)-> 
		case string:str(Input, " ") of
			0->cmdstrip2(Input,"\r\n\t>");
			_Pos->cmdstrip(Input,"\r\n\t> ")
		end.
		
%%addin spaces
addinspaces([])-> "\r\n";
addinspaces([H|T])-> H++" "++addinspaces(T).
%%addin char	
addinchar([],_)-> "\r\n";
addinchar([H|T],Char)-> H++Char++addinchar(T,Char).	




%%stripping strings
cmdstrip(String,Chars)->
		case string:tokens(String, Chars) of
			[] -> {error, empty};
			[Stripped]->{ok, Stripped};
			[Stripped|_Rest]->{ok, Stripped,_Rest}
		end.

cmdstrip2([],_Chars)-> {error, empty};
cmdstrip2(String,Chars)->
		case string:tokens(String, Chars) of
			[] -> {error, empty};
			[Stripped]->{ok, Stripped}
		end.
    
strp(String) ->
    strp(String, "\r\n\t> ").

strp(String, Chars) ->
    [Stripped|_Rest] = string:tokens(String, Chars),
    Stripped.
