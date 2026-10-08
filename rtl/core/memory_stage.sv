// ============================================================================
// Module: memory_stage
// Description: Memory Access (MEM) stage of the RISC-V pipeline.
//              - Load/Store data memory access
//              - CIM interface: drives cim_enable, weight/input base addresses
//              - Generates cim_busy to stall the pipeline
//              - Passes results to MEM/WB pipeline register
// ============================================================================
`timescale 1ns/1ps
import pkg_riscv::*;

module memory_stage (
    // Input from EX/MEM pipeline register
    input  ex_mem_reg_t ex_mem_reg,

    // ---- Data Memory Interface ----
    output logic [31:0] dmem_addr,      // Memory address (ALU result = base+offset)
    output logic [31:0] dmem_wdata,     // Data to write (rs2 value)
    output logic        dmem_we,        // Write enable
    output logic        dmem_re,        // Read enable
    input  logic [31:0] dmem_rdata,     // Data read from memory

    // ---- CIM Interface ----
    output logic        cim_enable,         // Trigger CIM operation
    output logic [31:0] cim_base_weights,   // Weight vector base address (rs1)
    output logic [31:0] cim_base_inputs,    // Input vector base address (rs2)
    output logic [2:0]  cim_funct3,         // Operation variant
    input  logic [31:0] cim_result,         // MAC result from CIM PE
    input  logic        cim_done,           // CIM operation complete

    // Stall signal to hazard unit
    output logic        cim_busy,

    // Output to MEM/WB pipeline register
    output mem_wb_reg_t mem_wb_next
);

    // ====================================================================
    // 1. Data Memory Control
    // ====================================================================
    assign dmem_addr  = ex_mem_reg.alu_result;      // Address = base + offset
    assign dmem_wdata = ex_mem_reg.rs2_data;         // Store data from rs2
    assign dmem_we    = ex_mem_reg.ctrl.mem_write;   // SW/SH/SB
    assign dmem_re    = ex_mem_reg.ctrl.mem_read;    // LW/LH/LB/LHU/LBU

    // ====================================================================
    // 2. Load Data Alignment (sign/zero extension based on funct3)
    // ====================================================================
    logic [31:0] load_data;

    always_comb begin
        case (ex_mem_reg.funct3)
            3'b000:  load_data = {{24{dmem_rdata[7]}},  dmem_rdata[7:0]};   // LB  (sign-ext byte)
            3'b001:  load_data = {{16{dmem_rdata[15]}}, dmem_rdata[15:0]};  // LH  (sign-ext half)
            3'b010:  load_data = dmem_rdata;                                 // LW  (full word)
            3'b100:  load_data = {24'd0, dmem_rdata[7:0]};                  // LBU (zero-ext byte)
            3'b101:  load_data = {16'd0, dmem_rdata[15:0]};                 // LHU (zero-ext half)
            default: load_data = dmem_rdata;                                 // Default: word
        endcase
    end

    // ====================================================================
    // 3. CIM Interface
    //    When is_cim is asserted, drive CIM PE with base addresses.
    //    Pipeline stalls until cim_done is received.
    // ====================================================================
    assign cim_enable       = ex_mem_reg.ctrl.is_cim;
    assign cim_base_weights = ex_mem_reg.rs1_data;   // rs1 = weight base addr
    assign cim_base_inputs  = ex_mem_reg.rs2_data;   // rs2 = input base addr
    assign cim_funct3       = ex_mem_reg.funct3;

    // CIM is busy when enabled but not yet done
    assign cim_busy = cim_enable && !cim_done;

    // ====================================================================
    // 4. Output to MEM/WB Pipeline Register
    // ====================================================================
    always_comb begin
        mem_wb_next.alu_result = ex_mem_reg.alu_result;
        mem_wb_next.mem_data   = load_data;
        mem_wb_next.mul_result = ex_mem_reg.mul_result;
        mem_wb_next.cim_result = cim_result;
        mem_wb_next.rd_addr    = ex_mem_reg.rd_addr;
        mem_wb_next.ctrl       = ex_mem_reg.ctrl;
    end

endmodule
