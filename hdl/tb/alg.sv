`timescale 1ns / 1ps

`include "../src/incl.vh"

package alg;
    class SHA256;
        static bit [31:0] init_hash [0:7] = '{
            32'h6a09e667, 32'hbb67ae85, 32'h3c6ef372, 32'ha54ff53a, 
            32'h510e527f, 32'h9b05688c, 32'h1f83d9ab, 32'h5be0cd19
        };
        static bit[31:0] k [0:63] = '{
            32'h428a2f98, 32'h71374491, 32'hb5c0fbcf, 32'he9b5dba5, 32'h3956c25b, 32'h59f111f1, 32'h923f82a4, 32'hab1c5ed5,        
            32'hd807aa98, 32'h12835b01, 32'h243185be, 32'h550c7dc3, 32'h72be5d74, 32'h80deb1fe, 32'h9bdc06a7, 32'hc19bf174,
            32'he49b69c1, 32'hefbe4786, 32'h0fc19dc6, 32'h240ca1cc, 32'h2de92c6f, 32'h4a7484aa, 32'h5cb0a9dc, 32'h76f988da,
            32'h983e5152, 32'ha831c66d, 32'hb00327c8, 32'hbf597fc7, 32'hc6e00bf3, 32'hd5a79147, 32'h06ca6351, 32'h14292967,
            32'h27b70a85, 32'h2e1b2138, 32'h4d2c6dfc, 32'h53380d13, 32'h650a7354, 32'h766a0abb, 32'h81c2c92e, 32'h92722c85,
            32'ha2bfe8a1, 32'ha81a664b, 32'hc24b8b70, 32'hc76c51a3, 32'hd192e819, 32'hd6990624, 32'hf40e3585, 32'h106aa070,
            32'h19a4c116, 32'h1e376c08, 32'h2748774c, 32'h34b0bcb5, 32'h391c0cb3, 32'h4ed8aa4a, 32'h5b9cca4f, 32'h682e6ff3,
            32'h748f82ee, 32'h78a5636f, 32'h84c87814, 32'h8cc70208, 32'h90befffa, 32'ha4506ceb, 32'hbef9a3f7, 32'hc67178f2
        };

        //
        // run sha256 algorithm
        //
        static function bit[255:0] run(input bit [7:0] data []);
            bit [511:0] chunks [];
            bit [63:0][31:0] w;
            bit [31:0] a, b, c, d, e, f, g, h;
            bit [31:0] h0, h1, h2, h3, h4, h5, h6, h7;
            bit [31:0] S1, ch, temp1, S0, maj, temp2;

            // Initialize hash values
            h0 = init_hash[0];
            h1 = init_hash[1];
            h2 = init_hash[2];
            h3 = init_hash[3];
            h4 = init_hash[4];
            h5 = init_hash[5];
            h6 = init_hash[6];
            h7 = init_hash[7];

            // padding
            padding(data, chunks);
            // $display("n_chunks: %0d", $size(chunks));
            // foreach(chunks[i])
            //     $display("chunk[%0d]: %0h", i, chunks[i]);
            // break message into 512-bit chunks
            foreach(chunks[i]) begin
                // create a 64-entry message schedule array w[0..63] of 32-bit words
                w = get_w(chunks[i]);
                // foreach (w[j])
                //     $display("w[%0d] = %0d", j, w[j]);
                // Initialize working variables to current hash value
                a = h0;
                b = h1;
                c = h2;
                d = h3;
                e = h4;
                f = h5;
                g = h6;
                h = h7;
                // Compression function main loop
                for (int j=0; j<64; j++) begin
                    S1 = rightrotate(e, 6) ^ rightrotate(e, 11) ^ rightrotate(e, 25);
                    ch = (e & f) ^ ((~e) & g);
                    temp1 = h + S1 + ch + k[j] + w[j];
                    S0 = rightrotate(a, 2) ^ rightrotate(a, 13) ^ rightrotate(a, 22);
                    maj = (a & b) ^ (a & c) ^ (b & c);
                    temp2 = S0 + maj;

                    h = g;
                    g = f;
                    f = e;
                    e = (d + temp1);
                    d = c;
                    c = b;
                    b = a;
                    a = (temp1 + temp2);

                    // if (j==0) begin
                    //     $display("a: %0h, b: %0h", a, b);
                    // end
                end
                // Add the compressed chunk to the current hash value
                h0 = h0 + a;
                h1 = h1 + b;
                h2 = h2 + c;
                h3 = h3 + d;
                h4 = h4 + e;
                h5 = h5 + f;
                h6 = h6 + g;
                h7 = h7 + h;
            end
            return hash_endianness_converter({h7,h6,h5,h4,h3,h2,h1,h0});
        endfunction

        // padding
        static function void padding(input bit [7:0] in_data [], output bit [511:0] data []);
            bit [511:0] ret = 0;
            bit [63:0] n_bits = 0;
            int n_bytes = 0, n_chunks = 0;

            n_bits = $size(in_data)*8;
            n_bytes = $size(in_data);
            // n_chunks
            if (n_bytes%64 < 56) n_chunks = n_bytes/64+1;
            else n_chunks = n_bytes/64+2;
            // data
            data = new[n_chunks];
            foreach(data[i])
                data[i] = 0;
            for (int i=0; i<n_bytes; i++)
                data[i/64][8*(i%64)+:8] = in_data[i];
            // length
            for (int i=0; i<8; i++) begin
                data[n_chunks-1][448+(7-i)*8+:8] = n_bits[8*i+:8];
            end
            // first padding
            data[n_bytes/64][8*(n_bytes%64)+:8] = 8'h80;
        endfunction

        // calculate w
        static function bit[63:0][31:0] get_w(bit[511:0] chunk);
            bit[63:0][31:0] w;
            bit [31:0] s0, s1;
            // w[0..15]
            for (int i=0; i<16; i++)
                w[i] = {chunk[32*i+:8], chunk[32*i+8+:8], chunk[32*i+16+:8], chunk[32*i+24+:8]};
            // w[16..63]
            for (int i=16; i<64; i++) begin
                s0 = rightrotate(w[i-15], 7) ^ rightrotate(w[i-15], 18) ^ rightshift(w[i-15], 3);
                s1 = rightrotate(w[i-2], 17) ^ rightrotate(w[i-2], 19) ^ rightshift(w[i-2], 10);
                w[i] = (w[i-16] + s0 + w[i-7] + s1);
            end
            return w;
        endfunction

        // rightrotate
        static function bit[31:0] rightrotate(bit[31:0] a, int b);
            return (a >> b) | (a << (32-b));
        endfunction

        // rightshift
        static function bit[31:0] rightshift(bit[31:0] a, int b);
            return a >> b;
        endfunction

        // first chunk
        static function bit[511:0] first_chunk (bit [7:0] data []);
            bit [511:0] chunks [];
            padding(data, chunks);
            return chunks[0];
        endfunction

        // endianness converter
        static function bit[255:0] hash_endianness_converter(bit[255:0] ori_out);
            bit[255:0] ret;
            for (int k=0; k<8; k++) begin
                ret[32*k+:8] = ori_out[32*k+24+:8];
                ret[32*k+8+:8] = ori_out[32*k+16+:8];
                ret[32*k+16+:8] = ori_out[32*k+8+:8];
                ret[32*k+24+:8] = ori_out[32*k+:8];
            end
            return ret;
        endfunction
    endclass //SHA256
endpackage