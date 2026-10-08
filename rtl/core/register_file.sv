// ============================================================================
// Module: register_file
// Description: 32 x 32-bit RISC-V integer register file
//              - 2 asynchronous read ports (rs1, rs2)
//              - 1 synchronous write port (rd)
//              - x0 is hardwired to zero
// ============================================================================
`timescale 1ns/1ps

module register_file (
    input  logic        clk,
    input  logic        we,         // Write enable
    input  logic [4:0]  rs1,        // Read address 1
    input  logic [4:0]  rs2,        // Read address 2
    input  logic [4:0]  rd,         // Write address
    input  logic [31:0] wdata,      // Write data
    output logic [31:0] rdata1,     // Read data 1
    output logic [31:0] rdata2      // Read data 2
);

    // 32 registers, each 32-bit wide
    logic [31:0] regfile [0:31];

    // ---- Asynchronous Read ----
    // x0 is always zero per RISC-V spec
    assign rdata1 = (rs1 == 5'd0) ? 32'd0 : regfile[rs1];
    assign rdata2 = (rs2 == 5'd0) ? 32'd0 : regfile[rs2];

    // ---- Synchronous Write ----
    // Writes happen on rising clock edge; x0 cannot be written
    always_ff @(posedge clk) begin
        if (we && (rd != 5'd0)) begin
            regfile[rd] <= wdata;
        end
    end

endmodule
