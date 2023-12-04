#!/bin/sh
# Copyright (C) 2020-2023 zrajm <zdocopt@zrajm.org>
# Licensed under GNU GPL version 2, see LICENSE-GPL2.txt for details.
#
# Usage: pushdownmachine --test
# Run tests.
#

## Desired features:
## * Optional option alguments --color[=WHEN]
## * Arguments wrapping over multiple lines
## * Later: Multiple options lists(?)
## * Options defined separately
##
## =============================================================================
##
## Example Usage
## =============
##
## Usage: ls [OPTION]... [FILE]...
## List information about the FILEs (the current directory by default).
## Sort entries alphabetically if none of -cftuvSUX nor --sort is specified.
##
## Mandatory arguments to long options are mandatory for short options too.
##   -a, --all                  do not ignore entries starting with .
##   ...
##
## -----------------------------------------------------------------------------
##
## usage: git [--version] [--help] [-C <path>] [-c <name>=<value>]
##            [--exec-path[=<path>]] [--html-path] [--man-path] [--info-path]
##            [-p | --paginate | --no-pager] [--no-replace-objects] [--bare]
##            [--git-dir=<path>] [--work-tree=<path>] [--namespace=<name>]
##            <command> [<args>]
##
## -----------------------------------------------------------------------------
## (From docopt documentation)
##
## Naval Fate.
##
## Usage:
##   naval_fate ship new NAME...
##   naval_fate ship NAME move X Y [--speed=KN]
##   naval_fate ship shoot X Y
##   naval_fate mine (set|remove) X Y [--moored|--drifting]
##   naval_fate -h | --help
##   naval_fate --version
##
## Options:
##   -h,--help      Show this screen.
##      --version   Show version.
##      --speed=KN  Speed in knots [default: 10].
##      --moored    Moored (anchored) mine.
##      --drifting  Drifting mine.
##
## =============================================================================

# -e -- errexit mode. Interrupt script if any command has exit code >0, unless
# caught. The tests run with '&& :' which suppresses this for a single command,
# while still catching the exit value in '$?'.
set -e

# set -euv

#DEBUG=1
DEBUG="${DEBUG:-}"
if [ "$DEBUG" ]; then
    DEBUG() { {
        printf '%s\n' "$1"; shift
        printf '    %s\n' "$@"
    } >&2; }
else
    DEBUG() { :; }
fi

################################################################################

out() { printf '%s\n' "$*"; }
warn() {
    [ "$1" ] && out "${0##*/}: $1" >&2
    [ "$2" ] && out "$2" >&2
    return 0
}
#die() { warn "$@"; exit 5; }

# Usage: ok_varname VARNAME [FROMSTR]
#
# Returns true if VARNAME is a valid shell variable name, otherwise output
# error message on STDERR, and return false. (If FROMSTR is specified, it will
# preced the error any error message -- typically FROMSTR is the name of the
# calling function). A variable name may only contain upper case letters, '_'
# and digits (though the first character must not be a digit).
ok_varname() {
    case "$1" in
        ''|*[!A-Z0-9_]*|[0-9]*)
            warn "${2:+$2: }Bad variable name '$1'"
            return 1
    esac
    return 0
}

# Usage: getarg VARNAME NUM ARG...
#
# Set VARNAME to `$ARG[NUM]`. Use to extract single argument from from `$@`
# with `getarg THIS 2 "$@"`. INDEX must be between 1 and $#.
getarg() { eval "$1=\"\${$(($2 + 2))}\""; }

# Usage: getvar VARNAME1 VARNAME2
#
# Set VARNAME1 to whatever variable VARNAME2 contains.
getvar() {
    ok_varname "$1" getvar || return 1
    ok_varname "$2" getvar || return 1
    eval "$1=\"\${$2}\""
}

# Usage: setvar VARNAME VALUE
#
# Set variable VARNAME to the specified value.
setvar() {
    ok_varname "$1" setvar || return 1
    eval "$1=\"\$2\""
}

# Usage: incvar VARNAME
#
# Sets variable VARNAME to 0 if unset, otherwise increment VARNAME by one.
incvar() {
    ok_varname "$1" incvar || return 1
    eval "set -- \"\$1\" \"\${$1:--1}\""       # put $VARNAME or '-1' in $2
    case "$2" in                               # must start with '-' or digit
        -|[!0-9-]*|?*[!0-9]*)                  #   only digits after that
            warn "incvar: Invalid number '$2'"
            return 2
    esac
    eval "$1='$(($2 + 1))'"
}

# Usage: decvar VARNAME
#
# Sets variable VARNAME to 0 if unset, otherwise decrement VARNAME by one.
decvar() {
    ok_varname "$1" decvar || return 1
    eval "set -- \"\$1\" \"\${$1}\""           # put $VARNAME content in $2
    case "$2" in                               # must start with '-' or digit
        ''|-|[!0-9-]*|?*[!0-9]*)               #   only digits after that
            warn "decvar: Invalid number '$2'"
            return 2
    esac
    eval "$1='$(($2 - 1))'"
}

# Usage: ifvar VARNAME
#
# Returns true (0) if variable is non-zero in length, false (1) otherwise.
ifvar() {
    ok_varname "$1" ifvar || return 1
    eval "[ \"\${$1}\" ]"
}

# Usage: eqvar VARNAME1 VARNAME2
#
# Returns true (0) if variables VARNAME1 and VARNAME2 have identical content,
# otherwise return false (1).
eqvar() {
    ok_varname "$1" eqvar || return 1
    ok_varname "$2" eqvar || return 1
    eval "[ \"\${$1}\" = \"\${$2}\" ]"
}

# Usage: prefix VARNAME PREFIX
#
# Modifies content in variable VARNAME by prepending PREFIX to all lines in it.
prefix() {
    ok_varname "$1" prefix || return 1
    # Globbing is turned off (`set -f`) locally (`local -`) otherwise the
    # `IFS`/`set` linesplitting also glob expands words containing '*' (iff
    # there are matching files) -- which would be very confusing.
    local - _VAR="$1" _PRE="$2" _ARG='' IFS='
'                                              # intentional newline
    set -f                                     # disable globbing
    eval "set -- \${$1}"                       # linesplit VARNAME into $@
    for _ARG in "$@"; do
        shift
        set -- "$@" "$_PRE$_ARG"
    done
    eval "$_VAR=\$*"
}

# Usage: append VARNAME STRING
#
# Append STRING to VARNAME with a space inbetween (unless VARNAME is empty, in
# which case no space is inserted in front of STRING).
append() {
    ok_varname "$1" append || return 1
    # VARNAME="${VARNAME:+$VARNAME }$2"
    eval "$1=\"\${$1:+\${$1} }\$2\""
}

# Usage: appendnl VARNAME STRING
#
# Append STRING to VARNAME with a space inbetween (unless VARNAME is empty, in
# which case no space is inserted in front of STRING).
appendnl() {
    ok_varname "$1" appendnl || return 1
    # VARNAME="${VARNAME:+$VARNAME<NEWLINE>}$2"
    eval "$1=\"\${$1:+\${$1}
}\$2\""                                        # intentional newline
}

# Usage: readdoc VARNAME <FILE
#
# Extract the doc string from a block of text passed on standard input, and
# return it in the variable VARNAME. Return false if VARNAME is not a valid
# variable name, or if no input was provided on stdin. The first chunk of
# contiguous lines which starts with `# ` in the input are considered the
# docstring. Docstring is terminated by the first line not starting with `# `,
# and may be preceeded by non-docstring lines. Empty lines (containing a single
# `#`) are also allowed within the docstring (and result in an empty line in
# the output). Shebang lines (starting with `#!`) does not terminate the
# docstring, but not included in the output either.
#
# Typically invoked with `readdoc varname <"$0"`
readdoc() {
    local _
    [ -t 0 ] && warn "readdoc: Missing input on STDIN" && return 1
    ok_varname "$1" readdoc || return 1
    setvar "$1" ''
    while IFS='' read -r _; do
        case "$_" in
            '#!'*) :;;                         # ignore shebang
            '#')   appendnl "$1" '' ;;         # blank line
            '# '*) appendnl "$1" "${_#\# }" ;; # docstring
            *)  ifvar "$1" && break ;;         # terminate docstring
        esac
    done
}

# Usage: replace VARNAME OLDSTR NEWSTR
#
# Replace all occurrences of OLDSTR in the variable VARNAME with NEWSTR.
# Returns false if VARNAME is not a valid variable name, otherwise it will
# always return true (regardless of whether OLDSTR could be found or not). If
# OLDSTR couldn't be found variable VARNAME will remain unmodified. OLDSTR is a
# string (not a pattern) so an OLDSTR of e.g. '[ab]' will exactly match the
# string '[ab]' (it does not match either 'a' or 'b' as one might expect).
replace() {
    [ "$#" -ne 3 ] && warn 'replace: Bad number of arguments' && return 1
    ok_varname "$1" replace || return 1
    # $1:VARNAME $2:OLDSTR $3:NEWSTR $4:DONE $5:REMAIN $6:PREVIOUS REMAIN
    eval "set -- \"\$@\" \"\" \"\${$1}\""      # put $VARNAME into $5
    while
        # Copy head of REMAIN (up to first occurrence of
        # OLDSTR) into DONE, and remove same bit from REMAIN.
        set -- "$1" "$2" "$3" "$4${5%%"$2"*}" "${5#*"$2"}" "$5"
        # OLDSTR not found in REMAIN (= it wasn't modified).
        [ "$5" != "$6" ]
    do
        set -- "$1" "$2" "$3" "$4$3" "$5"      #   add NEWSTR to DONE
    done
    setvar "$1" "$4"
}

# Usage: parse RULESVAR TOKENIZED
#
# Go through TOKENIZED and create finite-state machine rules suitable for
# parsing a command line. Also checks the validity/nesting of (...) and [...]
# constructs. (Failing if brackets or parentheses are unbalanced.)
#
# The generated rules will be saved in the specified RULESVAR. Each rule is
# separated by an newline, and is of the format 'STARTSTATE ENDSTATE [INPUT]'.
# If no INPUT is present, then ENDSTATE is always 'x'.
#
# The following special characters are recognized:
#   * Group start: '[' or '('
#   * Group end: ']' or ')'
#   * Subgroup separator: '|'
#   * Group repeat: '...'
#
# The beginning of a subgroup can be attached to one or more states (if the
# previous subgroup[s] where optional). The first part of each subgroup is
# therefore connected to all the STARTAT states (space-separated list state
# identifiers). The remaining group states should be the same regardless of
# which 'entry' was taken.
#
# Internals:
#
# LVL is the current level of nesting. GROUPS in the number of the current
# parenthesis. In '()()' GROUPS is 1 and 2, and LVL 0 and 1. In '(())' GROUPS
# is also 1 & 2, but LVL is 0 (outside paren), 1 (inside first paren), and 2
# (inside innermost paren). I.e. GROUPS never decreases, while LVL does. IN is
# the current group we're in, so in '()()' it looks like this '0(1)0(2)0',
# while in '(())' its '0(1(2)1)0'.

#
# GROUP0...N is a pseudo-array containing group stack. It has no meaning
# outside this loop. It contains the group number of the current parenthetical
# group at the end.
#
# TYPE0...N is pseudo-array containing group type. TYPE0='' (because its not
# within brackets), all higher numbers are either ']' or ')' depending on
# whether it's a [...] or (...) group.
#

# Ellipsis and Bracket Rules (_ELL<$LVL>)
# =======================================
# Ellipsis (_ELL$LVL) rules are extra rules built up during the processing of
# each parenthesis/bracket group, which are only inserted into the final
# ruleset if the group in question is followed by '...' (if not used, then the
# ellipsis rules are forgotten upon exiting the group). In the Finate State
# Automaton images, these are the lines marked in purple (which allow for
# repetition of a group).
#
# FINAL STATES
# ============
# Accumulate final states FINAL$IN. Whenever a new group is started on the same
# level, and after the one which registered its final states, then the final
# states should be removed, and instead a set of rules for transitioning from
# the previously final state into the new group should be created. (And we
# continue to accumulate new final state names.)
#
# Upon reaching the end of the input string, check to make sure were in one of
# the final states.

# STATE is the currently processed state, STATEMAX is the maxiumum state used
# so far (for each state added STATEMAX is increased, so that it is the highest
# STATE used so far).

