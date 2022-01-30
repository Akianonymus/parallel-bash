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

_check_test() {
    declare output=0 name="${1:-}" && shift

    printf "\n%s\n" "Running benchmark for ${name}.."
    output="$(time (printf "%s\n" "${args}" | "${@}") | wc -l)"

    if [[ ${output} = "${total_args}" ]]; then
        printf "\n%s\n" "Benchmark ran successfully."
    else
        printf "\n%s\n" "Error: Benchmark failed for ${name}."
        printf "%s\n" "  Expected ${total_args} outputs, got ${output}"
    fi
}

_check_test "parallel-bash" bash parallel-bash.bash -k -p "${jobs}" func {}

_check_test "xargs" xargs -P "${jobs}" -I {} -n 1 bash -c 'func {}'

_check_test "gnu parallel" parallel -j "${jobs}" func {}
