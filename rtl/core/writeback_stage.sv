// ============================================================================
// Module: writeback_stage
// Description: Writeback (WB) stage of the RISC-V pipeline.
//              Selects the final result to write back to the register file
//              based on result_src control signal.
//
//   result_src | Source           | Instructions
//   -----------|------------------|---------------------------
//   2'b00      | ALU result       | R-type, I-type ALU, LUI, AUIPC
//   2'b01      | Memory data      | LOAD (LW, LH, LB, LHU, LBU)
//   2'b10      | Multiplier result| MUL, MULH, DIV, REM, etc.
//   2'b11      | CIM MAC result   | imu_mac (Custom-0)
// ============================================================================
`timescale 1ns/1ps
import pkg_riscv::*;

module writeback_stage (
    // Input from MEM/WB pipeline register
    input  mem_wb_reg_t mem_wb_reg,

    // Output: data to write to register file
    output logic [31:0] wb_data
);

    always_comb begin
        case (mem_wb_reg.ctrl.result_src)
            2'b00:   wb_data = mem_wb_reg.alu_result;   // ALU
            2'b01:   wb_data = mem_wb_reg.mem_data;      // Memory Load
            2'b10:   wb_data = mem_wb_reg.mul_result;    // M-extension
            2'b11:   wb_data = mem_wb_reg.cim_result;    // CIM MAC
            default: wb_data = mem_wb_reg.alu_result;
        endcase
    end

endmodule
