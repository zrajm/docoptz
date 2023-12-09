#!/usr/bin/env dash
# Copyright (C) 2020-2023 zrajm <zdocopt@zrajm.org>
# License: GPLv2 [https://gnu.org/licenses/gpl-2.0.txt]
. "./zdocopt.sh"
. "./t/testfunc.sh"

############################
#####  Test readdoc()  #####
############################
## Call with missing input on STDIN
tmpfile TMPFILE
readdoc 2>"$TMPFILE" && :; RETVAL="$?"
readall ERRMSG <"$TMPFILE"
is "$RETVAL"  '1'                                      'Return value'
is "$ERRMSG"  "$BIN: readdoc: Missing input on STDIN"  'Error message'
unset ERRMSG TMPFILE

## Call with missing argument
tmpfile TMPFILE
readdoc 2>"$TMPFILE" <&- && :; RETVAL="$?"
readall ERRMSG <"$TMPFILE"
is "$RETVAL"  '1'                                      'Return value'
is "$ERRMSG"  "$BIN: readdoc: Bad variable name ''"    'Error message'
unset ERRMSG TMPFILE

## Content with only docstring
DOC="comment string"
tmpfile TMPFILE
readdoc GOTTED_DOC 2>"$TMPFILE" <<'EOF' && :; RETVAL="$?"
# comment string
EOF
readall ERRMSG <"$TMPFILE"
is "$RETVAL"       '0'              'Return value'
is "$ERRMSG"       ''               'Error message'
is "$GOTTED_DOC"   "$DOC"           'Docstr: $DOC'
unset DOC ERRMSG GOTTED_DOC TMPFILE

## Docstring ending in newline
DOC="comment string"
tmpfile TMPFILE
readdoc GOTTED_DOC 2>"$TMPFILE" <<'EOF' && :; RETVAL="$?"
# comment string

EOF
readall ERRMSG <"$TMPFILE"
is "$RETVAL"       '0'              'Return value'
is "$ERRMSG"       ''               'Error message'
is "$GOTTED_DOC"   "$DOC"           'Docstr: $DOC'
unset DOC ERRMSG GOTTED_DOC TMPFILE

## Docstring ending with shell command
DOC="comment string"
tmpfile TMPFILE
readdoc GOTTED_DOC 2>"$TMPFILE" <<'EOF' && :; RETVAL="$?"
# comment string
shell-command
EOF
readall ERRMSG <"$TMPFILE"
is "$RETVAL"       '0'              'Return value'
is "$ERRMSG"       ''               'Error message'
is "$GOTTED_DOC"   "$DOC"           'Docstr: $DOC'
unset DOC ERRMSG GOTTED_DOC TMPFILE

## Ignore shebang(s) in docstring
DOC="comment string"
tmpfile TMPFILE
readdoc GOTTED_DOC 2>"$TMPFILE" <<'EOF' && :; RETVAL="$?"
#!/she/bang
# comment string
#! a docstring 'comment'
EOF
readall ERRMSG <"$TMPFILE"
is "$RETVAL"       '0'              'Return value'
is "$ERRMSG"       ''               'Error message'
is "$GOTTED_DOC"   "$DOC"           'Docstr: $DOC'
unset DOC ERRMSG GOTTED_DOC TMPFILE

## Some text/commands before docstr
DOC="comment string
comment string"
tmpfile TMPFILE
readdoc GOTTED_DOC 2>"$TMPFILE" <<'EOF' && :; RETVAL="$?"
#!/she/bang
shell-command(s)
# comment string
# comment string
EOF
readall ERRMSG <"$TMPFILE"
is "$RETVAL"       '0'              'Return value'
is "$ERRMSG"       ''               'Error message'
is "$GOTTED_DOC"   "$DOC"           'Docstr: $DOC'
unset DOC ERRMSG GOTTED_DOC TMPFILE

## Only get first comment block, ignore subsequent ones
DOC="comment string"
tmpfile TMPFILE
readdoc GOTTED_DOC 2>"$TMPFILE" <<'EOF' && :; RETVAL="$?"
#!/she/bang
shell-command
# comment string

# comment string
EOF
readall ERRMSG <"$TMPFILE"
is "$RETVAL"       '0'              'Return value'
is "$ERRMSG"       ''               'Error message'
is "$GOTTED_DOC"   "$DOC"           'Docstr: $DOC'
unset DOC ERRMSG GOTTED_DOC TMPFILE

## Comment may contain blank lines (except at beginning)
DOC="comment string

comment string
"
tmpfile TMPFILE
readdoc GOTTED_DOC 2>"$TMPFILE" <<'EOF' && :; RETVAL="$?"
#!/she/bang
shell-command
# comment string
#
# comment string
#
EOF
readall ERRMSG <"$TMPFILE"
is "$RETVAL"       '0'              'Return value'
is "$ERRMSG"       ''               'Error message'
is "$GOTTED_DOC"   "$DOC"           'Docstr: $DOC'
unset DOC ERRMSG GOTTED_DOC TMPFILE

done_testing
#[eof]
