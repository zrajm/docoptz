#!/usr/bin/env dash
# Copyright (C) 2020-2023 zrajm <docoptz@zrajm.org>
# License: GPLv2 [https://gnu.org/licenses/gpl-2.0.txt]
. "./dashtap/dashtap.sh"
. "./docoptz.sh"

cat() { stdin <"$1"; }
dumpenv() {
    local VAR
    for VAR in "$@"; do
        local "$VAR"
        unset "$VAR"
    done
    set
}
BIN="${0##*/}"

function_exists parse "Function 'parse' exists"

cd "$(mktemp -d)"
title 'parse `...`: `...` not allowed at beginning'
INPUT='...'
parse GOTTED_RULES "$INPUT" 2>stderr && :; RC="$?" # intentionally unquoted
is "$RC"           '1'                                  'Return value'
is "$(cat stderr)" "$BIN: Badly placed '...' in rule: ...
(Must come after ARGUMENT or end parenthesis/bracket.)" 'Error message'
unset INPUT GOTTED_RULES RC

cd "$(mktemp -d)"
title 'parse `(...`: `...` not allowed after start parenthesis'
INPUT='( ...'
parse GOTTED_RULES "$INPUT" 2>stderr && :; RC="$?" # intentionally unquoted
is "$RC"           '1'                                  'Return value'
is "$(cat stderr)" "$BIN: Badly placed '...' in rule: ( ...
(Must come after ARGUMENT or end parenthesis/bracket.)" 'Error message'
unset INPUT GOTTED_RULES RC

cd "$(mktemp -d)"
title 'parse `|`: `|` not allowed outside paren or bracket'
INPUT='|'
parse GOTTED_RULES "$INPUT" 2>stderr && :; RC="$?" # intentionally unquoted
is "$RC"           '1'                                 'Return value'
is "$(cat stderr)" "$BIN: Badly placed '|' in rule: |
(Must be inside parentheses/brackets.)"                'Error message'
unset INPUT GOTTED_RULES RC

cd "$(mktemp -d)"
title 'parse `A)`: Too many end paren'
INPUT='A )'
parse GOTTED_RULES "$INPUT" 2>stderr && :; RC="$?" # intentionally unquoted
is "$RC"           '1'                                     'Return value'
is "$(cat stderr)" "$BIN: Too many ')' in rule: A )"       'Error message'
unset INPUT GOTTED_RULES RC

cd "$(mktemp -d)"
title 'parse `A]`: Too many end brackets'
INPUT='A ]'
parse GOTTED_RULES "$INPUT" 2>stderr && :; RC="$?" # intentionally unquoted
is "$RC"           '1'                                     'Return value'
is "$(cat stderr)" "$BIN: Too many ']' in rule: A ]"       'Error message'
unset INPUT GOTTED_RULES RC

cd "$(mktemp -d)"
title 'parse `[A)`: Missing end bracket'
INPUT='[ A )'
parse GOTTED_RULES "$INPUT" 2>stderr && :; RC="$?" # intentionally unquoted
is "$RC"           '1'                                     'Return value'
is "$(cat stderr)" "$BIN: Missing ')' in rule (group 1): [ A )" 'Error message'
unset INPUT GOTTED_RULES RC

cd "$(mktemp -d)"
title 'parse `(A]`: Missing end paren'
INPUT='( A ]'
parse GOTTED_RULES "$INPUT" 2>stderr && :; RC="$?" # intentionally unquoted
is "$RC"           '1'                                     'Return value'
is "$(cat stderr)" "$BIN: Missing ']' in rule (group 1): ( A ]" 'Error message'
unset INPUT GOTTED_RULES RC

cd "$(mktemp -d)"
title 'parse `(A`: Missing end paren'
INPUT='( A'
parse GOTTED_RULES "$INPUT" 2>stderr && :; RC="$?" # intentionally unquoted
is "$RC"           '1'                                     'Return value'
is "$(cat stderr)" "$BIN: Missing ')' at end of rule: ( A" 'Error message'
unset INPUT GOTTED_RULES RC

###############################################################################

title 'parse `[[A] B]`'
INPUT='  [   [   A   ]   B   ]'
LEVEL='0 [ 1 [ 2 A 2 ] 1 B 1 ] 0'
GROUP='0 [ 1 [ 2 A 2 ] 1 B 1 ] 0'
STATE='0 [ 0 [ 0 A 2 ] 2 B 1 ] 1'
RULES='0 2 A
0 1 B
2 1 B
0 x
1 x'
parse GOTTED_RULES "$INPUT" && :; RC="$?"  # intentionally unquoted
is "$RC"           '0'      'Return value'
is "$_DEBUG_LEVEL" "$LEVEL" "Bracket level: '$INPUT'"
is "$_DEBUG_GROUP" "$GROUP" "Group numbers: '$INPUT'"
is "$_DEBUG_STATE" "$STATE" "State numbers: '$INPUT'"
is "$GOTTED_RULES" "$RULES"         "Rules: '$INPUT'"
unset INPUT LEVEL GROUP STATE RULES GOTTED_RULES RC

title 'parse `[A [B]]`'
INPUT='  [   A   [   B   ]   ]'
LEVEL='0 [ 1 A 1 [ 2 B 2 ] 1 ] 0'
GROUP='0 [ 1 A 1 [ 2 B 2 ] 1 ] 0'
STATE='0 [ 0 A 2 [ 2 B 3 ] 3 ] 3'
RULES='0 2 A
2 3 B
0 x
3 x'
parse GOTTED_RULES "$INPUT" && :; RC="$?"  # intentionally unquoted
is "$RC"           '0'      'Return value'
is "$_DEBUG_LEVEL" "$LEVEL" "Bracket level: '$INPUT'"
is "$_DEBUG_GROUP" "$GROUP" "Group numbers: '$INPUT'"
is "$_DEBUG_STATE" "$STATE" "State numbers: '$INPUT'"
is "$GOTTED_RULES" "$RULES"         "Rules: '$INPUT'"
unset INPUT LEVEL GROUP STATE RULES GOTTED_RULES RC

title 'parse `[A] [B [C] [D]]`'
INPUT='  [   A   ]   [   B   [   C   ]   [   D   ]   ]'
LEVEL='0 [ 1 A 1 ] 0 [ 1 B 1 [ 2 C 2 ] 1 [ 2 D 2 ] 1 ] 0'
GROUP='0 [ 1 A 1 ] 0 [ 2 B 2 [ 3 C 3 ] 2 [ 4 D 4 ] 2 ] 0'
STATE='0 [ 0 A 1 ] 1 [ 1 B 3 [ 3 C 4 ] 4 [ 4 D 5 ] 5 ] 5'
RULES='0 1 A
0 3 B
1 3 B
3 4 C
3 5 D
4 5 D
0 x
1 x
5 x'
parse GOTTED_RULES "$INPUT" && :; RC="$?"  # intentionally unquoted
is "$RC"           '0'      'Return value'
is "$_DEBUG_LEVEL" "$LEVEL" "Bracket level: '$INPUT'"
is "$_DEBUG_GROUP" "$GROUP" "Group numbers: '$INPUT'"
is "$_DEBUG_STATE" "$STATE" "State numbers: '$INPUT'"
is "$GOTTED_RULES" "$RULES"         "Rules: '$INPUT'"
unset INPUT LEVEL GROUP STATE RULES GOTTED_RULES RC

title 'parse `[A]`'
INPUT='  [   A   ]'
LEVEL='0 [ 1 A 1 ] 0'
GROUP='0 [ 1 A 1 ] 0'
STATE='0 [ 0 A 1 ] 1'
RULES='0 1 A
0 x
1 x'
parse GOTTED_RULES "$INPUT" && :; RC="$?"  # intentionally unquoted
is "$RC"           '0'      'Return value'
is "$_DEBUG_LEVEL" "$LEVEL" "Bracket level: '$INPUT'"
is "$_DEBUG_GROUP" "$GROUP" "Group numbers: '$INPUT'"
is "$_DEBUG_STATE" "$STATE" "State numbers: '$INPUT'"
is "$GOTTED_RULES" "$RULES"         "Rules: '$INPUT'"
unset INPUT LEVEL GROUP STATE RULES GOTTED_RULES RC

title 'parse `[A] B`'
INPUT='  [   A   ]   B'
LEVEL='0 [ 1 A 1 ] 0 B 0'
GROUP='0 [ 1 A 1 ] 0 B 0'
STATE='0 [ 0 A 1 ] 1 B 2'
RULES='0 1 A
0 2 B
1 2 B
2 x'
parse GOTTED_RULES "$INPUT" && :; RC="$?"  # intentionally unquoted
is "$RC"           '0'      'Return value'
is "$_DEBUG_LEVEL" "$LEVEL" "Bracket level: '$INPUT'"
is "$_DEBUG_GROUP" "$GROUP" "Group numbers: '$INPUT'"
is "$_DEBUG_STATE" "$STATE" "State numbers: '$INPUT'"
is "$GOTTED_RULES" "$RULES"         "Rules: '$INPUT'"
unset INPUT LEVEL GROUP STATE RULES GOTTED_RULES RC

title 'parse `[A] [B] C`'
INPUT='  [   A   ]   [   B   ]   C'
LEVEL='0 [ 1 A 1 ] 0 [ 1 B 1 ] 0 C 0'
GROUP='0 [ 1 A 1 ] 0 [ 2 B 2 ] 0 C 0'
STATE='0 [ 0 A 1 ] 1 [ 1 B 2 ] 2 C 3'
RULES='0 1 A
0 2 B
1 2 B
0 3 C
1 3 C
2 3 C
3 x'
parse GOTTED_RULES "$INPUT" && :; RC="$?"  # intentionally unquoted
is "$RC"           '0'      'Return value'
is "$_DEBUG_LEVEL" "$LEVEL" "Bracket level: '$INPUT'"
is "$_DEBUG_GROUP" "$GROUP" "Group numbers: '$INPUT'"
is "$_DEBUG_STATE" "$STATE" "State numbers: '$INPUT'"
is "$GOTTED_RULES" "$RULES"         "Rules: '$INPUT'"
unset INPUT LEVEL GROUP STATE RULES GOTTED_RULES RC

