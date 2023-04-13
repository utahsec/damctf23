#!/usr/bin/python3

from base64 import b64encode

def checksum(data):
    x = 0
    for byte in data:
        x += byte + 1

    return [x & 0xFF, (x >> 8) & 0xFF]

def ror(data, n):
    for j in range(n):
        c = (data[-1] & 1) ^ 1
        for i in range(len(data)):
            magic = ((i + 1) << 4) | (i + 1)
            data[i] ^= magic
            c_ = data[i] & 1
            data[i] = (c << 7) | (data[i] >> 1)
            c = c_
        #print(hex(j), list(map(hex, data)))

def rol_byte(x, n):
    for i in range(n):
        x = ((x << 1) & 0xFF) | (x >> 7)
    return x

def part1():
    data = [4, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0]
    ck = checksum(data)
    ck[0] = rol_byte(ck[0], 1)
    data = ck + [1] + data
    ror(data, 1)
    data = bytearray([1] + data)
    print(b64encode(data))

    for i in data:
        print("{:02x}".format(i), end='')
    print()

part1()

def part2():
    data = [3, 0xEE, 0x18, 0x03, 0x4C, 0x28, 0x8D, 0, 0, 0, 0, 0]
    ck = checksum(data)
    ROTS_BYTE=6
    ck[0] = rol_byte(ck[0], 256 if ROTS_BYTE == 0 else ROTS_BYTE)
    data = ck + [ROTS_BYTE] + data
    ROTS=142
    ror(data, 256 if ROTS == 0 else ROTS)
    data = bytearray([ROTS] + data)
    print(b64encode(data))

    for i in data:
        print("{:02x}".format(i), end='')
    print()

print()
part2()

