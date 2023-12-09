#!/usr/bin/env dash
# Copyright (C) 2020-2023 zrajm <docoptz@zrajm.org>
# License: GPLv2 [https://gnu.org/licenses/gpl-2.0.txt]
. "./docoptz.sh"
. "./t/testfunc.sh"

########################
####  Test ifvar()  ####
########################
tmpfile TMPFILE
ifvar a 2>"$TMPFILE" && :; RETVAL="$?"
readall ERRMSG <"$TMPFILE"
is "$RETVAL"  '1'                                   'Return value'
is "$ERRMSG"  "$BIN: ifvar: Bad variable name 'a'"  'Error message'

A='('
ifvar A && :; RETVAL="$?"
is "$RETVAL"       '0'      'Return value'
unset A

A=''
ifvar A && :; RETVAL="$?"
is "$RETVAL"       '1'      'Return value'
unset A

done_testing
#[eof]