title 'parse `[A] B [C] `'
INPUT='  [   A   ]   B   [   C   ]  '
LEVEL='0 [ 1 A 1 ] 0 B 0 [ 1 C 1 ] 0'
GROUP='0 [ 1 A 1 ] 0 B 0 [ 2 C 2 ] 0'
STATE='0 [ 0 A 1 ] 1 B 2 [ 2 C 3 ] 3'
RULES='0 1 A
0 2 B
1 2 B
2 3 C
2 x
3 x'
parse GOTTED_RULES "$INPUT" && :; RC="$?"  # intentionally unquoted
is "$RC"           '0'      'Return value'
is "$_DEBUG_LEVEL" "$LEVEL" "Bracket level: '$INPUT'"
is "$_DEBUG_GROUP" "$GROUP" "Group numbers: '$INPUT'"
is "$_DEBUG_STATE" "$STATE" "State numbers: '$INPUT'"
is "$GOTTED_RULES" "$RULES"         "Rules: '$INPUT'"
unset INPUT LEVEL GROUP STATE RULES GOTTED_RULES RC

title 'parse `[A|B] C [D|E] `'
INPUT='  [   A   |   B   ]   C   [   D   |   E   ]  '
LEVEL='0 [ 1 A 1 | 1 B 1 ] 0 C 0 [ 1 D 1 | 1 E 1 ] 0'
GROUP='0 [ 1 A 1 | 1 B 1 ] 0 C 0 [ 2 D 2 | 2 E 2 ] 0'
STATE='0 [ 0 A 1 | 0 B 1 ] 1 C 2 [ 2 D 3 | 2 E 3 ] 3'
RULES='0 1 A
0 1 B
0 2 C
1 2 C
2 3 D
2 3 E
2 x
3 x'
parse GOTTED_RULES "$INPUT" && :; RC="$?"  # intentionally unquoted
is "$RC"           '0'      'Return value'
is "$_DEBUG_LEVEL" "$LEVEL" "Bracket level: '$INPUT'"
is "$_DEBUG_GROUP" "$GROUP" "Group numbers: '$INPUT'"
is "$_DEBUG_STATE" "$STATE" "State numbers: '$INPUT'"
is "$GOTTED_RULES" "$RULES"         "Rules: '$INPUT'"
unset INPUT LEVEL GROUP STATE RULES GOTTED_RULES RC

title 'parse `[A] [B] [C]`'
INPUT='  [   A   ]   [   B   ]   [   C   ]'
LEVEL='0 [ 1 A 1 ] 0 [ 1 B 1 ] 0 [ 1 C 1 ] 0'
GROUP='0 [ 1 A 1 ] 0 [ 2 B 2 ] 0 [ 3 C 3 ] 0'
STATE='0 [ 0 A 1 ] 1 [ 1 B 2 ] 2 [ 2 C 3 ] 3'
RULES='0 1 A
0 2 B
1 2 B
0 3 C
1 3 C
2 3 C
0 x
1 x
2 x
3 x'
parse GOTTED_RULES "$INPUT" && :; RC="$?"  # intentionally unquoted
is "$RC"           '0'      'Return value'
is "$_DEBUG_LEVEL" "$LEVEL" "Bracket level: '$INPUT'"
is "$_DEBUG_GROUP" "$GROUP" "Group numbers: '$INPUT'"
is "$_DEBUG_STATE" "$STATE" "State numbers: '$INPUT'"
is "$GOTTED_RULES" "$RULES"         "Rules: '$INPUT'"
unset INPUT LEVEL GROUP STATE RULES GOTTED_RULES RC

title 'parse `[A] [B] [C|D]`'
INPUT='  [   A   ]   [   B   ]   [   C   |   D   ]'
LEVEL='0 [ 1 A 1 ] 0 [ 1 B 1 ] 0 [ 1 C 1 | 1 D 1 ] 0'
GROUP='0 [ 1 A 1 ] 0 [ 2 B 2 ] 0 [ 3 C 3 | 3 D 3 ] 0'
STATE='0 [ 0 A 1 ] 1 [ 1 B 2 ] 2 [ 2 C 3 | 2 D 3 ] 3'
#      0 [ 0 A 1 ] 1 [ 1 B 2 ] 2 [ 2 C 3 | 0 1 2 D 3 ] 3 FIXME < '0 1 2' BUG
RULES='0 1 A
0 2 B
1 2 B
0 3 C
1 3 C
2 3 C
0 3 D
1 3 D
2 3 D
0 x
1 x
2 x
3 x'
parse GOTTED_RULES "$INPUT" && :; RC="$?"  # intentionally unquoted
is "$RC"           '0'      'Return value'
is "$_DEBUG_LEVEL" "$LEVEL" "Bracket level: '$INPUT'"
is "$_DEBUG_GROUP" "$GROUP" "Group numbers: '$INPUT'"
is "$_DEBUG_STATE" "$STATE" "State numbers: '$INPUT'"
is "$GOTTED_RULES" "$RULES"         "Rules: '$INPUT'"
unset INPUT LEVEL GROUP STATE RULES GOTTED_RULES RC

title 'parse `[A] [B [C] [D]]`'
INPUT='  [   A   ]   [   B   [   C   ]   [   D   ]   ]'
LEVEL='0 [ 1 A 1 ] 0 [ 1 B 1 [ 2 C 2 ] 1 [ 2 D 2 ] 1 ] 0'
GROUP='0 [ 1 A 1 ] 0 [ 2 B 2 [ 3 C 3 ] 2 [ 4 D 4 ] 2 ] 0'
STATE='0 [ 0 A 1 ] 1 [ 1 B 3 [ 3 C 4 ] 4 [ 4 D 5 ] 5 ] 5'
RULES='0 1 A
0 3 B
1 3 B
3 4 C
3 5 D
4 5 D
0 x
1 x
5 x'
parse GOTTED_RULES "$INPUT" && :; RC="$?"  # intentionally unquoted
is "$RC"           '0'      'Return value'
is "$_DEBUG_LEVEL" "$LEVEL" "Bracket level: '$INPUT'"
is "$_DEBUG_GROUP" "$GROUP" "Group numbers: '$INPUT'"
is "$_DEBUG_STATE" "$STATE" "State numbers: '$INPUT'"
is "$GOTTED_RULES" "$RULES"         "Rules: '$INPUT'"
unset INPUT LEVEL GROUP STATE RULES GOTTED_RULES RC

title 'parse `[A] [B]`'
INPUT='  [   A   ]   [   B   ]'
LEVEL='0 [ 1 A 1 ] 0 [ 1 B 1 ] 0'
GROUP='0 [ 1 A 1 ] 0 [ 2 B 2 ] 0'
STATE='0 [ 0 A 1 ] 1 [ 1 B 2 ] 2'
RULES='0 1 A
0 2 B
1 2 B
0 x
1 x
2 x'
parse GOTTED_RULES "$INPUT" && :; RC="$?"  # intentionally unquoted
is "$RC"           '0'      'Return value'
is "$_DEBUG_LEVEL" "$LEVEL" "Bracket level: '$INPUT'"
is "$_DEBUG_GROUP" "$GROUP" "Group numbers: '$INPUT'"
is "$_DEBUG_STATE" "$STATE" "State numbers: '$INPUT'"
is "$GOTTED_RULES" "$RULES"         "Rules: '$INPUT'"
unset INPUT LEVEL GROUP STATE RULES GOTTED_RULES RC

title 'parse `[A] (B)`'
INPUT='  [   A   ]   (   B   )'
LEVEL='0 [ 1 A 1 ] 0 ( 1 B 1 ) 0'
GROUP='0 [ 1 A 1 ] 0 ( 2 B 2 ) 0'
STATE='0 [ 0 A 1 ] 1 ( 1 B 2 ) 2'
RULES='0 1 A
0 2 B
1 2 B
2 x'
parse GOTTED_RULES "$INPUT" && :; RC="$?"  # intentionally unquoted
is "$RC"           '0'      'Return value'
is "$_DEBUG_LEVEL" "$LEVEL" "Bracket level: '$INPUT'"
is "$_DEBUG_GROUP" "$GROUP" "Group numbers: '$INPUT'"
is "$_DEBUG_STATE" "$STATE" "State numbers: '$INPUT'"
is "$GOTTED_RULES" "$RULES"         "Rules: '$INPUT'"
unset INPUT LEVEL GROUP STATE RULES GOTTED_RULES RC

title 'parse `(A) [B]`'
INPUT='  (   A   )   [   B   ]'
LEVEL='0 ( 1 A 1 ) 0 [ 1 B 1 ] 0'
GROUP='0 ( 1 A 1 ) 0 [ 2 B 2 ] 0'
STATE='0 ( 0 A 1 ) 1 [ 1 B 2 ] 2'
RULES='0 1 A
1 2 B
1 x
2 x'
parse GOTTED_RULES "$INPUT" && :; RC="$?"  # intentionally unquoted
is "$RC"           '0'      'Return value'
is "$_DEBUG_LEVEL" "$LEVEL" "Bracket level: '$INPUT'"
is "$_DEBUG_GROUP" "$GROUP" "Group numbers: '$INPUT'"
is "$_DEBUG_STATE" "$STATE" "State numbers: '$INPUT'"
is "$GOTTED_RULES" "$RULES"         "Rules: '$INPUT'"
unset INPUT LEVEL GROUP STATE RULES GOTTED_RULES RC

title 'parse `[a] [[b] c]`'
INPUT='  [   a   ]   [   [   b   ]   c   ]'
LEVEL='0 [ 1 a 1 ] 0 [ 1 [ 2 b 2 ] 1 c 1 ] 0'
GROUP='0 [ 1 a 1 ] 0 [ 2 [ 3 b 3 ] 2 c 2 ] 0'
STATE='0 [ 0 a 1 ] 1 [ 1 [ 1 b 3 ] 3 c 2 ] 2'
RULES='0 1 a
0 3 b
1 3 b
0 2 c
1 2 c
3 2 c
0 x
1 x
2 x'
parse GOTTED_RULES "$INPUT" && :; RC="$?"  # intentionally unquoted
is "$RC"           '0'      'Return value'
is "$_DEBUG_LEVEL" "$LEVEL" "Bracket level: '$INPUT'"
is "$_DEBUG_GROUP" "$GROUP" "Group numbers: '$INPUT'"
is "$_DEBUG_STATE" "$STATE" "State numbers: '$INPUT'"
is "$GOTTED_RULES" "$RULES"         "Rules: '$INPUT'"
unset INPUT LEVEL GROUP STATE RULES GOTTED_RULES RC

