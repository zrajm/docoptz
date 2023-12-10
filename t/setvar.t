#!/usr/bin/env dash
# Copyright (C) 2020-2023 zrajm <docoptz@zrajm.org>
# License: GPLv2 [https://gnu.org/licenses/gpl-2.0.txt]
. "./dashtap/dashtap.sh"
. "./docoptz.sh"

cat() { stdin <"$1"; }
BIN="${0##*/}"

function_exists setvar "Function 'setvar' exists"

cd "$(mktemp -d)"
title "setvar: Set invalid variable name"
setvar a 2>stderr && :; RETVAL="$?"
is "$RETVAL"       '1'                                   'Return value'
is "$(cat stderr)" "$BIN: setvar: Bad variable name 'a'" 'Error message'

title "setvar: Set variable name"
setvar GOTTED '()' && :; RETVAL="$?"
is "$GOTTED"       '()'     'Gotted value'
is "$RETVAL"       '0'      'Return value'
unset GOTTED

done_testing
#[eof]
