`timescale 1ns / 1ps

`include "incl.vh"

//
// sha256, the input is 256 bits, it consists of 1 sha256 instants (1 chunk)
//
module sha256_256 (
    input clk,
    input [255:0] in_data,
    input in_vld,
    output [255:0] out_hash,
    output out_vld
);
    wire [511:0] padded;
    wire padded_vld;
    wire [255:0] chunk1_out_hash; 
    
    //
    // padding
    //
    padding_256 padding_256_inst(
    	.clk(clk),
        .in_data(in_data),
        .in_vld(in_vld),
        .padded(padded),
        .padded_vld(padded_vld)
    );

    //
    // chunk1
    //
    sha256 sha256_chunk1(
    	.clk(clk),
        .chunk(padded),
        .in_hash(256'h5be0cd191f83d9ab9b05688c510e527fa54ff53a3c6ef372bb67ae856a09e667),
        .in_vld(padded_vld),
        .out_hash(chunk1_out_hash),
        .out_vld(out_vld)
    );

    //
    // endianness converter
    //
    hash_endianness_converter hash_endianness_converter_inst(
    	.i(chunk1_out_hash),
        .o(out_hash)
    );
endmodule

//
// padding
//
module padding_256 (
    input clk,
    input [255:0] in_data,
    input in_vld,
    output reg [511:0] padded = 0,
    output reg padded_vld = 0
);
    always @(posedge clk) begin
        padded[255:0] <= in_data[255:0];
        padded[263:256] <= 8'h80;
        padded[495:264] <= 0;
        padded[503:496] <= 8'h01;
        padded[511:504] <= 8'h00;
        padded_vld <= in_vld;
    end
endmodule