# Usage: parse RULESVAR DOCSTR
#
# Go through TOKEN(s) and create finite-state machine rules suitable for
# parsing the command line specified by DOCSTR. Will fail (returning false)
# DOCSTR is malformed, if everything went well, returns true and set the
# RULESVAR variable to a (multiline) string with rules for a finite state
# automaton, suitable for parsing a command line.
parse() {
    local _VAR="$1" _INPUT="$2"
    ok_varname "$_VAR" parse || return 1
    # Tokenize by adding space round syntactic chars, then split into $@.
    local _STR _SHOPT="$-"                     # save shell options
    for _STR in '(' '[' '|' ']' ')' '...'; do  # foreach syntactic string
        replace _INPUT "$_STR" " $_STR "       #   add space around them
    done
    set -f                                     # turn noglob ON
    set -- $_INPUT                             # intentionally unquoted
    case "$_SHOPT" in *f*) ;; *) set +f; esac  # restore noglob state
    _DEBUG_STATE=''                            # used in testing
    _DEBUG_GROUP=''
    _DEBUG_LEVEL=''
    local _STATE=0 _STATEMAX=0
    local _RULES=''
    local _GRPMAX=0 _LVL=0 _IN=0               # group count + level, current group
    local _BEG0=0 _END0=0 _GRP0=0 _TYPE0='' _ELL0='' # base states of stacks
    local _TMP _CUR=0 _CUR0=0
    # Loop over $@ while setting $A to current arg, and $NEXT to next arg.
    local I=0 A='' NEXT='' PREV='' _NEXTNEXT
    while I="$(( I + 1 ))"; [ "$I" -le "$#" ]; do
        getarg A    "$I"           "$@"        # current arg
        getarg NEXT "$(( I + 1 ))" "$@"        #   next arg
        append _DEBUG_STATE "$_STATE $A" || return 1
        append _DEBUG_GROUP "$_IN $A"    || return 1
        append _DEBUG_LEVEL "$_LVL $A"   || return 1
        case "$A" in
            ['(['])                            # start parenthesis or bracket
                local "_CUR$_LVL"="$_CUR"      #   store previous start states
                incvar _LVL                    #   level (paren depth)
                incvar _GRPMAX                 #   group (paren number)
                incvar _STATEMAX               #   state counter
                _IN="$_GRPMAX"                 #   current group
                local "_BEG$_LVL"="$_CUR"      #     stack: group start states
                local "_END$_LVL"="$_STATEMAX" #     stack: group end state
                local "_GRP$_LVL"="$_GRPMAX"   #     stack: group number
                local "_ELL$_LVL"=''           #     stack: ellipsis rules
                case "$A" in                   #     stack: group type
                    '(') local "_TYPE$_LVL"=')' ;;
                    '[') local "_TYPE$_LVL"=']' ;;
                esac ;;
            '|')                               # pipe
                # FIXME: Should '||', '[|', '(|', '|]' and '|)' be allowed?
                if [ "$_LVL" -eq 0 ]; then
                    warn "Badly placed '|' in rule: $*" \
                         '(Must be inside parentheses/brackets.)'
                    return 1
                fi
                getvar _STATE "_BEG$_LVL"      #   restore group start state
                _STATE="${_STATE##* }"         #
                getvar _CUR   "_BEG$_LVL" ;;   #   restore group start states
            ['])'])                            # end bracket
                local _TYPE; getvar _TYPE "_TYPE$_LVL"
                [ "$_LVL" -le 0    ] && warn "Too many '$A' in rule: $*" && return 1
                [ "$A" != "$_TYPE" ] && warn "Missing '$A' in rule (group $_IN): $*" && return 1
                unset _TYPE
                if [ "$NEXT" = '...' ]; then   #     if followed by '...'
                    local _ELL
                    getvar _ELL "_ELL$_LVL"
                    local _NEWRULES="$_ELL"
                    prefix _NEWRULES "$_STATE "
                    appendnl "_RULES" "$_NEWRULES" || return 1
                    unset _ELL _NEWRULES
                fi
                # Pop off last element of 'stack's.
                unset "_BEG$_LVL" "_END$_LVL" "_GRP$_LVL" "_TYPE$_LVL" "_ELL$_LVL"
                decvar _LVL                    #   go down one level
                getvar _IN "_GRP$_LVL"         #   restore previous group number
                case "$A" in                   #   restore previous come-from states
                    ')') _CUR='' ;;
                    ']') getvar _CUR "_CUR$_LVL" ;;
                esac
                append _CUR "$_STATE"
                # FIXME: These lines not covered by test cases!! (necessary?)
                # (This *should* update state when there are multiple end parentheses.)
                # case "$NEXT" in [')]'])
                #     local "_END$_LVL"="$_STATE"
                # esac
                ;;
            '...')                             # ellipsis
                ## This state only handles if an ellipsis is allowed. Actual
                ## ellipsis logic runs in the end group state, and ARG state
                ## where all the needed variables are already set.
                _TMP=''; case "$PREV" in (['|([']|...) _TMP=1; esac
                if [ "$I" = 1 -o "$_TMP" = 1 ]; then
                    warn "Badly placed '...' in rule: $*" \
                         '(Must come after ARGUMENT or end parenthesis/bracket.)'
                    return 1
                fi ;;
            *)                                 # anything else
                getarg _NEXTNEXT "$(( I + 2 ))" "$@"
                case "$NEXT:$_NEXTNEXT" in     #   this is last word in a group
                    ['|)]']':'*|'...:'['|)]']) #     use end state of bracket
                        getvar _STATE "_END$_LVL" ;;
                    *)                         #   otherwise
                        incvar _STATEMAX       #     increase state by one
                        _STATE="$_STATEMAX" ;;
                esac
                for _TMP in $_CUR; do          # intentionally unquoted
                    appendnl _RULES "$_TMP $_STATE $A" || return 1
                done
                _CUR="$_STATE"
                # If followed by '...' add rule to self.
                if [ "$NEXT" = '...' ]; then
                    appendnl _RULES "$_STATE $_STATE $A" || return 1
                fi
                case "$PREV" in ['[(|'])       # add ellipsis rule
                    appendnl "_ELL$_LVL" "$_STATE $A" || return 1
                    # If this group and previous group start at same state (ie
                    # leading parenthesis is doubled, tripled etc) then copy
                    # ellipsis rules to previous group as well.
                    local _J="$_LVL"
                    while decvar _J && [ "$_J" -gt 0 ] && eqvar "_BEG$_LVL" "_BEG$_J"; do
                        appendnl "_ELL$_J" "$_STATE $A" || return 1
                    done
                esac ;;
        esac
        # # DEBUG: Indented parse output
        # local _DEBUG_INDENT _DEBUG_INDENT_NEXT
        # case "$A" in
        #     '('|'[')                           # start parenthesis or bracket
        #         _DEBUG_INDENT_NEXT="    $_DEBUG_INDENT" ;;
        #     ']'|')')                           # end bracket
        #         _DEBUG_INDENT="${_DEBUG_INDENT#    }"
        #         _DEBUG_INDENT_NEXT="$_DEBUG_INDENT" ;;
        #     '|')                               #   pipe
        #         _DEBUG_INDENT_NEXT="$_DEBUG_INDENT"
        #         _DEBUG_INDENT="${_DEBUG_INDENT#  }" ;;
        # esac
        # local TMP
        # getvar TMP "_ELL$_LVL"
        # out "${_DEBUG_INDENT}'$A'"
        # out "${_DEBUG_INDENT}    ((ELLIPSIS$_LVL: $TMP))"
        # #out "  ${_DEBUG_INDENT}LVL:$_LVL STATE:$_STATE"
        # _DEBUG_INDENT="$_DEBUG_INDENT_NEXT"
        PREV="$A"
    done
    # Add final state rules to rules.
    for _TMP in $_CUR; do                      # intentionally unquoted
        appendnl _RULES "$_TMP x" || return 1
    done
    #unset "_GRP0"  # last element of group stack
    #unset "_TYPE0"
    append _DEBUG_STATE "$_STATE" || return 1
    append _DEBUG_GROUP "$_IN"    || return 1
    append _DEBUG_LEVEL "$_LVL"   || return 1
    if [ "$_LVL" -ne 0 ]; then
        local PAREN; getvar PAREN "_TYPE$_LVL"
        warn "Missing '$PAREN' at end of rule: $*"
        return 1
    fi
    setvar "$_VAR" "$_RULES"
}

################################################################################
##                                                                            ##
##  Test "Framework"                                                          ##
##                                                                            ##
################################################################################

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

################################################################################
##                                                                            ##
##  Tests                                                                     ##
##                                                                            ##
################################################################################

if [ ! -t 0 ]; then
    warn "ERROR: Test suite require that STDIN is not connected to pipe!"
    trap - EXIT
    exit 30
fi

#########################
####  Test getarg()  ####
#########################
getarg GOTTED 1 a b c d e f g h i j && :; RETVAL="$?"
is "$GOTTED"       'a'      'Gotted value'
is "$RETVAL"       '0'      'Return value'
unset GOTTED

getarg GOTTED 10 a b c d e f g h i j && :; RETVAL="$?"
is "$GOTTED"       'j'      'Gotted value'
is "$RETVAL"       '0'      'Return value'
unset GOTTED

#########################
####  Test getvar()  ####
#########################
tmpfile TMPFILE
getvar a 2>"$TMPFILE" && :; RETVAL="$?"
readall ERRMSG <"$TMPFILE"
is "$RETVAL"  '1'                                   'Return value'
is "$ERRMSG"  "$BIN: getvar: Bad variable name 'a'" 'Error message'

tmpfile TMPFILE
getvar A b 2>"$TMPFILE" && :; RETVAL="$?"
readall ERRMSG <"$TMPFILE"
is "$RETVAL"  '1'                                   'Return value'
is "$ERRMSG"  "$BIN: getvar: Bad variable name 'b'" 'Error message'

VAL="()"
getvar GOTTED VAL && :; RETVAL="$?"
is "$GOTTED"       '()'     'Gotted value'
is "$RETVAL"       '0'      'Return value'
unset GOTTED VAL

#########################
####  Test setvar()  ####
#########################
tmpfile TMPFILE
setvar a 2>"$TMPFILE" && :; RETVAL="$?"
readall ERRMSG <"$TMPFILE"
is "$RETVAL"  '1'                                   'Return value'
is "$ERRMSG"  "$BIN: setvar: Bad variable name 'a'" 'Error message'

setvar GOTTED '()' && :; RETVAL="$?"
is "$GOTTED"       '()'     'Gotted value'
is "$RETVAL"       '0'      'Return value'
unset GOTTED

#########################
####  Test incvar()  ####
#########################
## Increment invalid variable name
tmpfile TMPFILE
incvar a 2>"$TMPFILE" && :; RETVAL="$?"
readall ERRMSG <"$TMPFILE"
is "$RETVAL"  '1'           'Return value'
is "$ERRMSG"  \
   "$BIN: incvar: Bad variable name 'a'" \
   'Error message'

## Increment an invalid number
tmpfile TMPFILE
VALUE=123abc
incvar VALUE 2>"$TMPFILE" && :; RETVAL="$?"
readall ERRMSG <"$TMPFILE"
is "$RETVAL"  '2'           'Return value'
is "$ERRMSG"  \
   "$BIN: incvar: Invalid number '123abc'" \
   'Error message'
unset VALUE

## Increment '-' (minus sign w/o number)
tmpfile TMPFILE
VALUE='-'
incvar VALUE 2>"$TMPFILE" && :; RETVAL="$?"
readall ERRMSG <"$TMPFILE"
is "$RETVAL"  '2'           'Return value'
is "$ERRMSG"  \
   "$BIN: incvar: Invalid number '-'" \
   'Error message'
unset VALUE

## Increment value containing variable name
tmpfile TMPFILE
VALUE=VALUE2
VALUE2=10
incvar VALUE 2>"$TMPFILE" && :; RETVAL="$?"
readall ERRMSG <"$TMPFILE"
is "$RETVAL"  '2'           'Return value'
is "$ERRMSG"  \
   "$BIN: incvar: Invalid number 'VALUE2'" \
   'Error message'
unset VALUE VALUE2

## Increment unset value
incvar VALUE && :; RETVAL="$?"
is "$VALUE"        '0'      'Gotted value'
is "$RETVAL"       '0'      'Return value'

## Increment empty value
VALUE=''
incvar VALUE && :; RETVAL="$?"
is "$VALUE"        '0'      'Gotted value'
is "$RETVAL"       '0'      'Return value'
unset VALUE

