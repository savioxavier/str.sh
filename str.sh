#!/usr/bin/bash

# shellcheck disable=SC2155

function __strsh_err() {
    local RED="\u001b[31m"
    local DIM="\u001b[2m"
    local RESET="\u001b[0m"

    echo -e "${RED}[str.sh error]:${DIM} ""$*${RESET}" >&2
}

function __strsh_warn() {
    local YELLOW="\u001b[33m"
    local DIM="\u001b[2m"
    local RESET="\u001b[0m"

    echo -e "${YELLOW}[str.sh warn]:${DIM} ""$*${RESET}" >&2
}

function read_multi() {
    # read_multi has the ability to read multiple files

    if [[ "$#" -eq 0 ]] && [[ -t 0 ]]; then
        __strsh_err "at least one file or stdin input should be provided"
        return 1
    fi

    if [[ "$#" -eq 0 ]]; then
        \cat # Read from stdin
    else
        \cat "$@" # Read files in order
    fi
}

read_single() {
    if [ $# -eq 0 ]; then
        __strsh_err "Error: No arguments for read_single provided."
        return 1
    fi

    if [ -f "$1" ]; then
        cat "$1"
    elif [[ $2 == "--string-only" ]]; then # override for cat
        echo "$1"
    elif [ ! -t 0 ]; then
        cat -
    else
        __strsh_err "no valid input source (neither a file nor stdin) provided."
        return 1
    fi
}

function str.lower() {
    local S=$(read_multi "$@")
    echo "$S" | tr '[:upper:]' '[:lower:]'
}

function str.upper() {
    local S=$(read_multi "$@")
    echo "$S" | tr '[:lower:]' '[:upper:]'
}

function str.contains() {
    local S=$(read_single "$1")
    local S_SUBSTRING

    if [ ! -t 0 ]; then
        S_SUBSTRING="$1"
    else
        S_SUBSTRING="$2"
    fi

    if [[ -z "${S_SUBSTRING}" ]]; then
        __strsh_err "empty substring"
        return 1
    fi

    if [[ $S == *"$S_SUBSTRING"* ]]; then
        echo "true"
    else
        echo "false"
    fi
}

function str.contains.r() {
    local S=$(read_single "$1")
    local S_SUBSTRING

    if [ ! -t 0 ]; then
        S_SUBSTRING="$1"
    else
        S_SUBSTRING="$2"
    fi

    if [[ -z "${S_SUBSTRING}" ]]; then
        __strsh_err "no substring provided"
        return 1
    fi

    if [[ $S_SUBSTRING == *"\d"* ]]; then
        __strsh_warn "str.contains.r requires posix compliant regex, use [0-9] or [[:digit:]] instead of \d"
    fi

    if [[ $S_SUBSTRING == *"\w"* ]]; then
        __strsh_warn "str.contains.r requires posix compliant regex, use [A-Za-z0-9] or [[:alnum:]] instead of \w"
    fi

    if [[ $S_SUBSTRING == *"\s"* ]]; then
        __strsh_warn 'str.contains.r requires posix compliant regex, use [ \\t\\r\\n\\v\\f] or [[:space:]] instead of \s'
    fi

    # See shellcheck/SC2076: Don't quote rhs of =~, it'll match literally rather than as a regex.
    if [[ $S =~ $S_SUBSTRING ]]; then
        echo "true"
    else
        echo "false"
    fi
}

function str.reverse() {
    S=$(read_single "$1")
    echo -e "${S}" | rev
}

function str.equal() {
    local S=$(read_single "$1" --string-only)
    local S_COMPARE

    # is stdin present?
    if [ ! -t 0 ]; then
        S_COMPARE="$1"
    else
        # special execption: if no stdin is provided are there
        # and two arguments are provided, both are treated as
        # pure strings instead of just one file and one string
        S_COMPARE="$2"
    fi

    if [[ -z "${S_COMPARE}" ]]; then
        __strsh_err "no compare string provided"
        return 1
    fi

    if [[ "$S" == "$S_COMPARE" ]]; then
        echo "true"
    else
        echo "false"
    fi

}

function str.wc() {
    local S=$(read_single "$1")

    local WORDS=$(echo "$S" | wc --words)
    local CHARS=$(echo "$S" | wc --chars)
    local BYTES=$(echo "$S" | wc --bytes)
    local LINES=$(echo "$S" | wc --lines)

    local MAX_LINE_LENGTH=$(echo "$S" | wc --max-line-length)

    # Print them all in an easily parseable format
    echo -e "words=$WORDS\nchars=$CHARS\nbytes=$BYTES\nlines=$LINES\nmax-line-length=$MAX_LINE_LENGTH"
}

function str.length() {
    local S=$(read_single "$1")

    echo "${#S}"
}

function __strsh_execute_command() {
    echo -e "\u001b[2m\u001b[36mexecuting command: \u001b[0m\u001b[36m'$1' \u001b[0m\u001b[36m\u001b[2;3m($2)\u001b[0m"
    eval "$1"
}

function __strsh_section_divider() {
    local SECNAME="$1"

    echo -e "\u001b[35m"
    echo -e "----- ${SECNAME} -----"
    echo -e "\n\u001b[0m"
}

function __strsh_run_tests() {
    __strsh_section_divider "str.contains"

    __strsh_execute_command 'str.contains help.txt "git"' "with file"
    __strsh_execute_command 'cat help.txt | str.contains "Create an empty"' "stdin"
    __strsh_execute_command 'cat help.txt | str.contains' "no substr, has stdin"
    __strsh_execute_command 'str.contains help.txt' "no substr"
    __strsh_execute_command 'str.contains' "absolutely nothing"

    # TODO: Add more tests for str.contains.r
    __strsh_section_divider "str.contains.r"

    __strsh_execute_command 'str.contains.r help.txt "git"' "with file"
    __strsh_execute_command 'cat help.txt | str.contains.r "Create an empty"' "stdin"
    __strsh_execute_command 'cat help.txt | str.contains.r' "no substr, has stdin"
    __strsh_execute_command 'str.contains.r help.txt' "no substr"
    __strsh_execute_command 'str.contains.r' "absolutely nothing"
    __strsh_execute_command 'str.contains.r help.txt "Test numbers: \d+"' "posix compliant regex only"

    __strsh_section_divider "str.reverse"

    __strsh_execute_command "str.reverse help.txt" "reverse file"
    __strsh_execute_command "cat help.txt | str.reverse" "reverse text, cat stdin"
    __strsh_execute_command "echo hello there | str.reverse" "reverse text, has stdin"
    __strsh_execute_command "str.reverse" "absolutely nothing"

    __strsh_section_divider "str.equal"

    __strsh_execute_command 'str.equal "hi" "hi"' "with strings"
    __strsh_execute_command 'str.equal "hi" "not hi"' "with strings, not equal"
    __strsh_execute_command "str.equal 'hi' $(echo hi)" "with strings, one command substitution"
    __strsh_execute_command 'echo hi | str.equal "hi"' "stdin"
    __strsh_execute_command 'cat help.txt | str.equal' "no compare string, has stdin"
    __strsh_execute_command 'str.equal help.txt' "no compare string"
    __strsh_execute_command 'str.equal' "absolutely nothing"

    __strsh_section_divider "str.length"

    __strsh_execute_command 'str.length help.txt' "with file"
    __strsh_execute_command 'echo hello | str.length' "with stdin"
}

# Aliases

# TODO: Add more aliases
# TODO: Enable aliases once they are done

# alias str.l="str.lower"
# alias str._="str.lower"
# alias str.low="str.lower"

# alias str.u="str.upper"
# alias str.^="str.upper"
# alias str.up="str.upper"

# alias str.has="str.contains"

# alias str.has.r="str.contains.r"
# alias str.has.regex="str.contains.r"
# alias str.contains.regex="str.contains.r"

# alias str.eq="str.equal"
# alias str.same="str.equal"
# alias str.equals="str.equal"

# Because I wanted a funny three character name
# that probably wouldn't be used anywhere else
# Also, I used it because shell-format neatly
# formats three character function names in one line
@_h() {
    local NAME="$1"
    local USAGE_1="$2" # Usually file based
    local USAGE_2="$3" # Usually stdin based
    local DESC="$4"
    local ALIASES="$5"

    local RESET="\033[0m"
    local BOLD="\033[1m"
    local DIM="\033[2m"
    local RED="\033[31m"
    local GREEN="\033[32m"
    local YELLOW="\033[33m"
    local BLUE="\033[34m"
    local MAGENTA="\033[35m"
    local CYAN="\033[36m"

    echo -e """
${BOLD}${CYAN}${NAME}${RESET}   ${YELLOW}${DESC}${RESET} ${DIM}(aliases: ${MAGENTA}${ALIASES}${RESET}${DIM})${RESET}
            ${DIM}${GREEN}${USAGE_1}${RESET}${DIM} or ${BLUE}${USAGE_2}${RESET}"""
}

str.sh() {
    # Main command utility

    # TODO: Add help notes for every command

    if [[ "$1" == "-h" || "$1" == "--help" ]]; then
        @_h "str.lower" \
            "str.lower <file>" \
            "stdin text | str.lower" \
            "Lowercase-ify text" \
            "l, _, low"

        @_h "str.upper" \
            "str.upper <file>" \
            "stdin text | str.upper" \
            "Uppercase-ify text" \
            "u, ^, up"

        @_h "str.equal" \
            "str.equal <string1> <string2>" \
            "stdin <string1> | str.equal <string2>" \
            "Check whether two given strings are equal" \
            "eq, same, equals"
    fi
}
