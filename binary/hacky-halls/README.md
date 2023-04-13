# Hacky Halls

## Description

```
This is probably the coolest challenge I've ever made - AI generated code for a randomly generated 3D maze? What could possibly be more fun than that?!
```

### Flag

`dam{y0u_aRE_iN_A_ma2e_0f_7Wi57Y_Pa22A9E5_aLL_alIKE}`

## Checklist for Author

* [x] Challenge compiles
* [x] Dockerfile has been updated
* [x] `base-container/run_chal.sh` has been updated
* [x] `build-artifacts` has been updated to include any files needed from the remote service (i.e. libc)
    * If there are no files needed from the container, please **delete** this file to speed up CI/CD runs
* [ ] There is at least one test exploit/script in the `tests` directory **TODO!!**
* [x] Update `.dockerignore` with files that won't necessitate a container rebuild

## Info

Uhhhhh this isn't solved yet but I think it's not too hard - the script in the tests directory is what I used to leak the anticheat key. After that, you get arbitrary read because you can specify whatever indices of the maze array you want, and then decrypt the 1024 byte blocks you get back. I guess it's not total arbitrary read because you miss some stuff but you get enough to probably leak some library addresses.

Second vulnerabilty gives you sequential write from the coords buffer - if you write more than 3 values separated by commas in your message to the server, you can start overwriting stuff 4 bytes at a time. And you can skip over stuff 4 bytes at a time by just not putting anything between the commas. So it's ez money, just ROP to open, ROP to read, ROP to send_encrypted_message or whatever it is I forgot already and I'm out of time yikes