title 'parse `[a] [[b] [c] d]`'
INPUT='  [   a   ]   [   [   b   ]   [   c   ]   d   ]'
LEVEL='0 [ 1 a 1 ] 0 [ 1 [ 2 b 2 ] 1 [ 2 c 2 ] 1 d 1 ] 0'
GROUP='0 [ 1 a 1 ] 0 [ 2 [ 3 b 3 ] 2 [ 4 c 4 ] 2 d 2 ] 0'
STATE='0 [ 0 a 1 ] 1 [ 1 [ 1 b 3 ] 3 [ 3 c 4 ] 4 d 2 ] 2'
RULES='0 1 a
0 3 b
1 3 b
0 4 c
1 4 c
3 4 c
0 2 d
1 2 d
3 2 d
4 2 d
0 x
1 x
2 x'
parse GOTTED_RULES "$INPUT" && :; RC="$?"  # intentionally unquoted
is "$RC"           '0'      'Return value'
is "$_DEBUG_LEVEL" "$LEVEL" "Bracket level: '$INPUT'"
is "$_DEBUG_GROUP" "$GROUP" "Group numbers: '$INPUT'"
is "$_DEBUG_STATE" "$STATE" "State numbers: '$INPUT'"
is "$GOTTED_RULES" "$RULES"         "Rules: '$INPUT'"
unset INPUT LEVEL GROUP STATE RULES GOTTED_RULES RC

title 'parse `[A] [B]`'
INPUT='  [   A   ]   [   B   ]'
LEVEL='0 [ 1 A 1 ] 0 [ 1 B 1 ] 0'
GROUP='0 [ 1 A 1 ] 0 [ 2 B 2 ] 0'
STATE='0 [ 0 A 1 ] 1 [ 1 B 2 ] 2'
RULES='0 1 A
0 2 B
1 2 B
0 x
1 x
2 x'
parse GOTTED_RULES "$INPUT" && :; RC="$?"  # intentionally unquoted
is "$RC"           '0'      'Return value'
is "$_DEBUG_LEVEL" "$LEVEL" "Bracket level: '$INPUT'"
is "$_DEBUG_GROUP" "$GROUP" "Group numbers: '$INPUT'"
is "$_DEBUG_STATE" "$STATE" "State numbers: '$INPUT'"
is "$GOTTED_RULES" "$RULES"         "Rules: '$INPUT'"
unset INPUT LEVEL GROUP STATE RULES GOTTED_RULES RC

title 'parse `[A B C|D E F|G H I]... X`'
INPUT='  [   A   B   C   |   D   E   F   |   G   H   I   ]   ...   X'
LEVEL='0 [ 1 A 1 B 1 C 1 | 1 D 1 E 1 F 1 | 1 G 1 H 1 I 1 ] 0 ... 0 X 0'
GROUP='0 [ 1 A 1 B 1 C 1 | 1 D 1 E 1 F 1 | 1 G 1 H 1 I 1 ] 0 ... 0 X 0'
STATE='0 [ 0 A 2 B 3 C 1 | 0 D 4 E 5 F 1 | 0 G 6 H 7 I 1 ] 1 ... 1 X 8'
RULES='0 2 A
2 3 B
3 1 C
0 4 D
4 5 E
5 1 F
0 6 G
6 7 H
7 1 I
1 2 A
1 4 D
1 6 G
0 8 X
1 8 X
8 x'
parse GOTTED_RULES "$INPUT" && :; RC="$?"  # intentionally unquoted
is "$RC"           '0'      'Return value'
is "$_DEBUG_LEVEL" "$LEVEL" "Bracket level: '$INPUT'"
is "$_DEBUG_GROUP" "$GROUP" "Group numbers: '$INPUT'"
is "$_DEBUG_STATE" "$STATE" "State numbers: '$INPUT'"
is "$GOTTED_RULES" "$RULES"         "Rules: '$INPUT'"
unset INPUT LEVEL GROUP STATE RULES GOTTED_RULES RC

title 'parse `A`'
INPUT='  A'
LEVEL='0 A 0'
GROUP='0 A 0'
STATE='0 A 1'
RULES='0 1 A
1 x'
parse GOTTED_RULES "$INPUT" && :; RC="$?"  # intentionally unquoted
is "$RC"           '0'      'Return value'
is "$_DEBUG_LEVEL" "$LEVEL" "Bracket level: '$INPUT'"
is "$_DEBUG_GROUP" "$GROUP" "Group numbers: '$INPUT'"
is "$_DEBUG_STATE" "$STATE" "State numbers: '$INPUT'"
is "$GOTTED_RULES" "$RULES"         "Rules: '$INPUT'"
unset INPUT LEVEL GROUP STATE RULES GOTTED_RULES RC

title 'parse `A B`'
INPUT='  A   B'
LEVEL='0 A 0 B 0'
GROUP='0 A 0 B 0'
STATE='0 A 1 B 2'
RULES='0 1 A
1 2 B
2 x'
parse GOTTED_RULES "$INPUT" && :; RC="$?"  # intentionally unquoted
is "$RC"           '0'      'Return value'
is "$_DEBUG_LEVEL" "$LEVEL" "Bracket level: '$INPUT'"
is "$_DEBUG_GROUP" "$GROUP" "Group numbers: '$INPUT'"
is "$_DEBUG_STATE" "$STATE" "State numbers: '$INPUT'"
is "$GOTTED_RULES" "$RULES"         "Rules: '$INPUT'"
unset INPUT LEVEL GROUP STATE RULES GOTTED_RULES RC

title 'parse `(A B)`'
INPUT='  (   A   B   )'
LEVEL='0 ( 1 A 1 B 1 ) 0'
GROUP='0 ( 1 A 1 B 1 ) 0'
STATE='0 ( 0 A 2 B 1 ) 1'
RULES='0 2 A
2 1 B
1 x'
parse GOTTED_RULES "$INPUT" && :; RC="$?"  # intentionally unquoted
is "$RC"           '0'      'Return value'
is "$_DEBUG_LEVEL" "$LEVEL" "Bracket level: '$INPUT'"
is "$_DEBUG_GROUP" "$GROUP" "Group numbers: '$INPUT'"
is "$_DEBUG_STATE" "$STATE" "State numbers: '$INPUT'"
is "$GOTTED_RULES" "$RULES"         "Rules: '$INPUT'"
unset INPUT LEVEL GROUP STATE RULES GOTTED_RULES RC

title 'parse `(A B)...`'
INPUT='  (   A   B   ) ...'
LEVEL='0 ( 1 A 1 B 1 ) 0 ... 0'
GROUP='0 ( 1 A 1 B 1 ) 0 ... 0'
STATE='0 ( 0 A 2 B 1 ) 1 ... 1'
RULES='0 2 A
2 1 B
1 2 A
1 x'
parse GOTTED_RULES "$INPUT" && :; RC="$?"  # intentionally unquoted
is "$RC"           '0'      'Return value'
is "$_DEBUG_LEVEL" "$LEVEL" "Bracket level: '$INPUT'"
is "$_DEBUG_GROUP" "$GROUP" "Group numbers: '$INPUT'"
is "$_DEBUG_STATE" "$STATE" "State numbers: '$INPUT'"
is "$GOTTED_RULES" "$RULES"         "Rules: '$INPUT'"
unset INPUT LEVEL GROUP STATE RULES GOTTED_RULES RC

title 'parse `(A) B`'
INPUT='  (   A   )   B'
LEVEL='0 ( 1 A 1 ) 0 B 0'
GROUP='0 ( 1 A 1 ) 0 B 0'
STATE='0 ( 0 A 1 ) 1 B 2'
RULES='0 1 A
1 2 B
2 x'
parse GOTTED_RULES "$INPUT" && :; RC="$?"  # intentionally unquoted
is "$RC"           '0'      'Return value'
is "$_DEBUG_LEVEL" "$LEVEL" "Bracket level: '$INPUT'"
is "$_DEBUG_GROUP" "$GROUP" "Group numbers: '$INPUT'"
is "$_DEBUG_STATE" "$STATE" "State numbers: '$INPUT'"
is "$GOTTED_RULES" "$RULES"         "Rules: '$INPUT'"
unset INPUT LEVEL GROUP STATE RULES GOTTED_RULES RC

title 'parse `(A...)...`'
# FIXME: '(X...)...' doesn't make sense. Should it be forbidden?
# (Right now two identical rules are generated, which is weird but okay.)
INPUT='  (   A   ...   )   ...'          # Does this make sense?
LEVEL='0 ( 1 A 1 ... 1 ) 0 ... 0'
GROUP='0 ( 1 A 1 ... 1 ) 0 ... 0'
STATE='0 ( 0 A 1 ... 1 ) 1 ... 1'
RULES='0 1 A
1 1 A
1 1 A
1 x'
parse GOTTED_RULES "$INPUT" && :; RC="$?"  # intentionally unquoted
is "$RC"           '0'      'Return value'
is "$_DEBUG_LEVEL" "$LEVEL" "Bracket level: '$INPUT'"
is "$_DEBUG_GROUP" "$GROUP" "Group numbers: '$INPUT'"
is "$_DEBUG_STATE" "$STATE" "State numbers: '$INPUT'"
is "$GOTTED_RULES" "$RULES"         "Rules: '$INPUT'"
unset INPUT LEVEL GROUP STATE RULES GOTTED_RULES RC

title 'parse `(A...|B)...`'
INPUT='  (   A   ...   |   B   )   ...'
LEVEL='0 ( 1 A 1 ... 1 | 1 B 1 ) 0 ... 0'
GROUP='0 ( 1 A 1 ... 1 | 1 B 1 ) 0 ... 0'
STATE='0 ( 0 A 1 ... 1 | 0 B 1 ) 1 ... 1'
RULES='0 1 A
1 1 A
0 1 B
1 1 A
1 1 B
1 x'
# One would expect these rules instead
# RULES='0 1 A
# 1 1 A
# 0 1 B
# 1 1 B
# 1 x'
parse GOTTED_RULES "$INPUT" && :; RC="$?"  # intentionally unquoted
is "$RC"           '0'      'Return value'
is "$_DEBUG_LEVEL" "$LEVEL" "Bracket level: '$INPUT'"
is "$_DEBUG_GROUP" "$GROUP" "Group numbers: '$INPUT'"
is "$_DEBUG_STATE" "$STATE" "State numbers: '$INPUT'"
is "$GOTTED_RULES" "$RULES"         "Rules: '$INPUT'"
unset INPUT LEVEL GROUP STATE RULES GOTTED_RULES RC

title 'parse `(A)... B`'
INPUT='  (   A   )   ...   B'
LEVEL='0 ( 1 A 1 ) 0 ... 0 B 0'
GROUP='0 ( 1 A 1 ) 0 ... 0 B 0'
STATE='0 ( 0 A 1 ) 1 ... 1 B 2'
RULES='0 1 A
1 1 A
1 2 B
2 x'
parse GOTTED_RULES "$INPUT" && :; RC="$?"  # intentionally unquoted
is "$RC"           '0'      'Return value'
is "$_DEBUG_LEVEL" "$LEVEL" "Bracket level: '$INPUT'"
is "$_DEBUG_GROUP" "$GROUP" "Group numbers: '$INPUT'"
is "$_DEBUG_STATE" "$STATE" "State numbers: '$INPUT'"
is "$GOTTED_RULES" "$RULES"         "Rules: '$INPUT'"
unset INPUT LEVEL GROUP STATE RULES GOTTED_RULES RC

