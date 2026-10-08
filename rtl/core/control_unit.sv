// ============================================================================
// Module: control_unit
// Description: Main instruction decoder for RV32IM + Custom-0 (imu_mac).
//              Decodes the opcode, funct3, and funct7 fields to generate
//              all pipeline control signals.
//
// Custom-0 (imu_mac):  opcode = 7'b0001011, funct3 = 3'b000
//   - Triggers CIM MAC operation
//   - Result written back from CIM PE (result_src = 2'b11)
// ============================================================================
`timescale 1ns/1ps
import pkg_riscv::*;

module control_unit (
    input  logic [6:0] opcode,      // inst[6:0]
    input  logic [2:0] funct3,      // inst[14:12]
    input  logic [6:0] funct7,      // inst[31:25]
    output ctrl_t      ctrl         // Control signal bundle
);

    always_comb begin
        // ---- Default: all signals inactive ----
        ctrl.reg_write  = 1'b0;
        ctrl.result_src = 2'b00;    // ALU result
        ctrl.mem_read   = 1'b0;
        ctrl.mem_write  = 1'b0;
        ctrl.alu_src    = 1'b0;     // rs2
        ctrl.branch     = 1'b0;
        ctrl.jump       = 1'b0;
        ctrl.alu_op     = ALU_ADD;
        ctrl.is_mul     = 1'b0;
        ctrl.mul_op     = MUL_MUL;
        ctrl.is_cim     = 1'b0;

        case (opcode)
            // ============================================================
            // LUI: rd = imm << 12
            // ============================================================
            OP_LUI: begin
                ctrl.reg_write = 1'b1;
                ctrl.alu_src   = 1'b1;     // Use immediate
                ctrl.alu_op    = ALU_ADD;   // rs1=x0 (0) + imm
            end

            // ============================================================
            // AUIPC: rd = PC + (imm << 12)
            // ============================================================
            OP_AUIPC: begin
                ctrl.reg_write = 1'b1;
                ctrl.alu_src   = 1'b1;
                ctrl.alu_op    = ALU_ADD;
            end

            // ============================================================
            // JAL: rd = PC+4, PC = PC + imm
            // ============================================================
            OP_JAL: begin
                ctrl.reg_write = 1'b1;
                ctrl.jump      = 1'b1;
            end

            // ============================================================
            // JALR: rd = PC+4, PC = (rs1 + imm) & ~1
            // ============================================================
            OP_JALR: begin
                ctrl.reg_write = 1'b1;
                ctrl.jump      = 1'b1;
                ctrl.alu_src   = 1'b1;
            end

            // ============================================================
            // BRANCH: BEQ, BNE, BLT, BGE, BLTU, BGEU
            // ============================================================
            OP_BRANCH: begin
                ctrl.branch = 1'b1;
                ctrl.alu_op = ALU_SUB;      // Subtract for comparison
            end

            // ============================================================
            // LOAD: LB, LH, LW, LBU, LHU
            // ============================================================
            OP_LOAD: begin
                ctrl.reg_write  = 1'b1;
                ctrl.result_src = 2'b01;    // Memory data
                ctrl.mem_read   = 1'b1;
                ctrl.alu_src    = 1'b1;     // Base + offset
                ctrl.alu_op     = ALU_ADD;
            end

            // ============================================================
            // STORE: SB, SH, SW
            // ============================================================
            OP_STORE: begin
                ctrl.mem_write = 1'b1;
                ctrl.alu_src   = 1'b1;      // Base + offset
                ctrl.alu_op    = ALU_ADD;
            end

            // ============================================================
            // ALU Immediate: ADDI, SLTI, SLTIU, XORI, ORI, ANDI, SLLI,
            //                SRLI, SRAI
            // ============================================================
            OP_IMM: begin
                ctrl.reg_write = 1'b1;
                ctrl.alu_src   = 1'b1;      // Use immediate
                case (funct3)
                    3'b000: ctrl.alu_op = ALU_ADD;      // ADDI
                    3'b010: ctrl.alu_op = ALU_SLT;      // SLTI
                    3'b011: ctrl.alu_op = ALU_SLTU;     // SLTIU
                    3'b100: ctrl.alu_op = ALU_XOR;      // XORI
                    3'b110: ctrl.alu_op = ALU_OR;       // ORI
                    3'b111: ctrl.alu_op = ALU_AND;      // ANDI
                    3'b001: ctrl.alu_op = ALU_SLL;      // SLLI
                    3'b101: ctrl.alu_op = funct7[5] ? ALU_SRA : ALU_SRL; // SRLI/SRAI
                    default: ctrl.alu_op = ALU_ADD;
                endcase
            end

            // ============================================================
            // ALU Register: ADD, SUB, SLL, SLT, SLTU, XOR, SRL, SRA,
            //               OR, AND, MUL, MULH, MULHSU, MULHU,
            //               DIV, DIVU, REM, REMU
            // ============================================================
            OP_REG: begin
                ctrl.reg_write = 1'b1;
                if (funct7 == 7'b0000001) begin
                    // ---- M-Extension (Multiply/Divide) ----
                    ctrl.is_mul     = 1'b1;
                    ctrl.result_src = 2'b10; // Multiplier result
                    case (funct3)
                        3'b000: ctrl.mul_op = MUL_MUL;
                        3'b001: ctrl.mul_op = MUL_MULH;
                        3'b010: ctrl.mul_op = MUL_MULHSU;
                        3'b011: ctrl.mul_op = MUL_MULHU;
                        3'b100: ctrl.mul_op = MUL_DIV;
                        3'b101: ctrl.mul_op = MUL_DIVU;
                        3'b110: ctrl.mul_op = MUL_REM;
                        3'b111: ctrl.mul_op = MUL_REMU;
                        default: ctrl.mul_op = MUL_MUL;
                    endcase
                end else begin
                    // ---- Base Integer ALU ----
                    case (funct3)
                        3'b000: ctrl.alu_op = funct7[5] ? ALU_SUB : ALU_ADD;
                        3'b001: ctrl.alu_op = ALU_SLL;
                        3'b010: ctrl.alu_op = ALU_SLT;
                        3'b011: ctrl.alu_op = ALU_SLTU;
                        3'b100: ctrl.alu_op = ALU_XOR;
                        3'b101: ctrl.alu_op = funct7[5] ? ALU_SRA : ALU_SRL;
                        3'b110: ctrl.alu_op = ALU_OR;
                        3'b111: ctrl.alu_op = ALU_AND;
                        default: ctrl.alu_op = ALU_ADD;
                    endcase
                end
            end

            // ============================================================
            // CUSTOM-0: imu_mac rd, rs1, rs2
            //   opcode = 0001011, funct3 = 000
            //   rs1 = base address of weight vector in CIM-SRAM
            //   rs2 = base address of input activation vector
            //   rd  = destination for MAC result
            // ============================================================
            OP_CUSTOM_0: begin
                if (funct3 == 3'b000) begin
                    ctrl.reg_write  = 1'b1;
                    ctrl.is_cim     = 1'b1;
                    ctrl.result_src = 2'b11; // CIM result
                end
            end

            // ============================================================
            // SYSTEM: ECALL, EBREAK (not implemented — treated as NOP)
            // ============================================================
            OP_SYSTEM: begin
                // NOP for now
            end

            default: begin
                // Unknown opcode — all signals remain at default (NOP)
            end
        endcase
    end

endmodule
