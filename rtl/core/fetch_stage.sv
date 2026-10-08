// ============================================================================
// Module: fetch_stage
// Description: Instruction Fetch (IF) stage of the RISC-V pipeline.
//              - Manages the Program Counter (PC)
//              - Reads instruction from instruction memory
//              - Handles stall (hold PC), branch, and jump
// ============================================================================
`timescale 1ns/1ps
import pkg_riscv::*;

module fetch_stage (
    input  logic        clk,
    input  logic        rst_n,
    input  logic        stall,          // Hold PC (load-use or CIM busy)
    input  logic        branch_taken,   // Branch taken from EX stage
    input  logic        jump,           // Jump from EX stage
    input  logic [31:0] target_pc,      // Branch/Jump target address

    // Instruction Memory Interface
    output logic [31:0] imem_addr,      // Instruction address (= PC)
    input  logic [31:0] imem_data,      // Fetched instruction

    // Output to IF/ID pipeline register
    output if_id_reg_t  if_id_next
);

    logic [31:0] pc_reg;    // Current Program Counter
    logic [31:0] pc_next;   // Next PC value

    // ---- Next PC Logic ----
    // Priority: branch/jump > stall > PC+4
    always_comb begin
        if (branch_taken || jump)
            pc_next = target_pc;        // Redirect to branch/jump target
        else if (stall)
            pc_next = pc_reg;           // Hold current PC
        else
            pc_next = pc_reg + 32'd4;   // Sequential: next instruction
    end

    // ---- PC Register ----
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            pc_reg <= 32'h0000_0000;    // Reset vector at address 0
        else
            pc_reg <= pc_next;
    end

    // ---- Outputs ----
    assign imem_addr       = pc_reg;        // Read instruction at current PC
    assign if_id_next.pc   = pc_reg;        // Pass PC to decode stage
    assign if_id_next.inst = imem_data;     // Pass fetched instruction

endmodule
