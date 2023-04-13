#!/usr/bin/env python3

import numpy as np
from Crypto.Util.Padding import pad, unpad

import gpt

BLOCK_SIZE = 16

def xor(x, y):
    return bytes([a ^ b for a, b in zip(x, y)])

def encrypt_nokey(block):
    round_keys = np.zeros((4, 4), dtype=int)
    return gpt.encrypt(block.decode('latin-1'), round_keys).encode('latin-1')

def decrypt(block, offset):
    block = bytes([(x - y) % 256 for x, y in zip(block, offset)])
    round_keys = np.zeros((4, 4), dtype=int)
    return gpt.decrypt(block.decode('latin-1'), round_keys).encode('latin-1')

with open('output.txt', 'r') as f:
    ciphertext = bytes.fromhex(f.read())

def cbc_dec(ctxt, offset):
    msg = b''
    for i in range(BLOCK_SIZE, len(ctxt), BLOCK_SIZE):
        iv = ctxt[i-BLOCK_SIZE:i]
        msg += xor(iv, decrypt(ctxt[i:i+BLOCK_SIZE], offset))
    return unpad(msg, BLOCK_SIZE)

known_ptxt = pad(b'}', BLOCK_SIZE)
known_ptxt = xor(ciphertext[-2*BLOCK_SIZE:-BLOCK_SIZE], known_ptxt)
known_ctxt = ciphertext[-BLOCK_SIZE:]

offset = [a - b for a, b in zip(known_ctxt, encrypt_nokey(known_ptxt))]
flag = cbc_dec(ciphertext, offset).decode()
print(flag)

with open('flag', 'r') as f:
    real_flag = f.read().strip()
assert(flag == real_flag)
