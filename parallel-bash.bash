#!/usr/bin/env bash
# Parallel processing of commands in pure bash
# Also supports functions

_usage::parallel-bash() {
    printf "%b\n" \
        "Parallel processing commands in pure bash ( like xargs )

Usage: something | ${0##*/} -p 5 -c echo
       ${0##*/} -p 5 -c echo < some_file
       ${0##*/} -p 5 -c echo <<< 'some string'

The keyword '{}' can be used to for command inputs.

Either a command or a function can be used. For functions, need to export it first.

e.g: something | ${0##*/} -p 5 -c echo {} {}

Required flags:

    -c | --commands => Commands to use. This flag should be used at last as all the arguments given after this flag are treated as commands input.

Optional flags:

    -k | -kc | --kill-children-processes => Kill children processes created when command is manually interrupted.

    -p | --parallel-jobs => Number of parallel processes. Default value is 1.

    -D | --debug => Show debug trace.

    -h | --help => Show this help."
    exit 0
}

_setup_arguments::parallel-bash() {
    while [[ $# -gt 0 ]]; do
        case "${1}" in
            -h | --help) _usage::parallel-bash ;;
            -D | --debug) set -x ;;
            -p | --parallel-jobs)
                if [[ ${2} -gt 0 ]]; then
                    NO_OF_JOBS="${2}" && shift
                else
                    printf "\nError: -P only takes as positive integer as argument.\n"
                    return 1
                fi
                ;;
            -c | --commands)
                shift
                CMD_ARRAY=""
                # all the args given after -c is taken as command input
                for cmd in "${@}"; do CMD_ARRAY+="\"${cmd}\"  "; done
                break
                ;;
            -k | -kc | --kill-children-processes)
                KILL_CHILD_PROCESSES=true
                ;;
            *) printf '%s: %s: Unknown option\nTry '"%s -h/--help"' for more information.\n' "${0##*/}" "${1}" "${0##*/}" && return 1 ;;
        esac
        shift
    done

    # create a tempfile to store total input count
    { command -v mktemp 1>| /dev/null && TMPFILE_PARALLEL_BASH="$(mktemp -u)"; } || TMPFILE_PARALLEL_BASH="${PWD}/.$(_t="$(printf "%(%s)T\\n" "-1")" && printf "%s\n" "$((_t * _t))").LOG"

    # grab all the inputs from the pipe
    # use mapfile if available, it's quite faster than a while loop
    if [[ ${BASH_VERSINFO:-0} -ge 4 ]]; then
        # lastly, print it to "${TMPFILE_PARALLEL_BASH}.arraycount" so we can later use it, this prevents the usage of wc -l
        INPUT_ARRAY="$({
            mapfile -t input
            printf "%s\n" "${input[@]}"
            printf "%s\n" "${#input[@]}" >| "${TMPFILE_PARALLEL_BASH}.arraycount"
        })"
    else
        # increment the count var to count the total no of args
        # lastly, print it to "${TMPFILE_PARALLEL_BASH}.arraycount" so we can later use it, this prevents the usage of wc -l
        INPUT_ARRAY="$(
            count=0
            while read -r line || { printf "%s\n" "${input1}" && printf "%s\n" "$((count))" >| "${TMPFILE_PARALLEL_BASH}.arraycount" && break; }; do
                [[ -z ${line} ]] && continue
                input1+="${line}"$'\n'
                : "$((count += 1))"
            done
        )"
    fi

    TOTAL_INPUT="$(< "${TMPFILE_PARALLEL_BASH}.arraycount")" || return 1
    export TOTAL_INPUT && rm -f "${TMPFILE_PARALLEL_BASH}.arraycount"

    # both INPUT_ARRAY and CMD_ARRAY should be fulfilled
    [[ -z ${INPUT_ARRAY} ]] && printf "%s\n" "Error: Provide some input." && return 1
    [[ -z ${CMD_ARRAY} ]] && printf "%s\n" "Error: Provide some commands using -c flag." && return 1

    return 0
}

_process_arguments::parallel-bash() {
    declare job=0 no_of_jobs_final=0 cmds=""
    # no of parallel jobs shouldn't exceed no of input
    no_of_jobs_final="$((NO_OF_JOBS > TOTAL_INPUT ? TOTAL_INPUT : NO_OF_JOBS))"

    # a wrapper function
    # takes 1 argument
    _execute::_process_arguments::parallel-bash() {
        # job, no_of_jobs_final ans cmds is from parent function
        ((job += 1))
        # not using arrays because it is slow
        # `;` is added to last to prevent stopping the execution because of a failed process
        export "cmds+=${1:-:} ; "
        # when job == no_of_jobs_final, then reset it and then again start appending from job 1
        [[ ${job} -eq "${no_of_jobs_final}" ]] && {
            job=0
            # all hail the eval lord
            eval "${cmds}" &
            cmds=""
        }
    }

    # iterate over both input arrays
    # then pass formed string for _execute::_process_arguments::parallel-bash
    case "${CMD_ARRAY}" in
        *'{}'*)
            while read -r -u 4 line; do
                # If CMD_ARRAY array contains {}, then replace it with the input
                _execute::_process_arguments::parallel-bash "${CMD_ARRAY//\{\}/\"${line}\"}"
            done 4<<< "${INPUT_ARRAY}"
            ;;
        *)
            while read -r -u 4 line; do
                _execute::_process_arguments::parallel-bash "${CMD_ARRAY} \"${line}\""
            done 4<<< "${INPUT_ARRAY}"
            ;;
    esac

    # this is probably pointless as the processes might be already completed before even reaching this point
    # todo: fix this
    declare status
    wait || status=1

    return "${status:-0}"
}

_cleanup::parallel-bash() {
    {
        rm -f "${TMPFILE_PARALLEL_BASH}.arraycount"

        export abnormal_exit && if [[ -n ${abnormal_exit} ]]; then
            printf "\n\n%s\n" "parallel-bash exited manually."
            if [[ ${KILL_CHILD_PROCESSES} = "true" ]]; then
                printf "%s\n" "Killing child processes."
                # this kills the script including all the child processes
                kill -- -$$ &
            else
                printf "%s\n" "Not killing child processes."
            fi
        fi
    } 2>| /dev/null || :
    return 0
}

parallel-bash() {
    [[ $# = 0 ]] && _usage::parallel-bash

    ! [[ ${BASH_VERSINFO:-0} -ge 3 ]] &&
        printf "Bash version lower than 3.x not supported.\n" && return 1

    set -o errexit -o noclobber -o pipefail

    trap 'abnormal_exit="1"; exit' INT TERM
    trap '_cleanup::parallel-bash' EXIT
    trap '' TSTP # ignore ctrl + z

    declare NO_OF_JOBS=1 CMD_ARRAY INPUT_ARRAY MAIN_PID TOTAL_INPUT KILL_CHILD_PROCESSES
    _setup_arguments::parallel-bash "${@}" || return 1

    export MAIN_PID="$$"

    _process_arguments::parallel-bash || return 1
    return 0
}

parallel-bash "${@}" || exit 1
