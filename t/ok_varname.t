#!/usr/bin/env dash
# Copyright (C) 2020-2023 zrajm <docoptz@zrajm.org>
# License: GPLv2 [https://gnu.org/licenses/gpl-2.0.txt]
set -e

. "./docoptz.sh"
. "./t/testfunc.sh"

#############################
####  Test ok_varname()  ####
#############################
## Varname may not be empty
tmpfile TMPFILE
ok_varname '' 2>"$TMPFILE" && :; RETVAL="$?"
readall ERRMSG <"$TMPFILE"
is "$RETVAL"  '1'                                     'Return value'
is "$ERRMSG"  "$BIN: Bad variable name ''"            'Error message'

## Varname may not start with digit
tmpfile TMPFILE
ok_varname 0ABC 2>"$TMPFILE" && :; RETVAL="$?"
readall ERRMSG <"$TMPFILE"
is "$RETVAL"  '1'                                     'Return value'
is "$ERRMSG"  "$BIN: Bad variable name '0ABC'"        'Error message'

## Varname may not contain lower case
tmpfile TMPFILE
ok_varname ABCx test 2>"$TMPFILE" && :; RETVAL="$?"
readall ERRMSG <"$TMPFILE"
is "$RETVAL"  '1'                                     'Return value'
is "$ERRMSG"  "$BIN: test: Bad variable name 'ABCx'"  'Error message'

## Varname may start with/contain '_'
ok_varname _ABC && :; RETVAL="$?"
is "$RETVAL"  '0'                                     'Return value'

done_testing
#[eof]
