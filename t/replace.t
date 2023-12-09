#!/usr/bin/env dash
# Copyright (C) 2020-2023 zrajm <zdocopt@zrajm.org>
# License: GPLv2 [https://gnu.org/licenses/gpl-2.0.txt]
. "./zdocopt.sh"
. "./t/testfunc.sh"

############################
#####  Test replace()  #####
############################
## Call with too few arguments
tmpfile TMPFILE
(replace abc) 2>"$TMPFILE" && :; RETVAL="$?"
readall ERRMSG <"$TMPFILE"
is "$RETVAL"  '1'                                       'Return value'
is "$ERRMSG"  "$BIN: replace: Bad number of arguments"  'Error message'

## Call with too many arguments
tmpfile TMPFILE
(replace 1 2 3 4) 2>"$TMPFILE" && :; RETVAL="$?"
readall ERRMSG <"$TMPFILE"
is "$RETVAL"  '1'                                       'Return value'
is "$ERRMSG"  "$BIN: replace: Bad number of arguments"  'Error message'

## Call with invalid variable name (1st arg)
tmpfile TMPFILE
(replace abc : :) 2>"$TMPFILE" && :; RETVAL="$?"
readall ERRMSG <"$TMPFILE"
is "$RETVAL"  '1'                                       'Return value'
is "$ERRMSG"  "$BIN: replace: Bad variable name 'abc'"  'Error message'

## Replace character at beginning and end
VALUE=':A:B::'
replace VALUE ':' '|' && :; RETVAL="$?"
is "$RETVAL"  '0'                                       'Return value'
is "$VALUE"   '|A|B||'                                  'Replace: : -> |'

## Replace multi character substring
VALUE='<>A<>B<><>'
replace VALUE '<>' '$' && :; RETVAL="$?"
is "$RETVAL"  '0'                                       'Return value'
is "$VALUE"   '$A$B$$'                                  'Replace: <> -> $'

## Attempt shell injection attack
VALUE="'\";ls"
replace VALUE ';' '()' && :; RETVAL="$?"
is "$RETVAL"  '0'                                       'Return value'
is "$VALUE"   "'\"()ls"                                 'Replace: ; -> ()'

## Replace spaces (multiple spaces should be retained)
VALUE=' hej  du   '
replace VALUE ' ' '.' && :; RETVAL="$?"
is "$RETVAL"  '0'                                       'Return value'
is "$VALUE"   '.hej..du...'                             'Replace: <space> -> .'

# Replace end bracket (with something)
VALUE='[]'
replace VALUE ']' '[' && :; RETVAL="$?"
is "$RETVAL"  '0'                                       'Return value'
is "$VALUE"   '[['                                      'Replace: ] -> ['

## Replace thingy that looks like a character class (but is string literal)
VALUE='x[ab]x[ba]x'
replace VALUE '[ab]' '<>' && :; RETVAL="$?"
is "$RETVAL"  '0'                                       'Return value'
is "$VALUE"   'x<>x[ba]x'                               'Replace: [ab] -> <>'

## Replace double quotes
VALUE='x"x"x'
replace VALUE '"' '<>' && :; RETVAL="$?"
is "$RETVAL"  '0'                                       'Return value'
is "$VALUE"   'x<>x<>x'                                 'Replace: " -> <>'

done_testing
#[eof]
