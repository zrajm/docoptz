#!/usr/bin/env dash
# Copyright (C) 2020-2023 zrajm <docoptz@zrajm.org>
# License: GPLv2 [https://gnu.org/licenses/gpl-2.0.txt]
. "./dashtap/dashtap.sh"
. "./docoptz.sh"

cat() { stdin <"$1"; }
BIN="${0##*/}"

function_exists incvar "Function 'incvar' exists"

cd "$(mktemp -d)"
title "incvar: Increment invalid variable name"
incvar a 2>stderr && :; RC="$?"
is "$RC"       '1'      'Return value'
is "$(cat stderr)" \
   "$BIN: incvar: Bad variable name 'a'" \
   'Error message'
unset RC

cd "$(mktemp -d)"
title "incvar: Increment an invalid number"
VALUE=123abc
incvar VALUE 2>stderr && :; RC="$?"
is "$RC"       '2'      'Return value'
is "$(cat stderr)" \
   "$BIN: incvar: Invalid number '123abc'" \
   'Error message'
unset VALUE RC

cd "$(mktemp -d)"
title "incvar: Increment '-' (minus sign w/o number)"
VALUE='-'
incvar VALUE 2>stderr && :; RC="$?"
is "$RC"       '2'      'Return value'
is "$(cat stderr)" \
   "$BIN: incvar: Invalid number '-'" \
   'Error message'
unset VALUE RC

cd "$(mktemp -d)"
title "incvar: Increment value containing variable name"
VALUE=VALUE2
VALUE2=10
incvar VALUE 2>stderr && :; RC="$?"
is "$RC"       '2'      'Return value'
is "$(cat stderr)" \
   "$BIN: incvar: Invalid number 'VALUE2'" \
   'Error message'
unset VALUE VALUE2 RC

title "incvar: Increment unset value"
incvar VALUE && :; RC="$?"
is "$VALUE"    '0'      'Gotted value'
is "$RC"       '0'      'Return value'
unset RC

title "incvar: Increment empty value"
VALUE=''
incvar VALUE && :; RC="$?"
is "$VALUE"    '0'      'Gotted value'
is "$RC"       '0'      'Return value'
unset VALUE RC

title "incvar: Increment number -10"
VALUE=-10
incvar VALUE && :; RC="$?"
is "$VALUE"    '-9'     'Gotted value'
is "$RC"       '0'      'Return value'
unset VALUE RC

title "incvar: Increment number -1"
VALUE=-1
incvar VALUE && :; RC="$?"
is "$VALUE"    '0'      'Gotted value'
is "$RC"       '0'      'Return value'
unset VALUE RC

title "incvar: Increment number 0"
VALUE=0
incvar VALUE && :; RC="$?"
is "$VALUE"    '1'      'Gotted value'
is "$RC"       '0'      'Return value'
unset VALUE RC

title "incvar: Increment number 1"
VALUE=1
incvar VALUE && :; RC="$?"
is "$VALUE"    '2'      'Gotted value'
is "$RC"       '0'      'Return value'
unset VALUE RC

title "incvar: Increment number 10"
VALUE=10
incvar VALUE && :; RC="$?"
is "$VALUE"    '11'     'Gotted value'
is "$RC"       '0'      'Return value'
unset VALUE RC

title "incvar: Increment number 65536"
VALUE=65536
incvar VALUE && :; RC="$?"
is "$VALUE"    '65537'  'Gotted value'
is "$RC"       '0'      'Return value'
unset VALUE RC

done_testing
#[eof]
