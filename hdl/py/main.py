from hashlib import sha256
import random
from binascii import unhexlify, hexlify

def gt(txt):
    return sha256(txt.encode("ascii")).hexdigest()

def u64_2_bytes(n):
    ret = bytes()
    for i in range(8):
        ret += ((n >> ((7-i)*8)) & 0xff).to_bytes(1, "big")
    return ret

def u32_2_bytes(n):
    ret = bytes()
    for i in range(4):
        ret += ((n >> ((3-i)*8)) & 0xff).to_bytes(1, "big")
    return ret

def rightrotate(a, b):
    return (a >> b) | (a << (32-b))

def rightshift(a, b):
    return a >> b

def my_sha256(data: bytes) -> bytes:
    # Initialize hash values:
    h0 = 0x6a09e667
    h1 = 0xbb67ae85
    h2 = 0x3c6ef372
    h3 = 0xa54ff53a
    h4 = 0x510e527f
    h5 = 0x9b05688c
    h6 = 0x1f83d9ab
    h7 = 0x5be0cd19
    # Initialize array of round constants:
    k = [
        0x428a2f98, 0x71374491, 0xb5c0fbcf, 0xe9b5dba5, 0x3956c25b, 0x59f111f1, 0x923f82a4, 0xab1c5ed5,
        0xd807aa98, 0x12835b01, 0x243185be, 0x550c7dc3, 0x72be5d74, 0x80deb1fe, 0x9bdc06a7, 0xc19bf174,
        0xe49b69c1, 0xefbe4786, 0x0fc19dc6, 0x240ca1cc, 0x2de92c6f, 0x4a7484aa, 0x5cb0a9dc, 0x76f988da,
        0x983e5152, 0xa831c66d, 0xb00327c8, 0xbf597fc7, 0xc6e00bf3, 0xd5a79147, 0x06ca6351, 0x14292967,
        0x27b70a85, 0x2e1b2138, 0x4d2c6dfc, 0x53380d13, 0x650a7354, 0x766a0abb, 0x81c2c92e, 0x92722c85,
        0xa2bfe8a1, 0xa81a664b, 0xc24b8b70, 0xc76c51a3, 0xd192e819, 0xd6990624, 0xf40e3585, 0x106aa070,
        0x19a4c116, 0x1e376c08, 0x2748774c, 0x34b0bcb5, 0x391c0cb3, 0x4ed8aa4a, 0x5b9cca4f, 0x682e6ff3,
        0x748f82ee, 0x78a5636f, 0x84c87814, 0x8cc70208, 0x90befffa, 0xa4506ceb, 0xbef9a3f7, 0xc67178f2
    ]

    # padding
    n_bytes = len(data)
    if n_bytes%64 < 56:
        n_pad_bytes = 56-n_bytes%64
    else:
        n_pad_bytes = 64-(n_bytes%64-56)
    data += (0x80).to_bytes(1, "little")
    for i in range(n_pad_bytes-1):
        data += (0).to_bytes(1, "little")
    data += u64_2_bytes(n_bytes*8)  # length

    assert len(data)%64==0, f"padding error, len(data)={len(data)}"

    # print(hexlify(data).decode("utf-8"))
    
    # break message into 512-bit chunks
    n_chunks = len(data)//64
    for i in range(n_chunks):
        # create a 64-entry message schedule array w[0..63] of 32-bit words
        w = [0]*64
        # copy chunk into first 16 words w[0..15] of the message schedule array
        for j in range(16):
            w[j] = (data[i*64+j*4]<<24) | (data[i*64+j*4+1]<<16) | (data[i*64+j*4+2]<<8) | (data[i*64+j*4+3])
        # Extend the first 16 words into the remaining 48 words w[16..63] of the message schedule array:
        for j in range(16, 64):
            s0 = rightrotate(w[j-15], 7) ^ rightrotate(w[j-15], 18) ^ rightshift(w[j-15], 3)
            s1 = rightrotate(w[j-2], 17) ^ rightrotate(w[j-2], 19) ^ rightshift(w[j-2], 10)
            w[j] = (w[j-16] + s0 + w[j-7] + s1)%(2**32)
        
        # for i in range(64):
        #     print(f"w: {i} -> {w[i]}")
        
        # Initialize working variables to current hash value:
        a = h0
        b = h1
        c = h2
        d = h3
        e = h4
        f = h5
        g = h6
        h = h7
        # Compression function main loop:
        for j in range(64):
            S1 = rightrotate(e, 6) ^ rightrotate(e, 11) ^ rightrotate(e, 25)
            ch = (e & f) ^ ((~e) & g)
            temp1 = h + S1 + ch + k[j] + w[j]
            S0 = rightrotate(a, 2) ^ rightrotate(a, 13) ^ rightrotate(a, 22)
            maj = (a & b) ^ (a & c) ^ (b & c)
            temp2 = S0 + maj

            h = g
            g = f
            f = e
            e = (d + temp1)%(2**32)
            d = c
            c = b
            b = a
            a = (temp1 + temp2)%(2**32)

            # if j==0:
            #     print(hex(b), hex(a))
        
        # Add the compressed chunk to the current hash value:
        h0 = (h0 + a)%(2**32)
        h1 = (h1 + b)%(2**32)
        h2 = (h2 + c)%(2**32)
        h3 = (h3 + d)%(2**32)
        h4 = (h4 + e)%(2**32)
        h5 = (h5 + f)%(2**32)
        h6 = (h6 + g)%(2**32)
        h7 = (h7 + h)%(2**32)
    
    bs = bytes()
    bs += u32_2_bytes(h0)
    bs += u32_2_bytes(h1)
    bs += u32_2_bytes(h2)
    bs += u32_2_bytes(h3)
    bs += u32_2_bytes(h4)
    bs += u32_2_bytes(h5)
    bs += u32_2_bytes(h6)
    bs += u32_2_bytes(h7)
    return bs

def test_corr(vec_size=10, count=1):
    for i in range(count):
        # random string
        rand_str = ""
        for _ in range(vec_size):
            rand_str += chr(random.randint(0, 255))
        # bytes of this string
        str_bytes = rand_str.encode("utf8")
        # expected and got
        expected = sha256(str_bytes).digest()
        got = my_sha256(str_bytes)
        # compare
        if expected == got:
            print(f"Case {i}, passed.")
        else:
            print(f"Case {i}, failed.")

# test_corr(vec_size=80, count=10)

header_hex = ("01000000" +
    "81cd02ab7e569e8bcd9317e2fe99f2de44d49ab2b8851ba4a308000000000000" +
    "e320b6c2fffc8d750423db8b1eb942ae710e951ed797f7affc8892b0f1fc122b" +
    "c7f5d74d" +
    "f2b9441a" +
    "42a14695"
)
header_bin = unhexlify(header_hex)
print(hexlify(header_bin[::-1]).decode("utf-8"))
hash1 = my_sha256(header_bin)
hash2 = my_sha256(hash1)
print(hexlify(hash1[::-1]).decode("utf-8"))
print(hexlify(hash2[::-1]).decode("utf-8"))
