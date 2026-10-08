`timescale 1ns / 1ps

module instruction_mem #(
    parameter DEPTH = 1024,
    parameter INIT_FILE = "imem.hex"
) (
    input  logic [31:0] addr,
    output logic [31:0] rdata
);

    logic [31:0] mem [0:DEPTH-1];
    
    initial begin
        $readmemh(INIT_FILE, mem);
    end
    
    logic [$clog2(DEPTH)-1:0] mem_addr;
    assign mem_addr = addr[2 +: $clog2(DEPTH)];
    
    assign rdata = mem[mem_addr];

endmodule
