`timescale 1ns / 1ps

`include "../src/incl.vh"

`define SIZE 10

import alg::*;

module tb_sha256d;

    bit clk = 0;
    logic [639:0] in_data = 0;
    logic in_vld = 0;
    logic [255:0] out_hash;
    logic out_vld;

    bit [255:0] gt [$]; 

    bit [639:0] known_test_cases [0:1] = '{
        // Block 125552
        640'h9546a1421a44b9f24dd7f5c72b12fcf1b09288fcaff797d71e950e71ae42b91e8bdb2304758dfcffc2b620e300000000000008a3a41b85b8b29ad444def299fee21793cd8b9e567eab02cd8100000001,
        // block 277316
        640'h371c26881903a30c52be093ac91c008c26e50763e9f548bb8b2fc323735f73577effbc55502c51eb4cc7cf2e0000000000000002a7bbd25a417c0374cc55261021e8a9ca74442b01284f056900000002
    };

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
        bit [255:0] stage1_out_hash;
        bit [7:0] stage2_in_data [];
        bit [255:0] expected;

        for (int i=0; i<`SIZE; i++) begin
            // random test case
            test_case = new [80];
            if (i < $size(known_test_cases)) begin  // use known test case
                for (int j=0; j<80; j++) 
                    test_case[j] = known_test_cases[i][8*j+:8];
            end else begin  // use random test case
                for (int j=0; j<80; j++) 
                    test_case[j] = $urandom_range(255,0); 
            end
            // expected result
            stage1_out_hash = SHA256::run(test_case);
            stage2_in_data = new [32];
            for (int j=0; j<32; j++)
                stage2_in_data[j] = stage1_out_hash[8*j+:8];
            expected = SHA256::run(stage2_in_data);
            gt.push_back(expected);
            // send to hardware
            @(posedge clk) begin
                for (int j=0; j<80; j++) 
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
    
    sha256d dut(
    	.clk      (clk      ),
        .in_data  (in_data  ),
        .in_vld   (in_vld   ),
        .out_hash (out_hash ),
        .out_vld  (out_vld  )
    );
    
endmodule