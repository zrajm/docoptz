#!/usr/bin/env dash
# Copyright (C) 2020-2023 zrajm <docoptz@zrajm.org>
# License: GPLv2 [https://gnu.org/licenses/gpl-2.0.txt]
. "./dashtap/dashtap.sh"
. "./docoptz.sh"

cat() { stdin <"$1"; }
BIN="${0##*/}"

function_exists replace "Function 'replace' exists"

cd "$(mktemp -d)"
title "replace: Call with too few arguments"
(replace abc) 2>stderr && :; RETVAL="$?"
is "$RETVAL"       '1'                                      'Return value'
is "$(cat stderr)" "$BIN: replace: Bad number of arguments" 'Error message'

cd "$(mktemp -d)"
title "replace: Call with too many arguments"
(replace 1 2 3 4) 2>stderr && :; RETVAL="$?"
is "$RETVAL"       '1'                                      'Return value'
is "$(cat stderr)" "$BIN: replace: Bad number of arguments" 'Error message'

cd "$(mktemp -d)"
title "replace: Call with invalid variable name (1st arg)"
(replace abc : :) 2>stderr && :; RETVAL="$?"
is "$RETVAL"       '1'                                      'Return value'
is "$(cat stderr)" "$BIN: replace: Bad variable name 'abc'" 'Error message'

title "replace: Replace character at beginning and end"
VALUE=':A:B::'
replace VALUE ':' '|' && :; RETVAL="$?"
is "$RETVAL"  '0'                                       'Return value'
is "$VALUE"   '|A|B||'                                  'Replace: : -> |'

title "replace: Replace multi character substring"
VALUE='<>A<>B<><>'
replace VALUE '<>' '$' && :; RETVAL="$?"
is "$RETVAL"  '0'                                       'Return value'
is "$VALUE"   '$A$B$$'                                  'Replace: <> -> $'

title "replace: Attempt shell injection attack"
VALUE="'\";ls"
replace VALUE ';' '()' && :; RETVAL="$?"
is "$RETVAL"  '0'                                       'Return value'
is "$VALUE"   "'\"()ls"                                 'Replace: ; -> ()'

title "replace: Replace spaces (multiple spaces should be retained)"
VALUE=' hej  du   '
replace VALUE ' ' '.' && :; RETVAL="$?"
is "$RETVAL"  '0'                                       'Return value'
is "$VALUE"   '.hej..du...'                             'Replace: <space> -> .'

title "replace: Replace end bracket (with something)"
VALUE='[]'
replace VALUE ']' '[' && :; RETVAL="$?"
is "$RETVAL"  '0'                                       'Return value'
is "$VALUE"   '[['                                      'Replace: ] -> ['

title "replace: Replace thingy that looks like a character class (but is string literal)"
VALUE='x[ab]x[ba]x'
replace VALUE '[ab]' '<>' && :; RETVAL="$?"
is "$RETVAL"  '0'                                       'Return value'
is "$VALUE"   'x<>x[ba]x'                               'Replace: [ab] -> <>'

title "replace: Replace double quotes"
VALUE='x"x"x'
replace VALUE '"' '<>' && :; RETVAL="$?"
is "$RETVAL"  '0'                                       'Return value'
is "$VALUE"   'x<>x<>x'                                 'Replace: " -> <>'

done_testing
#[eof]
