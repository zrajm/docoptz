#!/usr/bin/env dash
# Copyright (C) 2020-2023 zrajm <zdocopt@zrajm.org>
# License: GPLv2 [https://gnu.org/licenses/gpl-2.0.txt]
. "./zdocopt.sh"
. "./t/testfunc.sh"

#########################
####  Test setvar()  ####
#########################
tmpfile TMPFILE
setvar a 2>"$TMPFILE" && :; RETVAL="$?"
readall ERRMSG <"$TMPFILE"
is "$RETVAL"  '1'                                   'Return value'
is "$ERRMSG"  "$BIN: setvar: Bad variable name 'a'" 'Error message'

setvar GOTTED '()' && :; RETVAL="$?"
is "$GOTTED"       '()'     'Gotted value'
is "$RETVAL"       '0'      'Return value'
unset GOTTED

done_testing
#[eof]
