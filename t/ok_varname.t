#!/usr/bin/env dash
# Copyright (C) 2020-2023 zrajm <docoptz@zrajm.org>
# License: GPLv2 [https://gnu.org/licenses/gpl-2.0.txt]
. "./dashtap/dashtap.sh"
. "./docoptz.sh"

cat() { stdin <"$1"; }
BIN="${0##*/}"

function_exists ok_varname "Function 'ok_varname' exists"

cd "$(mktemp -d)"
title "ok_varname: Varname may not be empty"
ok_varname '' 2>stderr && :; RETVAL="$?"
is "$RETVAL"       '1'                                    'Return value'
is "$(cat stderr)" "$BIN: Bad variable name ''"           'Error message'

cd "$(mktemp -d)"
title "ok_varname: Varname may not start with digit"
ok_varname 0ABC 2>stderr && :; RETVAL="$?"
is "$RETVAL"       '1'                                    'Return value'
is "$(cat stderr)" "$BIN: Bad variable name '0ABC'"       'Error message'

cd "$(mktemp -d)"
title "ok_varname: Varname may not contain lower case"
ok_varname ABCx test 2>stderr && :; RETVAL="$?"
is "$RETVAL"       '1'                                    'Return value'
is "$(cat stderr)" "$BIN: test: Bad variable name 'ABCx'" 'Error message'

title "ok_varname: Varname may start with/contain '_'"
ok_varname _ABC && :; RETVAL="$?"
is "$RETVAL"       '0'                                    'Return value'

done_testing
#[eof]
