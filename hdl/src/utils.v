`timescale 1ns / 1ps

module shift_reg #(
    parameter DELAY = 192,
    parameter DATA_WIDTH = 8
) (
    input clk,
    input [DATA_WIDTH-1:0] i,
    output [DATA_WIDTH-1:0] o
);
generate
if (DELAY==0) begin
    assign o = i;
end else begin
    reg [DATA_WIDTH-1:0] pipes [DELAY-1:0];
    integer k;

    initial begin
        for (k=0; k<DELAY; k=k+1) 
            pipes[k] <= {DATA_WIDTH{1'b0}};
    end

    assign o = pipes[DELAY-1];

    always @(posedge clk) begin
        pipes[0] <= i;
        for (k=1; k<DELAY; k=k+1) 
            pipes[k] <= pipes[k-1];
    end
end
endgenerate
endmodule

//
// Converter the endianness of output hash
//
module hash_endianness_converter (
    input [255:0] i,
    output [255:0] o
);
    genvar k;
    generate
        for (k=0; k<8; k=k+1) begin
            assign o[32*k+:8] = i[32*k+24+:8];
            assign o[32*k+8+:8] = i[32*k+16+:8];
            assign o[32*k+16+:8] = i[32*k+8+:8];
            assign o[32*k+24+:8] = i[32*k+:8];
        end 
    endgenerate
endmodule