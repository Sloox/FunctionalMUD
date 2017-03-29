%% @author M Wright <201176962@student.uj.ac.za>
%% @copyright Wright, MJ 2014-2015
%% @version 1.2
%% @title Color & Terminal formatter
%% @doc Adds color to terminal output & attempts to format the output nicely
%% @end

-module(aCol).
-export([addcol/1,oldline/1,actioncol/1]).
%move to begin of old line, add end of line char, insert line, Move curosr down
oldline(Data)->[[27, $[, "1",$F ],["\r\n"],Data].

%%"\033[F" start of previous line

%%event color
actioncol(Data)->[[27, $[, "41", $m ], addcol({white,Data}), [27, $[, "40", $m ]].
%%primary colors
addcol({black, Data})->[[27, $[, "1;30", $m ],Data,[27, $[, "0", $m ]];
addcol({red, Data})->[[27, $[, "1;31", $m ],Data,[27, $[, "0", $m ]];
addcol({green, Data})->[[27, $[, "1;32", $m ],Data,[27, $[, "0", $m ]];
addcol({yellow, Data})->[[27, $[, "1;33", $m ],Data,[27, $[, "0", $m ]];
addcol({blue, Data})->[[27, $[, "1;34", $m ],Data,[27, $[, "0", $m ]];
addcol({magenta, Data})->[[27, $[, "1;35", $m ],Data,[27, $[, "0", $m ]];
addcol({cyan, Data})->[[27, $[, "1;36", $m ],Data,[27, $[, "0", $m ]];
addcol({white, Data})->[[27, $[, "1;37", $m ],Data,[27, $[, "0", $m ]];
addcol({darkred, Data})->[[27, $[, "0;31", $m ],Data,[27, $[, "0", $m ]];
addcol({purple, Data})->[[27, $[, "0;35", $m ],Data,[27, $[, "0", $m ]];
addcol({brown, Data})->[[27, $[, "0;33", $m ],Data,[27, $[, "0", $m ]];
addcol({grey, Data})->[[27, $[, "0;37", $m ],Data,[27, $[, "0", $m ]];
addcol(Other)->Other.
