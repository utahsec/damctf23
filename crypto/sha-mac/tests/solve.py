from pwn import *

# BEGIN SHA256 (RE)IMPLEMENTATION
# All of this is basically taken verbatim from the Secure Hash Standard
# (https://nvlpubs.nist.gov/nistpubs/FIPS/NIST.FIPS.180-4.pdf)

# SHA256 word length is 32 bits
WORD_LEN = 32
MODULUS = pow(2, WORD_LEN)

# there are 8 32-bit words in a SHA256 hash
HASH_WORDS = 8

# SHA256 algorithm constants (derived from cube roots of first 64 primes)
K_256 = [
    0x428a2f98, 0x71374491, 0xb5c0fbcf, 0xe9b5dba5, 0x3956c25b, 0x59f111f1, 0x923f82a4, 0xab1c5ed5,
    0xd807aa98, 0x12835b01, 0x243185be, 0x550c7dc3, 0x72be5d74, 0x80deb1fe, 0x9bdc06a7, 0xc19bf174,
    0xe49b69c1, 0xefbe4786, 0x0fc19dc6, 0x240ca1cc, 0x2de92c6f, 0x4a7484aa, 0x5cb0a9dc, 0x76f988da,
    0x983e5152, 0xa831c66d, 0xb00327c8, 0xbf597fc7, 0xc6e00bf3, 0xd5a79147, 0x06ca6351, 0x14292967,
    0x27b70a85, 0x2e1b2138, 0x4d2c6dfc, 0x53380d13, 0x650a7354, 0x766a0abb, 0x81c2c92e, 0x92722c85,
    0xa2bfe8a1, 0xa81a664b, 0xc24b8b70, 0xc76c51a3, 0xd192e819, 0xd6990624, 0xf40e3585, 0x106aa070,
    0x19a4c116, 0x1e376c08, 0x2748774c, 0x34b0bcb5, 0x391c0cb3, 0x4ed8aa4a, 0x5b9cca4f, 0x682e6ff3,
    0x748f82ee, 0x78a5636f, 0x84c87814, 0x8cc70208, 0x90befffa, 0xa4506ceb, 0xbef9a3f7, 0xc67178f2,
]

# initial hash values (derived from square roots of first 8 primes)
H0 = [
    0x6a09e667,
    0xbb67ae85,
    0x3c6ef372,
    0xa54ff53a,
    0x510e527f,
    0x9b05688c,
    0x1f83d9ab,
    0x5be0cd19
]

# working variables during hash process
VARS = ["a", "b", "c", "d", "e", "f", "g", "h"]

class WorkingVars:
    def __init__(self, init_state=None):
        # initialize state from existing hash (used during length extension)
        if init_state is not None:
            state_words = [
                int.from_bytes(init_state[4*t:4*t+4], byteorder="big")
                for t in range(HASH_WORDS)
            ]
        
        # empty -> initialize from default values
        else:
            state_words = H0
        
        # efficiency :)
        for v, word in zip(VARS, state_words):
            setattr(self, v, word)
        
        self.hash_val = state_words
    
    def update_hash(self):
        """Adds the current working variables to the previous hash words, as is done between rounds."""
        new_hash = []
        for v, word in zip(VARS, self.hash_val):
            new_word = (getattr(self, v) + word) % MODULUS
            new_hash.append(new_word)
            setattr(self, v, new_word)

        self.hash_val = new_hash

    def digest(self):
        """Outputs the SHA256 hash digest of the current data."""
        output = bytes()
        for word in self.hash_val:
            output += word.to_bytes(length=4, byteorder="big")

        assert len(output) == 32
        return output

# miscellaneous SHA256 functions

def rotr(x, n):
    return (x >> n | x << (WORD_LEN - n)) & (MODULUS - 1)

def ch(x, y, z):
    return (x & y) ^ (~x & z)

def maj(x, y, z):
    return (x & y) ^ (x & z) ^ (y & z)

def Sigma0(x):
    return rotr(x, 2) ^ rotr(x, 13) ^ rotr(x, 22)

def Sigma1(x):
    return rotr(x, 6) ^ rotr(x, 11) ^ rotr(x, 25)

def sigma0(x):
    return rotr(x, 7) ^ rotr(x, 18) ^ (x >> 3)

