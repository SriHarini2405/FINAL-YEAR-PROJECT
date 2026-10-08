// ============================================================================
// Module: imm_gen
// Description: Immediate generator for all RV32IM instruction formats.
//              Extracts and sign-extends the immediate value based on opcode.
//
//   Format    | Bits used                          | Instructions
//   ----------|-------------------------------------|--------------------
//   I-type    | inst[31:20]                         | LOAD, ALU-Imm, JALR
//   S-type    | inst[31:25], inst[11:7]             | STORE
//   B-type    | inst[31], inst[7], inst[30:25],     | BRANCH
//             | inst[11:8], 0                       |
//   U-type    | inst[31:12], 12'b0                  | LUI, AUIPC
//   J-type    | inst[31], inst[19:12], inst[20],    | JAL
//             | inst[30:21], 0                      |
// ============================================================================
`timescale 1ns/1ps
import pkg_riscv::*;

module imm_gen (
    input  logic [31:0] inst,       // Full 32-bit instruction
    output logic [31:0] imm         // Sign-extended immediate
);

    logic [6:0] opcode;
    assign opcode = inst[6:0];

    always_comb begin
        case (opcode)
            // I-type: loads, ALU-immediate, JALR
            OP_LOAD, OP_IMM, OP_JALR:
                imm = {{20{inst[31]}}, inst[31:20]};

            // S-type: stores
            OP_STORE:
                imm = {{20{inst[31]}}, inst[31:25], inst[11:7]};

            // B-type: branches (target is PC + imm, imm is multiple of 2)
            OP_BRANCH:
                imm = {{20{inst[31]}}, inst[7], inst[30:25], inst[11:8], 1'b0};

            // U-type: LUI, AUIPC (upper 20 bits)
            OP_LUI, OP_AUIPC:
                imm = {inst[31:12], 12'b0};

            // J-type: JAL (target is PC + imm, imm is multiple of 2)
            OP_JAL:
                imm = {{12{inst[31]}}, inst[19:12], inst[20], inst[30:21], 1'b0};

            // Default (includes CUSTOM_0 — no immediate needed)
            default:
                imm = 32'd0;
        endcase
    end

endmodule
