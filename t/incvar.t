#!/usr/bin/env dash
# Copyright (C) 2020-2023 zrajm <docoptz@zrajm.org>
# License: GPLv2 [https://gnu.org/licenses/gpl-2.0.txt]
set -e

. "./docoptz.sh"
. "./t/testfunc.sh"

#########################
####  Test incvar()  ####
#########################
## Increment invalid variable name
tmpfile TMPFILE
incvar a 2>"$TMPFILE" && :; RETVAL="$?"
readall ERRMSG <"$TMPFILE"
is "$RETVAL"  '1'           'Return value'
is "$ERRMSG"  \
   "$BIN: incvar: Bad variable name 'a'" \
   'Error message'

## Increment an invalid number
tmpfile TMPFILE
VALUE=123abc
incvar VALUE 2>"$TMPFILE" && :; RETVAL="$?"
readall ERRMSG <"$TMPFILE"
is "$RETVAL"  '2'           'Return value'
is "$ERRMSG"  \
   "$BIN: incvar: Invalid number '123abc'" \
   'Error message'
unset VALUE

## Increment '-' (minus sign w/o number)
tmpfile TMPFILE
VALUE='-'
incvar VALUE 2>"$TMPFILE" && :; RETVAL="$?"
readall ERRMSG <"$TMPFILE"
is "$RETVAL"  '2'           'Return value'
is "$ERRMSG"  \
   "$BIN: incvar: Invalid number '-'" \
   'Error message'
unset VALUE

## Increment value containing variable name
tmpfile TMPFILE
VALUE=VALUE2
VALUE2=10
incvar VALUE 2>"$TMPFILE" && :; RETVAL="$?"
readall ERRMSG <"$TMPFILE"
is "$RETVAL"  '2'           'Return value'
is "$ERRMSG"  \
   "$BIN: incvar: Invalid number 'VALUE2'" \
   'Error message'
unset VALUE VALUE2

## Increment unset value
incvar VALUE && :; RETVAL="$?"
is "$VALUE"        '0'      'Gotted value'
is "$RETVAL"       '0'      'Return value'

## Increment empty value
VALUE=''
incvar VALUE && :; RETVAL="$?"
is "$VALUE"        '0'      'Gotted value'
is "$RETVAL"       '0'      'Return value'
unset VALUE

## Increment number -10
VALUE=-10
incvar VALUE && :; RETVAL="$?"
is "$VALUE"        '-9'     'Gotted value'
is "$RETVAL"       '0'      'Return value'
unset VALUE

## Increment number -1
VALUE=-1
incvar VALUE && :; RETVAL="$?"
is "$VALUE"        '0'      'Gotted value'
is "$RETVAL"       '0'      'Return value'
unset VALUE

## Increment number 0
VALUE=0
incvar VALUE && :; RETVAL="$?"
is "$VALUE"        '1'      'Gotted value'
is "$RETVAL"       '0'      'Return value'
unset VALUE

## Increment number 1
VALUE=1
incvar VALUE && :; RETVAL="$?"
is "$VALUE"        '2'      'Gotted value'
is "$RETVAL"       '0'      'Return value'
unset VALUE

## Increment number 10
VALUE=10
incvar VALUE && :; RETVAL="$?"
is "$VALUE"        '11'     'Gotted value'
is "$RETVAL"       '0'      'Return value'
unset VALUE

## Increment number 65536
VALUE=65536
incvar VALUE && :; RETVAL="$?"
is "$VALUE"        '65537'  'Gotted value'
is "$RETVAL"       '0'      'Return value'
unset VALUE

done_testing
#[eof]
