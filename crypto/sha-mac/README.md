# sha-mac

## Description

```
GCM? HMAC? Why do we have so many ways to do the same thing? Anyways, hash functions are supposed to be collision resistant or something right?
```

### Flag

`dam{wh3n_1n_d0ub7_ju57_m4k3_17_l0ng3r}`

## Checklist for Author

* [X] Challenge compiles
* [X] Dockerfile has been updated
* [X] `base-container/run_chal.sh` has been updated
* [X] `build-artifacts` has been updated to include any files needed from the remote service (i.e. libc)
    * If there are no files needed from the container, please **delete** this file to speed up CI/CD runs
* [X] There is at least one test exploit/script in the `tests` directory
* [X] Update `.dockerignore` with files that won't necessitate a container rebuild

## Info

Length extension on AES CBC ciphertexts with a little IV bit flip thrown in for good measure :)