title 'parse `A (B)`'
INPUT='  A   (   B   )'
LEVEL='0 A 0 ( 1 B 1 ) 0'
GROUP='0 A 0 ( 1 B 1 ) 0'
STATE='0 A 1 ( 1 B 2 ) 2'
RULES='0 1 A
1 2 B
2 x'
parse GOTTED_RULES "$INPUT" && :; RC="$?"  # intentionally unquoted
is "$RC"           '0'      'Return value'
is "$_DEBUG_LEVEL" "$LEVEL" "Bracket level: '$INPUT'"
is "$_DEBUG_GROUP" "$GROUP" "Group numbers: '$INPUT'"
is "$_DEBUG_STATE" "$STATE" "State numbers: '$INPUT'"
is "$GOTTED_RULES" "$RULES"         "Rules: '$INPUT'"
unset INPUT LEVEL GROUP STATE RULES GOTTED_RULES RC

title 'parse `A (B)...`'
INPUT='  A   (   B   ) ...'
LEVEL='0 A 0 ( 1 B 1 ) 0 ... 0'
GROUP='0 A 0 ( 1 B 1 ) 0 ... 0'
STATE='0 A 1 ( 1 B 2 ) 2 ... 2'
RULES='0 1 A
1 2 B
2 2 B
2 x'
parse GOTTED_RULES "$INPUT" && :; RC="$?"  # intentionally unquoted
is "$RC"           '0'      'Return value'
is "$_DEBUG_LEVEL" "$LEVEL" "Bracket level: '$INPUT'"
is "$_DEBUG_GROUP" "$GROUP" "Group numbers: '$INPUT'"
is "$_DEBUG_STATE" "$STATE" "State numbers: '$INPUT'"
is "$GOTTED_RULES" "$RULES"         "Rules: '$INPUT'"
unset INPUT LEVEL GROUP STATE RULES GOTTED_RULES RC

title 'parse `(A) (B)`'
INPUT='  (   A   )   (   B   )'
LEVEL='0 ( 1 A 1 ) 0 ( 1 B 1 ) 0'
GROUP='0 ( 1 A 1 ) 0 ( 2 B 2 ) 0'
STATE='0 ( 0 A 1 ) 1 ( 1 B 2 ) 2'
RULES='0 1 A
1 2 B
2 x'
parse GOTTED_RULES "$INPUT" && :; RC="$?"  # intentionally unquoted
is "$RC"           '0'      'Return value'
is "$_DEBUG_LEVEL" "$LEVEL" "Bracket level: '$INPUT'"
is "$_DEBUG_GROUP" "$GROUP" "Group numbers: '$INPUT'"
is "$_DEBUG_STATE" "$STATE" "State numbers: '$INPUT'"
is "$GOTTED_RULES" "$RULES"         "Rules: '$INPUT'"
unset INPUT LEVEL GROUP STATE RULES GOTTED_RULES RC

title 'parse `(A)... (B)`'
INPUT='  (   A   )   ...   (   B   )'
LEVEL='0 ( 1 A 1 ) 0 ... 0 ( 1 B 1 ) 0'
GROUP='0 ( 1 A 1 ) 0 ... 0 ( 2 B 2 ) 0'
STATE='0 ( 0 A 1 ) 1 ... 1 ( 1 B 2 ) 2'
RULES='0 1 A
1 1 A
1 2 B
2 x'
parse GOTTED_RULES "$INPUT" && :; RC="$?"  # intentionally unquoted
is "$RC"           '0'      'Return value'
is "$_DEBUG_LEVEL" "$LEVEL" "Bracket level: '$INPUT'"
is "$_DEBUG_GROUP" "$GROUP" "Group numbers: '$INPUT'"
is "$_DEBUG_STATE" "$STATE" "State numbers: '$INPUT'"
is "$GOTTED_RULES" "$RULES"         "Rules: '$INPUT'"
unset INPUT LEVEL GROUP STATE RULES GOTTED_RULES RC

title 'parse `(A) (B)...`'
INPUT='  (   A   )   (   B   )   ...'
LEVEL='0 ( 1 A 1 ) 0 ( 1 B 1 ) 0 ... 0'
GROUP='0 ( 1 A 1 ) 0 ( 2 B 2 ) 0 ... 0'
STATE='0 ( 0 A 1 ) 1 ( 1 B 2 ) 2 ... 2'
RULES='0 1 A
1 2 B
2 2 B
2 x'
parse GOTTED_RULES "$INPUT" && :; RC="$?"  # intentionally unquoted
is "$RC"           '0'      'Return value'
is "$_DEBUG_LEVEL" "$LEVEL" "Bracket level: '$INPUT'"
is "$_DEBUG_GROUP" "$GROUP" "Group numbers: '$INPUT'"
is "$_DEBUG_STATE" "$STATE" "State numbers: '$INPUT'"
is "$GOTTED_RULES" "$RULES"         "Rules: '$INPUT'"
unset INPUT LEVEL GROUP STATE RULES GOTTED_RULES RC

title 'parse `(A)... (B)...`'
INPUT='  (   A   )   ...   (   B   )   ...'
LEVEL='0 ( 1 A 1 ) 0 ... 0 ( 1 B 1 ) 0 ... 0'
GROUP='0 ( 1 A 1 ) 0 ... 0 ( 2 B 2 ) 0 ... 0'
STATE='0 ( 0 A 1 ) 1 ... 1 ( 1 B 2 ) 2 ... 2'
RULES='0 1 A
1 1 A
1 2 B
2 2 B
2 x'
parse GOTTED_RULES "$INPUT" && :; RC="$?"  # intentionally unquoted
is "$RC"           '0'      'Return value'
is "$_DEBUG_LEVEL" "$LEVEL" "Bracket level: '$INPUT'"
is "$_DEBUG_GROUP" "$GROUP" "Group numbers: '$INPUT'"
is "$_DEBUG_STATE" "$STATE" "State numbers: '$INPUT'"
is "$GOTTED_RULES" "$RULES"         "Rules: '$INPUT'"
unset INPUT LEVEL GROUP STATE RULES GOTTED_RULES RC

title 'parse `((A) B)`'
INPUT='  (   (   A   )   B   )'
LEVEL='0 ( 1 ( 2 A 2 ) 1 B 1 ) 0'
GROUP='0 ( 1 ( 2 A 2 ) 1 B 1 ) 0'
STATE='0 ( 0 ( 0 A 2 ) 2 B 1 ) 1'
RULES='0 2 A
2 1 B
1 x'
parse GOTTED_RULES "$INPUT" && :; RC="$?"  # intentionally unquoted
is "$RC"           '0'      'Return value'
is "$_DEBUG_LEVEL" "$LEVEL" "Bracket level: '$INPUT'"
is "$_DEBUG_GROUP" "$GROUP" "Group numbers: '$INPUT'"
is "$_DEBUG_STATE" "$STATE" "State numbers: '$INPUT'"
is "$GOTTED_RULES" "$RULES"         "Rules: '$INPUT'"
unset INPUT LEVEL GROUP STATE RULES GOTTED_RULES RC

title 'parse `(A (B))`'
INPUT='  (   A   (   B   )   )'
LEVEL='0 ( 1 A 1 ( 2 B 2 ) 1 ) 0'
GROUP='0 ( 1 A 1 ( 2 B 2 ) 1 ) 0'
STATE='0 ( 0 A 2 ( 2 B 3 ) 3 ) 3'              # (state 1 never used)
RULES='0 2 A
2 3 B
3 x'
parse GOTTED_RULES "$INPUT" && :; RC="$?"  # intentionally unquoted
is "$RC"           '0'      'Return value'
is "$_DEBUG_LEVEL" "$LEVEL" "Bracket level: '$INPUT'"
is "$_DEBUG_GROUP" "$GROUP" "Group numbers: '$INPUT'"
is "$_DEBUG_STATE" "$STATE" "State numbers: '$INPUT'"
is "$GOTTED_RULES" "$RULES"         "Rules: '$INPUT'"
unset INPUT LEVEL GROUP STATE RULES GOTTED_RULES RC

title 'parse `(A (B (C)))`'
INPUT='  (   A   (   B   (   C   )   )   )'
LEVEL='0 ( 1 A 1 ( 2 B 2 ( 3 C 3 ) 2 ) 1 ) 0'
GROUP='0 ( 1 A 1 ( 2 B 2 ( 3 C 3 ) 2 ) 1 ) 0'
STATE='0 ( 0 A 2 ( 2 B 4 ( 4 C 5 ) 5 ) 5 ) 5'  # (state 1 & 3 never used)
RULES='0 2 A
2 4 B
4 5 C
5 x'
parse GOTTED_RULES "$INPUT" && :; RC="$?"  # intentionally unquoted
is "$RC"           '0'      'Return value'
is "$_DEBUG_LEVEL" "$LEVEL" "Bracket level: '$INPUT'"
is "$_DEBUG_GROUP" "$GROUP" "Group numbers: '$INPUT'"
is "$_DEBUG_STATE" "$STATE" "State numbers: '$INPUT'"
is "$GOTTED_RULES" "$RULES"         "Rules: '$INPUT'"
unset INPUT LEVEL GROUP STATE RULES GOTTED_RULES RC

title 'parse `(A B C|D E F|G H I) X`'
INPUT='  (   A   B   C   |   D   E   F   |   G   H   I   )   X'
LEVEL='0 ( 1 A 1 B 1 C 1 | 1 D 1 E 1 F 1 | 1 G 1 H 1 I 1 ) 0 X 0'
GROUP='0 ( 1 A 1 B 1 C 1 | 1 D 1 E 1 F 1 | 1 G 1 H 1 I 1 ) 0 X 0'
STATE='0 ( 0 A 2 B 3 C 1 | 0 D 4 E 5 F 1 | 0 G 6 H 7 I 1 ) 1 X 8'
RULES='0 2 A
2 3 B
3 1 C
0 4 D
4 5 E
5 1 F
0 6 G
6 7 H
7 1 I
1 8 X
8 x'
parse GOTTED_RULES "$INPUT" && :; RC="$?"  # intentionally unquoted
is "$RC"           '0'      'Return value'
is "$_DEBUG_LEVEL" "$LEVEL" "Bracket level: '$INPUT'"
is "$_DEBUG_GROUP" "$GROUP" "Group numbers: '$INPUT'"
is "$_DEBUG_STATE" "$STATE" "State numbers: '$INPUT'"
is "$GOTTED_RULES" "$RULES"         "Rules: '$INPUT'"
unset INPUT LEVEL GROUP STATE RULES GOTTED_RULES RC

