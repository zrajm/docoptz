#!/usr/bin/env dash
# Copyright (C) 2020-2023 zrajm <docoptz@zrajm.org>
# License: GPLv2 [https://gnu.org/licenses/gpl-2.0.txt]
. "./dashtap/dashtap.sh"
. "./docoptz.sh"

cat() { stdin <"$1"; }
BIN="${0##*/}"

function_exists getvar "Function 'getvar' exists"

cd "$(mktemp -d)"
title "getvar: Invalid variable name as 1st arg"
getvar a 2>stderr && :; RC="$?"
is "$RC"       '1'      'Return value'
is "$(cat stderr)"      "$BIN: getvar: Bad variable name 'a'"  'Error message'
unset RC

cd "$(mktemp -d)"
title "getvar: Invalid variable name as 2nd arg"
getvar A b 2>stderr && :; RC="$?"
is "$RC"       '1'      'Return value'
is "$(cat stderr)"      "$BIN: getvar: Bad variable name 'b'"  'Error message'
unset RC

title "getvar: Get value containing '()'"
VAL="()"
getvar GOTTED VAL && :; RC="$?"
is "$GOTTED"   '()'     'Gotted value'
is "$RC"       '0'      'Return value'
unset GOTTED VAL RC

done_testing
#[eof]
