#!/usr/bin/env bash
# 1st arg as no of jobs, optional

set -o errexit -o noclobber -o pipefail

func() {
    printf "1\n"
}
export -f func

declare jobs="${1:-10}"

declare total_args="$((jobs * 1000))"

printf "%s\n" "Total parallel threads: ${jobs}"
printf "%s\n" "Total arguments to test: ${total_args}"

args="$(eval printf "%s\\\n " "{1..${total_args}}")"

printf "\n%s\n" "Running benchmark for parallel-bash.."
time (printf "%s\n" "${args}" | bash parallel-bash.bash -p "${jobs}" -c func {}) 1> /dev/null

printf "\n%s\n" "Running benchmark for xargs.."
time (printf "%b\n" "${args}" | xargs -P "${jobs}" -n 1 -I {} bash -c 'func {}') 1> /dev/null

printf "\n%s\n" "Running benchmark for gnu parallel.."
time (printf "%s\n" "${args}" | parallel -j "${jobs}" func {}) 1> /dev/null