title 'parse `[A B C|D E F|G H I] X`'
INPUT='  [   A   B   C   |   D   E   F   |   G   H   I   ]   X'
LEVEL='0 [ 1 A 1 B 1 C 1 | 1 D 1 E 1 F 1 | 1 G 1 H 1 I 1 ] 0 X 0'
GROUP='0 [ 1 A 1 B 1 C 1 | 1 D 1 E 1 F 1 | 1 G 1 H 1 I 1 ] 0 X 0'
STATE='0 [ 0 A 2 B 3 C 1 | 0 D 4 E 5 F 1 | 0 G 6 H 7 I 1 ] 1 X 8'
RULES='0 2 A
2 3 B
3 1 C
0 4 D
4 5 E
5 1 F
0 6 G
6 7 H
7 1 I
0 8 X
1 8 X
8 x'
parse GOTTED_RULES "$INPUT" && :; RC="$?"  # intentionally unquoted
is "$RC"           '0'      'Return value'
is "$_DEBUG_LEVEL" "$LEVEL" "Bracket level: '$INPUT'"
is "$_DEBUG_GROUP" "$GROUP" "Group numbers: '$INPUT'"
is "$_DEBUG_STATE" "$STATE" "State numbers: '$INPUT'"
is "$GOTTED_RULES" "$RULES"         "Rules: '$INPUT'"
unset INPUT LEVEL GROUP STATE RULES GOTTED_RULES RC

title 'parse `[A B C|D E F|G H I]... X`'
INPUT='  [   A   B   C   |   D   E   F   |   G   H   I   ]   ...   X'
LEVEL='0 [ 1 A 1 B 1 C 1 | 1 D 1 E 1 F 1 | 1 G 1 H 1 I 1 ] 0 ... 0 X 0'
GROUP='0 [ 1 A 1 B 1 C 1 | 1 D 1 E 1 F 1 | 1 G 1 H 1 I 1 ] 0 ... 0 X 0'
STATE='0 [ 0 A 2 B 3 C 1 | 0 D 4 E 5 F 1 | 0 G 6 H 7 I 1 ] 1 ... 1 X 8'
RULES='0 2 A
2 3 B
3 1 C
0 4 D
4 5 E
5 1 F
0 6 G
6 7 H
7 1 I
1 2 A
1 4 D
1 6 G
0 8 X
1 8 X
8 x'
parse GOTTED_RULES "$INPUT" && :; RC="$?"  # intentionally unquoted
is "$RC"           '0'      'Return value'
is "$_DEBUG_LEVEL" "$LEVEL" "Bracket level: '$INPUT'"
is "$_DEBUG_GROUP" "$GROUP" "Group numbers: '$INPUT'"
is "$_DEBUG_STATE" "$STATE" "State numbers: '$INPUT'"
is "$GOTTED_RULES" "$RULES"         "Rules: '$INPUT'"
unset INPUT LEVEL GROUP STATE RULES GOTTED_RULES RC

title 'parse `(A)`'
INPUT='  (   A   )'
LEVEL='0 ( 1 A 1 ) 0'
GROUP='0 ( 1 A 1 ) 0'
STATE='0 ( 0 A 1 ) 1'
RULES='0 1 A
1 x'
parse GOTTED_RULES "$INPUT" && :; RC="$?"  # intentionally unquoted
is "$RC"           '0'      'Return value'
is "$_DEBUG_LEVEL" "$LEVEL" "Bracket level: '$INPUT'"
is "$_DEBUG_GROUP" "$GROUP" "Group numbers: '$INPUT'"
is "$_DEBUG_STATE" "$STATE" "State numbers: '$INPUT'"
is "$GOTTED_RULES" "$RULES"         "Rules: '$INPUT'"
unset INPUT LEVEL GROUP STATE RULES GOTTED_RULES RC

title 'parse `((A B))`'
INPUT='  (   (   A   B   )   )'
LEVEL='0 ( 1 ( 2 A 2 B 2 ) 1 ) 0'
GROUP='0 ( 1 ( 2 A 2 B 2 ) 1 ) 0'
STATE='0 ( 0 ( 0 A 3 B 2 ) 2 ) 2'
RULES='0 3 A
3 2 B
2 x'
parse GOTTED_RULES "$INPUT" && :; RC="$?"  # intentionally unquoted
is "$RC"           '0'      'Return value'
is "$_DEBUG_LEVEL" "$LEVEL" "Bracket level: '$INPUT'"
is "$_DEBUG_GROUP" "$GROUP" "Group numbers: '$INPUT'"
is "$_DEBUG_STATE" "$STATE" "State numbers: '$INPUT'"
is "$GOTTED_RULES" "$RULES"         "Rules: '$INPUT'"
unset INPUT LEVEL GROUP STATE RULES GOTTED_RULES RC

title 'parse `[A]`'
INPUT='  [   A   ]'
LEVEL='0 [ 1 A 1 ] 0'
GROUP='0 [ 1 A 1 ] 0'
STATE='0 [ 0 A 1 ] 1'
RULES='0 1 A
0 x
1 x'
parse GOTTED_RULES "$INPUT" && :; RC="$?"  # intentionally unquoted
is "$RC"           '0'      'Return value'
is "$_DEBUG_LEVEL" "$LEVEL" "Bracket level: '$INPUT'"
is "$_DEBUG_GROUP" "$GROUP" "Group numbers: '$INPUT'"
is "$_DEBUG_STATE" "$STATE" "State numbers: '$INPUT'"
is "$GOTTED_RULES" "$RULES"         "Rules: '$INPUT'"
unset INPUT LEVEL GROUP STATE RULES GOTTED_RULES RC

title 'parse `(A|B)`'
INPUT='  (   A   |   B   )'
LEVEL='0 ( 1 A 1 | 1 B 1 ) 0'
GROUP='0 ( 1 A 1 | 1 B 1 ) 0'
STATE='0 ( 0 A 1 | 0 B 1 ) 1'
RULES='0 1 A
0 1 B
1 x'
parse GOTTED_RULES "$INPUT" && :; RC="$?"  # intentionally unquoted
is "$RC"           '0'      'Return value'
is "$_DEBUG_LEVEL" "$LEVEL" "Bracket level: '$INPUT'"
is "$_DEBUG_GROUP" "$GROUP" "Group numbers: '$INPUT'"
is "$_DEBUG_STATE" "$STATE" "State numbers: '$INPUT'"
is "$GOTTED_RULES" "$RULES"         "Rules: '$INPUT'"
unset INPUT LEVEL GROUP STATE RULES GOTTED_RULES RC

title 'parse `(A|B)...`'
INPUT='  (   A   |   B   )   ...'
LEVEL='0 ( 1 A 1 | 1 B 1 ) 0 ... 0'
GROUP='0 ( 1 A 1 | 1 B 1 ) 0 ... 0'
STATE='0 ( 0 A 1 | 0 B 1 ) 1 ... 1'
RULES='0 1 A
0 1 B
1 1 A
1 1 B
1 x'
parse GOTTED_RULES "$INPUT" && :; RC="$?"  # intentionally unquoted
is "$RC"           '0'      'Return value'
is "$_DEBUG_LEVEL" "$LEVEL" "Bracket level: '$INPUT'"
is "$_DEBUG_GROUP" "$GROUP" "Group numbers: '$INPUT'"
is "$_DEBUG_STATE" "$STATE" "State numbers: '$INPUT'"
is "$GOTTED_RULES" "$RULES"         "Rules: '$INPUT'"
unset INPUT LEVEL GROUP STATE RULES GOTTED_RULES RC

title 'parse `A... B`'
INPUT='  A   ...   B'
LEVEL='0 A 0 ... 0 B 0'
GROUP='0 A 0 ... 0 B 0'
STATE='0 A 1 ... 1 B 2'
RULES='0 1 A
1 1 A
1 2 B
2 x'
parse GOTTED_RULES "$INPUT" && :; RC="$?"  # intentionally unquoted
is "$RC"           '0'      'Return value'
is "$_DEBUG_LEVEL" "$LEVEL" "Bracket level: '$INPUT'"
is "$_DEBUG_GROUP" "$GROUP" "Group numbers: '$INPUT'"
is "$_DEBUG_STATE" "$STATE" "State numbers: '$INPUT'"
is "$GOTTED_RULES" "$RULES"         "Rules: '$INPUT'"
unset INPUT LEVEL GROUP STATE RULES GOTTED_RULES RC

title 'parse `(A)... B`'
INPUT='  (   A   ) ... B'
LEVEL='0 ( 1 A 1 ) 0 ... 0 B 0'
GROUP='0 ( 1 A 1 ) 0 ... 0 B 0'
STATE='0 ( 0 A 1 ) 1 ... 1 B 2'
RULES='0 1 A
1 1 A
1 2 B
2 x'
parse GOTTED_RULES "$INPUT" && :; RC="$?"  # intentionally unquoted
is "$RC"           '0'      'Return value'
is "$_DEBUG_LEVEL" "$LEVEL" "Bracket level: '$INPUT'"
is "$_DEBUG_GROUP" "$GROUP" "Group numbers: '$INPUT'"
is "$_DEBUG_STATE" "$STATE" "State numbers: '$INPUT'"
is "$GOTTED_RULES" "$RULES"         "Rules: '$INPUT'"
unset INPUT LEVEL GROUP STATE RULES GOTTED_RULES RC

title 'parse `(A B)...`'
INPUT='  (   A   B   )   ...'
LEVEL='0 ( 1 A 1 B 1 ) 0 ... 0'
GROUP='0 ( 1 A 1 B 1 ) 0 ... 0'
STATE='0 ( 0 A 2 B 1 ) 1 ... 1'
RULES='0 2 A
2 1 B
1 2 A
1 x'
parse GOTTED_RULES "$INPUT" && :; RC="$?"  # intentionally unquoted
is "$RC"           '0'      'Return value'
is "$_DEBUG_LEVEL" "$LEVEL" "Bracket level: '$INPUT'"
is "$_DEBUG_GROUP" "$GROUP" "Group numbers: '$INPUT'"
is "$_DEBUG_STATE" "$STATE" "State numbers: '$INPUT'"
is "$GOTTED_RULES" "$RULES"         "Rules: '$INPUT'"
unset INPUT LEVEL GROUP STATE RULES GOTTED_RULES RC

