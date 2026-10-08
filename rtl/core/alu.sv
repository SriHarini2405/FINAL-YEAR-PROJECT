// ============================================================================
// Module: alu
// Description: 32-bit Arithmetic Logic Unit for RV32I base instructions.
//              Supports ADD, SUB, AND, OR, XOR, SLL, SRL, SRA, SLT, SLTU.
// ============================================================================
`timescale 1ns/1ps
import pkg_riscv::*;

module alu (
    input  logic [31:0] a,          // Operand A (rs1 or forwarded value)
    input  logic [31:0] b,          // Operand B (rs2/immediate or forwarded)
    input  alu_op_e     alu_ctrl,   // ALU operation select
    output logic [31:0] result,     // ALU result
    output logic        zero        // Zero flag (result == 0)
);

    always_comb begin
        case (alu_ctrl)
            ALU_ADD:  result = a + b;                                   // ADD / ADDI
            ALU_SUB:  result = a - b;                                   // SUB
            ALU_SLL:  result = a << b[4:0];                             // SLL / SLLI
            ALU_SLT:  result = {31'b0, ($signed(a) < $signed(b))};      // SLT / SLTI
            ALU_SLTU: result = {31'b0, (a < b)};                        // SLTU / SLTIU
            ALU_XOR:  result = a ^ b;                                   // XOR / XORI
            ALU_SRL:  result = a >> b[4:0];                             // SRL / SRLI
            ALU_SRA:  result = $unsigned($signed(a) >>> b[4:0]);        // SRA / SRAI
            ALU_OR:   result = a | b;                                   // OR / ORI
            ALU_AND:  result = a & b;                                   // AND / ANDI
            default:  result = 32'd0;
        endcase
    end

    // Zero flag: used by branch comparator in execute stage
    assign zero = (result == 32'd0);

endmodule
