#!/bin/sh
# Copyright (C) 2020-2023 zrajm <docoptz@zrajm.org>
# License: GPLv2 [https://gnu.org/licenses/gpl-2.0.txt]

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
    local _VAR="$1" _PRE="$2" _ARG='' IFS='
'                                              # intentional newline
    # Turn off globs (`set -f`) locally (`local -`) here, otherwise splitting
    # of unquoted variable in `set --` would also do glob expansion (if there
    # are matching files) which would be very confusing.
    local -; set -f; eval "set -- \${$1}"      # linesplit VARNAME into $@
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

# trimleft VARNAME [STR]
#
# Strip all occurences of STR off of the left end of VARNAME. If no STR is
# given, will strip off all whitespace characters found in $IFS. STR may be
# multiple characters (`XY`), or even a Shell `case` type "character class"
# (`[XY]` or `[!XY]`).
trimleft() {
    eval "set -- \"\$1\" \"\${2:-[$IFS]}\" \"\${$1}\"" # put $VARNAME in $3
    while [ "$3" != "${3#$2}" ]; do
        set -- "$1" "$2" "${3#$2}"
    done
    setvar "$1" "$3" || return 1
}

# Usage: gethelp VARNAME <FILE
#
# Set variable named VARNAME to the first 'Usage:' description found in FILE.
# Returns false if VARNAME is an invalid variable name, or if no usage string
# could be found. A usage string starts with `# Usage:` (case insensitive) and
# ends with the first blank or non-comment line. Each line of the usage string
# must start with `# `, except for empty lines which may consist of a single
# `#`.
#
# Typically invoked with `gethelp varname <"$0"`
#
# FIXME: Make agnostic as to the number of `#` and space at beginning of line.
gethelp() {
    if [ -t 0 ]; then warn "gethelp: Missing input on STDIN"; return 1; fi
    local _ IFS='
';  set -- "$1"                                # intentional newline
    while read -r _; do
        if [ "$#" -eq 1 ]; then
            case "$_" in
                '# '[Uu][Ss][Aa][Gg][Ee]:*) set -- "$1" "${_#\# }"
            esac
            continue
        fi
        case "$_" in
            '#')   set -- "$1" "$2$IFS" ;;     # blank line
            '# '*) set -- "$1" "$2$IFS${_#\# }" ;; # docstring
            ''|[!#]*) break
        esac
    done
    if [ "$#" -eq 1 ]; then warn "gethelp: No help message found"; return 1; fi
    setvar "$1" "$2" || return 1
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
# The generated rules are saved in the variable called RULESVAR, which will
# contain multiple lines of text. Collectively these lines make up a
# state-transition table of a finite state machine, with each line containing
# two or three words in the format: 'STARTSTATE ENDSTATE [INPUT]'. The lines
# with no INPUT all come at the end of RULES, all have an ENDSTATE of 'x' --
# these indicate which states are allowed final states.
#
# The following special characters are recognized:
#   * Optional group: '[' ... ']'
#   * Required group: '(' ... ')'
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
# LVL is the current level of nesting. GROUP is the number of the current
# parenthesis (analogous to regular expression capture group variables, $1, $2
# etc, used in Perl and Javascript). In '()()' GROUP is 1 and 2, and LVL 0 and
# 1. In '(())' GROUP is also 1 and 2, but LVL is 0 (outside paren), 1 (inside
# first paren), and 2 (inside innermost paren). I.e. GROUP never decreases,
# while LVL does. IN is the current group we're in, so in '()()' it looks like
# '0(1)0(2)0', while in '(())' its '0(1(2)1)0'.
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

# STATE is the currently processed state, STATEMAX is the maximum state used so
# far (for each state added STATEMAX is increased, so that it is the highest
# STATE used so far).

# Usage: parse RULESVAR DOCSTR
#
# Go through TOKEN(s) and create finite-state machine rules suitable for
# parsing the command line specified by DOCSTR. Will fail (returning false) if
# DOCSTR is malformed, or if everything went well, returns true and set the
# RULESVAR variable to a (multiline) string with rules for a finite state
# automaton, suitable for parsing a command line.
parse() {
    local _VAR="$1" _INPUT="$2"
    ok_varname "$_VAR" parse || return 1
    # Tokenize by adding space round syntactic chars, then split into $@.
    local _STR
    for _STR in '(' '[' '|' ']' ')' '...'; do  # foreach syntactic string
        replace _INPUT "$_STR" " $_STR "       #   add space around them
    done
    # Turn off globs (`set -f`) locally (`local -`) here, otherwise splitting
    # of unquoted variable in `set --` would also do glob expansion (if there
    # are matching files) which would be very confusing.
    local -; set -f; set -- $_INPUT            # intentionally unquoted
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

#[eof]