title 'parse `(A) (B)`'
INPUT='  (   A   )   (   B   )'
LEVEL='0 ( 1 A 1 ) 0 ( 1 B 1 ) 0'
GROUP='0 ( 1 A 1 ) 0 ( 2 B 2 ) 0'
STATE='0 ( 0 A 1 ) 1 ( 1 B 2 ) 2'
RULES='0 1 A
1 2 B
2 x'
parse GOTTED_RULES "$INPUT" && :; RC="$?"  # intentionally unquoted
is "$RC"           '0'      'Return value'
is "$_DEBUG_LEVEL" "$LEVEL" "Bracket level: '$INPUT'"
is "$_DEBUG_GROUP" "$GROUP" "Group numbers: '$INPUT'"
is "$_DEBUG_STATE" "$STATE" "State numbers: '$INPUT'"
is "$GOTTED_RULES" "$RULES"         "Rules: '$INPUT'"
unset INPUT LEVEL GROUP STATE RULES GOTTED_RULES RC

title 'parse `(A) (B)...`'
INPUT='  (   A   )   (   B   )   ...'
LEVEL='0 ( 1 A 1 ) 0 ( 1 B 1 ) 0 ... 0'
GROUP='0 ( 1 A 1 ) 0 ( 2 B 2 ) 0 ... 0'
STATE='0 ( 0 A 1 ) 1 ( 1 B 2 ) 2 ... 2'
RULES='0 1 A
1 2 B
2 2 B
2 x'
parse GOTTED_RULES "$INPUT" && :; RC="$?"  # intentionally unquoted
is "$RC"           '0'      'Return value'
is "$_DEBUG_LEVEL" "$LEVEL" "Bracket level: '$INPUT'"
is "$_DEBUG_GROUP" "$GROUP" "Group numbers: '$INPUT'"
is "$_DEBUG_STATE" "$STATE" "State numbers: '$INPUT'"
is "$GOTTED_RULES" "$RULES"         "Rules: '$INPUT'"
unset INPUT LEVEL GROUP STATE RULES GOTTED_RULES RC

title 'parse `(A (B))...`'
INPUT='  (   A   (   B   )   )   ...'
LEVEL='0 ( 1 A 1 ( 2 B 2 ) 1 ) 0 ... 0'
GROUP='0 ( 1 A 1 ( 2 B 2 ) 1 ) 0 ... 0'
STATE='0 ( 0 A 2 ( 2 B 3 ) 3 ) 3 ... 3'
RULES='0 2 A
2 3 B
3 2 A
3 x'
parse GOTTED_RULES "$INPUT" && :; RC="$?"  # intentionally unquoted
is "$RC"           '0'      'Return value'
is "$_DEBUG_LEVEL" "$LEVEL" "Bracket level: '$INPUT'"
is "$_DEBUG_GROUP" "$GROUP" "Group numbers: '$INPUT'"
is "$_DEBUG_STATE" "$STATE" "State numbers: '$INPUT'"
is "$GOTTED_RULES" "$RULES"         "Rules: '$INPUT'"
unset INPUT LEVEL GROUP STATE RULES GOTTED_RULES RC

title 'parse `((A) B)...`'
INPUT='  (   (   A   )   B   )   ...'
LEVEL='0 ( 1 ( 2 A 2 ) 1 B 1 ) 0 ... 0'
GROUP='0 ( 1 ( 2 A 2 ) 1 B 1 ) 0 ... 0'
STATE='0 ( 0 ( 0 A 2 ) 2 B 1 ) 1 ... 1'
RULES='0 2 A
2 1 B
1 2 A
1 x'
parse GOTTED_RULES "$INPUT" && :; RC="$?"  # intentionally unquoted
is "$RC"           '0'      'Return value'
is "$_DEBUG_LEVEL" "$LEVEL" "Bracket level: '$INPUT'"
is "$_DEBUG_GROUP" "$GROUP" "Group numbers: '$INPUT'"
is "$_DEBUG_STATE" "$STATE" "State numbers: '$INPUT'"
is "$GOTTED_RULES" "$RULES"         "Rules: '$INPUT'"
unset INPUT LEVEL GROUP STATE RULES GOTTED_RULES RC

title 'parse `(((A) B) C)...`'
INPUT='  (   (   (   A   )   B   )   C   )   ...'
LEVEL='0 ( 1 ( 2 ( 3 A 3 ) 2 B 2 ) 1 C 1 ) 0 ... 0'
GROUP='0 ( 1 ( 2 ( 3 A 3 ) 2 B 2 ) 1 C 1 ) 0 ... 0'
STATE='0 ( 0 ( 0 ( 0 A 3 ) 3 B 2 ) 2 C 1 ) 1 ... 1'
RULES='0 3 A
3 2 B
2 1 C
1 3 A
1 x'
parse GOTTED_RULES "$INPUT" && :; RC="$?"  # intentionally unquoted
is "$RC"           '0'      'Return value'
is "$_DEBUG_LEVEL" "$LEVEL" "Bracket level: '$INPUT'"
is "$_DEBUG_GROUP" "$GROUP" "Group numbers: '$INPUT'"
is "$_DEBUG_STATE" "$STATE" "State numbers: '$INPUT'"
is "$GOTTED_RULES" "$RULES"         "Rules: '$INPUT'"
unset INPUT LEVEL GROUP STATE RULES GOTTED_RULES RC

title 'parse `(((A)... B) C)...`'
INPUT='  (   (   (   A   )   ...   B   )   C   )   ...'
LEVEL='0 ( 1 ( 2 ( 3 A 3 ) 2 ... 2 B 2 ) 1 C 1 ) 0 ... 0'
GROUP='0 ( 1 ( 2 ( 3 A 3 ) 2 ... 2 B 2 ) 1 C 1 ) 0 ... 0'
STATE='0 ( 0 ( 0 ( 0 A 3 ) 3 ... 3 B 2 ) 2 C 1 ) 1 ... 1'
RULES='0 3 A
3 3 A
3 2 B
2 1 C
1 3 A
1 x'
parse GOTTED_RULES "$INPUT" && :; RC="$?"  # intentionally unquoted
is "$RC"           '0'      'Return value'
is "$_DEBUG_LEVEL" "$LEVEL" "Bracket level: '$INPUT'"
is "$_DEBUG_GROUP" "$GROUP" "Group numbers: '$INPUT'"
is "$_DEBUG_STATE" "$STATE" "State numbers: '$INPUT'"
is "$GOTTED_RULES" "$RULES"         "Rules: '$INPUT'"
unset INPUT LEVEL GROUP STATE RULES GOTTED_RULES RC

title 'parse `((A)... B)`'
INPUT='  (   (   A   )   ...   B   )'
LEVEL='0 ( 1 ( 2 A 2 ) 1 ... 1 B 1 ) 0'
GROUP='0 ( 1 ( 2 A 2 ) 1 ... 1 B 1 ) 0'
STATE='0 ( 0 ( 0 A 2 ) 2 ... 2 B 1 ) 1'
RULES='0 2 A
2 2 A
2 1 B
1 x'
parse GOTTED_RULES "$INPUT" && :; RC="$?"  # intentionally unquoted
is "$RC"           '0'      'Return value'
is "$_DEBUG_LEVEL" "$LEVEL" "Bracket level: '$INPUT'"
is "$_DEBUG_GROUP" "$GROUP" "Group numbers: '$INPUT'"
is "$_DEBUG_STATE" "$STATE" "State numbers: '$INPUT'"
is "$GOTTED_RULES" "$RULES"         "Rules: '$INPUT'"
unset INPUT LEVEL GROUP STATE RULES GOTTED_RULES RC

title 'parse `((A)... B)...`'
INPUT='  (   (   A   )   ...   B   )   ...'
LEVEL='0 ( 1 ( 2 A 2 ) 1 ... 1 B 1 ) 0 ... 0'
GROUP='0 ( 1 ( 2 A 2 ) 1 ... 1 B 1 ) 0 ... 0'
STATE='0 ( 0 ( 0 A 2 ) 2 ... 2 B 1 ) 1 ... 1'
RULES='0 2 A
2 2 A
2 1 B
1 2 A
1 x'
parse GOTTED_RULES "$INPUT" && :; RC="$?"  # intentionally unquoted
is "$RC"           '0'      'Return value'
is "$_DEBUG_LEVEL" "$LEVEL" "Bracket level: '$INPUT'"
is "$_DEBUG_GROUP" "$GROUP" "Group numbers: '$INPUT'"
is "$_DEBUG_STATE" "$STATE" "State numbers: '$INPUT'"
is "$GOTTED_RULES" "$RULES"         "Rules: '$INPUT'"
unset INPUT LEVEL GROUP STATE RULES GOTTED_RULES RC

title 'parse `(A (B (C)))...`'
INPUT='  (   A   (   B   (   C   )   )   )   ...'
LEVEL='0 ( 1 A 1 ( 2 B 2 ( 3 C 3 ) 2 ) 1 ) 0 ... 0'
GROUP='0 ( 1 A 1 ( 2 B 2 ( 3 C 3 ) 2 ) 1 ) 0 ... 0'
STATE='0 ( 0 A 2 ( 2 B 4 ( 4 C 5 ) 5 ) 5 ) 5 ... 5'
RULES='0 2 A
2 4 B
4 5 C
5 2 A
5 x'
parse GOTTED_RULES "$INPUT" && :; RC="$?"  # intentionally unquoted
is "$RC"           '0'      'Return value'
is "$_DEBUG_LEVEL" "$LEVEL" "Bracket level: '$INPUT'"
is "$_DEBUG_GROUP" "$GROUP" "Group numbers: '$INPUT'"
is "$_DEBUG_STATE" "$STATE" "State numbers: '$INPUT'"
is "$GOTTED_RULES" "$RULES"         "Rules: '$INPUT'"
unset INPUT LEVEL GROUP STATE RULES GOTTED_RULES RC

######################################################################

title 'parse `(A B C|D E F|G H I)`: Tests from Images of Finite State Automaton (4 tests)'
INPUT='  (   A   B   C   |   D   E   F   |   G   H   I   )'
LEVEL='0 ( 1 A 1 B 1 C 1 | 1 D 1 E 1 F 1 | 1 G 1 H 1 I 1 ) 0'
GROUP='0 ( 1 A 1 B 1 C 1 | 1 D 1 E 1 F 1 | 1 G 1 H 1 I 1 ) 0'
STATE='0 ( 0 A 2 B 3 C 1 | 0 D 4 E 5 F 1 | 0 G 6 H 7 I 1 ) 1'
RULES='0 2 A
2 3 B
3 1 C
0 4 D
4 5 E
5 1 F
0 6 G
6 7 H
7 1 I
1 x'
parse GOTTED_RULES "$INPUT" && :; RC="$?"  # intentionally unquoted
is "$RC"           '0'      'Return value'
is "$_DEBUG_LEVEL" "$LEVEL" "Bracket level: '$INPUT'"
is "$_DEBUG_GROUP" "$GROUP" "Group numbers: '$INPUT'"
is "$_DEBUG_STATE" "$STATE" "State numbers: '$INPUT'"
is "$GOTTED_RULES" "$RULES"         "Rules: '$INPUT'"
unset INPUT LEVEL GROUP STATE RULES GOTTED_RULES RC

