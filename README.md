# FunctionalMUD
erMUD is a simple MUD that has been implemented in the functional language Erlang. erMUD is a PvP exploration MUD.
erMUD needs to be compiled and run through the Erlang VM. Once the server is started (It can be started via application:start(erMudapp) or mserver:st()) and all the modules are started successfully, it can be used via a telnet to the servers IP and listening port.
erMUD has support for Linux and Windows color formatting for traditional emersion. However the ANSI escape codes that are used require support for ANSI/VT100 within the console. Natively both Windows and Linux have support. For the cases where Windows does not have the telnet libraries installed Putty can be used instead.

Currently the following functions have been implemented:

─	Player vs. Player

─	No limit to incoming client connections

─	Event generation to add atmosphere

─	Dynamic room loading through the dungeon.conf file

─	Personal messaging among players

─	Public messaging based on player room location

─	Primitive inventory

─	Random items scattered through rooms

The player has access to the following functions while playing:

─	Attack <player> , attacks a player based of name
─	Say <msg>, public message to everyone in current room
─	Move <direction>, move to new location if possible
─	Look <direction>, look around for information
─	Listp, list players in current room
─	Search, search for item in current room
─	Info, provide verbose summary info
─	Whereami, where is the player
─	Inv, player stats
─	Help, general help
─	Quit, quit game
The player also has the ability to make use of atmospheric commands such as cry, smile, dance to name a few.
