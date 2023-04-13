#!/usr/bin/env python3

from hashlib import *
import sys
from Crypto.PublicKey import ECC
from pwn import *

# OT protocol is from "Blazing Fast OT for Three-Round UC OT Extension". It is vulnerable to a
# selective abort attack. This is fine when it's used for OT extension, but a problem when used
# directly for OT.

curve = "NIST P-256"
T = ECC.EccPoint(5, 84324075564118526167843364924090959423913731519542450286139900919689799730227, curve=curve)

def RO2(P):
    return int.from_bytes(shake_128(f"RO2, {int(P.x)}, {int(P.y)}".encode()).digest(16), 'little')

def RO3(x):
    return int.from_bytes(shake_128(f"RO3, {x}".encode()).digest(16), 'little')

def RO4(l):
    return int.from_bytes(shake_128(", ".join(["RO4"] + [str(x) for x in l]).encode()).digest(16), 'little')

flag_len = 33
batch_size = 7 * flag_len

def connect():
    #return process("./src/chal.py")
    return remote('chals.damctf.xyz', 30124)

def ot_sender(cheat_index):
    p = connect()
    p.recvuntil("Receiver says: ".encode())
    recv_pub_keys = p.recvline().decode()
    recv_pub_keys = [int(x.strip(" ()[]\n")) for x in recv_pub_keys.split(",")]

    Z = ECC.generate(curve=curve)
    Tr = T * Z.d

    ot_messages = []
    challenges = []
    responses = []
    for i in range(batch_size):
        B_i = ECC.EccPoint(recv_pub_keys[2*i], recv_pub_keys[2*i + 1], curve=curve)
        B_i_r = B_i * Z.d
        p_i_0 = RO2(B_i_r)
        p_i_1 = RO2(B_i_r + (-Tr))
        ot_messages.append((p_i_0, p_i_1))

        RO3_p_i_0 = RO3(p_i_0)
        RO3_p_i_1 = RO3(p_i_1)
        chal_i = RO3_p_i_0 ^ RO3_p_i_1
        if i == cheat_index:
            chal_i = 0
        challenges.append(chal_i)
        responses.append(RO3_p_i_0)

    ans = RO4(responses)
    gamma = RO3(ans)

    p.recvuntil("Sender says: ".encode())
    p.sendline(str([int(Z.pointQ.x), int(Z.pointQ.y), gamma] + challenges).encode())

    try:
        p.recvuntil("Receiver says: ".encode())
        p.close()
        return 0
    except EOFError:
        p.close()
        return 1

flag = ""
for i in range(flag_len):
    byte = 0
    for j in range(7):
        byte += ot_sender(i*7 + j) << j
    flag += chr(byte)
print(flag)

with open('flag', 'r') as f:
    real_flag = f.read().strip()
assert(real_flag == flag)
