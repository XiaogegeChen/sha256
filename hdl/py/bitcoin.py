import hashlib
from binascii import unhexlify, hexlify

# Block 125552
# header_hex = ("01000000" +
#     "81cd02ab7e569e8bcd9317e2fe99f2de44d49ab2b8851ba4a308000000000000" +
#     "e320b6c2fffc8d750423db8b1eb942ae710e951ed797f7affc8892b0f1fc122b" +
#     "c7f5d74d" +
#     "f2b9441a" +
#     "42a14695"
# )

# block 277316
header_hex = ("02000000" +   # Version
    "69054f28012b4474caa9e821102655cc74037c415ad2bba70200000000000000" +  # hashPrevBlock
    "2ecfc74ceb512c5055bcff7e57735f7323c32f8bbb48f5e96307e5268c001cc9" +  # hashMerkleRoot
    "3a09be52" +  # Time
    "0ca30319" +  # Bits
    "88261c37"  # Nonce
)

header_bin = unhexlify(header_hex)
print(hexlify(header_bin[::-1]).decode("utf-8"))
hash = hashlib.sha256(hashlib.sha256(header_bin).digest()).digest()
print(hexlify(hash[::-1]).decode("utf-8"))
