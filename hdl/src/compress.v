`timescale 1ns / 1ps

`include "incl.vh"

//
// Compression function main loop
// 4-stage pipeline
//
module compress (
    input clk,
    input [31:0] w,
    input [31:0] k,
    input [32*8-1:0] in_hash,
    input in_vld,
    output [32*8-1:0] out_hash,
    output out_vld
);
    integer i;
    wire [31:0] a;
    wire [31:0] b;
    wire [31:0] c;
    wire [31:0] d;
    wire [31:0] e;
    wire [31:0] f;
    wire [31:0] g;
    wire [31:0] h;
    assign a = in_hash[31:0];
    assign b = in_hash[63:32];
    assign c = in_hash[95:64];
    assign d = in_hash[127:96];
    assign e = in_hash[159:128];
    assign f = in_hash[191:160];
    assign g = in_hash[223:192];
    assign h = in_hash[255:224];

    // pipestage1. S1, ch, S0, maj, sum_kw, out_hash
    reg [31:0] s1_S1 = 0;
    reg [31:0] s1_ch = 0;
    reg [31:0] s1_S0 = 0;
    reg [31:0] s1_maj = 0;
    reg [31:0] s1_sum_kw = 0;
    reg [31:0] s1_h = 0;
    reg [32*8-1:0] s1_out_hash = 0;
    reg s1_vld = 0;

    always @(posedge clk) begin
        s1_S1 <= {e[5:0], e[31:6]} ^ {e[10:0], e[31:11]} ^ {e[24:0], e[31:25]};
        s1_ch <= (e & f) ^ ((~e) & g);
        s1_S0 <= {a[1:0], a[31:2]} ^ {a[12:0], a[31:13]} ^ {a[21:0], a[31:22]};
        s1_maj <= (a & b) ^ (a & c) ^ (b & c);
        s1_sum_kw <= k+w;
        s1_h <= h;
        s1_out_hash <= {in_hash[223:0], in_hash[255:224]};
        s1_vld <= in_vld;
    end

    // pipestage2. sum_S1_ch, sum_kwh, temp2, out_hash
    reg [31:0] s2_sum_S1_ch = 0;
    reg [31:0] s2_sum_kwh = 0;
    reg [31:0] s2_temp2 = 0;
    reg [32*8-1:0] s2_out_hash = 0;
    reg s2_vld = 0;

    always @(posedge clk) begin
        s2_sum_S1_ch <= s1_S1+s1_ch;
        s2_sum_kwh <= s1_sum_kw+s1_h;
        s2_temp2 <= s1_S0+s1_maj;
        s2_out_hash <= s1_out_hash;
        s2_vld <= s1_vld;
    end

    // pipestage3. temp1, temp2, out_hash
    reg [31:0] s3_temp1 = 0; 
    reg [31:0] s3_temp2 = 0; 
    reg [32*8-1:0] s3_out_hash = 0; 
    reg s3_vld = 0;

    always @(posedge clk) begin
        s3_temp1 <= s2_sum_S1_ch+s2_sum_kwh;
        s3_temp2 <= s2_temp2;
        s3_out_hash <= s2_out_hash;
        s3_vld <= s2_vld;
    end

    // pipestage4. 
    reg [32*8-1:0] s4_out_hash = 0;
    reg s4_vld = 0;

    always @(posedge clk) begin
        s4_out_hash[31:0] <= s3_temp1+s3_temp2;
        s4_out_hash[63:32] <= s3_out_hash[63:32];
        s4_out_hash[95:64] <= s3_out_hash[95:64];
        s4_out_hash[127:96] <= s3_out_hash[127:96];
        s4_out_hash[159:128] <= s3_out_hash[159:128]+s3_temp1;
        s4_out_hash[191:160] <= s3_out_hash[191:160];
        s4_out_hash[223:192] <= s3_out_hash[223:192];
        s4_out_hash[255:224] <= s3_out_hash[255:224];
        s4_vld <= s3_vld;
    end
    
    assign out_hash = s4_out_hash;
    assign out_vld = s4_vld;
endmodule