def sigma1(x):
    return rotr(x, 17) ^ rotr(x, 19) ^ (x >> 10)

# SHA256 operates on 512-bit blocks
# the pre_len parameter comes in useful when doing a little length extension :)
def pad(msg, pre_len=0):
    bit_len = (len(msg) + pre_len) * 8
    
    # Python makes it easiest to just operate on bytes instead of individual bits
    padding_bits = ((448 - bit_len - 1) % 512) + 1
    assert padding_bits % 8 == 0
    padding_bytes = padding_bits // 8

    # padding consists of a single 1 bit followed by a specific number of zero bits
    padding = bytes([0x80]) + bytes(padding_bytes - 1)

    # padding ends with original message length represented as a big-endian 64-bit integer
    len_bytes = bit_len.to_bytes(length=8, byteorder="big")
    
    # actually do the padding :)
    padded_msg = msg + padding + len_bytes
    
    # ensure the padded message has a valid length
    assert ((len(padded_msg) + pre_len) * 8) % 512 == 0

    return padded_msg

def message_schedule(msg):
    schedule = []
    
    # first 16 words come directly from (padded) message
    for t in range(16):
        msg_word = int.from_bytes(msg[4*t:4*t+4], byteorder="big")
        schedule.append(msg_word)

    # next 48 depend on the previous ones
    for t in range(16, 64):
        word = sigma1(schedule[t-2]) + schedule[t-7] + sigma0(schedule[t-15]) + schedule[t-16]
        word %= MODULUS
        schedule.append(word)

    assert len(schedule) == 64
    return schedule

def do_rounds(v, schedule):
    for t in range(64):
        t1 = (v.h + Sigma1(v.e) + ch(v.e, v.f, v.g) + K_256[t] + schedule[t]) % MODULUS
        t2 = (Sigma0(v.a) + maj(v.a, v.b, v.c)) % MODULUS
        v.h = v.g
        v.g = v.f
        v.f = v.e
        v.e = (v.d + t1) % MODULUS
        v.d = v.c
        v.c = v.b
        v.b = v.a
        v.a = (t1 + t2) % MODULUS

def hash_msg(msg, init_state=None, pre_len=0):
    padded = pad(msg, pre_len)
    vs = WorkingVars(init_state)
    
    for i in range(0, len(padded), 64):
        current_block = padded[i:i+64]
        schedule = message_schedule(current_block)

        do_rounds(vs, schedule)
        vs.update_hash()

    return vs.digest()

def length_extension(orig_len, orig_hash, appended):
    # make a dummy message with the correct original length for padding purposes
    dummy_orig_padded = pad(b"A"*orig_len)
    
    # do the length extension by continuing the hashing process from where it left off :)
    return hash_msg(appended, orig_hash, len(dummy_orig_padded))

# END SHA256 REIMPLEMENTATION

if __name__ == "__main__":
    context.log_level = "error"
    io = process(["python", "server.py"])
    
    flag_enc = bytearray.fromhex(io.recvlineS())
    
    # bit flip flag encryption IV to bypass check for flag in plaintext :)
    flag_enc[0] ^= 1
    
    # truncate authentication hash cause we don't need it
    flag_enc = flag_enc[:-32]
    
    # get message to length extend with :)
    starter_msg = b"giv flag pls"
    io.sendlineafter(b") ", b"e")
    io.sendlineafter(b"encrypt: ", starter_msg)
    io.recvuntil(b"message: ")
    starter_enc = bytes.fromhex(io.recvlineS())
    
    # actually do length extension lol
    extended_hash = length_extension(len(starter_enc), starter_enc[-32:], flag_enc)

    # remove MAC from initial message since we have a new one
    extended = pad(starter_enc[:-32], pre_len=32) + flag_enc + extended_hash
    
    # decrypt our ciphertext containing (almost) the flag
    io.sendlineafter(b") ", b"d")
    io.sendlineafter(b"(hex): ", extended.hex().encode())
    io.recvuntil(b"(in hex): ")
    plaintext = bytes.fromhex(io.recvlineS())

    # eam{ is the result of the above bit flip :)
    flag_index = plaintext.find(b"eam{")
    flag_end = plaintext.find(b"}", flag_index)
    flag = "dam{" + plaintext[flag_index+4:flag_end+1].decode()
    print("Flag:", flag)
