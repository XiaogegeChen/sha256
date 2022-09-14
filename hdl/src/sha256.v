`timescale 1ns / 1ps

`include "incl.vh"

//
// process a chunk
//
module sha256 (
    input clk,
    input [511:0] chunk,
    input [255:0] in_hash,
    input in_vld,
    output [255:0] out_hash,
    output out_vld
);
    //
    // Initialize array of round constants:
    //
    wire [31:0] k [63:0];
    assign k[0] = 32'h428a2f98;
    assign k[1] = 32'h71374491;
    assign k[2] = 32'hb5c0fbcf;
    assign k[3] = 32'he9b5dba5;
    assign k[4] = 32'h3956c25b;
    assign k[5] = 32'h59f111f1;
    assign k[6] = 32'h923f82a4;
    assign k[7] = 32'hab1c5ed5;
    assign k[8] = 32'hd807aa98;
    assign k[9] = 32'h12835b01;
    assign k[10] = 32'h243185be;
    assign k[11] = 32'h550c7dc3;
    assign k[12] = 32'h72be5d74;
    assign k[13] = 32'h80deb1fe;
    assign k[14] = 32'h9bdc06a7;
    assign k[15] = 32'hc19bf174;
    assign k[16] = 32'he49b69c1;
    assign k[17] = 32'hefbe4786;
    assign k[18] = 32'hfc19dc6;
    assign k[19] = 32'h240ca1cc;
    assign k[20] = 32'h2de92c6f;
    assign k[21] = 32'h4a7484aa;
    assign k[22] = 32'h5cb0a9dc;
    assign k[23] = 32'h76f988da;
    assign k[24] = 32'h983e5152;
    assign k[25] = 32'ha831c66d;
    assign k[26] = 32'hb00327c8;
    assign k[27] = 32'hbf597fc7;
    assign k[28] = 32'hc6e00bf3;
    assign k[29] = 32'hd5a79147;
    assign k[30] = 32'h6ca6351;
    assign k[31] = 32'h14292967;
    assign k[32] = 32'h27b70a85;
    assign k[33] = 32'h2e1b2138;
    assign k[34] = 32'h4d2c6dfc;
    assign k[35] = 32'h53380d13;
    assign k[36] = 32'h650a7354;
    assign k[37] = 32'h766a0abb;
    assign k[38] = 32'h81c2c92e;
    assign k[39] = 32'h92722c85;
    assign k[40] = 32'ha2bfe8a1;
    assign k[41] = 32'ha81a664b;
    assign k[42] = 32'hc24b8b70;
    assign k[43] = 32'hc76c51a3;
    assign k[44] = 32'hd192e819;
    assign k[45] = 32'hd6990624;
    assign k[46] = 32'hf40e3585;
    assign k[47] = 32'h106aa070;
    assign k[48] = 32'h19a4c116;
    assign k[49] = 32'h1e376c08;
    assign k[50] = 32'h2748774c;
    assign k[51] = 32'h34b0bcb5;
    assign k[52] = 32'h391c0cb3;
    assign k[53] = 32'h4ed8aa4a;
    assign k[54] = 32'h5b9cca4f;
    assign k[55] = 32'h682e6ff3;
    assign k[56] = 32'h748f82ee;
    assign k[57] = 32'h78a5636f;
    assign k[58] = 32'h84c87814;
    assign k[59] = 32'h8cc70208;
    assign k[60] = 32'h90befffa;
    assign k[61] = 32'ha4506ceb;
    assign k[62] = 32'hbef9a3f7;
    assign k[63] = 32'hc67178f2;

    genvar m;

    wire in_vld_d1;
    wire [255:0] in_hash_d1;
    wire [255:0] in_hash_post_add;
    wire [32*64-1:0] w;
    wire [255:0] loop_out_hash [63:0];
    wire [63:0] loop_out_vld;

    //
    // delayed input for 1 cycle (in_hash and in_vld)
    //
    shift_reg #(
        .DELAY(1),
        .DATA_WIDTH(256+1)
    ) shift_reg_inst1(
    	.clk(clk),
        .i({in_vld, in_hash}),
        .o({in_vld_d1, in_hash_d1})
    );

    // 
    // delay in_hash for 64*4+1 cycles
    //
    shift_reg #(
        .DELAY(257),
        .DATA_WIDTH(256)
    ) shift_reg_inst2(
    	.clk(clk),
        .i(in_hash),
        .o(in_hash_post_add)
    );

    //
    // w
    //
    w_shift w_shift_inst(
    	.clk(clk),
        .chunk(chunk),
        .out_w(w)
    );
    
    //
    // main loop
    //
    generate
        for (m=0; m<64; m=m+1) begin
            if (m==0) begin
                compress compress_inst(
                    .clk(clk),
                    .w(w[32*m+:32]),
                    .k(k[m]),
                    .in_hash(in_hash_d1),
                    .in_vld(in_vld_d1),
                    .out_hash(loop_out_hash[m]),
                    .out_vld(loop_out_vld[m])
                );
            end else begin
                compress compress_inst(
                    .clk(clk),
                    .w(w[32*m+:32]),
                    .k(k[m]),
                    .in_hash(loop_out_hash[m-1]),
                    .in_vld(loop_out_vld[m-1]),
                    .out_hash(loop_out_hash[m]),
                    .out_vld(loop_out_vld[m])
                );
            end
        end
    endgenerate

    //
    // hash add
    //
    hash_add hash_add_inst(
    	.clk(clk),
        .ori_hash(in_hash_post_add),
        .last_hash(loop_out_hash[63]),
        .in_vld(loop_out_vld[63]),
        .out_hash(out_hash),
        .out_vld(out_vld)
    );
endmodule

//
// Add the compressed chunk to the current hash value
//
module hash_add (
    input clk,
    input [255:0] ori_hash,
    input [255:0] last_hash,
    input in_vld,
    output reg [255:0] out_hash = 0,
    output reg out_vld = 0
);
    integer i;
    always @(posedge clk) begin
        for (i=0; i<8; i=i+1)
            out_hash[32*i+:32] <= ori_hash[32*i+:32]+last_hash[32*i+:32];
        out_vld <= in_vld;
    end
endmodule