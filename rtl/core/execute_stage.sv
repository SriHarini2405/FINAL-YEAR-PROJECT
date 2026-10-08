// ============================================================================
// Module: execute_stage
// Description: Execute (EX) stage of the RISC-V pipeline.
//              - ALU computation with forwarding muxes
//              - M-extension multiplier
//              - Branch condition evaluation
//              - Branch/Jump target address calculation
//              - For CIM instructions: passes rs1/rs2 values through to MEM
// ============================================================================
`timescale 1ns/1ps
import pkg_riscv::*;

module execute_stage (
    // Input from ID/EX pipeline register
    input  id_ex_reg_t  id_ex_reg,

    // Forwarding inputs
    input  logic [1:0]  forward_a,      // Forwarding mux select for operand A
    input  logic [1:0]  forward_b,      // Forwarding mux select for operand B
    input  logic [31:0] mem_fwd_data,   // Forwarded data from EX/MEM stage
    input  logic [31:0] wb_fwd_data,    // Forwarded data from MEM/WB stage

    // Output to EX/MEM pipeline register
    output ex_mem_reg_t ex_mem_next,

    // Branch/Jump control (fed back to IF stage)
    output logic        branch_taken,   // Branch condition met
    output logic        jump,           // Unconditional jump
    output logic [31:0] target_pc       // Branch/Jump target address
);

    logic [31:0] alu_in_a;      // ALU operand A (after forwarding)
    logic [31:0] alu_in_b;      // ALU operand B (after forwarding + imm mux)
    logic [31:0] rs2_fwd;       // rs2 after forwarding (before imm mux)
    logic [31:0] alu_result;    // ALU output
    logic [31:0] mul_result;    // Multiplier output
    logic        alu_zero;      // ALU zero flag

    // ====================================================================
    // 1. Forwarding Muxes
    //    00 = register file value (no forwarding)
    //    01 = MEM/WB forwarded data
    //    10 = EX/MEM forwarded data
    // ====================================================================
    always_comb begin
        case (forward_a)
            2'b00:   alu_in_a = id_ex_reg.rs1_data;
            2'b01:   alu_in_a = wb_fwd_data;
            2'b10:   alu_in_a = mem_fwd_data;
            default: alu_in_a = id_ex_reg.rs1_data;
        endcase

        case (forward_b)
            2'b00:   rs2_fwd = id_ex_reg.rs2_data;
            2'b01:   rs2_fwd = wb_fwd_data;
            2'b10:   rs2_fwd = mem_fwd_data;
            default: rs2_fwd = id_ex_reg.rs2_data;
        endcase
    end

    // ====================================================================
    // 2. ALU Input B Mux
    //    alu_src=0: use rs2 (R-type, branch)
    //    alu_src=1: use immediate (I-type, load, store)
    // ====================================================================
    assign alu_in_b = id_ex_reg.ctrl.alu_src ? id_ex_reg.imm : rs2_fwd;

    // ====================================================================
    // 3. ALU Instance
    // ====================================================================
    alu u_alu (
        .a        (alu_in_a),
        .b        (alu_in_b),
        .alu_ctrl (id_ex_reg.ctrl.alu_op),
        .result   (alu_result),
        .zero     (alu_zero)
    );

    // ====================================================================
    // 4. Multiplier Instance (M-Extension)
    // ====================================================================
    multiplier u_mul (
        .a        (alu_in_a),
        .b        (rs2_fwd),
        .mul_ctrl (id_ex_reg.ctrl.mul_op),
        .result   (mul_result)
    );

    // ====================================================================
    // 5. Branch Condition Evaluation
    //    Uses ALU result and zero flag to determine if branch is taken
    // ====================================================================
    always_comb begin
        branch_taken = 1'b0;
        if (id_ex_reg.ctrl.branch) begin
            case (id_ex_reg.funct3)
                3'b000:  branch_taken =  alu_zero;         // BEQ:  rs1 == rs2
                3'b001:  branch_taken = !alu_zero;          // BNE:  rs1 != rs2
                3'b100:  branch_taken =  alu_result[31];    // BLT:  signed(rs1) < signed(rs2)
                3'b101:  branch_taken = !alu_result[31];    // BGE:  signed(rs1) >= signed(rs2)
                3'b110:  branch_taken =  alu_result[0];     // BLTU: unsigned(rs1) < unsigned(rs2)
                3'b111:  branch_taken = !alu_result[0];     // BGEU: unsigned(rs1) >= unsigned(rs2)
                default: branch_taken = 1'b0;
            endcase
        end
    end

    // ====================================================================
    // 6. Jump Signal
    // ====================================================================
    assign jump = id_ex_reg.ctrl.jump;

    // ====================================================================
    // 7. Target PC Calculation
    //    JAL:  target = PC + imm
    //    JALR: target = rs1 + imm (alu_src=1, so base = rs1 value)
    //    Branch: target = PC + imm
    // ====================================================================
    logic [31:0] pc_base;
    // For JALR, base is rs1; for JAL/Branch, base is PC
    assign pc_base  = (id_ex_reg.ctrl.jump && id_ex_reg.ctrl.alu_src) ? alu_in_a : id_ex_reg.pc;
    assign target_pc = pc_base + id_ex_reg.imm;

    // ====================================================================
    // 8. Output to EX/MEM Pipeline Register
    // ====================================================================
    always_comb begin
        ex_mem_next.alu_result = alu_result;
        ex_mem_next.mul_result = mul_result;
        ex_mem_next.rs2_data   = rs2_fwd;           // Store data (for SW/SH/SB)
        ex_mem_next.rs1_data   = alu_in_a;           // Weight base addr (for CIM)
        ex_mem_next.rd_addr    = id_ex_reg.rd_addr;
        ex_mem_next.funct3     = id_ex_reg.funct3;
        ex_mem_next.ctrl       = id_ex_reg.ctrl;
    end

endmodule
