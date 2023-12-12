#!/usr/bin/env dash
# Copyright (C) 2020-2023 zrajm <docoptz@zrajm.org>
# License: GPLv2 [https://gnu.org/licenses/gpl-2.0.txt]
. "./dashtap/dashtap.sh"
. "./docoptz.sh"

cat() { stdin <"$1"; }
BIN="${0##*/}"

function_exists decvar "Function 'decvar' exists"

cd "$(mktemp -d)"
title "decvar: Decrement invalid variable name"
decvar a 2>stderr && :; RC="$?"
is "$RC"  '1'  'Return value'
is "$(cat stderr)" \
   "$BIN: decvar: Bad variable name 'a'" \
   'Error message'
unset RC

cd "$(mktemp -d)"
title "decvar: Decrement an invalid number"
VALUE=123abc
decvar VALUE 2>stderr && :; RC="$?"
is "$RC"  '2'  'Return value'
is "$(cat stderr)" \
   "$BIN: decvar: Invalid number '123abc'" \
   'Error message'
unset VALUE RC

cd "$(mktemp -d)"
title "decvar: Decrement '-' (minus sign w/o number)"
VALUE='-'
decvar VALUE 2>stderr && :; RC="$?"
is "$RC"  '2'  'Return value'
is "$(cat stderr)" \
   "$BIN: decvar: Invalid number '-'" \
   'Error message'
unset VALUE RC

cd "$(mktemp -d)"
title "decvar: Decrement value containing variable name"
VALUE=VALUE2
VALUE2=10
decvar VALUE 2>stderr && :; RC="$?"
is "$RC"  '2'  'Return value'
is "$(cat stderr)" \
   "$BIN: decvar: Invalid number 'VALUE2'" \
   'Error message'
unset VALUE VALUE2 RC

cd "$(mktemp -d)"
title "decvar: Decrement unset value"
decvar VALUE 2>stderr && :; RC="$?"
is "$RC"  '2'  'Return value'
is "$(cat stderr)" \
   "$BIN: decvar: Invalid number ''" \
   'Error message'
unset VALUE RC

cd "$(mktemp -d)"
title "decvar: Decrement empty value"
VALUE=''
decvar VALUE 2>stderr && :; RC="$?"
is "$RC"  '2'  'Return value'
is "$(cat stderr)" \
   "$BIN: decvar: Invalid number ''" \
   'Error message'
unset VALUE RC

title "decvar: Decrement number -10"
VALUE=-10
decvar VALUE && :; RC="$?"
is "$VALUE"    '-11'    'Gotted value'
is "$RC"       '0'      'Return value'
unset VALUE RC

title "decvar: Decrement number -1"
VALUE=-1
decvar VALUE && :; RC="$?"
is "$VALUE"    '-2'     'Gotted value'
is "$RC"       '0'      'Return value'
unset VALUE RC

title "decvar: Decrement number 0"
VALUE=0
decvar VALUE && :; RC="$?"
is "$VALUE"    '-1'     'Gotted value'
is "$RC"       '0'      'Return value'
unset VALUE RC

title "decvar: Decrement number 1"
VALUE=1
decvar VALUE && :; RC="$?"
is "$VALUE"    '0'      'Gotted value'
is "$RC"       '0'      'Return value'
unset VALUE RC

title "decvar: Decrement number 10"
VALUE=10
decvar VALUE && :; RC="$?"
is "$VALUE"    '9'      'Gotted value'
is "$RC"       '0'      'Return value'
unset VALUE RC

title "decvar: Decrement number 65536"
VALUE=65536
decvar VALUE && :; RC="$?"
is "$VALUE"    '65535'  'Gotted value'
is "$RC"       '0'      'Return value'
unset VALUE RC

done_testing
#[eof]