## Increment number -10
VALUE=-10
incvar VALUE && :; RETVAL="$?"
is "$VALUE"        '-9'     'Gotted value'
is "$RETVAL"       '0'      'Return value'
unset VALUE

## Increment number -1
VALUE=-1
incvar VALUE && :; RETVAL="$?"
is "$VALUE"        '0'      'Gotted value'
is "$RETVAL"       '0'      'Return value'
unset VALUE

## Increment number 0
VALUE=0
incvar VALUE && :; RETVAL="$?"
is "$VALUE"        '1'      'Gotted value'
is "$RETVAL"       '0'      'Return value'
unset VALUE

## Increment number 1
VALUE=1
incvar VALUE && :; RETVAL="$?"
is "$VALUE"        '2'      'Gotted value'
is "$RETVAL"       '0'      'Return value'
unset VALUE

## Increment number 10
VALUE=10
incvar VALUE && :; RETVAL="$?"
is "$VALUE"        '11'     'Gotted value'
is "$RETVAL"       '0'      'Return value'
unset VALUE

## Increment number 65536
VALUE=65536
incvar VALUE && :; RETVAL="$?"
is "$VALUE"        '65537'  'Gotted value'
is "$RETVAL"       '0'      'Return value'
unset VALUE

#########################
####  Test decvar()  ####
#########################
## Decrement invalid variable name
tmpfile TMPFILE
decvar a 2>"$TMPFILE" && :; RETVAL="$?"
readall ERRMSG <"$TMPFILE"
is "$RETVAL"  '1'           'Return value'
is "$ERRMSG"  \
   "$BIN: decvar: Bad variable name 'a'" \
   'Error message'

## Decrement an invalid number
tmpfile TMPFILE
VALUE=123abc
decvar VALUE 2>"$TMPFILE" && :; RETVAL="$?"
readall ERRMSG <"$TMPFILE"
is "$RETVAL"  '2'           'Return value'
is "$ERRMSG"  \
   "$BIN: decvar: Invalid number '123abc'" \
   'Error message'
unset VALUE

## Decrement '-' (minus sign w/o number)
tmpfile TMPFILE
VALUE='-'
decvar VALUE 2>"$TMPFILE" && :; RETVAL="$?"
readall ERRMSG <"$TMPFILE"
is "$RETVAL"  '2'           'Return value'
is "$ERRMSG"  \
   "$BIN: decvar: Invalid number '-'" \
   'Error message'
unset VALUE

## Decrement value containing variable name
tmpfile TMPFILE
VALUE=VALUE2
VALUE2=10
decvar VALUE 2>"$TMPFILE" && :; RETVAL="$?"
readall ERRMSG <"$TMPFILE"
is "$RETVAL"  '2'           'Return value'
is "$ERRMSG"  \
   "$BIN: decvar: Invalid number 'VALUE2'" \
   'Error message'
unset VALUE VALUE2

## Decrement unset value
tmpfile TMPFILE
decvar VALUE 2>"$TMPFILE" && :; RETVAL="$?"
readall ERRMSG <"$TMPFILE"
is "$RETVAL"  '2'           'Return value'
is "$ERRMSG"  \
   "$BIN: decvar: Invalid number ''" \
   'Error message'

## Decrement empty value
tmpfile TMPFILE
VALUE=''
decvar VALUE 2>"$TMPFILE" && :; RETVAL="$?"
readall ERRMSG <"$TMPFILE"
is "$RETVAL"  '2'           'Return value'
is "$ERRMSG"  \
   "$BIN: decvar: Invalid number ''" \
   'Error message'
unset VALUE

## Decrement number -10
VALUE=-10
decvar VALUE && :; RETVAL="$?"
is "$VALUE"        '-11'    'Gotted value'
is "$RETVAL"       '0'      'Return value'
unset VALUE

## Decrement number -1
VALUE=-1
decvar VALUE && :; RETVAL="$?"
is "$VALUE"        '-2'     'Gotted value'
is "$RETVAL"       '0'      'Return value'
unset VALUE

## Decrement number 0
VALUE=0
decvar VALUE && :; RETVAL="$?"
is "$VALUE"        '-1'     'Gotted value'
is "$RETVAL"       '0'      'Return value'
unset VALUE

## Decrement number 1
VALUE=1
decvar VALUE && :; RETVAL="$?"
is "$VALUE"        '0'      'Gotted value'
is "$RETVAL"       '0'      'Return value'
unset VALUE

## Decrement number 10
VALUE=10
decvar VALUE && :; RETVAL="$?"
is "$VALUE"        '9'      'Gotted value'
is "$RETVAL"       '0'      'Return value'
unset VALUE

## Decrement number 65536
VALUE=65536
decvar VALUE && :; RETVAL="$?"
is "$VALUE"        '65535'  'Gotted value'
is "$RETVAL"       '0'      'Return value'
unset VALUE

########################
####  Test ifvar()  ####
########################
tmpfile TMPFILE
ifvar a 2>"$TMPFILE" && :; RETVAL="$?"
readall ERRMSG <"$TMPFILE"
is "$RETVAL"  '1'                                   'Return value'
is "$ERRMSG"  "$BIN: ifvar: Bad variable name 'a'"  'Error message'

A='('
ifvar A && :; RETVAL="$?"
is "$RETVAL"       '0'      'Return value'
unset A

A=''
ifvar A && :; RETVAL="$?"
is "$RETVAL"       '1'      'Return value'
unset A

########################
####  Test eqvar()  ####
########################
tmpfile TMPFILE
eqvar a b 2>"$TMPFILE" && :; RETVAL="$?"
readall ERRMSG <"$TMPFILE"
is "$RETVAL"  '1'                                   'Return value'
is "$ERRMSG"  "$BIN: eqvar: Bad variable name 'a'"  'Error message'

tmpfile TMPFILE
eqvar A b 2>"$TMPFILE" && :; RETVAL="$?"
readall ERRMSG <"$TMPFILE"
is "$RETVAL"  '1'                                   'Return value'
is "$ERRMSG"  "$BIN: eqvar: Bad variable name 'b'"  'Error message'

A='('
B='('
eqvar A B && :; RETVAL="$?"
is "$RETVAL"       '0'      'Return value'
unset A B

A='"'
B='"'
eqvar A B && :; RETVAL="$?"
is "$RETVAL"       '0'      'Return value'
unset A B

A='\"'
B='\"'
eqvar A B && :; RETVAL="$?"
is "$RETVAL"       '0'      'Return value'
unset A B

A='('
B=')'
eqvar A B && :; RETVAL="$?"
is "$RETVAL"       '1'      'Return value'
unset A B

#############################
####  Test ok_varname()  ####
#############################
## Varname may not be empty
tmpfile TMPFILE
ok_varname '' 2>"$TMPFILE" && :; RETVAL="$?"
readall ERRMSG <"$TMPFILE"
is "$RETVAL"  '1'                                     'Return value'
is "$ERRMSG"  "$BIN: Bad variable name ''"            'Error message'

## Varname may not start with digit
tmpfile TMPFILE
ok_varname 0ABC 2>"$TMPFILE" && :; RETVAL="$?"
readall ERRMSG <"$TMPFILE"
is "$RETVAL"  '1'                                     'Return value'
is "$ERRMSG"  "$BIN: Bad variable name '0ABC'"        'Error message'

## Varname may not contain lower case
tmpfile TMPFILE
ok_varname ABCx test 2>"$TMPFILE" && :; RETVAL="$?"
readall ERRMSG <"$TMPFILE"
is "$RETVAL"  '1'                                     'Return value'
is "$ERRMSG"  "$BIN: test: Bad variable name 'ABCx'"  'Error message'

## Varname may start with/contain '_'
ok_varname _ABC && :; RETVAL="$?"
is "$RETVAL"  '0'                                     'Return value'

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

#########################################
#####  Test parse() error messages  #####
#########################################
## Badly placed '...' (at beginning)
INPUT='...'
tmpfile TMPFILE
parse GOTTED_RULES "$INPUT" 2>"$TMPFILE" && :; RETVAL="$?" # intentionally unquoted
readall ERRMSG <"$TMPFILE"
is "$RETVAL" '1'                                      'Return value'
is "$ERRMSG" "$BIN: Badly placed '...' in rule: ...
(Must come after ARGUMENT or end parenthesis/bracket.)" 'Error message'

## Badly placed '...' (after start parenthesis)
INPUT='( ...'
tmpfile TMPFILE
parse GOTTED_RULES "$INPUT" 2>"$TMPFILE" && :; RETVAL="$?" # intentionally unquoted
readall ERRMSG <"$TMPFILE"
is "$RETVAL" '1'                                      'Return value'
is "$ERRMSG" "$BIN: Badly placed '...' in rule: ( ...
(Must come after ARGUMENT or end parenthesis/bracket.)" 'Error message'

## Badly placed '|' (outside paren)
INPUT='|'
tmpfile TMPFILE
parse GOTTED_RULES "$INPUT" 2>"$TMPFILE" && :; RETVAL="$?" # intentionally unquoted
readall ERRMSG <"$TMPFILE"
is "$RETVAL" '1'                                     'Return value'
is "$ERRMSG" "$BIN: Badly placed '|' in rule: |
(Must be inside parentheses/brackets.)"                'Error message'

## One ')' too many
INPUT='A )'
tmpfile TMPFILE
parse GOTTED_RULES "$INPUT" 2>"$TMPFILE" && :; RETVAL="$?" # intentionally unquoted
readall ERRMSG <"$TMPFILE"
is "$RETVAL" '1'                                     'Return value'
is "$ERRMSG" "$BIN: Too many ')' in rule: A )"       'Error message'

## One ']' too many
INPUT='A ]'
tmpfile TMPFILE
parse GOTTED_RULES "$INPUT" 2>"$TMPFILE" && :; RETVAL="$?" # intentionally unquoted
readall ERRMSG <"$TMPFILE"
is "$RETVAL" '1'                                     'Return value'
is "$ERRMSG" "$BIN: Too many ']' in rule: A ]"       'Error message'

## Missing ')'
INPUT='[ A )'
tmpfile TMPFILE
parse GOTTED_RULES "$INPUT" 2>"$TMPFILE" && :; RETVAL="$?" # intentionally unquoted
readall ERRMSG <"$TMPFILE"
is "$RETVAL" '1'                                     'Return value'
is "$ERRMSG" "$BIN: Missing ')' in rule (group 1): [ A )" 'Error message'

## Missing ']'
INPUT='( A ]'
tmpfile TMPFILE
parse GOTTED_RULES "$INPUT" 2>"$TMPFILE" && :; RETVAL="$?" # intentionally unquoted
readall ERRMSG <"$TMPFILE"
is "$RETVAL" '1'                                     'Return value'
is "$ERRMSG" "$BIN: Missing ']' in rule (group 1): ( A ]" 'Error message'

## Missing ']'
INPUT='( A'
tmpfile TMPFILE
parse GOTTED_RULES "$INPUT" 2>"$TMPFILE" && :; RETVAL="$?" # intentionally unquoted
readall ERRMSG <"$TMPFILE"
is "$RETVAL" '1'                                     'Return value'
is "$ERRMSG" "$BIN: Missing ')' at end of rule: ( A" 'Error message'

###########################################
#####  Test parse() normal operation  #####
###########################################

INPUT='  [   [   A   ]   B   ]'
LEVEL='0 [ 1 [ 2 A 2 ] 1 B 1 ] 0'
GROUP='0 [ 1 [ 2 A 2 ] 1 B 1 ] 0'
STATE='0 [ 0 [ 0 A 2 ] 2 B 1 ] 1'
RULES='0 2 A
0 1 B
2 1 B
0 x
1 x'
parse GOTTED_RULES "$INPUT" && :; RETVAL="$?"  # intentionally unquoted
is "$RETVAL"       '0'      'Return value'
is "$_DEBUG_LEVEL" "$LEVEL" "Bracket level: '$INPUT'"
is "$_DEBUG_GROUP" "$GROUP" "Group numbers: '$INPUT'"
is "$_DEBUG_STATE" "$STATE" "State numbers: '$INPUT'"
is "$GOTTED_RULES" "$RULES"         "Rules: '$INPUT'"
unset INPUT LEVEL GROUP STATE RULES GOTTED_RULES RETVAL

