`timescale 1ns / 1ps

`include "incl.vh"

//
// sha256(sha256(in_data))
//
module sha256d (
    input clk,
    input [639:0] in_data,
    input in_vld,
    output [255:0] out_hash,
    output out_vld
);
    wire [255:0] stage1_out_hash;
    wire stage1_out_vld;

    //
    // stage 1
    //
    sha256_640 sha256_640_inst(
    	.clk(clk),
        .in_data(in_data),
        .in_vld(in_vld),
        .out_hash(stage1_out_hash),
        .out_vld(stage1_out_vld)
    );

    //
    // stage 2
    //
    sha256_256 sha256_256_inst(
    	.clk(clk),
        .in_data(stage1_out_hash),
        .in_vld(stage1_out_vld),
        .out_hash(out_hash),
        .out_vld(out_vld)
    );
endmodule