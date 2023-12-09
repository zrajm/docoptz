#!/usr/bin/env dash
# Copyright (C) 2020-2023 zrajm <docoptz@zrajm.org>
# License: GPLv2 [https://gnu.org/licenses/gpl-2.0.txt]
. "./docoptz.sh"
. "./t/testfunc.sh"

#########################
####  Test decvar()  ####
#########################
## Decrement invalid variable name
tmpfile TMPFILE
decvar a 2>"$TMPFILE" && :; RETVAL="$?"
readall ERRMSG <"$TMPFILE"
is "$RETVAL"  '1'           'Return value'
is "$ERRMSG"  \
   "$BIN: decvar: Bad variable name 'a'" \
   'Error message'

## Decrement an invalid number
tmpfile TMPFILE
VALUE=123abc
decvar VALUE 2>"$TMPFILE" && :; RETVAL="$?"
readall ERRMSG <"$TMPFILE"
is "$RETVAL"  '2'           'Return value'
is "$ERRMSG"  \
   "$BIN: decvar: Invalid number '123abc'" \
   'Error message'
unset VALUE

## Decrement '-' (minus sign w/o number)
tmpfile TMPFILE
VALUE='-'
decvar VALUE 2>"$TMPFILE" && :; RETVAL="$?"
readall ERRMSG <"$TMPFILE"
is "$RETVAL"  '2'           'Return value'
is "$ERRMSG"  \
   "$BIN: decvar: Invalid number '-'" \
   'Error message'
unset VALUE

## Decrement value containing variable name
tmpfile TMPFILE
VALUE=VALUE2
VALUE2=10
decvar VALUE 2>"$TMPFILE" && :; RETVAL="$?"
readall ERRMSG <"$TMPFILE"
is "$RETVAL"  '2'           'Return value'
is "$ERRMSG"  \
   "$BIN: decvar: Invalid number 'VALUE2'" \
   'Error message'
unset VALUE VALUE2

## Decrement unset value
tmpfile TMPFILE
decvar VALUE 2>"$TMPFILE" && :; RETVAL="$?"
readall ERRMSG <"$TMPFILE"
is "$RETVAL"  '2'           'Return value'
is "$ERRMSG"  \
   "$BIN: decvar: Invalid number ''" \
   'Error message'

## Decrement empty value
tmpfile TMPFILE
VALUE=''
decvar VALUE 2>"$TMPFILE" && :; RETVAL="$?"
readall ERRMSG <"$TMPFILE"
is "$RETVAL"  '2'           'Return value'
is "$ERRMSG"  \
   "$BIN: decvar: Invalid number ''" \
   'Error message'
unset VALUE

## Decrement number -10
VALUE=-10
decvar VALUE && :; RETVAL="$?"
is "$VALUE"        '-11'    'Gotted value'
is "$RETVAL"       '0'      'Return value'
unset VALUE

## Decrement number -1
VALUE=-1
decvar VALUE && :; RETVAL="$?"
is "$VALUE"        '-2'     'Gotted value'
is "$RETVAL"       '0'      'Return value'
unset VALUE

## Decrement number 0
VALUE=0
decvar VALUE && :; RETVAL="$?"
is "$VALUE"        '-1'     'Gotted value'
is "$RETVAL"       '0'      'Return value'
unset VALUE

## Decrement number 1
VALUE=1
decvar VALUE && :; RETVAL="$?"
is "$VALUE"        '0'      'Gotted value'
is "$RETVAL"       '0'      'Return value'
unset VALUE

## Decrement number 10
VALUE=10
decvar VALUE && :; RETVAL="$?"
is "$VALUE"        '9'      'Gotted value'
is "$RETVAL"       '0'      'Return value'
unset VALUE

## Decrement number 65536
VALUE=65536
decvar VALUE && :; RETVAL="$?"
is "$VALUE"        '65535'  'Gotted value'
is "$RETVAL"       '0'      'Return value'
unset VALUE

done_testing
#[eof]