title 'parse `[A B C|D E F|G H I]`: Tests from Images of Finite State Automaton (4 tests)'
INPUT='  [   A   B   C   |   D   E   F   |   G   H   I   ]'
LEVEL='0 [ 1 A 1 B 1 C 1 | 1 D 1 E 1 F 1 | 1 G 1 H 1 I 1 ] 0'
GROUP='0 [ 1 A 1 B 1 C 1 | 1 D 1 E 1 F 1 | 1 G 1 H 1 I 1 ] 0'
STATE='0 [ 0 A 2 B 3 C 1 | 0 D 4 E 5 F 1 | 0 G 6 H 7 I 1 ] 1'
RULES='0 2 A
2 3 B
3 1 C
0 4 D
4 5 E
5 1 F
0 6 G
6 7 H
7 1 I
0 x
1 x'
parse GOTTED_RULES "$INPUT" && :; RC="$?"  # intentionally unquoted
is "$RC"           '0'      'Return value'
is "$_DEBUG_LEVEL" "$LEVEL" "Bracket level: '$INPUT'"
is "$_DEBUG_GROUP" "$GROUP" "Group numbers: '$INPUT'"
is "$_DEBUG_STATE" "$STATE" "State numbers: '$INPUT'"
is "$GOTTED_RULES" "$RULES"         "Rules: '$INPUT'"
unset INPUT LEVEL GROUP STATE RULES GOTTED_RULES RC

title 'parse `(A B C|D E F|G H I)...`: Tests from Images of Finite State Automaton (4 tests)'
INPUT='  (   A   B   C   |   D   E   F   |   G   H   I   )   ...'
LEVEL='0 ( 1 A 1 B 1 C 1 | 1 D 1 E 1 F 1 | 1 G 1 H 1 I 1 ) 0 ... 0'
GROUP='0 ( 1 A 1 B 1 C 1 | 1 D 1 E 1 F 1 | 1 G 1 H 1 I 1 ) 0 ... 0'
STATE='0 ( 0 A 2 B 3 C 1 | 0 D 4 E 5 F 1 | 0 G 6 H 7 I 1 ) 1 ... 1'
RULES='0 2 A
2 3 B
3 1 C
0 4 D
4 5 E
5 1 F
0 6 G
6 7 H
7 1 I
1 2 A
1 4 D
1 6 G
1 x'
parse GOTTED_RULES "$INPUT" && :; RC="$?"  # intentionally unquoted
is "$RC"           '0'      'Return value'
is "$_DEBUG_LEVEL" "$LEVEL" "Bracket level: '$INPUT'"
is "$_DEBUG_GROUP" "$GROUP" "Group numbers: '$INPUT'"
is "$_DEBUG_STATE" "$STATE" "State numbers: '$INPUT'"
is "$GOTTED_RULES" "$RULES"         "Rules: '$INPUT'"
unset INPUT LEVEL GROUP STATE RULES GOTTED_RULES RC

cd "$(mktemp -d)"
title 'parse `[A B C|D E F|G H I]...`: Tests from Images of Finite State Automaton (4 tests)'
INPUT='  [   A   B   C   |   D   E   F   |   G   H   I   ] ...'
LEVEL='0 [ 1 A 1 B 1 C 1 | 1 D 1 E 1 F 1 | 1 G 1 H 1 I 1 ] 0 ... 0'
GROUP='0 [ 1 A 1 B 1 C 1 | 1 D 1 E 1 F 1 | 1 G 1 H 1 I 1 ] 0 ... 0'
STATE='0 [ 0 A 2 B 3 C 1 | 0 D 4 E 5 F 1 | 0 G 6 H 7 I 1 ] 1 ... 1'
RULES='0 2 A
2 3 B
3 1 C
0 4 D
4 5 E
5 1 F
0 6 G
6 7 H
7 1 I
1 2 A
1 4 D
1 6 G
0 x
1 x'
dumpenv \
    _DEBUG_STATE _DEBUG_GROUP _DEBUG_LEVEL \
    INPUT LEVEL GROUP STATE \
    GOTTED_RULES RC TESTS_COUNT TEST_OUT FAILED_TESTS TMPNUM \
    >env1.txt # expect
parse GOTTED_RULES "$INPUT" && :; RC="$?"  # intentionally unquoted
dumpenv \
    _DEBUG_STATE _DEBUG_GROUP _DEBUG_LEVEL \
    INPUT LEVEL GROUP STATE \
    GOTTED_RULES RC TESTS_COUNT TEST_OUT FAILED_TESTS TMPNUM \
    >env2.txt # got
is "$RC"           '0'      'Return value'
is "$_DEBUG_LEVEL" "$LEVEL" "Bracket level: '$INPUT'"
is "$_DEBUG_GROUP" "$GROUP" "Group numbers: '$INPUT'"
is "$_DEBUG_STATE" "$STATE" "State numbers: '$INPUT'"
is "$GOTTED_RULES" "$RULES"         "Rules: '$INPUT'"
is_same_env : "Variable leakage: '$INPUT'" 3<env1.txt 4<env2.txt
unset INPUT LEVEL GROUP STATE RULES GOTTED_RULES RC

cd "$(mktemp -d)"
title 'parse `(A|B...)`: `...` (after word) inside end of parentheses'
INPUT='  (   A   |   B   ...   )'
LEVEL='0 ( 1 A 1 | 1 B 1 ... 1 ) 0'
GROUP='0 ( 1 A 1 | 1 B 1 ... 1 ) 0'
STATE='0 ( 0 A 1 | 0 B 1 ... 1 ) 1'
RULES="0 1 A
0 1 B
1 1 B
1 x"
dumpenv \
    _DEBUG_STATE _DEBUG_GROUP _DEBUG_LEVEL \
    INPUT LEVEL GROUP STATE \
    GOTTED_RULES RC TESTS_COUNT TEST_OUT FAILED_TESTS TMPNUM \
    > env1.txt # expect
parse GOTTED_RULES "$INPUT" && :; RC="$?"  # intentionally unquoted
dumpenv \
    _DEBUG_STATE _DEBUG_GROUP _DEBUG_LEVEL \
    INPUT LEVEL GROUP STATE \
    GOTTED_RULES RC TESTS_COUNT TEST_OUT FAILED_TESTS TMPNUM \
    >env2.txt # got
is "$RC"           '0'      'Return value'
is "$_DEBUG_LEVEL" "$LEVEL" "Bracket level: '$INPUT'"
is "$_DEBUG_GROUP" "$GROUP" "Group numbers: '$INPUT'"
is "$_DEBUG_STATE" "$STATE" "State numbers: '$INPUT'"
is "$GOTTED_RULES" "$RULES"         "Rules: '$INPUT'"
is_same_env : "Variable leakage: '$INPUT'" 3<env1.txt 4<env2.txt
unset INPUT LEVEL GROUP STATE RULES GOTTED_RULES RC

cd "$(mktemp -d)"
title 'parse `(A|(B)...)`: `...` (after paren group) inside end of parentheses'
INPUT='  (   A   |   (   B   )   ...   )'
LEVEL='0 ( 1 A 1 | 1 ( 2 B 2 ) 1 ... 1 ) 0'
GROUP='0 ( 1 A 1 | 1 ( 2 B 2 ) 1 ... 1 ) 0'
STATE='0 ( 0 A 1 | 0 ( 0 B 2 ) 2 ... 2 ) 2'       # <-- FIXME Expected BAD result
#STATE='0 ( 0 A 1 | 0 ( 0 B 1 ) 1 ... 1 ) 1'      #     DESIRED result
RULES="0 1 A
0 1 B
1 1 B
1 x"
dumpenv \
    _DEBUG_STATE _DEBUG_GROUP _DEBUG_LEVEL \
    INPUT LEVEL GROUP STATE \
    GOTTED_RULES RC TESTS_COUNT TEST_OUT FAILED_TESTS TMPNUM \
    > env1.txt # expect
parse GOTTED_RULES "$INPUT" && :; RC="$?"  # intentionally unquoted
dumpenv \
    _DEBUG_STATE _DEBUG_GROUP _DEBUG_LEVEL \
    INPUT LEVEL GROUP STATE \
    GOTTED_RULES RC TESTS_COUNT TEST_OUT FAILED_TESTS TMPNUM \
    >env2.txt # got
is "$RC"           '0'      'Return value'
is "$_DEBUG_LEVEL" "$LEVEL" "Bracket level: '$INPUT'"
is "$_DEBUG_GROUP" "$GROUP" "Group numbers: '$INPUT'"
is "$_DEBUG_STATE" "$STATE" "State numbers: '$INPUT'"
#is "$GOTTED_RULES" "$RULES"         "Rules: '$INPUT'"
is_same_env : "Variable leakage: '$INPUT'" 3<env1.txt 4<env2.txt
unset INPUT LEVEL GROUP STATE RULES GOTTED_RULES RC

cd "$(mktemp -d)"
title 'parse `(A|[B]...)`: `...` (after bracket group) inside end of parentheses'
INPUT='  (   A   |   [   B   ]   ...   )'
LEVEL='0 ( 1 A 1 | 1 [ 2 B 2 ] 1 ... 1 ) 0'
GROUP='0 ( 1 A 1 | 1 [ 2 B 2 ] 1 ... 1 ) 0'
STATE='0 ( 0 A 1 | 0 [ 0 B 2 ] 2 ... 2 ) 2'       # <-- FIXME Expected BAD result
#STATE='0 ( 0 A 1 | 0 [ 0 B 1 ] 1 ... 1 ) 1'      #     DESIRED result
RULES=''
dumpenv \
    _DEBUG_STATE _DEBUG_GROUP _DEBUG_LEVEL \
    INPUT LEVEL GROUP STATE \
    GOTTED_RULES RC TESTS_COUNT TEST_OUT FAILED_TESTS TMPNUM \
    > env1.txt # expect
parse GOTTED_RULES "$INPUT" && :; RC="$?"  # intentionally unquoted
dumpenv \
    _DEBUG_STATE _DEBUG_GROUP _DEBUG_LEVEL \
    INPUT LEVEL GROUP STATE \
    GOTTED_RULES RC TESTS_COUNT TEST_OUT FAILED_TESTS TMPNUM \
    >env2.txt # got
is "$RC"           '0'      'Return value'
is "$_DEBUG_LEVEL" "$LEVEL" "Bracket level: '$INPUT'"
is "$_DEBUG_GROUP" "$GROUP" "Group numbers: '$INPUT'"
is "$_DEBUG_STATE" "$STATE" "State numbers: '$INPUT'"
#is "$GOTTED_RULES" "$RULES"         "Rules: '$INPUT'"
is_same_env : "Variable leakage: '$INPUT'" 3<env1.txt 4<env2.txt
unset INPUT LEVEL GROUP STATE RULES GOTTED_RULES RC

