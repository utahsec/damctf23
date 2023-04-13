import random

def get_octet():
    return str(random.randint(5,200))

def get_ip():
    return ".".join([get_octet(), get_octet(), get_octet(), get_octet()])

for _ in range(297):
    print(f"[inet:ipv4={get_ip()}]")