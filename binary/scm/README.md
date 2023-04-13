# scm

## Description

```
Keeping track of your different shellcode payloads is annoying, but the SCM is here to help!
```

### Flag

`dam{w0w_wh4t_a_f0rk1ng_m3ss_but_sh3llc0de_1s_fun}`

## Checklist for Author

* [X] Challenge compiles
* [X] Dockerfile has been updated
* [X] `base-container/run_chal.sh` has been updated
* [X] `build-artifacts` has been updated to include any files needed from the remote service (i.e. libc)
    * If there are no files needed from the container, please **delete** this file to speed up CI/CD runs
* [X] There is at least one test exploit/script in the `tests` directory
* [X] Update `.dockerignore` with files that won't necessitate a container rebuild

## Info

_Author, put whatever you want here_

int overflow to open fd to the flag and read it in, to the same page you are executing from. mmap regions are predictable, will know the page on the next execution
then a write shellcode to write it to stdout