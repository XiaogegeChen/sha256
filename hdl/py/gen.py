def w_arrival_time(idx):
    if idx < 16:
        return 0
    return ((idx-16)//2+1)*3

def in_delay(idx1, idx2):
    arrival_1 = w_arrival_time(idx1)
    arrival_2 = w_arrival_time(idx2)
    return arrival_2-arrival_1

def out_delay(idx):  # idx [16..63]
    loop_arrival = 4*idx
    w_arrival = w_arrival_time(idx)
    return loop_arrival-w_arrival

def w_sel(idx):
    return f"[{idx*32+31}:{idx*32}]"

def gen_w_inst_16_63():
    s = ""
    for i in range(16, 64):
        s += f"""    w_16_63 #(  // w{i}, inputs should be aligned
        .DELAY_DIST_16({in_delay(i-16, i-2)}),  // w{i-16}, delay {in_delay(i-16, i-2)} cycles
        .DELAY_DIST_15({in_delay(i-15, i-2)}),  // w{i-15}, delay {in_delay(i-15, i-2)} cycles
        .DELAY_DIST_7({in_delay(i-7, i-2)}),  // w{i-7}, delay {in_delay(i-7, i-2)} cycles
        .DELAY_DIST_2(0),  // w{i-2}, delay 0 cycles
        .DELAY_OUT_W({out_delay(i)})
    ) w_{i}_inst( 
        .clk(clk),
        .dist_16(w{w_sel(i-16)}),  // w{i-16}
        .dist_15(w{w_sel(i-15)}),  // w{i-15}
        .dist_7(w{w_sel(i-7)}),  // w{i-7}
        .dist_2(w{w_sel(i-2)}),  // w{i-2}
        .out_w(w{w_sel(i)}),
        .out_w_delayed(out_w{w_sel(i)})
    );\n
"""
    return s

def gen_w_inst(fp="py/w.txt"):
    s = gen_w_inst_16_63()
    with open(fp, mode="w", encoding="utf8") as f:
        f.write(s)

# print("""
# 0x428a2f98, 0x71374491, 0xb5c0fbcf, 0xe9b5dba5, 0x3956c25b, 0x59f111f1, 0x923f82a4, 0xab1c5ed5,
#         0xd807aa98, 0x12835b01, 0x243185be, 0x550c7dc3, 0x72be5d74, 0x80deb1fe, 0x9bdc06a7, 0xc19bf174,
#         0xe49b69c1, 0xefbe4786, 0x0fc19dc6, 0x240ca1cc, 0x2de92c6f, 0x4a7484aa, 0x5cb0a9dc, 0x76f988da,
#         0x983e5152, 0xa831c66d, 0xb00327c8, 0xbf597fc7, 0xc6e00bf3, 0xd5a79147, 0x06ca6351, 0x14292967,
#         0x27b70a85, 0x2e1b2138, 0x4d2c6dfc, 0x53380d13, 0x650a7354, 0x766a0abb, 0x81c2c92e, 0x92722c85,
#         0xa2bfe8a1, 0xa81a664b, 0xc24b8b70, 0xc76c51a3, 0xd192e819, 0xd6990624, 0xf40e3585, 0x106aa070,
#         0x19a4c116, 0x1e376c08, 0x2748774c, 0x34b0bcb5, 0x391c0cb3, 0x4ed8aa4a, 0x5b9cca4f, 0x682e6ff3,
#         0x748f82ee, 0x78a5636f, 0x84c87814, 0x8cc70208, 0x90befffa, 0xa4506ceb, 0xbef9a3f7, 0xc67178f2""".replace("0x", "32'h"))