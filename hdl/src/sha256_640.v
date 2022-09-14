`timescale 1ns / 1ps

`include "incl.vh"

//
// sha256, the input is 640 bits, it consists of 2 sha256 instants (2 chunks)
//
module sha256_640 (
    input clk,
    input [639:0] in_data,
    input in_vld,
    output [255:0] out_hash,
    output out_vld
);
    wire [1023:0] chunks;
    wire chunks_vld;
    wire [255:0] chunk1_out_hash;
    wire chunk1_out_vld;
    wire [511:0] delayed_chunk2;
    wire [255:0] chunk2_out_hash;

    //
    // delayed chunk2
    //
    shift_reg #(
        .DELAY(64*4+2),
        .DATA_WIDTH(512)
    ) shift_reg_chunk2(
    	.clk(clk),
        .i(chunks[1023:512]),
        .o(delayed_chunk2)
    );
    
    //
    // padding
    //
    padding_640 padding_640_inst(
    	.clk(clk),
        .in_data(in_data),
        .in_vld(in_vld),
        .padded(chunks),
        .padded_vld(chunks_vld)
    );

    //
    // chunk1
    //
    sha256 sha256_chunk1(
    	.clk(clk),
        .chunk(chunks[511:0]),
        .in_hash(256'h5be0cd191f83d9ab9b05688c510e527fa54ff53a3c6ef372bb67ae856a09e667),
        .in_vld(chunks_vld),
        .out_hash(chunk1_out_hash),
        .out_vld(chunk1_out_vld)
    );
    
    //
    // chunk2
    //
    sha256 sha256_chunk2(
    	.clk(clk),
        .chunk(delayed_chunk2),
        .in_hash(chunk1_out_hash),
        .in_vld(chunk1_out_vld),
        .out_hash(chunk2_out_hash),
        .out_vld(out_vld)
    );

    //
    // endianness converter
    //
    hash_endianness_converter hash_endianness_converter_inst(
    	.i(chunk2_out_hash),
        .o(out_hash)
    );
    
endmodule

//
// padding
//
module padding_640 (
    input clk,
    input [639:0] in_data,
    input in_vld,
    output reg [1023:0] padded = 0,
    output reg padded_vld = 0
);
    always @(posedge clk) begin
        padded[639:0] <= in_data[639:0];
        padded[647:640] <= 8'h80;
        padded[1007:648] <= 0;
        padded[1015:1008] <= 8'h02;
        padded[1023:1016] <= 8'h80;
        padded_vld <= in_vld;
    end
endmodule