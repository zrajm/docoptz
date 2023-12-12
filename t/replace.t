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
(replace abc) 2>stderr && :; RC="$?"
is "$RC"           '1'                                      'Return value'
is "$(cat stderr)" "$BIN: replace: Bad number of arguments" 'Error message'
unset RC

cd "$(mktemp -d)"
title "replace: Call with too many arguments"
(replace 1 2 3 4) 2>stderr && :; RC="$?"
is "$RC"           '1'                                      'Return value'
is "$(cat stderr)" "$BIN: replace: Bad number of arguments" 'Error message'
unset RC

cd "$(mktemp -d)"
title "replace: Call with invalid variable name (1st arg)"
(replace abc : :) 2>stderr && :; RC="$?"
is "$RC"           '1'                                      'Return value'
is "$(cat stderr)" "$BIN: replace: Bad variable name 'abc'" 'Error message'
unset RC

title "replace: Replace character at beginning and end"
VALUE=':A:B::'
replace VALUE ':' '|' && :; RC="$?"
is "$RC"      '0'                                       'Return value'
is "$VALUE"   '|A|B||'                                  'Replace: : -> |'
unset VALUE RC

title "replace: Replace multi character substring"
VALUE='<>A<>B<><>'
replace VALUE '<>' '$' && :; RC="$?"
is "$RC"      '0'                                       'Return value'
is "$VALUE"   '$A$B$$'                                  'Replace: <> -> $'
unset VALUE RC

title "replace: Attempt shell injection attack"
VALUE="'\";ls"
replace VALUE ';' '()' && :; RC="$?"
is "$RC"      '0'                                       'Return value'
is "$VALUE"   "'\"()ls"                                 'Replace: ; -> ()'
unset VALUE RC

title "replace: Replace spaces (multiple spaces should be retained)"
VALUE=' hej  du   '
replace VALUE ' ' '.' && :; RC="$?"
is "$RC"      '0'                                       'Return value'
is "$VALUE"   '.hej..du...'                             'Replace: <space> -> .'
unset VALUE RC

title "replace: Replace end bracket (with something)"
VALUE='[]'
replace VALUE ']' '[' && :; RC="$?"
is "$RC"      '0'                                       'Return value'
is "$VALUE"   '[['                                      'Replace: ] -> ['
unset VALUE RC

title "replace: Replace thingy that looks like a character class (but is string literal)"
VALUE='x[ab]x[ba]x'
replace VALUE '[ab]' '<>' && :; RC="$?"
is "$RC"      '0'                                       'Return value'
is "$VALUE"   'x<>x[ba]x'                               'Replace: [ab] -> <>'
unset VALUE RC

title "replace: Replace double quotes"
VALUE='x"x"x'
replace VALUE '"' '<>' && :; RC="$?"
is "$RC"      '0'                                       'Return value'
is "$VALUE"   'x<>x<>x'                                 'Replace: " -> <>'
unset VALUE RC

done_testing
#[eof]
