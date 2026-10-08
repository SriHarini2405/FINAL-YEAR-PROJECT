`timescale 1ns / 1ps

module data_mem #(
    parameter DEPTH = 1024,
    parameter INIT_FILE = "dmem.hex"
) (
    input  logic        clk,
    input  logic        rst_n,
    
    input  logic [31:0] addr,
    input  logic [31:0] wdata,
    input  logic        wen,
    input  logic [2:0]  funct3, // For byte, halfword, word access
    
    output logic [31:0] rdata
);

    logic [31:0] mem [0:DEPTH-1];
    
    initial begin
        $readmemh(INIT_FILE, mem);
    end
    
    logic [$clog2(DEPTH)-1:0] mem_addr;
    assign mem_addr = addr[2 +: $clog2(DEPTH)];
    
    logic [31:0] read_word;
    assign read_word = mem[mem_addr];
    
    always_comb begin
        rdata = read_word; // Default word
        // Add logic for LB, LH etc based on funct3 here if needed
        // funct3: 000=LB, 001=LH, 010=LW, 100=LBU, 101=LHU
        case(funct3)
            3'b000: rdata = {{24{read_word[7]}}, read_word[7:0]};
            3'b001: rdata = {{16{read_word[15]}}, read_word[15:0]};
            3'b010: rdata = read_word;
            3'b100: rdata = {24'b0, read_word[7:0]};
            3'b101: rdata = {16'b0, read_word[15:0]};
            default: rdata = read_word;
        endcase
    end
    
    always_ff @(posedge clk) begin
        if (wen) begin
            // Depending on funct3 (SB, SH, SW), write masking should be applied.
            // Simplified here:
            case(funct3)
                3'b000: mem[mem_addr][7:0] <= wdata[7:0]; // SB
                3'b001: mem[mem_addr][15:0] <= wdata[15:0]; // SH
                3'b010: mem[mem_addr] <= wdata; // SW
                default: mem[mem_addr] <= wdata;
            endcase
        end
    end

endmodule
