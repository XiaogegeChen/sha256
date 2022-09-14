`timescale 1ns / 1ps

`include "../src/incl.vh"

`define SIZE 5

import alg::*;

module tb_sha256_256;

    bit clk = 0;
    logic [255:0] in_data = 0;
    logic in_vld = 0;
    logic [255:0] out_hash;
    logic out_vld;

    bit [255:0] gt [$]; 

    initial begin
        clk <= 0;
        #300 begin
            run();
            #10000;
            $finish;
        end
    end

    always #5 clk = ~clk;

    task automatic run();
        fork
            wr();
            rd();
        join
        $display("Finished");
    endtask 

    task automatic wr();
        bit [7:0] test_case [];

        for (int i=0; i<`SIZE; i++) begin
            // random test case
            test_case = new [32];
            for (int j=0; j<32; j++) 
                test_case[j] = $urandom_range(255,0);
            // expected result
            gt.push_back(SHA256::run(test_case));
            // send to hardware
            @(posedge clk) begin
                for (int j=0; j<32; j++) 
                    in_data[8*j+:8] <= test_case[j];
                in_vld <= 1;
            end
        end
        @(posedge clk) begin
            in_vld <= 0;
        end
    endtask 

    task automatic rd();
        bit [255:0] expected;
        bit [255:0] got;

        int cnt = 0;
        forever begin
            @(posedge clk) begin
                if (out_vld) begin
                    expected = gt.pop_front();
                    got = out_hash;
                    if (expected==got)
                        $display("Test case %0d, passed.", cnt);
                    else
                        $display("Test case %0d, failed. expected: %0h, got: %0h.", cnt, expected, got);
                    cnt ++;
                    if (cnt == `SIZE) break;
                end
            end
        end
    endtask 
    
    sha256_256 dut(
    	.clk      (clk      ),
        .in_data  (in_data  ),
        .in_vld   (in_vld   ),
        .out_hash (out_hash ),
        .out_vld  (out_vld  )
    );
    
endmodule