INPUT='  [   A   [   B   ]   ]'
LEVEL='0 [ 1 A 1 [ 2 B 2 ] 1 ] 0'
GROUP='0 [ 1 A 1 [ 2 B 2 ] 1 ] 0'
STATE='0 [ 0 A 2 [ 2 B 3 ] 3 ] 3'
RULES='0 2 A
2 3 B
0 x
3 x'
parse GOTTED_RULES "$INPUT" && :; RETVAL="$?"  # intentionally unquoted
is "$RETVAL"       '0'      'Return value'
is "$_DEBUG_LEVEL" "$LEVEL" "Bracket level: '$INPUT'"
is "$_DEBUG_GROUP" "$GROUP" "Group numbers: '$INPUT'"
is "$_DEBUG_STATE" "$STATE" "State numbers: '$INPUT'"
is "$GOTTED_RULES" "$RULES"         "Rules: '$INPUT'"
unset INPUT LEVEL GROUP STATE RULES GOTTED_RULES RETVAL

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
parse GOTTED_RULES "$INPUT" && :; RETVAL="$?"  # intentionally unquoted
is "$RETVAL"       '0'      'Return value'
is "$_DEBUG_LEVEL" "$LEVEL" "Bracket level: '$INPUT'"
is "$_DEBUG_GROUP" "$GROUP" "Group numbers: '$INPUT'"
is "$_DEBUG_STATE" "$STATE" "State numbers: '$INPUT'"
is "$GOTTED_RULES" "$RULES"         "Rules: '$INPUT'"
unset INPUT LEVEL GROUP STATE RULES GOTTED_RULES RETVAL

INPUT='  [   A   ]'
LEVEL='0 [ 1 A 1 ] 0'
GROUP='0 [ 1 A 1 ] 0'
STATE='0 [ 0 A 1 ] 1'
RULES='0 1 A
0 x
1 x'
parse GOTTED_RULES "$INPUT" && :; RETVAL="$?"  # intentionally unquoted
is "$RETVAL"       '0'      'Return value'
is "$_DEBUG_LEVEL" "$LEVEL" "Bracket level: '$INPUT'"
is "$_DEBUG_GROUP" "$GROUP" "Group numbers: '$INPUT'"
is "$_DEBUG_STATE" "$STATE" "State numbers: '$INPUT'"
is "$GOTTED_RULES" "$RULES"         "Rules: '$INPUT'"
unset INPUT LEVEL GROUP STATE RULES GOTTED_RULES RETVAL

INPUT='  [   A   ]   B'
LEVEL='0 [ 1 A 1 ] 0 B 0'
GROUP='0 [ 1 A 1 ] 0 B 0'
STATE='0 [ 0 A 1 ] 1 B 2'
RULES='0 1 A
0 2 B
1 2 B
2 x'
parse GOTTED_RULES "$INPUT" && :; RETVAL="$?"  # intentionally unquoted
is "$RETVAL"       '0'      'Return value'
is "$_DEBUG_LEVEL" "$LEVEL" "Bracket level: '$INPUT'"
is "$_DEBUG_GROUP" "$GROUP" "Group numbers: '$INPUT'"
is "$_DEBUG_STATE" "$STATE" "State numbers: '$INPUT'"
is "$GOTTED_RULES" "$RULES"         "Rules: '$INPUT'"
unset INPUT LEVEL GROUP STATE RULES GOTTED_RULES RETVAL

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
parse GOTTED_RULES "$INPUT" && :; RETVAL="$?"  # intentionally unquoted
is "$RETVAL"       '0'      'Return value'
is "$_DEBUG_LEVEL" "$LEVEL" "Bracket level: '$INPUT'"
is "$_DEBUG_GROUP" "$GROUP" "Group numbers: '$INPUT'"
is "$_DEBUG_STATE" "$STATE" "State numbers: '$INPUT'"
is "$GOTTED_RULES" "$RULES"         "Rules: '$INPUT'"
unset INPUT LEVEL GROUP STATE RULES GOTTED_RULES RETVAL

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
parse GOTTED_RULES "$INPUT" && :; RETVAL="$?"  # intentionally unquoted
is "$RETVAL"       '0'      'Return value'
is "$_DEBUG_LEVEL" "$LEVEL" "Bracket level: '$INPUT'"
is "$_DEBUG_GROUP" "$GROUP" "Group numbers: '$INPUT'"
is "$_DEBUG_STATE" "$STATE" "State numbers: '$INPUT'"
is "$GOTTED_RULES" "$RULES"         "Rules: '$INPUT'"
unset INPUT LEVEL GROUP STATE RULES GOTTED_RULES RETVAL

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
parse GOTTED_RULES "$INPUT" && :; RETVAL="$?"  # intentionally unquoted
is "$RETVAL"       '0'      'Return value'
is "$_DEBUG_LEVEL" "$LEVEL" "Bracket level: '$INPUT'"
is "$_DEBUG_GROUP" "$GROUP" "Group numbers: '$INPUT'"
is "$_DEBUG_STATE" "$STATE" "State numbers: '$INPUT'"
is "$GOTTED_RULES" "$RULES"         "Rules: '$INPUT'"
unset INPUT LEVEL GROUP STATE RULES GOTTED_RULES RETVAL

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
parse GOTTED_RULES "$INPUT" && :; RETVAL="$?"  # intentionally unquoted
is "$RETVAL"       '0'      'Return value'
is "$_DEBUG_LEVEL" "$LEVEL" "Bracket level: '$INPUT'"
is "$_DEBUG_GROUP" "$GROUP" "Group numbers: '$INPUT'"
is "$_DEBUG_STATE" "$STATE" "State numbers: '$INPUT'"
is "$GOTTED_RULES" "$RULES"         "Rules: '$INPUT'"
unset INPUT LEVEL GROUP STATE RULES GOTTED_RULES RETVAL

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
parse GOTTED_RULES "$INPUT" && :; RETVAL="$?"  # intentionally unquoted
is "$RETVAL"       '0'      'Return value'
is "$_DEBUG_LEVEL" "$LEVEL" "Bracket level: '$INPUT'"
is "$_DEBUG_GROUP" "$GROUP" "Group numbers: '$INPUT'"
is "$_DEBUG_STATE" "$STATE" "State numbers: '$INPUT'"
is "$GOTTED_RULES" "$RULES"         "Rules: '$INPUT'"
unset INPUT LEVEL GROUP STATE RULES GOTTED_RULES RETVAL

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
parse GOTTED_RULES "$INPUT" && :; RETVAL="$?"  # intentionally unquoted
is "$RETVAL"       '0'      'Return value'
is "$_DEBUG_LEVEL" "$LEVEL" "Bracket level: '$INPUT'"
is "$_DEBUG_GROUP" "$GROUP" "Group numbers: '$INPUT'"
is "$_DEBUG_STATE" "$STATE" "State numbers: '$INPUT'"
is "$GOTTED_RULES" "$RULES"         "Rules: '$INPUT'"
unset INPUT LEVEL GROUP STATE RULES GOTTED_RULES RETVAL

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
parse GOTTED_RULES "$INPUT" && :; RETVAL="$?"  # intentionally unquoted
is "$RETVAL"       '0'      'Return value'
is "$_DEBUG_LEVEL" "$LEVEL" "Bracket level: '$INPUT'"
is "$_DEBUG_GROUP" "$GROUP" "Group numbers: '$INPUT'"
is "$_DEBUG_STATE" "$STATE" "State numbers: '$INPUT'"
is "$GOTTED_RULES" "$RULES"         "Rules: '$INPUT'"
unset INPUT LEVEL GROUP STATE RULES GOTTED_RULES RETVAL

INPUT='  [   A   ]   (   B   )'
LEVEL='0 [ 1 A 1 ] 0 ( 1 B 1 ) 0'
GROUP='0 [ 1 A 1 ] 0 ( 2 B 2 ) 0'
STATE='0 [ 0 A 1 ] 1 ( 1 B 2 ) 2'
RULES='0 1 A
0 2 B
1 2 B
2 x'
parse GOTTED_RULES "$INPUT" && :; RETVAL="$?"  # intentionally unquoted
is "$RETVAL"       '0'      'Return value'
is "$_DEBUG_LEVEL" "$LEVEL" "Bracket level: '$INPUT'"
is "$_DEBUG_GROUP" "$GROUP" "Group numbers: '$INPUT'"
is "$_DEBUG_STATE" "$STATE" "State numbers: '$INPUT'"
is "$GOTTED_RULES" "$RULES"         "Rules: '$INPUT'"
unset INPUT LEVEL GROUP STATE RULES GOTTED_RULES RETVAL

INPUT='  (   A   )   [   B   ]'
LEVEL='0 ( 1 A 1 ) 0 [ 1 B 1 ] 0'
GROUP='0 ( 1 A 1 ) 0 [ 2 B 2 ] 0'
STATE='0 ( 0 A 1 ) 1 [ 1 B 2 ] 2'
RULES='0 1 A
1 2 B
1 x
2 x'
parse GOTTED_RULES "$INPUT" && :; RETVAL="$?"  # intentionally unquoted
is "$RETVAL"       '0'      'Return value'
is "$_DEBUG_LEVEL" "$LEVEL" "Bracket level: '$INPUT'"
is "$_DEBUG_GROUP" "$GROUP" "Group numbers: '$INPUT'"
is "$_DEBUG_STATE" "$STATE" "State numbers: '$INPUT'"
is "$GOTTED_RULES" "$RULES"         "Rules: '$INPUT'"
unset INPUT LEVEL GROUP STATE RULES GOTTED_RULES RETVAL

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
parse GOTTED_RULES "$INPUT" && :; RETVAL="$?"  # intentionally unquoted
is "$RETVAL"       '0'      'Return value'
is "$_DEBUG_LEVEL" "$LEVEL" "Bracket level: '$INPUT'"
is "$_DEBUG_GROUP" "$GROUP" "Group numbers: '$INPUT'"
is "$_DEBUG_STATE" "$STATE" "State numbers: '$INPUT'"
is "$GOTTED_RULES" "$RULES"         "Rules: '$INPUT'"
unset INPUT LEVEL GROUP STATE RULES GOTTED_RULES RETVAL

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
parse GOTTED_RULES "$INPUT" && :; RETVAL="$?"  # intentionally unquoted
is "$RETVAL"       '0'      'Return value'
is "$_DEBUG_LEVEL" "$LEVEL" "Bracket level: '$INPUT'"
is "$_DEBUG_GROUP" "$GROUP" "Group numbers: '$INPUT'"
is "$_DEBUG_STATE" "$STATE" "State numbers: '$INPUT'"
is "$GOTTED_RULES" "$RULES"         "Rules: '$INPUT'"
unset INPUT LEVEL GROUP STATE RULES GOTTED_RULES RETVAL

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
parse GOTTED_RULES "$INPUT" && :; RETVAL="$?"  # intentionally unquoted
is "$RETVAL"       '0'      'Return value'
is "$_DEBUG_LEVEL" "$LEVEL" "Bracket level: '$INPUT'"
is "$_DEBUG_GROUP" "$GROUP" "Group numbers: '$INPUT'"
is "$_DEBUG_STATE" "$STATE" "State numbers: '$INPUT'"
is "$GOTTED_RULES" "$RULES"         "Rules: '$INPUT'"
unset INPUT LEVEL GROUP STATE RULES GOTTED_RULES RETVAL

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
parse GOTTED_RULES "$INPUT" && :; RETVAL="$?"  # intentionally unquoted
is "$RETVAL"       '0'      'Return value'
is "$_DEBUG_LEVEL" "$LEVEL" "Bracket level: '$INPUT'"
is "$_DEBUG_GROUP" "$GROUP" "Group numbers: '$INPUT'"
is "$_DEBUG_STATE" "$STATE" "State numbers: '$INPUT'"
is "$GOTTED_RULES" "$RULES"         "Rules: '$INPUT'"
unset INPUT LEVEL GROUP STATE RULES GOTTED_RULES RETVAL

INPUT='  A'
LEVEL='0 A 0'
GROUP='0 A 0'
STATE='0 A 1'
RULES='0 1 A
1 x'
parse GOTTED_RULES "$INPUT" && :; RETVAL="$?"  # intentionally unquoted
is "$RETVAL"       '0'      'Return value'
is "$_DEBUG_LEVEL" "$LEVEL" "Bracket level: '$INPUT'"
is "$_DEBUG_GROUP" "$GROUP" "Group numbers: '$INPUT'"
is "$_DEBUG_STATE" "$STATE" "State numbers: '$INPUT'"
is "$GOTTED_RULES" "$RULES"         "Rules: '$INPUT'"
unset INPUT LEVEL GROUP STATE RULES GOTTED_RULES RETVAL

