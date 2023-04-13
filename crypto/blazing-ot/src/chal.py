#!/usr/bin/env python3

from hashlib import *
import sys
from Crypto.PublicKey import ECC

curve = "NIST P-256"
T = ECC.EccPoint(5, 84324075564118526167843364924090959423913731519542450286139900919689799730227, curve=curve)

def RO2(P):
    return int.from_bytes(shake_128(f"RO2, {int(P.x)}, {int(P.y)}".encode()).digest(16), 'little')

def RO3(x):
    return int.from_bytes(shake_128(f"RO3, {x}".encode()).digest(16), 'little')

def RO4(l):
    return int.from_bytes(shake_128(", ".join(["RO4"] + [str(x) for x in l]).encode()).digest(16), 'little')

def ot_receiver(choice_bits):
    keys = []
    pub_keys = []
    for b in choice_bits:
        a_i = ECC.generate(curve=curve)
        keys.append(a_i)
        B_i = [a_i.pointQ, a_i.pointQ + T][b]
        pub_keys.append((int(B_i.x), int(B_i.y)))

    print("Receiver says:", pub_keys)

    sender_msg = input("Sender says: ")
    sender_msg = [int(x.strip(" ()[]\n")) for x in sender_msg.split(",")]

    Z = ECC.EccPoint(sender_msg[0], sender_msg[1], curve=curve)
    gamma = sender_msg[2]

    responses = []
    ot_messages = []
    for i, b in enumerate(choice_bits):
        chal_i = sender_msg[i + 3]
        p_i_b_i = RO2(Z * keys[i].d)
        resp_i = RO3(p_i_b_i) ^ (b * chal_i)
        ot_messages.append(p_i_b_i)
        responses.append(resp_i)

    ans = RO4(responses)
    if RO3(ans) != gamma:
        print("Invalid challenge.")
        sys.exit(1)

    print("Receiver says:", ans)
    return ot_messages

def ot_sender(batch_size):
    recv_pub_keys = input("Receiver says: ")
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
        challenges.append(chal_i)
        responses.append(RO3_p_i_0)

    ans = RO4(responses)
    gamma = RO3(ans)

    print(f"Sender says:", [int(Z.pointQ.x), int(Z.pointQ.y), gamma] + challenges)

    recv_ans = input("Receiver says: ")
    recv_ans = int(recv_ans)

    if recv_ans != ans:
        print("Incorrect response.")
        sys.exit(1)

    return ot_messages

def main():
    # Not needed on the server, but you may want this when running it locally:
    # import tty
    # tty.setcbreak(sys.stdin)

    with open('flag', 'r') as f:
        flag = f.read().strip()
    assert(len(flag) == 33)

    # Only 7 bits per byte because flag is ascii.
    flag_bits = [(ord(c) >> i) & 1 for c in flag for i in range(7)]

    ot_messages = ot_receiver(flag_bits)

    # TODO: Evaluate a garbled circuit using ot_messages as wire labels.

if __name__ == "__main__":
    main()
