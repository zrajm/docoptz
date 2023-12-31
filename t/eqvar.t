#!/usr/bin/env dash
# Copyright (C) 2020-2023 zrajm <docoptz@zrajm.org>
# License: GPLv2 [https://gnu.org/licenses/gpl-2.0.txt]
. "./dashtap/dashtap.sh"
. "./docoptz.sh"

cat() { stdin <"$1"; }
BIN="${0##*/}"

function_exists eqvar "Function 'eqvar' exists"

cd "$(mktemp -d)"
title "eqvar: Both variable names are invalid"
eqvar a b 2>stderr && :; RC="$?"
is "$RC"       '1'      'Return value'
is "$(cat stderr)"  "$BIN: eqvar: Bad variable name 'a'"  'Error message'
unset RC

cd "$(mktemp -d)"
title "eqvar: 2nd variable name is invalid"
eqvar A b 2>stderr && :; RC="$?"
is "$RC"       '1'      'Return value'
is "$(cat stderr)"  "$BIN: eqvar: Bad variable name 'b'"  'Error message'
unset RC

title "eqvar: Two equal variables (containing a start parenthesis '(')"
A='('
B='('
eqvar A B && :; RC="$?"
is "$RC"       '0'      'Return value'
unset A B RC

title "eqvar: Two equal variables (containing a double quote '\"')"
A='"'
B='"'
eqvar A B && :; RC="$?"
is "$RC"       '0'      'Return value'
unset A B RC

title "eqvar: Two equal variables (containing backslash + double quote '\\\"')"
A='\"'
B='\"'
eqvar A B && :; RC="$?"
is "$RC"       '0'      'Return value'
unset A B RC

title "eqvar: Two equal variables (containing an end parenthesis '(')"
A='('
B=')'
eqvar A B && :; RC="$?"
is "$RC"       '1'      'Return value'
unset A B RC

done_testing
#[eof]
