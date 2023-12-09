#!/usr/bin/env dash
# Copyright (C) 2020-2023 zrajm <docoptz@zrajm.org>
# License: GPLv2 [https://gnu.org/licenses/gpl-2.0.txt]
set -e

. "./docoptz.sh"
. "./t/testfunc.sh"

#########################
####  Test getvar()  ####
#########################
tmpfile TMPFILE
getvar a 2>"$TMPFILE" && :; RETVAL="$?"
readall ERRMSG <"$TMPFILE"
is "$RETVAL"  '1'                                   'Return value'
is "$ERRMSG"  "$BIN: getvar: Bad variable name 'a'" 'Error message'

tmpfile TMPFILE
getvar A b 2>"$TMPFILE" && :; RETVAL="$?"
readall ERRMSG <"$TMPFILE"
is "$RETVAL"  '1'                                   'Return value'
is "$ERRMSG"  "$BIN: getvar: Bad variable name 'b'" 'Error message'

VAL="()"
getvar GOTTED VAL && :; RETVAL="$?"
is "$GOTTED"       '()'     'Gotted value'
is "$RETVAL"       '0'      'Return value'
unset GOTTED VAL

done_testing
#[eof]