INPUT='  A   B'
LEVEL='0 A 0 B 0'
GROUP='0 A 0 B 0'
STATE='0 A 1 B 2'
RULES='0 1 A
1 2 B
2 x'
parse GOTTED_RULES "$INPUT" && :; RETVAL="$?"  # intentionally unquoted
is "$RETVAL"       '0'      'Return value'
is "$_DEBUG_LEVEL" "$LEVEL" "Bracket level: '$INPUT'"
is "$_DEBUG_GROUP" "$GROUP" "Group numbers: '$INPUT'"
is "$_DEBUG_STATE" "$STATE" "State numbers: '$INPUT'"
is "$GOTTED_RULES" "$RULES"         "Rules: '$INPUT'"
unset INPUT LEVEL GROUP STATE RULES GOTTED_RULES RETVAL

INPUT='  (   A   B   )'
LEVEL='0 ( 1 A 1 B 1 ) 0'
GROUP='0 ( 1 A 1 B 1 ) 0'
STATE='0 ( 0 A 2 B 1 ) 1'
RULES='0 2 A
2 1 B
1 x'
parse GOTTED_RULES "$INPUT" && :; RETVAL="$?"  # intentionally unquoted
is "$RETVAL"       '0'      'Return value'
is "$_DEBUG_LEVEL" "$LEVEL" "Bracket level: '$INPUT'"
is "$_DEBUG_GROUP" "$GROUP" "Group numbers: '$INPUT'"
is "$_DEBUG_STATE" "$STATE" "State numbers: '$INPUT'"
is "$GOTTED_RULES" "$RULES"         "Rules: '$INPUT'"
unset INPUT LEVEL GROUP STATE RULES GOTTED_RULES RETVAL

INPUT='  (   A   B   ) ...'
LEVEL='0 ( 1 A 1 B 1 ) 0 ... 0'
GROUP='0 ( 1 A 1 B 1 ) 0 ... 0'
STATE='0 ( 0 A 2 B 1 ) 1 ... 1'
RULES='0 2 A
2 1 B
1 2 A
1 x'
parse GOTTED_RULES "$INPUT" && :; RETVAL="$?"  # intentionally unquoted
is "$RETVAL"       '0'      'Return value'
is "$_DEBUG_LEVEL" "$LEVEL" "Bracket level: '$INPUT'"
is "$_DEBUG_GROUP" "$GROUP" "Group numbers: '$INPUT'"
is "$_DEBUG_STATE" "$STATE" "State numbers: '$INPUT'"
is "$GOTTED_RULES" "$RULES"         "Rules: '$INPUT'"
unset INPUT LEVEL GROUP STATE RULES GOTTED_RULES RETVAL

INPUT='  (   A   )   B'
LEVEL='0 ( 1 A 1 ) 0 B 0'
GROUP='0 ( 1 A 1 ) 0 B 0'
STATE='0 ( 0 A 1 ) 1 B 2'
RULES='0 1 A
1 2 B
2 x'
parse GOTTED_RULES "$INPUT" && :; RETVAL="$?"  # intentionally unquoted
is "$RETVAL"       '0'      'Return value'
is "$_DEBUG_LEVEL" "$LEVEL" "Bracket level: '$INPUT'"
is "$_DEBUG_GROUP" "$GROUP" "Group numbers: '$INPUT'"
is "$_DEBUG_STATE" "$STATE" "State numbers: '$INPUT'"
is "$GOTTED_RULES" "$RULES"         "Rules: '$INPUT'"
unset INPUT LEVEL GROUP STATE RULES GOTTED_RULES RETVAL

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
parse GOTTED_RULES "$INPUT" && :; RETVAL="$?"  # intentionally unquoted
is "$RETVAL"       '0'      'Return value'
is "$_DEBUG_LEVEL" "$LEVEL" "Bracket level: '$INPUT'"
is "$_DEBUG_GROUP" "$GROUP" "Group numbers: '$INPUT'"
is "$_DEBUG_STATE" "$STATE" "State numbers: '$INPUT'"
is "$GOTTED_RULES" "$RULES"         "Rules: '$INPUT'"
unset INPUT LEVEL GROUP STATE RULES GOTTED_RULES RETVAL

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
## FIXME Why does '1 1 A' exist twice in above rules?
# One would expect these rules instead
# RULES='0 1 A
# 1 1 A
# 0 1 B
# 1 1 B
# 1 x'
parse GOTTED_RULES "$INPUT" && :; RETVAL="$?"  # intentionally unquoted
is "$RETVAL"       '0'      'Return value'
is "$_DEBUG_LEVEL" "$LEVEL" "Bracket level: '$INPUT'"
is "$_DEBUG_GROUP" "$GROUP" "Group numbers: '$INPUT'"
is "$_DEBUG_STATE" "$STATE" "State numbers: '$INPUT'"
is "$GOTTED_RULES" "$RULES"         "Rules: '$INPUT'"
unset INPUT LEVEL GROUP STATE RULES GOTTED_RULES RETVAL

INPUT='  (   A   )   ...   B'
LEVEL='0 ( 1 A 1 ) 0 ... 0 B 0'
GROUP='0 ( 1 A 1 ) 0 ... 0 B 0'
STATE='0 ( 0 A 1 ) 1 ... 1 B 2'
RULES='0 1 A
1 1 A
1 2 B
2 x'
parse GOTTED_RULES "$INPUT" && :; RETVAL="$?"  # intentionally unquoted
is "$RETVAL"       '0'      'Return value'
is "$_DEBUG_LEVEL" "$LEVEL" "Bracket level: '$INPUT'"
is "$_DEBUG_GROUP" "$GROUP" "Group numbers: '$INPUT'"
is "$_DEBUG_STATE" "$STATE" "State numbers: '$INPUT'"
is "$GOTTED_RULES" "$RULES"         "Rules: '$INPUT'"
unset INPUT LEVEL GROUP STATE RULES GOTTED_RULES RETVAL

INPUT='  A   (   B   )'
LEVEL='0 A 0 ( 1 B 1 ) 0'
GROUP='0 A 0 ( 1 B 1 ) 0'
STATE='0 A 1 ( 1 B 2 ) 2'
RULES='0 1 A
1 2 B
2 x'
parse GOTTED_RULES "$INPUT" && :; RETVAL="$?"  # intentionally unquoted
is "$RETVAL"       '0'      'Return value'
is "$_DEBUG_LEVEL" "$LEVEL" "Bracket level: '$INPUT'"
is "$_DEBUG_GROUP" "$GROUP" "Group numbers: '$INPUT'"
is "$_DEBUG_STATE" "$STATE" "State numbers: '$INPUT'"
is "$GOTTED_RULES" "$RULES"         "Rules: '$INPUT'"
unset INPUT LEVEL GROUP STATE RULES GOTTED_RULES RETVAL

INPUT='  A   (   B   ) ...'
LEVEL='0 A 0 ( 1 B 1 ) 0 ... 0'
GROUP='0 A 0 ( 1 B 1 ) 0 ... 0'
STATE='0 A 1 ( 1 B 2 ) 2 ... 2'
RULES='0 1 A
1 2 B
2 2 B
2 x'
parse GOTTED_RULES "$INPUT" && :; RETVAL="$?"  # intentionally unquoted
is "$RETVAL"       '0'      'Return value'
is "$_DEBUG_LEVEL" "$LEVEL" "Bracket level: '$INPUT'"
is "$_DEBUG_GROUP" "$GROUP" "Group numbers: '$INPUT'"
is "$_DEBUG_STATE" "$STATE" "State numbers: '$INPUT'"
is "$GOTTED_RULES" "$RULES"         "Rules: '$INPUT'"
unset INPUT LEVEL GROUP STATE RULES GOTTED_RULES RETVAL

INPUT='  (   A   )   (   B   )'
LEVEL='0 ( 1 A 1 ) 0 ( 1 B 1 ) 0'
GROUP='0 ( 1 A 1 ) 0 ( 2 B 2 ) 0'
STATE='0 ( 0 A 1 ) 1 ( 1 B 2 ) 2'
RULES='0 1 A
1 2 B
2 x'
parse GOTTED_RULES "$INPUT" && :; RETVAL="$?"  # intentionally unquoted
is "$RETVAL"       '0'      'Return value'
is "$_DEBUG_LEVEL" "$LEVEL" "Bracket level: '$INPUT'"
is "$_DEBUG_GROUP" "$GROUP" "Group numbers: '$INPUT'"
is "$_DEBUG_STATE" "$STATE" "State numbers: '$INPUT'"
is "$GOTTED_RULES" "$RULES"         "Rules: '$INPUT'"
unset INPUT LEVEL GROUP STATE RULES GOTTED_RULES RETVAL

INPUT='  (   A   )   ...   (   B   )'
LEVEL='0 ( 1 A 1 ) 0 ... 0 ( 1 B 1 ) 0'
GROUP='0 ( 1 A 1 ) 0 ... 0 ( 2 B 2 ) 0'
STATE='0 ( 0 A 1 ) 1 ... 1 ( 1 B 2 ) 2'
RULES='0 1 A
1 1 A
1 2 B
2 x'
parse GOTTED_RULES "$INPUT" && :; RETVAL="$?"  # intentionally unquoted
is "$RETVAL"       '0'      'Return value'
is "$_DEBUG_LEVEL" "$LEVEL" "Bracket level: '$INPUT'"
is "$_DEBUG_GROUP" "$GROUP" "Group numbers: '$INPUT'"
is "$_DEBUG_STATE" "$STATE" "State numbers: '$INPUT'"
is "$GOTTED_RULES" "$RULES"         "Rules: '$INPUT'"
unset INPUT LEVEL GROUP STATE RULES GOTTED_RULES RETVAL

INPUT='  (   A   )   (   B   )   ...'
LEVEL='0 ( 1 A 1 ) 0 ( 1 B 1 ) 0 ... 0'
GROUP='0 ( 1 A 1 ) 0 ( 2 B 2 ) 0 ... 0'
STATE='0 ( 0 A 1 ) 1 ( 1 B 2 ) 2 ... 2'
RULES='0 1 A
1 2 B
2 2 B
2 x'
parse GOTTED_RULES "$INPUT" && :; RETVAL="$?"  # intentionally unquoted
is "$RETVAL"       '0'      'Return value'
is "$_DEBUG_LEVEL" "$LEVEL" "Bracket level: '$INPUT'"
is "$_DEBUG_GROUP" "$GROUP" "Group numbers: '$INPUT'"
is "$_DEBUG_STATE" "$STATE" "State numbers: '$INPUT'"
is "$GOTTED_RULES" "$RULES"         "Rules: '$INPUT'"
unset INPUT LEVEL GROUP STATE RULES GOTTED_RULES RETVAL

INPUT='  (   A   )   ...   (   B   )   ...'
LEVEL='0 ( 1 A 1 ) 0 ... 0 ( 1 B 1 ) 0 ... 0'
GROUP='0 ( 1 A 1 ) 0 ... 0 ( 2 B 2 ) 0 ... 0'
STATE='0 ( 0 A 1 ) 1 ... 1 ( 1 B 2 ) 2 ... 2'
RULES='0 1 A
1 1 A
1 2 B
2 2 B
2 x'
parse GOTTED_RULES "$INPUT" && :; RETVAL="$?"  # intentionally unquoted
is "$RETVAL"       '0'      'Return value'
is "$_DEBUG_LEVEL" "$LEVEL" "Bracket level: '$INPUT'"
is "$_DEBUG_GROUP" "$GROUP" "Group numbers: '$INPUT'"
is "$_DEBUG_STATE" "$STATE" "State numbers: '$INPUT'"
is "$GOTTED_RULES" "$RULES"         "Rules: '$INPUT'"
unset INPUT LEVEL GROUP STATE RULES GOTTED_RULES RETVAL

INPUT='  (   (   A   )   B   )'
LEVEL='0 ( 1 ( 2 A 2 ) 1 B 1 ) 0'
GROUP='0 ( 1 ( 2 A 2 ) 1 B 1 ) 0'
STATE='0 ( 0 ( 0 A 2 ) 2 B 1 ) 1'
RULES='0 2 A
2 1 B
1 x'
parse GOTTED_RULES "$INPUT" && :; RETVAL="$?"  # intentionally unquoted
is "$RETVAL"       '0'      'Return value'
is "$_DEBUG_LEVEL" "$LEVEL" "Bracket level: '$INPUT'"
is "$_DEBUG_GROUP" "$GROUP" "Group numbers: '$INPUT'"
is "$_DEBUG_STATE" "$STATE" "State numbers: '$INPUT'"
is "$GOTTED_RULES" "$RULES"         "Rules: '$INPUT'"
unset INPUT LEVEL GROUP STATE RULES GOTTED_RULES RETVAL

