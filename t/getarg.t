#!/usr/bin/env dash
# Copyright (C) 2020-2023 zrajm <docoptz@zrajm.org>
# License: GPLv2 [https://gnu.org/licenses/gpl-2.0.txt]
. "./dashtap/dashtap.sh"
. "./docoptz.sh"

cat() { stdin <"$1"; }
BIN="${0##*/}"

function_exists getarg "Function 'getarg' exists"

title "getarg"
getarg GOTTED 1 a b c d e f g h i j && :; RETVAL="$?"
is "$GOTTED"       'a'      'Gotted value'
is "$RETVAL"       '0'      'Return value'
unset GOTTED

title "getarg"
getarg GOTTED 10 a b c d e f g h i j && :; RETVAL="$?"
is "$GOTTED"       'j'      'Gotted value'
is "$RETVAL"       '0'      'Return value'
unset GOTTED

done_testing
#[eof]
