# incharcerated

## Description

```
  No CTF would be complete without a jail challenge.

  `nc {{ host }} 31313`
```

### Flag

`dam{the-real-rubytaco-was-the-symbols-we-found-along-the-way}`

## Checklist for Author

* [x] Dockerfile has been updated
* [x] `base-container/run_chal.sh` has been updated
* [x] There is at least one test exploit/script in the `tests` directory
* [x] Update `.dockerignore` with files that won't necessitate a container rebuild

## Info

A Rubyjail! Except I'm not saying anything about Ruby and there's no source.

Players gotta recognize a) this isnt a python jail and b) read the flag

Solution under [`tests/`](tests/sol.rb).