INPUT='  (   A   (   B   )   )'
LEVEL='0 ( 1 A 1 ( 2 B 2 ) 1 ) 0'
GROUP='0 ( 1 A 1 ( 2 B 2 ) 1 ) 0'
STATE='0 ( 0 A 2 ( 2 B 3 ) 3 ) 3'              # (state 1 never used)
RULES='0 2 A
2 3 B
3 x'
parse GOTTED_RULES "$INPUT" && :; RETVAL="$?"  # intentionally unquoted
is "$RETVAL"       '0'      'Return value'
is "$_DEBUG_LEVEL" "$LEVEL" "Bracket level: '$INPUT'"
is "$_DEBUG_GROUP" "$GROUP" "Group numbers: '$INPUT'"
is "$_DEBUG_STATE" "$STATE" "State numbers: '$INPUT'"
is "$GOTTED_RULES" "$RULES"         "Rules: '$INPUT'"
unset INPUT LEVEL GROUP STATE RULES GOTTED_RULES RETVAL

INPUT='  (   A   (   B   (   C   )   )   )'
LEVEL='0 ( 1 A 1 ( 2 B 2 ( 3 C 3 ) 2 ) 1 ) 0'
GROUP='0 ( 1 A 1 ( 2 B 2 ( 3 C 3 ) 2 ) 1 ) 0'
STATE='0 ( 0 A 2 ( 2 B 4 ( 4 C 5 ) 5 ) 5 ) 5'  # (state 1 & 3 never used)
RULES='0 2 A
2 4 B
4 5 C
5 x'
parse GOTTED_RULES "$INPUT" && :; RETVAL="$?"  # intentionally unquoted
is "$RETVAL"       '0'      'Return value'
is "$_DEBUG_LEVEL" "$LEVEL" "Bracket level: '$INPUT'"
is "$_DEBUG_GROUP" "$GROUP" "Group numbers: '$INPUT'"
is "$_DEBUG_STATE" "$STATE" "State numbers: '$INPUT'"
is "$GOTTED_RULES" "$RULES"         "Rules: '$INPUT'"
unset INPUT LEVEL GROUP STATE RULES GOTTED_RULES RETVAL

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
parse GOTTED_RULES "$INPUT" && :; RETVAL="$?"  # intentionally unquoted
is "$RETVAL"       '0'      'Return value'
is "$_DEBUG_LEVEL" "$LEVEL" "Bracket level: '$INPUT'"
is "$_DEBUG_GROUP" "$GROUP" "Group numbers: '$INPUT'"
is "$_DEBUG_STATE" "$STATE" "State numbers: '$INPUT'"
is "$GOTTED_RULES" "$RULES"         "Rules: '$INPUT'"
unset INPUT LEVEL GROUP STATE RULES GOTTED_RULES RETVAL

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
parse GOTTED_RULES "$INPUT" && :; RETVAL="$?"  # intentionally unquoted
is "$RETVAL"       '0'      'Return value'
is "$_DEBUG_LEVEL" "$LEVEL" "Bracket level: '$INPUT'"
is "$_DEBUG_GROUP" "$GROUP" "Group numbers: '$INPUT'"
is "$_DEBUG_STATE" "$STATE" "State numbers: '$INPUT'"
is "$GOTTED_RULES" "$RULES"         "Rules: '$INPUT'"
unset INPUT LEVEL GROUP STATE RULES GOTTED_RULES RETVAL

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
parse GOTTED_RULES "$INPUT" && :; RETVAL="$?"  # intentionally unquoted
is "$RETVAL"       '0'      'Return value'
is "$_DEBUG_LEVEL" "$LEVEL" "Bracket level: '$INPUT'"
is "$_DEBUG_GROUP" "$GROUP" "Group numbers: '$INPUT'"
is "$_DEBUG_STATE" "$STATE" "State numbers: '$INPUT'"
is "$GOTTED_RULES" "$RULES"         "Rules: '$INPUT'"
unset INPUT LEVEL GROUP STATE RULES GOTTED_RULES RETVAL

INPUT='  (   A   )'
LEVEL='0 ( 1 A 1 ) 0'
GROUP='0 ( 1 A 1 ) 0'
STATE='0 ( 0 A 1 ) 1'
RULES='0 1 A
1 x'
parse GOTTED_RULES "$INPUT" && :; RETVAL="$?"  # intentionally unquoted
is "$RETVAL"       '0'      'Return value'
is "$_DEBUG_LEVEL" "$LEVEL" "Bracket level: '$INPUT'"
is "$_DEBUG_GROUP" "$GROUP" "Group numbers: '$INPUT'"
is "$_DEBUG_STATE" "$STATE" "State numbers: '$INPUT'"
is "$GOTTED_RULES" "$RULES"         "Rules: '$INPUT'"
unset INPUT LEVEL GROUP STATE RULES GOTTED_RULES RETVAL

INPUT='  (   (   A   B   )   )'
LEVEL='0 ( 1 ( 2 A 2 B 2 ) 1 ) 0'
GROUP='0 ( 1 ( 2 A 2 B 2 ) 1 ) 0'
STATE='0 ( 0 ( 0 A 3 B 2 ) 2 ) 2'
RULES='0 3 A
3 2 B
2 x'
parse GOTTED_RULES "$INPUT" && :; RETVAL="$?"  # intentionally unquoted
is "$RETVAL"       '0'      'Return value'
is "$_DEBUG_LEVEL" "$LEVEL" "Bracket level: '$INPUT'"
is "$_DEBUG_GROUP" "$GROUP" "Group numbers: '$INPUT'"
is "$_DEBUG_STATE" "$STATE" "State numbers: '$INPUT'"
is "$GOTTED_RULES" "$RULES"         "Rules: '$INPUT'"
unset INPUT LEVEL GROUP STATE RULES GOTTED_RULES RETVAL

INPUT='  [   A   ]'
LEVEL='0 [ 1 A 1 ] 0'
GROUP='0 [ 1 A 1 ] 0'
STATE='0 [ 0 A 1 ] 1'
RULES='0 1 A
0 x
1 x'
parse GOTTED_RULES "$INPUT" && :; RETVAL="$?"  # intentionally unquoted
is "$RETVAL"       '0'      'Return value'
is "$_DEBUG_LEVEL" "$LEVEL" "Bracket level: '$INPUT'"
is "$_DEBUG_GROUP" "$GROUP" "Group numbers: '$INPUT'"
is "$_DEBUG_STATE" "$STATE" "State numbers: '$INPUT'"
is "$GOTTED_RULES" "$RULES"         "Rules: '$INPUT'"
unset INPUT LEVEL GROUP STATE RULES GOTTED_RULES RETVAL

INPUT='  (   A   |   B   )'
LEVEL='0 ( 1 A 1 | 1 B 1 ) 0'
GROUP='0 ( 1 A 1 | 1 B 1 ) 0'
STATE='0 ( 0 A 1 | 0 B 1 ) 1'
RULES='0 1 A
0 1 B
1 x'
parse GOTTED_RULES "$INPUT" && :; RETVAL="$?"  # intentionally unquoted
is "$RETVAL"       '0'      'Return value'
is "$_DEBUG_LEVEL" "$LEVEL" "Bracket level: '$INPUT'"
is "$_DEBUG_GROUP" "$GROUP" "Group numbers: '$INPUT'"
is "$_DEBUG_STATE" "$STATE" "State numbers: '$INPUT'"
is "$GOTTED_RULES" "$RULES"         "Rules: '$INPUT'"
unset INPUT LEVEL GROUP STATE RULES GOTTED_RULES RETVAL

INPUT='  (   A   |   B   )   ...'
LEVEL='0 ( 1 A 1 | 1 B 1 ) 0 ... 0'
GROUP='0 ( 1 A 1 | 1 B 1 ) 0 ... 0'
STATE='0 ( 0 A 1 | 0 B 1 ) 1 ... 1'
RULES='0 1 A
0 1 B
1 1 A
1 1 B
1 x'
parse GOTTED_RULES "$INPUT" && :; RETVAL="$?"  # intentionally unquoted
is "$RETVAL"       '0'      'Return value'
is "$_DEBUG_LEVEL" "$LEVEL" "Bracket level: '$INPUT'"
is "$_DEBUG_GROUP" "$GROUP" "Group numbers: '$INPUT'"
is "$_DEBUG_STATE" "$STATE" "State numbers: '$INPUT'"
is "$GOTTED_RULES" "$RULES"         "Rules: '$INPUT'"
unset INPUT LEVEL GROUP STATE RULES GOTTED_RULES RETVAL

INPUT='  A   ...   B'
LEVEL='0 A 0 ... 0 B 0'
GROUP='0 A 0 ... 0 B 0'
STATE='0 A 1 ... 1 B 2'
RULES='0 1 A
1 1 A
1 2 B
2 x'
parse GOTTED_RULES "$INPUT" && :; RETVAL="$?"  # intentionally unquoted
is "$RETVAL"       '0'      'Return value'
is "$_DEBUG_LEVEL" "$LEVEL" "Bracket level: '$INPUT'"
is "$_DEBUG_GROUP" "$GROUP" "Group numbers: '$INPUT'"
is "$_DEBUG_STATE" "$STATE" "State numbers: '$INPUT'"
is "$GOTTED_RULES" "$RULES"         "Rules: '$INPUT'"
unset INPUT LEVEL GROUP STATE RULES GOTTED_RULES RETVAL

INPUT='  (   A   ) ... B'
LEVEL='0 ( 1 A 1 ) 0 ... 0 B 0'
GROUP='0 ( 1 A 1 ) 0 ... 0 B 0'
STATE='0 ( 0 A 1 ) 1 ... 1 B 2'
RULES='0 1 A
1 1 A
1 2 B
2 x'
parse GOTTED_RULES "$INPUT" && :; RETVAL="$?"  # intentionally unquoted
is "$RETVAL"       '0'      'Return value'
is "$_DEBUG_LEVEL" "$LEVEL" "Bracket level: '$INPUT'"
is "$_DEBUG_GROUP" "$GROUP" "Group numbers: '$INPUT'"
is "$_DEBUG_STATE" "$STATE" "State numbers: '$INPUT'"
is "$GOTTED_RULES" "$RULES"         "Rules: '$INPUT'"
unset INPUT LEVEL GROUP STATE RULES GOTTED_RULES RETVAL

INPUT='  (   A   B   )   ...'
LEVEL='0 ( 1 A 1 B 1 ) 0 ... 0'
GROUP='0 ( 1 A 1 B 1 ) 0 ... 0'
STATE='0 ( 0 A 2 B 1 ) 1 ... 1'
RULES='0 2 A
2 1 B
1 2 A
1 x'
parse GOTTED_RULES "$INPUT" && :; RETVAL="$?"  # intentionally unquoted
is "$RETVAL"       '0'      'Return value'
is "$_DEBUG_LEVEL" "$LEVEL" "Bracket level: '$INPUT'"
is "$_DEBUG_GROUP" "$GROUP" "Group numbers: '$INPUT'"
is "$_DEBUG_STATE" "$STATE" "State numbers: '$INPUT'"
is "$GOTTED_RULES" "$RULES"         "Rules: '$INPUT'"
unset INPUT LEVEL GROUP STATE RULES GOTTED_RULES RETVAL

INPUT='  (   A   )   (   B   )'
LEVEL='0 ( 1 A 1 ) 0 ( 1 B 1 ) 0'
GROUP='0 ( 1 A 1 ) 0 ( 2 B 2 ) 0'
STATE='0 ( 0 A 1 ) 1 ( 1 B 2 ) 2'
RULES='0 1 A
1 2 B
2 x'
parse GOTTED_RULES "$INPUT" && :; RETVAL="$?"  # intentionally unquoted
is "$RETVAL"       '0'      'Return value'
is "$_DEBUG_LEVEL" "$LEVEL" "Bracket level: '$INPUT'"
is "$_DEBUG_GROUP" "$GROUP" "Group numbers: '$INPUT'"
is "$_DEBUG_STATE" "$STATE" "State numbers: '$INPUT'"
is "$GOTTED_RULES" "$RULES"         "Rules: '$INPUT'"
unset INPUT LEVEL GROUP STATE RULES GOTTED_RULES RETVAL

