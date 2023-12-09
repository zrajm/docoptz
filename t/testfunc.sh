#!/usr/bin/env dash
# Copyright (C) 2020-2023 zrajm <zdocopt@zrajm.org>
# License: GPLv2 [https://gnu.org/licenses/gpl-2.0.txt]

###############################################################################
##                                                                           ##
##  Test "Framework"                                                         ##
##                                                                           ##
###############################################################################

TESTS_DONE=''
FAILED_TESTS=0
TESTS_COUNT=0
TEST_OUT=''
TMPDIR="$(mktemp -dt zdocpt2-XXXXXX)"
TMPNUM="0"
BIN="${0##*/}"
trap "trapfunc \"$TMPDIR\"" EXIT INT

trapfunc() {
    local TMPDIR="$1" EXITCODE=0 MSG=''
    trap - EXIT INT
    [ -d '$TMPDIR' ] && rm -r '$TMPDIR'
    printf '\n'
    if [ "$TESTS_DONE" ]; then
        if [ "$FAILED_TESTS" -ne 0 ]; then
            appendnl MSG '=============================================='
            appendnl MSG "$(printf '== %-40s ==' 'ERRORS!!!!!!!!!!!!11111!!!')"
            appendnl MSG "$(printf '== %-40s ==' "$FAILED_TESTS (of $TESTS_COUNT) tests failed!")"
            appendnl MSG '=============================================='
            EXITCODE=10
        else
            appendnl MSG "All $TESTS_COUNT tests passed."
        fi
    else
       appendnl MSG  '***PREMATURE EXIT! Not all tests ran!'
       appendnl MSG '=============================================='
       appendnl MSG "$(printf '== %-40s ==\n' 'ABORTED EXECUTION!!!!!!!!!!!!11111!!!')"
       appendnl MSG "$(printf '== %-40s ==\n' "Ran $TESTS_COUNT tests before exiting.")"
       appendnl MSG '=============================================='
       EXITCODE=15
    fi
    [ "$TEST_OUT" ] && printf '%s\n' "$MSG" "$TEST_OUT"
    printf '%s\n' "$MSG"
    exit "$EXITCODE"
}

# Usage: tmpfile VARNAME
#
# Sets variable VARNAME to next suitable tempfile.
tmpfile() {
    ok_varname "$1" tmpfile || return 1
    setvar "$1" "$TMPDIR/$TMPNUM"
    incvar TMPNUM
}

# Usage: is GOT EXPECTED [DESCRIPTION]
#
# Tests if GOT and EXPECTED is the same, return true if this is the case, false
# otherwise. When returning false, also output a descriptive error message on
# standard output describing the difference between GOT and EXPECTED.
is() {
    local GOT="$1" EXPECTED="$2" MSG="$3"
    TESTS_COUNT="$(( TESTS_COUNT + 1 ))"
    if [ "$GOT" != "$EXPECTED" ]; then
        appendnl TEST_OUT "Test $TESTS_COUNT failed!!!"
        appendnl TEST_OUT "    $MSG"
        local FILE1='' FILE2=''; tmpfile FILE1; tmpfile FILE2
        { out 'EXPECTED:'; out "$EXPECTED"; } >"$FILE1"
        { out 'GOT:';      out "$GOT";      } >"$FILE2"
        local WIDTH="$(( $(wc -L <"$FILE1") + $(wc -L <"$FILE2") + 8 ))"
        [ "$WIDTH" -gt "$(( COLUMNS - 4))" ] && WIDTH="$(( COLUMNS - 4))"
        local TMP="$(diff --width="$WIDTH" --color=always --expand-tabs \
            --side-by-side "$FILE1" "$FILE2")"
        prefix TMP '    '
        appendnl TEST_OUT "$TMP"
        appendnl TEST_OUT '----------------------------------------'
        FAILED_TESTS="$(( FAILED_TESTS + 1 ))"
        printf 'F'
    else
        printf '.'
    fi
}

test_info() {
    appendnl TEST_OUT "$*"
}

done_testing() {
    TESTS_DONE=1
}

# Usage: dumpenv VARNAME...
#
# Outputs all environment variables to standard output (usin `set`) except
# those specified on the command line. All named variables are locally unset
# before outputting the variables but restored upon exiting the function.
dumpenv() {
    for VAR in "$@"; do
        local "$VAR"
        unset "$VAR"
    done
    set
}

# Usage: readall VARNAME [<FILE]
#
# Reads all of standard input sets the variable VARNAME to whatever was read.
# Each line read from standard input is separated by a newline, but no final
# trailing final trailing newline is added.
readall() {
    local _
    while IFS='' read -r _; do
        set -- "$1" "${2:+$2
}$_"                                           # intentional newline
    done
    setvar "$1" "$2"
}

###############################################################################

if [ ! -t 0 ]; then
    warn "ERROR: Test suite require that STDIN is not connected to pipe!"
    trap - EXIT
    exit 30
fi

#[eof]
