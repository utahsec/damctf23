# golden_banana

## Description

```
The Quest for the Golden Banana is a text-based adventure game that combines humor, action, and mystery in an epic story that will keep you hooked until the end. Explore exotic locations, interact with colorful characters, and make choices that will shape your destiny. Do you have what it takes to complete The Quest for the Golden Banana?

The story for this challenge was entirely written by the Bing AI chatbot :-)
```

### Flag

`dam{forM4t_5TRiN95_M4k3_m3_9O_b4N4n45}`

## Checklist for Author

* [x] Challenge compiles
* [x] Dockerfile has been updated
* [x] `base-container/run_chal.sh` has been updated
* [x] `build-artifacts` has been updated to include any files needed from the remote service (i.e. libc)
    * If there are no files needed from the container, please **delete** this file to speed up CI/CD runs
* [x] There is at least one test exploit/script in the `tests` directory
* [x] Update `.dockerignore` with files that won't necessitate a container rebuild

## Info

The entire game struct is stored on the stack and you can overwrite most of it because there's a gets call into a buffer in the struct. There's also a format string vulnerability when locations get printed out that can be abused to leak a stack address that you can use to calculate the address of the hidden room. Then you just use the buffer overflow again to overwrite one of the "choice" pointers to jump into the hidden room and get the flag.