INPUT='  (   A   )   (   B   )   ...'
LEVEL='0 ( 1 A 1 ) 0 ( 1 B 1 ) 0 ... 0'
GROUP='0 ( 1 A 1 ) 0 ( 2 B 2 ) 0 ... 0'
STATE='0 ( 0 A 1 ) 1 ( 1 B 2 ) 2 ... 2'
RULES='0 1 A
1 2 B
2 2 B
2 x'
parse GOTTED_RULES "$INPUT" && :; RETVAL="$?"  # intentionally unquoted
is "$RETVAL"       '0'      'Return value'
is "$_DEBUG_LEVEL" "$LEVEL" "Bracket level: '$INPUT'"
is "$_DEBUG_GROUP" "$GROUP" "Group numbers: '$INPUT'"
is "$_DEBUG_STATE" "$STATE" "State numbers: '$INPUT'"
is "$GOTTED_RULES" "$RULES"         "Rules: '$INPUT'"
unset INPUT LEVEL GROUP STATE RULES GOTTED_RULES RETVAL

INPUT='  (   A   (   B   )   )   ...'
LEVEL='0 ( 1 A 1 ( 2 B 2 ) 1 ) 0 ... 0'
GROUP='0 ( 1 A 1 ( 2 B 2 ) 1 ) 0 ... 0'
STATE='0 ( 0 A 2 ( 2 B 3 ) 3 ) 3 ... 3'
RULES='0 2 A
2 3 B
3 2 A
3 x'
parse GOTTED_RULES "$INPUT" && :; RETVAL="$?"  # intentionally unquoted
is "$RETVAL"       '0'      'Return value'
is "$_DEBUG_LEVEL" "$LEVEL" "Bracket level: '$INPUT'"
is "$_DEBUG_GROUP" "$GROUP" "Group numbers: '$INPUT'"
is "$_DEBUG_STATE" "$STATE" "State numbers: '$INPUT'"
is "$GOTTED_RULES" "$RULES"         "Rules: '$INPUT'"
unset INPUT LEVEL GROUP STATE RULES GOTTED_RULES RETVAL

INPUT='  (   (   A   )   B   )   ...'
LEVEL='0 ( 1 ( 2 A 2 ) 1 B 1 ) 0 ... 0'
GROUP='0 ( 1 ( 2 A 2 ) 1 B 1 ) 0 ... 0'
STATE='0 ( 0 ( 0 A 2 ) 2 B 1 ) 1 ... 1'
RULES='0 2 A
2 1 B
1 2 A
1 x'
parse GOTTED_RULES "$INPUT" && :; RETVAL="$?"  # intentionally unquoted
is "$RETVAL"       '0'      'Return value'
is "$_DEBUG_LEVEL" "$LEVEL" "Bracket level: '$INPUT'"
is "$_DEBUG_GROUP" "$GROUP" "Group numbers: '$INPUT'"
is "$_DEBUG_STATE" "$STATE" "State numbers: '$INPUT'"
is "$GOTTED_RULES" "$RULES"         "Rules: '$INPUT'"
unset INPUT LEVEL GROUP STATE RULES GOTTED_RULES RETVAL

INPUT='  (   (   (   A   )   B   )   C   )   ...'
LEVEL='0 ( 1 ( 2 ( 3 A 3 ) 2 B 2 ) 1 C 1 ) 0 ... 0'
GROUP='0 ( 1 ( 2 ( 3 A 3 ) 2 B 2 ) 1 C 1 ) 0 ... 0'
STATE='0 ( 0 ( 0 ( 0 A 3 ) 3 B 2 ) 2 C 1 ) 1 ... 1'
RULES='0 3 A
3 2 B
2 1 C
1 3 A
1 x'
parse GOTTED_RULES "$INPUT" && :; RETVAL="$?"  # intentionally unquoted
is "$RETVAL"       '0'      'Return value'
is "$_DEBUG_LEVEL" "$LEVEL" "Bracket level: '$INPUT'"
is "$_DEBUG_GROUP" "$GROUP" "Group numbers: '$INPUT'"
is "$_DEBUG_STATE" "$STATE" "State numbers: '$INPUT'"
is "$GOTTED_RULES" "$RULES"         "Rules: '$INPUT'"
unset INPUT LEVEL GROUP STATE RULES GOTTED_RULES RETVAL


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
parse GOTTED_RULES "$INPUT" && :; RETVAL="$?"  # intentionally unquoted
is "$RETVAL"       '0'      'Return value'
is "$_DEBUG_LEVEL" "$LEVEL" "Bracket level: '$INPUT'"
is "$_DEBUG_GROUP" "$GROUP" "Group numbers: '$INPUT'"
is "$_DEBUG_STATE" "$STATE" "State numbers: '$INPUT'"
is "$GOTTED_RULES" "$RULES"         "Rules: '$INPUT'"
unset INPUT LEVEL GROUP STATE RULES GOTTED_RULES RETVAL

INPUT='  (   (   A   )   ...   B   )'
LEVEL='0 ( 1 ( 2 A 2 ) 1 ... 1 B 1 ) 0'
GROUP='0 ( 1 ( 2 A 2 ) 1 ... 1 B 1 ) 0'
STATE='0 ( 0 ( 0 A 2 ) 2 ... 2 B 1 ) 1'
RULES='0 2 A
2 2 A
2 1 B
1 x'
parse GOTTED_RULES "$INPUT" && :; RETVAL="$?"  # intentionally unquoted
is "$RETVAL"       '0'      'Return value'
is "$_DEBUG_LEVEL" "$LEVEL" "Bracket level: '$INPUT'"
is "$_DEBUG_GROUP" "$GROUP" "Group numbers: '$INPUT'"
is "$_DEBUG_STATE" "$STATE" "State numbers: '$INPUT'"
is "$GOTTED_RULES" "$RULES"         "Rules: '$INPUT'"
unset INPUT LEVEL GROUP STATE RULES GOTTED_RULES RETVAL

INPUT='  (   (   A   )   ...   B   )   ...'
LEVEL='0 ( 1 ( 2 A 2 ) 1 ... 1 B 1 ) 0 ... 0'
GROUP='0 ( 1 ( 2 A 2 ) 1 ... 1 B 1 ) 0 ... 0'
STATE='0 ( 0 ( 0 A 2 ) 2 ... 2 B 1 ) 1 ... 1'
RULES='0 2 A
2 2 A
2 1 B
1 2 A
1 x'
parse GOTTED_RULES "$INPUT" && :; RETVAL="$?"  # intentionally unquoted
is "$RETVAL"       '0'      'Return value'
is "$_DEBUG_LEVEL" "$LEVEL" "Bracket level: '$INPUT'"
is "$_DEBUG_GROUP" "$GROUP" "Group numbers: '$INPUT'"
is "$_DEBUG_STATE" "$STATE" "State numbers: '$INPUT'"
is "$GOTTED_RULES" "$RULES"         "Rules: '$INPUT'"
unset INPUT LEVEL GROUP STATE RULES GOTTED_RULES RETVAL

INPUT='  (   A   (   B   (   C   )   )   )   ...'
LEVEL='0 ( 1 A 1 ( 2 B 2 ( 3 C 3 ) 2 ) 1 ) 0 ... 0'
GROUP='0 ( 1 A 1 ( 2 B 2 ( 3 C 3 ) 2 ) 1 ) 0 ... 0'
STATE='0 ( 0 A 2 ( 2 B 4 ( 4 C 5 ) 5 ) 5 ) 5 ... 5'
RULES='0 2 A
2 4 B
4 5 C
5 2 A
5 x'
parse GOTTED_RULES "$INPUT" && :; RETVAL="$?"  # intentionally unquoted
is "$RETVAL"       '0'      'Return value'
is "$_DEBUG_LEVEL" "$LEVEL" "Bracket level: '$INPUT'"
is "$_DEBUG_GROUP" "$GROUP" "Group numbers: '$INPUT'"
is "$_DEBUG_STATE" "$STATE" "State numbers: '$INPUT'"
is "$GOTTED_RULES" "$RULES"         "Rules: '$INPUT'"
unset INPUT LEVEL GROUP STATE RULES GOTTED_RULES RETVAL

######################################################################
##
##  Tests from Images of Finite State Automaton (4 tests)
##

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
parse GOTTED_RULES "$INPUT" && :; RETVAL="$?"  # intentionally unquoted
is "$RETVAL"       '0'      'Return value'
is "$_DEBUG_LEVEL" "$LEVEL" "Bracket level: '$INPUT'"
is "$_DEBUG_GROUP" "$GROUP" "Group numbers: '$INPUT'"
is "$_DEBUG_STATE" "$STATE" "State numbers: '$INPUT'"
is "$GOTTED_RULES" "$RULES"         "Rules: '$INPUT'"
unset INPUT LEVEL GROUP STATE RULES GOTTED_RULES RETVAL

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
parse GOTTED_RULES "$INPUT" && :; RETVAL="$?"  # intentionally unquoted
is "$RETVAL"       '0'      'Return value'
is "$_DEBUG_LEVEL" "$LEVEL" "Bracket level: '$INPUT'"
is "$_DEBUG_GROUP" "$GROUP" "Group numbers: '$INPUT'"
is "$_DEBUG_STATE" "$STATE" "State numbers: '$INPUT'"
is "$GOTTED_RULES" "$RULES"         "Rules: '$INPUT'"
unset INPUT LEVEL GROUP STATE RULES GOTTED_RULES RETVAL

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
parse GOTTED_RULES "$INPUT" && :; RETVAL="$?"  # intentionally unquoted
is "$RETVAL"       '0'      'Return value'
is "$_DEBUG_LEVEL" "$LEVEL" "Bracket level: '$INPUT'"
is "$_DEBUG_GROUP" "$GROUP" "Group numbers: '$INPUT'"
is "$_DEBUG_STATE" "$STATE" "State numbers: '$INPUT'"
is "$GOTTED_RULES" "$RULES"         "Rules: '$INPUT'"
unset INPUT LEVEL GROUP STATE RULES GOTTED_RULES RETVAL

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
BEGENV="$(dumpenv \
    _DEBUG_STATE _DEBUG_GROUP _DEBUG_LEVEL \
    INPUT LEVEL GROUP STATE BEGENV ENDENV \
    GOTTED_RULES RETVAL TESTS_COUNT TEST_OUT FAILED_TESTS TMPNUM \
)" # expect
parse GOTTED_RULES "$INPUT" && :; RETVAL="$?"  # intentionally unquoted
is "$RETVAL"       '0'      'Return value'
is "$_DEBUG_LEVEL" "$LEVEL" "Bracket level: '$INPUT'"
is "$_DEBUG_GROUP" "$GROUP" "Group numbers: '$INPUT'"
is "$_DEBUG_STATE" "$STATE" "State numbers: '$INPUT'"
is "$GOTTED_RULES" "$RULES"         "Rules: '$INPUT'"
ENDENV="$(dumpenv \
    _DEBUG_STATE _DEBUG_GROUP _DEBUG_LEVEL \
    INPUT LEVEL GROUP STATE BEGENV ENDENV \
    GOTTED_RULES RETVAL TESTS_COUNT TEST_OUT FAILED_TESTS TMPNUM \
)" # got
is "$ENDENV" "$BEGENV"      "Variable leakage: '$INPUT'"
unset INPUT LEVEL GROUP STATE RULES GOTTED_RULES RETVAL

## '...' (after word) inside end of parentheses
INPUT='  (   A   |   B   ...   )'
LEVEL='0 ( 1 A 1 | 1 B 1 ... 1 ) 0'
GROUP='0 ( 1 A 1 | 1 B 1 ... 1 ) 0'
STATE='0 ( 0 A 1 | 0 B 1 ... 1 ) 1'
RULES="0 1 A
0 1 B
1 1 B
1 x"
BEGENV="$(dumpenv \
    _DEBUG_STATE _DEBUG_GROUP _DEBUG_LEVEL \
    INPUT LEVEL GROUP STATE BEGENV ENDENV \
    GOTTED_RULES RETVAL TESTS_COUNT TEST_OUT FAILED_TESTS TMPNUM \
)" # expect
parse GOTTED_RULES "$INPUT" && :; RETVAL="$?"  # intentionally unquoted
is "$RETVAL"       '0'      'Return value'
is "$_DEBUG_LEVEL" "$LEVEL" "Bracket level: '$INPUT'"
is "$_DEBUG_GROUP" "$GROUP" "Group numbers: '$INPUT'"
is "$_DEBUG_STATE" "$STATE" "State numbers: '$INPUT'"
is "$GOTTED_RULES" "$RULES"         "Rules: '$INPUT'"
ENDENV="$(dumpenv \
    _DEBUG_STATE _DEBUG_GROUP _DEBUG_LEVEL \
    INPUT LEVEL GROUP STATE BEGENV ENDENV \
    GOTTED_RULES RETVAL TESTS_COUNT TEST_OUT FAILED_TESTS TMPNUM \
)" # got
is "$ENDENV" "$BEGENV"      "Variable leakage: '$INPUT'"
unset INPUT LEVEL GROUP STATE RULES GOTTED_RULES RETVAL

