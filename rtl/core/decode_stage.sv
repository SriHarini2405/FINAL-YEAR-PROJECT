// ============================================================================
// Module: decode_stage
// Description: Instruction Decode (ID) stage of the RISC-V pipeline.
//              - Decodes instruction fields (opcode, rs1, rs2, rd, funct3/7)
//              - Reads register file
//              - Generates immediate value
//              - Generates control signals
//              - Outputs ID/EX pipeline register
//
// Note: The register file and control unit are instantiated inside this stage.
// ============================================================================
`timescale 1ns/1ps
import pkg_riscv::*;

module decode_stage (
    input  logic        clk,
    input  logic        rst_n,
    input  logic        flush,          // Insert NOP on branch/jump

    // Input from IF/ID pipeline register
    input  if_id_reg_t  if_id_reg,

    // Writeback signals (from WB stage, for register file write)
    input  logic        wb_reg_write,   // Write enable
    input  logic [4:0]  wb_rd_addr,     // Destination register
    input  logic [31:0] wb_data,        // Data to write

    // Output to ID/EX pipeline register
    output id_ex_reg_t  id_ex_next,

    // Source register addresses (for hazard unit)
    output logic [4:0]  rs1_addr,
    output logic [4:0]  rs2_addr
);

    // ---- Extract instruction fields ----
    logic [31:0] inst;
    assign inst = if_id_reg.inst;

    assign rs1_addr = inst[19:15];
    assign rs2_addr = inst[24:20];

    logic [4:0]  rd_addr;
    logic [2:0]  funct3;
    logic [6:0]  opcode;
    logic [6:0]  funct7;

    assign rd_addr = inst[11:7];
    assign funct3  = inst[14:12];
    assign opcode  = inst[6:0];
    assign funct7  = inst[31:25];

    // ---- Register File ----
    logic [31:0] rs1_data, rs2_data;

    register_file u_regfile (
        .clk    (clk),
        .we     (wb_reg_write),
        .rs1    (rs1_addr),
        .rs2    (rs2_addr),
        .rd     (wb_rd_addr),
        .wdata  (wb_data),
        .rdata1 (rs1_data),
        .rdata2 (rs2_data)
    );

    // ---- Immediate Generator ----
    logic [31:0] imm;

    imm_gen u_imm_gen (
        .inst (inst),
        .imm  (imm)
    );

    // ---- Control Unit ----
    ctrl_t ctrl;

    control_unit u_ctrl (
        .opcode (opcode),
        .funct3 (funct3),
        .funct7 (funct7),
        .ctrl   (ctrl)
    );

    // ---- Output to ID/EX Pipeline Register ----
    always_comb begin
        if (flush) begin
            // Insert NOP (bubble) — all zeros
            id_ex_next = '0;
        end else begin
            id_ex_next.pc       = if_id_reg.pc;
            id_ex_next.rs1_data = rs1_data;
            id_ex_next.rs2_data = rs2_data;
            id_ex_next.imm      = imm;
            id_ex_next.rs1_addr = rs1_addr;
            id_ex_next.rs2_addr = rs2_addr;
            id_ex_next.rd_addr  = rd_addr;
            id_ex_next.funct3   = funct3;
            id_ex_next.ctrl     = ctrl;
        end
    end

endmodule
