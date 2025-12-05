`timescale 1ns/1ps

module tb_round_robin_arbiter();

localparam PORTS = 4;
localparam ZERO_CYCLE = 1;
localparam CLK_PERIOD = 10;

logic clk = 0;
logic rstn = 0;
logic [PORTS-1:0] req_vec;
logic [PORTS-1:0] grant_vec;

// Clock generation
always #(CLK_PERIOD/2) clk = ~clk;

round_robin_arbiter #(
    .PORTS(PORTS),
    .ZERO_CYCLE(ZERO_CYCLE)
) dut (
    .i_clk(clk),
    .i_rstn(rstn),
    .i_req_vec(req_vec),
    .o_grant_vec(grant_vec)
);

initial begin
    $display("=== Round Robin Arbiter Testbench ===");
    
    req_vec = '0;
    rstn = 0;
    
    // Reset
    repeat(5) @(posedge clk);
    rstn = 1;
    @(posedge clk);
    
    // Test 1: Single request
    $display("\nTest 1: Single request on port 0");
    req_vec = 4'b0001;
    @(posedge clk);
    #1;
    assert(grant_vec == 4'b0001) else $error("Expected grant on port 0");
    $display("  req=%b, grant=%b", req_vec, grant_vec);
    
    // Test 2: Hold grant while request active
    $display("\nTest 2: Hold grant while request active");
    repeat(3) begin
        @(posedge clk);
        #1;
        assert(grant_vec == 4'b0001) else $error("Grant should hold on port 0");
        $display("  req=%b, grant=%b", req_vec, grant_vec);
    end
    
    // Test 3: Round-robin cycling
    $display("\nTest 3: Round-robin cycling (release after grant)");
    req_vec = 4'b1111;
    repeat(8) begin
        @(posedge clk);
        #1;
        $display("  req=%b, grant=%b", req_vec, grant_vec);
        req_vec = req_vec & ~grant_vec;
        // Re-assert all requests for next cycle
        @(posedge clk);
        req_vec = 4'b1111;
    end
    
    // Test 4: Release all requests
    $display("\nTest 4: Release all requests");
    req_vec = 4'b0000;
    @(posedge clk);
    #1;
    assert(grant_vec == 4'b0000) else $error("Grant should be 0 with no requests");
    $display("  req=%b, grant=%b", req_vec, grant_vec);
    
    // Test 5: Sparse requests with cycling
    $display("\nTest 5: Sparse requests cycling");
    repeat(6) begin
        req_vec = 4'b1010;
        @(posedge clk);
        #1;
        $display("  req=%b, grant=%b", req_vec, grant_vec);
        req_vec = req_vec & ~grant_vec;
        @(posedge clk);
    end
    
    // Test 6: Continuous requests without release
    $display("\nTest 6: Hold grant when not released");
    req_vec = 4'b1111;
    @(posedge clk);
    #1;
    $display("  First grant: req=%b, grant=%b", req_vec, grant_vec);
    repeat(3) begin
        @(posedge clk);
        #1;
        $display("  Holding:     req=%b, grant=%b", req_vec, grant_vec);
    end
    
    $display("\n=== Testbench Complete ===");
    $finish;
end

// Timeout
initial begin
    #10000;
    $display("ERROR: Testbench timeout!");
    $finish;
end

endmodule