cd "$(mktemp -d)"
title 'parse `(ship HERE1|HERE2|-h|--help|--version)`'
INPUT='  (   ship   HERE1   |   HERE2   |   -h   |   --help   |   --version   )'
LEVEL='0 ( 1 ship 1 HERE1 1 | 1 HERE2 1 | 1 -h 1 | 1 --help 1 | 1 --version 1 ) 0'
GROUP='0 ( 1 ship 1 HERE1 1 | 1 HERE2 1 | 1 -h 1 | 1 --help 1 | 1 --version 1 ) 0'
STATE='0 ( 0 ship 2 HERE1 1 | 0 HERE2 1 | 0 -h 1 | 0 --help 1 | 0 --version 1 ) 1'
RULES=''
dumpenv \
    _DEBUG_STATE _DEBUG_GROUP _DEBUG_LEVEL \
    INPUT LEVEL GROUP STATE \
    GOTTED_RULES RC TESTS_COUNT TEST_OUT FAILED_TESTS TMPNUM \
    > env1.txt # expect
parse GOTTED_RULES "$INPUT" && :; RC="$?"  # intentionally unquoted
dumpenv \
    _DEBUG_STATE _DEBUG_GROUP _DEBUG_LEVEL \
    INPUT LEVEL GROUP STATE \
    GOTTED_RULES RC TESTS_COUNT TEST_OUT FAILED_TESTS TMPNUM \
    >env2.txt # got
is "$RC"           '0'      'Return value'
is "$_DEBUG_LEVEL" "$LEVEL" "Bracket level: '$INPUT'"
is "$_DEBUG_GROUP" "$GROUP" "Group numbers: '$INPUT'"
is "$_DEBUG_STATE" "$STATE" "State numbers: '$INPUT'"
#is "$GOTTED_RULES" "$RULES"         "Rules: '$INPUT'"
is_same_env : "Variable leakage: '$INPUT'" 3<env1.txt 4<env2.txt
unset INPUT LEVEL GROUP STATE RULES GOTTED_RULES RC

###############################################################################

# HERE1=
# HERE2= mine (set|remove) X Y [--moored|--drifting]

cd "$(mktemp -d)"
title 'parse `(new NAME...|NAME move X Y [--speed=KN]|shoot X Y)`:'
INPUT='  (   new   NAME   ...   |   NAME   move   X   Y   [   --speed=KN   ]   |   shoot   X   Y   )'
LEVEL='0 ( 1 new 1 NAME 1 ... 1 | 1 NAME 1 move 1 X 1 Y 1 [ 2 --speed=KN 2 ] 1 | 1 shoot 1 X 1 Y 1 ) 0'
GROUP='0 ( 1 new 1 NAME 1 ... 1 | 1 NAME 1 move 1 X 1 Y 1 [ 2 --speed=KN 2 ] 1 | 1 shoot 1 X 1 Y 1 ) 0'
STATE='0 ( 0 new 2 NAME 1 ... 1 | 0 NAME 4 move 5 X 6 Y 7 [ 7 --speed=KN 8 ] 8 | 0 shoot 9 X 10 Y 8 ) 8'  ## << EXPECTED BAD STATE
#
# TWO problems
# * '...' needs to look ahead to get possible group endstate
#
#STATE='0 ( 0 new 2 NAME 1 ... 1 | 0 NAME 4 move 5 X 6 Y 7 [ 7 --speed=KN   ] 1 | 0 shoot 9 X 10 Y 1 ) 1'
#STATE='0 ( 0 new 2 NAME 8 ... 8 | 0 NAME 4 move 5 X 6 Y 7 [ 7 --speed=KN 8 ] 8 | 0 shoot 9 X 10 Y 8 ) 8'
RULES=''
dumpenv \
    _DEBUG_STATE _DEBUG_GROUP _DEBUG_LEVEL \
    INPUT LEVEL GROUP STATE \
    GOTTED_RULES RC TESTS_COUNT TEST_OUT FAILED_TESTS TMPNUM \
    > env1.txt # expect
parse GOTTED_RULES "$INPUT" && :; RC="$?"  # intentionally unquoted
dumpenv \
    _DEBUG_STATE _DEBUG_GROUP _DEBUG_LEVEL \
    INPUT LEVEL GROUP STATE \
    GOTTED_RULES RC TESTS_COUNT TEST_OUT FAILED_TESTS TMPNUM \
    >env2.txt # got
is "$RC"           '0'      'Return value'
is "$_DEBUG_LEVEL" "$LEVEL" "Bracket level: '$INPUT'"
is "$_DEBUG_GROUP" "$GROUP" "Group numbers: '$INPUT'"
#is "$_DEBUG_STATE" "$STATE" "State numbers: '$INPUT'"   # FIXME FIX THIS
#is "$GOTTED_RULES" "$RULES"         "Rules: '$INPUT'"
is_same_env : "Variable leakage: '$INPUT'" 3<env1.txt 4<env2.txt
unset INPUT LEVEL GROUP STATE RULES GOTTED_RULES RC

###############################################################################

cd "$(mktemp -d)"
title 'parse `[A B C|D E F|G H I]...`:'
INPUT='  [   A   B   C   |   D   E   F   |   G   H   I   ] ...'
LEVEL='0 [ 1 A 1 B 1 C 1 | 1 D 1 E 1 F 1 | 1 G 1 H 1 I 1 ] 0 ... 0'
GROUP='0 [ 1 A 1 B 1 C 1 | 1 D 1 E 1 F 1 | 1 G 1 H 1 I 1 ] 0 ... 0'
STATE='0 [ 0 A 2 B 3 C 1 | 0 D 4 E 5 F 1 | 0 G 6 H 7 I 1 ] 1 ... 1'
RULES=''
dumpenv \
    _DEBUG_STATE _DEBUG_GROUP _DEBUG_LEVEL \
    INPUT LEVEL GROUP STATE \
    GOTTED_RULES RC TESTS_COUNT TEST_OUT FAILED_TESTS TMPNUM \
    > env1.txt # expect
parse GOTTED_RULES "$INPUT" && :; RC="$?"  # intentionally unquoted
dumpenv \
    _DEBUG_STATE _DEBUG_GROUP _DEBUG_LEVEL \
    INPUT LEVEL GROUP STATE \
    GOTTED_RULES RC TESTS_COUNT TEST_OUT FAILED_TESTS TMPNUM \
    >env2.txt # got
is "$RC"           '0'      'Return value'
is "$_DEBUG_LEVEL" "$LEVEL" "Bracket level: '$INPUT'"
is "$_DEBUG_GROUP" "$GROUP" "Group numbers: '$INPUT'"
is "$_DEBUG_STATE" "$STATE" "State numbers: '$INPUT'"
#is "$GOTTED_RULES" "$RULES"         "Rules: '$INPUT'"
is_same_env : "Variable leakage: '$INPUT'" 3<env1.txt 4<env2.txt
unset INPUT LEVEL GROUP STATE RULES GOTTED_RULES RC

###############################################################################

# ( ship HERE1 | HERE2 |  -h | --help | --version )
# HERE1= ( new NAME... | NAME move X Y [--speed=KN] | shoot X Y )
# HERE2= mine (set|remove) X Y [--moored|--drifting]

title 'parse: `(ship (new NAME...|NAME move X Y [--speed=KN]|shoot X Y)|mine (set|remove) X Y [--moored|--drifting]|-h|--help|--version)'
INPUT='  (   ship   (   new   NAME   ...   |   NAME   move   X   Y   [   --speed=KN   ]   |   shoot   X   Y   )   |   mine   (   set   |   remove   )   X   Y   [   --moored   |   --drifting   ]   |   -h   |   --help   |   --version   )'
GROUP='0 ( 1 ship 1 ( 2 new 2 NAME 2 ... 2 | 2 NAME 2 move 2 X 2 Y 2 [ 3 --speed=KN 3  ] 2  | 2 shoot 2 X 2 Y 2 ) 1 | 1 mine 1 ( 4 set 4 | 4 remove 4 ) 1 X 1 Y 1 [ 5 --moored 5 | 5 --drifting 5 ] 1 | 1 -h 1 | 1 --help 1 | 1 --version 1 ) 0'
LEVEL='0 ( 1 ship 1 ( 2 new 2 NAME 2 ... 2 | 2 NAME 2 move 2 X 2 Y 2 [ 3 --speed=KN 3  ] 2  | 2 shoot 2 X 2 Y 2 ) 1 | 1 mine 1 ( 2 set 2 | 2 remove 2 ) 1 X 1 Y 1 [ 2 --moored 2 | 2 --drifting 2 ] 1 | 1 -h 1 | 1 --help 1 | 1 --version 1 ) 0'
STATE='0 ( 0 ship 2 ( 2 new   NAME   ...   | 2 NAME   move   X   Y   [   --speed=KN    ]    | 2 shoot    X    Y   ) 1 | 0 mine    (    set    |    remove    )    X    Y    [    --moored    |    --drifting    ] 1  | 0 -h 1 | 0 --help 1 | 0 --version 1 ) 1'
STATE='0 ( 0 ship 2 ( 2 new 4 NAME 5 ... 5 | 2 NAME 6 move 7 X 8 Y 9 [ 9 --speed=KN 10 ] 10 | 2 shoot 11 X 12 Y 3 ) 3 | 0 mine 13 ( 13 set 14 | 13 remove 14 ) 14 X 15 Y 16 [ 16 --moored 17 | 16 --drifting 17 ] 17 | 0 -h 1 | 0 --help 1 | 0 --version 1 ) 1
'
#STATE='0 [ 0 A 2 B 3 C 1 | 0 D 4 E 5 F 1 | 0 G 6 H 7 I 1 ] 1'
# RULES='0 2 A
# 2 3 B
# 3 1 C
# 0 4 D
# 4 5 E
# 5 1 F
# 0 6 G
# 6 7 H
# 7 1 I
# 0 x
# 1 x'
parse GOTTED_RULES "$INPUT" && :; RC="$?"  # intentionally unquoted
is "$RC"           '0'      'Return value'
# is "$_DEBUG_LEVEL" "$LEVEL" "Bracket level: '$INPUT'"
# is "$_DEBUG_GROUP" "$GROUP" "Group numbers: '$INPUT'"
# is "$_DEBUG_STATE" "$STATE" "State numbers: '$INPUT'"
# is "$GOTTED_RULES" "$RULES"         "Rules: '$INPUT'"
unset INPUT LEVEL GROUP STATE RULES GOTTED_RULES RC

done_testing
#[eof]
