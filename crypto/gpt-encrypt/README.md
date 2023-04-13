# gpt-encrypt

## Description

```
I needed a block cipher to encrypt my flag, but I don't trust AES, so I asked ChatGPT to write one for me.

Note: the file `gpt.py` is almost directly copied from ChatGPT output, with some minor modifications to make it a valid python script.
```

### Flag

`dam{1iN34R-B1O<K-<IpheR5_@R_WEaK}`

## Checklist for Author

* [ ] Challenge compiles
* [ ] Dockerfile has been updated
* [ ] `base-container/run_chal.sh` has been updated
* [ ] `build-artifacts` has been updated to include any files needed from the remote service (i.e. libc)
    * If there are no files needed from the container, please **delete** this file to speed up CI/CD runs
* [-] There is at least one test exploit/script in the `tests` directory
* [ ] Update `.dockerignore` with files that won't necessitate a container rebuild

## Info

_Author, put whatever you want here_