## '...' (after paren group) inside end of parentheses
INPUT='  (   A   |   (   B   )   ...   )'
LEVEL='0 ( 1 A 1 | 1 ( 2 B 2 ) 1 ... 1 ) 0'
GROUP='0 ( 1 A 1 | 1 ( 2 B 2 ) 1 ... 1 ) 0'
STATE='0 ( 0 A 1 | 0 ( 0 B 2 ) 2 ... 2 ) 2'       # <-- FIXME Expected BAD result
#STATE='0 ( 0 A 1 | 0 ( 0 B 1 ) 1 ... 1 ) 1'      #     DESIRED result
RULES="0 1 A
0 1 B
1 1 B
1 x"
BEGENV="$(dumpenv \
    _DEBUG_STATE _DEBUG_GROUP _DEBUG_LEVEL \
    INPUT LEVEL GROUP STATE BEGENV ENDENV \
    GOTTED_RULES RETVAL TESTS_COUNT TEST_OUT FAILED_TESTS TMPNUM \
)" # expect
parse GOTTED_RULES "$INPUT" && :; RETVAL="$?"  # intentionally unquoted
is "$RETVAL"       '0'      'Return value'
is "$_DEBUG_LEVEL" "$LEVEL" "Bracket level: '$INPUT'"
is "$_DEBUG_GROUP" "$GROUP" "Group numbers: '$INPUT'"
is "$_DEBUG_STATE" "$STATE" "State numbers: '$INPUT'"
#is "$GOTTED_RULES" "$RULES"         "Rules: '$INPUT'"
ENDENV="$(dumpenv \
    _DEBUG_STATE _DEBUG_GROUP _DEBUG_LEVEL \
    INPUT LEVEL GROUP STATE BEGENV ENDENV \
    GOTTED_RULES RETVAL TESTS_COUNT TEST_OUT FAILED_TESTS TMPNUM \
)" # got
is "$ENDENV" "$BEGENV"      "Variable leakage: '$INPUT'"
unset INPUT LEVEL GROUP STATE RULES GOTTED_RULES RETVAL

## '...' (after bracket group) inside end of parentheses
INPUT='  (   A   |   [   B   ]   ...   )'
LEVEL='0 ( 1 A 1 | 1 [ 2 B 2 ] 1 ... 1 ) 0'
GROUP='0 ( 1 A 1 | 1 [ 2 B 2 ] 1 ... 1 ) 0'
STATE='0 ( 0 A 1 | 0 [ 0 B 2 ] 2 ... 2 ) 2'       # <-- FIXME Expected BAD result
#STATE='0 ( 0 A 1 | 0 [ 0 B 1 ] 1 ... 1 ) 1'      #     DESIRED result
RULES=''
BEGENV="$(dumpenv \
    _DEBUG_STATE _DEBUG_GROUP _DEBUG_LEVEL \
    INPUT LEVEL GROUP STATE BEGENV ENDENV \
    GOTTED_RULES RETVAL TESTS_COUNT TEST_OUT FAILED_TESTS TMPNUM \
)" # expect
parse GOTTED_RULES "$INPUT" && :; RETVAL="$?"  # intentionally unquoted
is "$RETVAL"       '0'      'Return value'
is "$_DEBUG_LEVEL" "$LEVEL" "Bracket level: '$INPUT'"
is "$_DEBUG_GROUP" "$GROUP" "Group numbers: '$INPUT'"
is "$_DEBUG_STATE" "$STATE" "State numbers: '$INPUT'"
#is "$GOTTED_RULES" "$RULES"         "Rules: '$INPUT'"
ENDENV="$(dumpenv \
    _DEBUG_STATE _DEBUG_GROUP _DEBUG_LEVEL \
    INPUT LEVEL GROUP STATE BEGENV ENDENV \
    GOTTED_RULES RETVAL TESTS_COUNT TEST_OUT FAILED_TESTS TMPNUM \
)" # got
is "$ENDENV" "$BEGENV"      "Variable leakage: '$INPUT'"
unset INPUT LEVEL GROUP STATE RULES GOTTED_RULES RETVAL

:<<'#BLOCK_COMMENT'
exit


################################################################################
################################################################################
################################################################################

INPUT='  (   ship   HERE1   |   HERE2   |   -h   |   --help   |   --version   )'
LEVEL='0 ( 1 ship 1 HERE1 1 | 1 HERE2 1 | 1 -h 1 | 1 --help 1 | 1 --version 1 ) 0'
GROUP='0 ( 1 ship 1 HERE1 1 | 1 HERE2 1 | 1 -h 1 | 1 --help 1 | 1 --version 1 ) 0'
STATE='0 ( 0 ship 2 HERE1 1 | 0 HERE2 1 | 0 -h 1 | 0 --help 1 | 0 --version 1 ) 1'
RULES=''
BEGENV="$(dumpenv \
    _DEBUG_STATE _DEBUG_GROUP _DEBUG_LEVEL \
    INPUT LEVEL GROUP STATE BEGENV ENDENV \
    GOTTED_RULES RETVAL TESTS_COUNT TEST_OUT FAILED_TESTS TMPNUM \
)" # expect
parse GOTTED_RULES "$INPUT" && :; RETVAL="$?"  # intentionally unquoted
is "$RETVAL"       '0'      'Return value'
is "$_DEBUG_LEVEL" "$LEVEL" "Bracket level: '$INPUT'"
is "$_DEBUG_GROUP" "$GROUP" "Group numbers: '$INPUT'"
is "$_DEBUG_STATE" "$STATE" "State numbers: '$INPUT'"
#is "$GOTTED_RULES" "$RULES"         "Rules: '$INPUT'"
ENDENV="$(dumpenv \
    _DEBUG_STATE _DEBUG_GROUP _DEBUG_LEVEL \
    INPUT LEVEL GROUP STATE BEGENV ENDENV \
    GOTTED_RULES RETVAL TESTS_COUNT TEST_OUT FAILED_TESTS TMPNUM \
)" # got
is "$ENDENV" "$BEGENV"      "Variable leakage: '$INPUT'"
unset INPUT LEVEL GROUP STATE RULES GOTTED_RULES RETVAL

################################################################################

# HERE1=
# HERE2= mine (set|remove) X Y [--moored|--drifting]

INPUT='  (   new   NAME   ...   |   NAME   move   X   Y   [   --speed=KN   ]   |   shoot   X   Y   )'
LEVEL='0 ( 1 new 1 NAME 1 ... 1 | 1 NAME 1 move 1 X 1 Y 1 [ 2 --speed=KN 2 ] 1 | 1 shoot 1 X 1 Y 1 ) 0'
GROUP='0 ( 1 new 1 NAME 1 ... 1 | 1 NAME 1 move 1 X 1 Y 1 [ 2 --speed=KN 2 ] 1 | 1 shoot 1 X 1 Y 1 ) 0'
STATE='0 ( 0 new 2 NAME 1 ... 1 | 0 NAME 4 move 5 X 6 Y 7 [ 7 --speed=KN 8 ] 8 | 0 shoot 9 X 10 Y 8 ) 8'  ## << EXPECTED BAD STATE

# TWO problems
# * '...' needs to look ahead to get possible group endstate

#STATE='0 ( 0 new 2 NAME 1 ... 1 | 0 NAME 4 move 5 X 6 Y 7 [ 7 --speed=KN   ] 1 | 0 shoot 9 X 10 Y 1 ) 1'
#STATE='0 ( 0 new 2 NAME 8 ... 8 | 0 NAME 4 move 5 X 6 Y 7 [ 7 --speed=KN 8 ] 8 | 0 shoot 9 X 10 Y 8 ) 8'
RULES=''
BEGENV="$(dumpenv \
    _DEBUG_STATE _DEBUG_GROUP _DEBUG_LEVEL \
    INPUT LEVEL GROUP STATE BEGENV ENDENV \
    GOTTED_RULES RETVAL TESTS_COUNT TEST_OUT FAILED_TESTS TMPNUM \
)" # expect
parse GOTTED_RULES "$INPUT" && :; RETVAL="$?"  # intentionally unquoted
is "$RETVAL"       '0'      'Return value'
is "$_DEBUG_LEVEL" "$LEVEL" "Bracket level: '$INPUT'"
is "$_DEBUG_GROUP" "$GROUP" "Group numbers: '$INPUT'"
is "$_DEBUG_STATE" "$STATE" "State numbers: '$INPUT'"
#is "$GOTTED_RULES" "$RULES"         "Rules: '$INPUT'"
ENDENV="$(dumpenv \
    _DEBUG_STATE _DEBUG_GROUP _DEBUG_LEVEL \
    INPUT LEVEL GROUP STATE BEGENV ENDENV \
    GOTTED_RULES RETVAL TESTS_COUNT TEST_OUT FAILED_TESTS TMPNUM \
)" # got
is "$ENDENV" "$BEGENV"      "Variable leakage: '$INPUT'"
unset INPUT LEVEL GROUP STATE RULES GOTTED_RULES RETVAL

################################################################################

INPUT='  [   A   B   C   |   D   E   F   |   G   H   I   ] ...'
LEVEL='0 [ 1 A 1 B 1 C 1 | 1 D 1 E 1 F 1 | 1 G 1 H 1 I 1 ] 0 ... 0'
GROUP='0 [ 1 A 1 B 1 C 1 | 1 D 1 E 1 F 1 | 1 G 1 H 1 I 1 ] 0 ... 0'
STATE='0 [ 0 A 2 B 3 C 1 | 0 D 4 E 5 F 1 | 0 G 6 H 7 I 1 ] 1 ... 1'
RULES=''
BEGENV="$(dumpenv \
    _DEBUG_STATE _DEBUG_GROUP _DEBUG_LEVEL \
    INPUT LEVEL GROUP STATE BEGENV ENDENV \
    GOTTED_RULES RETVAL TESTS_COUNT TEST_OUT FAILED_TESTS TMPNUM \
)" # expect
parse GOTTED_RULES "$INPUT" && :; RETVAL="$?"  # intentionally unquoted
is "$RETVAL"       '0'      'Return value'
is "$_DEBUG_LEVEL" "$LEVEL" "Bracket level: '$INPUT'"
is "$_DEBUG_GROUP" "$GROUP" "Group numbers: '$INPUT'"
is "$_DEBUG_STATE" "$STATE" "State numbers: '$INPUT'"
#is "$GOTTED_RULES" "$RULES"         "Rules: '$INPUT'"
ENDENV="$(dumpenv \
    _DEBUG_STATE _DEBUG_GROUP _DEBUG_LEVEL \
    INPUT LEVEL GROUP STATE BEGENV ENDENV \
    GOTTED_RULES RETVAL TESTS_COUNT TEST_OUT FAILED_TESTS TMPNUM \
)" # got
is "$ENDENV" "$BEGENV"      "Variable leakage: '$INPUT'"
unset INPUT LEVEL GROUP STATE RULES GOTTED_RULES RETVAL

################################################################################
exit

# ( ship HERE1 | HERE2 |  -h | --help | --version )
# HERE1= ( new NAME... | NAME move X Y [--speed=KN] | shoot X Y )
# HERE2= mine (set|remove) X Y [--moored|--drifting]

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
parse GOTTED_RULES "$INPUT" && :; RETVAL="$?"  # intentionally unquoted
is "$RETVAL"       '0'      'Return value'
is "$_DEBUG_LEVEL" "$LEVEL" "Bracket level: '$INPUT'"
is "$_DEBUG_GROUP" "$GROUP" "Group numbers: '$INPUT'"
#is "$_DEBUG_STATE" "$STATE" "State numbers: '$INPUT'"
# is "$GOTTED_RULES" "$RULES"         "Rules: '$INPUT'"
unset INPUT LEVEL GROUP STATE RULES GOTTED_RULES RETVAL

#BLOCK_COMMENT

done_testing
#[eof]
