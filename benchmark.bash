#!/usr/bin/env bash
# 1st arg as no of jobs, optional

! [[ ${BASH_VERSINFO:-0} -ge 3 ]] &&
    printf "Bash version lower than 3.x not supported.\n" && return 1

set -o errexit -o noclobber -o pipefail

_cleanup() {
    {
        export abnormal_exit && if [[ -n ${abnormal_exit} ]]; then
            printf "\n\n%s\n" "Script exited manually."
            # this kills the script including all the child processes
            kill -- -$$ &
        fi
    } 2>| /dev/null || :
    return 0
}

trap 'abnormal_exit="1"; exit' INT TERM
trap '_cleanup' EXIT
trap '' TSTP # ignore ctrl + z

func() {
    printf "1\n"
}
export -f func

declare jobs="${1:-10}"

declare total_args="$((jobs * 1000))"

printf "%s\n\n" "Bash version: ${BASH_VERSION}"
printf "%s\n" "Total parallel threads: ${jobs}"
printf "%s\n" "Total arguments to test: ${total_args}"

args="$(eval printf "%s\\\n " "{1..${total_args}}")"

printf "\n%s\n" "Running benchmark for parallel-bash.."
time (printf "%s\n" "${args}" | bash parallel-bash.bash -p "${jobs}" -c func {}) 1> /dev/null

printf "\n%s\n" "Running benchmark for xargs.."
time (printf "%b\n" "${args}" | xargs -P "${jobs}" -n 1 -I {} bash -c 'func {}') 1> /dev/null

printf "\n%s\n" "Running benchmark for gnu parallel.."
time (printf "%s\n" "${args}" | parallel -j "${jobs}" func {}) 1> /dev/null
