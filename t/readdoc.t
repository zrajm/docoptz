#!/usr/bin/env dash
# Copyright (C) 2020-2023 zrajm <docoptz@zrajm.org>
# License: GPLv2 [https://gnu.org/licenses/gpl-2.0.txt]
. "./dashtap/dashtap.sh"
. "./docoptz.sh"

cat() { stdin <"$1"; }
BIN="${0##*/}"

function_exists readdoc "Function 'readdoc' exists"

cd "$(mktemp -d)"
title "readdoc: Call with missing input on STDIN"
readdoc 2>stderr && :; RC="$?"
is "$RC"           '1'              'Return value'
is "$(cat stderr)" "$BIN: readdoc: Missing input on STDIN"  'Error message'
unset RC

cd "$(mktemp -d)"
title "readdoc: Call with missing argument"
readdoc 2>stderr <&- && :; RC="$?"
is "$RC"           '1'              'Return value'
is "$(cat stderr)" "$BIN: readdoc: Bad variable name ''"    'Error message'
unset RC

cd "$(mktemp -d)"
title "readdoc: Content with only docstring"
DOC="comment string"
readdoc GOTTED_DOC 2>stderr <<'EOF' && :; RC="$?"
# comment string
EOF
is "$RC"           '0'              'Return value'
is "$(cat stderr)" ''               'Error message'
is "$GOTTED_DOC"   "$DOC"           'Docstr: $DOC'
unset DOC GOTTED_DOC RC

cd "$(mktemp -d)"
title "readdoc: Docstring ending in newline"
DOC="comment string"
readdoc GOTTED_DOC 2>stderr <<'EOF' && :; RC="$?"
# comment string

EOF
is "$RC"           '0'              'Return value'
is "$(cat stderr)" ''               'Error message'
is "$GOTTED_DOC"   "$DOC"           'Docstr: $DOC'
unset DOC GOTTED_DOC RC

cd "$(mktemp -d)"
title "readdoc: Docstring ending with shell command"
DOC="comment string"
readdoc GOTTED_DOC 2>stderr <<'EOF' && :; RC="$?"
# comment string
shell-command
EOF
is "$RC"           '0'              'Return value'
is "$(cat stderr)" ''               'Error message'
is "$GOTTED_DOC"   "$DOC"           'Docstr: $DOC'
unset DOC GOTTED_DOC RC

cd "$(mktemp -d)"
title "readdoc: Ignore shebang(s) in docstring"
DOC="comment string"
readdoc GOTTED_DOC 2>stderr <<'EOF' && :; RC="$?"
#!/she/bang
# comment string
#! a docstring 'comment'
EOF
is "$RC"           '0'              'Return value'
is "$(cat stderr)" ''               'Error message'
is "$GOTTED_DOC"   "$DOC"           'Docstr: $DOC'
unset DOC GOTTED_DOC RC

cd "$(mktemp -d)"
title "readdoc: Some text/commands before docstr"
DOC="comment string
comment string"
readdoc GOTTED_DOC 2>stderr <<'EOF' && :; RC="$?"
#!/she/bang
shell-command(s)
# comment string
# comment string
EOF
is "$RC"           '0'              'Return value'
is "$(cat stderr)" ''               'Error message'
is "$GOTTED_DOC"   "$DOC"           'Docstr: $DOC'
unset DOC GOTTED_DOC RC

cd "$(mktemp -d)"
title "readdoc: Only get first comment block, ignore subsequent ones"
DOC="comment string"
readdoc GOTTED_DOC 2>stderr <<'EOF' && :; RC="$?"
#!/she/bang
shell-command
# comment string

# comment string
EOF
is "$RC"           '0'              'Return value'
is "$(cat stderr)" ''               'Error message'
is "$GOTTED_DOC"   "$DOC"           'Docstr: $DOC'
unset DOC GOTTED_DOC RC

cd "$(mktemp -d)"
title "readdoc: Comment may contain blank lines (except at beginning)"
DOC="comment string

comment string
"
readdoc GOTTED_DOC 2>stderr <<'EOF' && :; RC="$?"
#!/she/bang
shell-command
# comment string
#
# comment string
#
EOF
is "$RC"           '0'              'Return value'
is "$(cat stderr)" ''               'Error message'
is "$GOTTED_DOC"   "$DOC"           'Docstr: $DOC'
unset DOC GOTTED_DOC RC

done_testing
#[eof]
