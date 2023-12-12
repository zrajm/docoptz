#!/usr/bin/env dash
# Copyright (C) 2020-2023 zrajm <docoptz@zrajm.org>
# License: GPLv2 [https://gnu.org/licenses/gpl-2.0.txt]
. "./dashtap/dashtap.sh"
. "./docoptz.sh"

cat() { stdin <"$1"; }
BIN="${0##*/}"

function_exists ifvar "Function 'ifvar' exists"

cd "$(mktemp -d)"
title "ifvar"
ifvar a 2>stderr && :; RC="$?"
is "$RC"       '1'      'Return value'
is "$(cat stderr)" "$BIN: ifvar: Bad variable name 'a'"  'Error message'
unset RC

title "ifvar"
A='('
ifvar A && :; RC="$?"
is "$RC"       '0'      'Return value'
unset A RC

title "ifvar"
A=''
ifvar A && :; RC="$?"
is "$RC"       '1'      'Return value'
unset A RC

done_testing
#[eof]
