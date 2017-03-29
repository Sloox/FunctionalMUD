-module(erMudapp).
-behaviour(application).
-export([start/2, stop/1]).

start(_Type, _Args)->
	mserver:st().
	
stop(_State)->
	ok.