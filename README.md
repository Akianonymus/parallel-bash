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

Bash version: 4.4.20(1)-release

Total parallel threads: 100
Total arguments to test: 100000

Running benchmark for parallel-bash..

real	0m2.789s
user	0m3.212s
sys 	0m0.761s

Running benchmark for xargs..

real	0m39.873s
user	1m51.808s
sys 	0m31.845s

Running benchmark for gnu parallel..

real	3m11.139s
user	3m31.104s
sys 	1m53.784s
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
./benchmark.bash 10

Bash version: 5.0.18(1)-release

Total parallel threads: 10
Total arguments to test: 10000

Running benchmark for parallel-bash..

real    0m1.637s
user    0m1.903s
sys     0m0.157s

Running benchmark for xargs..

real    0m38.065s
user    1m12.877s
sys     0m35.557s

Running benchmark for gnu parallel..

real    1m40.060s
user    2m19.720s
sys     1m25.670s
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

    -k | -kc | --kill-children-processes => Kill children processes created when command is manually interrupted.

    -p | --parallel-jobs => Number of parallel processes. Default value is 1.

    -D | --debug => Show debug trace.

    -h | --help => Show this help.

Put parallel-bash.bash in an executable path.

e.g: `mv parallel-bash.bash /usr/bin/`

## Reporting Issues

Use the [GitHub issue tracker](https://github.com/Akianonymus/parallel-bash/issues) for any bugs or feature suggestions.

## Contributing

Submit patches to code or documentation as GitHub pull requests. Make sure to run format_and_lint.bash before making a new pull request.

If using a code editor, then use shfmt and shellcheck plugin instead of format_and_lint.bash.

All shellcheck warnings should also successfully pass, if needs to be disabled, proper explanation is needed.

## License

[UNLICENSE](https://github.com/Akianonymus/parallel-bash/blob/master/LICENSE)
