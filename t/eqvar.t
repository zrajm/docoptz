#!/usr/bin/env dash
# Copyright (C) 2020-2023 zrajm <docoptz@zrajm.org>
# License: GPLv2 [https://gnu.org/licenses/gpl-2.0.txt]
. "./docoptz.sh"
. "./t/testfunc.sh"

########################
####  Test eqvar()  ####
########################
tmpfile TMPFILE
eqvar a b 2>"$TMPFILE" && :; RETVAL="$?"
readall ERRMSG <"$TMPFILE"
is "$RETVAL"  '1'                                   'Return value'
is "$ERRMSG"  "$BIN: eqvar: Bad variable name 'a'"  'Error message'

tmpfile TMPFILE
eqvar A b 2>"$TMPFILE" && :; RETVAL="$?"
readall ERRMSG <"$TMPFILE"
is "$RETVAL"  '1'                                   'Return value'
is "$ERRMSG"  "$BIN: eqvar: Bad variable name 'b'"  'Error message'

A='('
B='('
eqvar A B && :; RETVAL="$?"
is "$RETVAL"       '0'      'Return value'
unset A B

A='"'
B='"'
eqvar A B && :; RETVAL="$?"
is "$RETVAL"       '0'      'Return value'
unset A B

A='\"'
B='\"'
eqvar A B && :; RETVAL="$?"
is "$RETVAL"       '0'      'Return value'
unset A B

A='('
B=')'
eqvar A B && :; RETVAL="$?"
is "$RETVAL"       '1'      'Return value'
unset A B

done_testing
#[eof]
