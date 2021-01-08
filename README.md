<h1 align="center">Parallel bash</h1>
<p align="center">
<a href="https://github.com/Akianonymus/parallel-bash/stargazers"><img src="https://img.shields.io/github/stars/Akianonymus/parallel-bash.svg?color=blueviolet&style=for-the-badge" alt="Stars"></a>
</p>

> Parallel processing of commands in pure bash.

- Minimal
- No external program needed
- Supports functions without invoking a new shell

Keeping above reasons aside, this is obviously not a full replacement of xargs.

Mainly i wrote this to use functions parallely without invoking a new shell.

For example, to use a function parallely with xargs or gnu parallel:

```
main() { echo "${1}" ;}
export -f main

printf "%b\n" {1..1000} | xargs -n1 -P 10 -c bash -c 'main {}'

printf "%b\n" {1..1000} | parallel -j 10 main {}
```

Here, it will initiate 1000 / 10 = 100 bash shells. That just adds up to the total time of execution and slowing unnecessarily.

Note: In gnu parallel, even though we don't need to add the bash -c part to the commands but it still internally uses a new shell.

Now, to use a function parallely with parallel-bash:

```
main() { echo "${1}" ;}
export -f main

printf "%b\n" {1..1000} | ./parallel-bash -p 10 -c main {}
```

Here, it will just spawn 100 background processes, which is obviously have a lot less of overhead than spawning a whole shell.

See next section for real-time benchmarks.

## Benchmarks

To run a benchmark, just execute `benchmark.bash` script.

### Benchmark 1

<strong>Machine specs</strong>

```
OS: Ubuntu 18.04.5 LTS x86_64
Kernel: 4.15.0-128-generic
Uptime: 16 days, 15 hours, 58 mins
Packages: 1465
Shell: bash 4.4.20
Terminal: /dev/pts/1
CPU: Intel i7-4770 (8) @ 3.900GHz
GPU: Intel Xeon E3-1200 v3/4th Gen Core Processor
Memory: 4032MiB / 32030MiB
```

Terminal output on running `benchmark.bash`:

```
./benchmark.bash 100
Total parallel threads: 100
Total arguments to test: 100000

Running benchmark for parallel-bash..

real    0m3.699s
user    0m4.118s
sys     0m0.913s

Running benchmark for xargs..

real    0m38.642s
user    1m48.122s
sys     0m30.651s

Running benchmark for gnu parallel..

real    2m34.377s
user    3m6.125s
sys     1m41.492s
```

### Benchmark 2

<strong>Machine specs</strong>

```
OS: Android 8.1.0 aarch64
Host: motorola XT1804
Kernel: 3.18.119-Sanders
Uptime: 10 days, 11 hours, 27 mins
Packages: 135 (dpkg), 1 (pkg)
Shell: zsh 5.8
CPU: Qualcomm MSM8953 (8) @ 2.016GHz
Memory: 2008MiB / 3593MiB
```

Terminal output on running `benchmark.bash`:

```
Total parallel threads: 10
Total arguments to test: 10000

Running benchmark for parallel-bash..

real    0m2.352s
user    0m2.960s
sys     0m0.247s

Running benchmark for xargs..

real    0m38.568s
user    1m14.353s
sys     0m36.303s

Running benchmark for gnu parallel..

real    1m51.539s
user    2m26.633s
sys     1m42.377s
```

## Compatibility

Should work on bash version >= 3.

## Usage

`some_input | parallel-bash -p 5 -c echo`

`parallel-bash -p 5 -c echo < some_file`

`parallel-bash -p 5 -c echo <<< 'some string'`

The keyword '{}' can be used to for command inputs.

Either a command or a function can be used. For functions, need to export it first.

e.g: `something | parallel-bash -p 5 -c echo {} {}`

<strong>Required flags</strong>

    -c | --commands => Commands to use. This flag should be used at last as all the arguments given after this flag are treated as commands input.

<strong>Optional flags</strong>

    -p | --parallel-jobs => Number of parallel processes. Default value is 1.

    -D | --debug => Show debug trace.

    -h | --help => Show this help.

To use in scripts, there are two ways:

<strong>Call it as a command</strong>

Put parallel-bash.bash in an executable path.

e.g: `mv parallel-bash.bash /usr/bin/`

<strong>Call it as a function</strong>

Copy parallel-bash function from `parallel-bash.function.bash` file and copy in your script or just source the file.

The difference between the contents of `parallel-bash.bash` and `parallel-bash.function.bash` is that the latter doesn't do the trap cleanups and doesn't do checks for bash version.

`parallel-bash.function.bash` also just contains everything in a single function.

If it is used as a function, then traps and cleanup should be handled in the main script.

See `_cleanup` function in `parallel-bash.bash` for more info.

## Reporting Issues

Use the [GitHub issue tracker](https://github.com/Akianonymus/parallel-bash/issues) for any bugs or feature suggestions.

## Contributing

Submit patches to code or documentation as GitHub pull requests. Make sure to run format_and_lint.bash before making a new pull request.

If using a code editor, then use shfmt and shellcheck plugin instead of format_and_lint.bash.

All shellcheck warnings should also successfully pass, if needs to be disabled, proper explanation is needed.

## License

[UNLICENSE](https://github.com/Akianonymus/parallel-bash/blob/master/LICENSE)
