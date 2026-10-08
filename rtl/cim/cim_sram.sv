`timescale 1ns / 1ps

module cim_sram #(
    parameter DEPTH = 256,
    parameter WIDTH = 32
) (
    input  logic             clk,
    input  logic             rst_n,
    
    input  logic [31:0]      addr,
    input  logic             wen,
    input  logic [WIDTH-1:0] wdata,
    output logic [WIDTH-1:0] rdata
);

    // Simple SRAM behavioral model
    logic [WIDTH-1:0] mem [0:DEPTH-1];
    
    // For Word-aligned access
    logic [$clog2(DEPTH)-1:0] mem_addr;
    assign mem_addr = addr[2 +: $clog2(DEPTH)];

    always_ff @(posedge clk) begin
        if (wen) begin
            mem[mem_addr] <= wdata;
        end
        rdata <= mem[mem_addr];
    end

endmodule
