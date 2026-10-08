// ============================================================================
// Module: riscv_top
// Description: Top-level module for the 5-stage pipelined RV32IM RISC-V
//              processor with Custom-0 CIM extension (imu_mac).
//
//              Instantiates all 5 pipeline stages, manages pipeline registers,
//              and connects the hazard unit for forwarding/stall/flush.
//
// Pipeline:  IF → ID → EX → MEM → WB
//                                ↕
//                           CIM-SRAM PE
//
// External Interfaces:
//   - Instruction Memory (read-only)
//   - Data Memory (read/write)
//   - CIM PE (enable, addresses, result, done)
// ============================================================================
`timescale 1ns/1ps
import pkg_riscv::*;

module riscv_top (
    input  logic        clk,
    input  logic        rst_n,

    // ---- Instruction Memory Interface ----
    output logic [31:0] imem_addr,          // PC → instruction memory
    input  logic [31:0] imem_data,          // Fetched instruction

    // ---- Data Memory Interface ----
    output logic [31:0] dmem_addr,          // Load/Store address
    output logic [31:0] dmem_wdata,         // Store data
    output logic        dmem_we,            // Write enable (Store)
    output logic        dmem_re,            // Read enable (Load)
    input  logic [31:0] dmem_rdata,         // Loaded data

    // ---- CIM Interface ----
    output logic        cim_enable,         // Start CIM MAC operation
    output logic [31:0] cim_base_weights,   // Weight base address
    output logic [31:0] cim_base_inputs,    // Input base address
    output logic [2:0]  cim_funct3,         // CIM operation variant
    input  logic [31:0] cim_result,         // MAC result
    input  logic        cim_done            // CIM operation complete
);

    // ====================================================================
    // Pipeline Registers
    // ====================================================================
    if_id_reg_t  if_id_reg,  if_id_next;
    id_ex_reg_t  id_ex_reg,  id_ex_next;
    ex_mem_reg_t ex_mem_reg, ex_mem_next;
    mem_wb_reg_t mem_wb_reg, mem_wb_next;

    // ====================================================================
    // Interconnect Signals
    // ====================================================================
    // Hazard unit outputs
    logic        stall_if, stall_id, stall_ex;
    logic        flush_id, flush_ex;
    logic [1:0]  forward_a, forward_b;

    // Source register addresses (from decode, for hazard detection)
    logic [4:0]  id_rs1_addr, id_rs2_addr;

    // Branch/Jump signals (from execute)
    logic        branch_taken;
    logic        jump;
    logic [31:0] target_pc;

    // Writeback data
    logic [31:0] wb_data;

    // CIM busy signal (from memory stage)
    logic        cim_busy;

    // Forwarded result from EX/MEM (used for forwarding mux)
    logic [31:0] mem_fwd_data;

    // ====================================================================
    // Forwarding Data Selection
    // The data forwarded from EX/MEM depends on the result source:
    //   result_src=10 → multiplier result
    //   result_src=11 → CIM result (only valid after cim_done)
    //   otherwise     → ALU result
    // ====================================================================
    always_comb begin
        case (ex_mem_reg.ctrl.result_src)
            2'b10:   mem_fwd_data = ex_mem_reg.mul_result;
            default: mem_fwd_data = ex_mem_reg.alu_result;
        endcase
    end

    // ====================================================================
    // Stage 1: Instruction Fetch (IF)
    // ====================================================================
    fetch_stage u_fetch (
        .clk            (clk),
        .rst_n          (rst_n),
        .stall          (stall_if),
        .branch_taken   (branch_taken),
        .jump           (jump),
        .target_pc      (target_pc),
        .imem_addr      (imem_addr),
        .imem_data      (imem_data),
        .if_id_next     (if_id_next)
    );

    // ====================================================================
    // Stage 2: Instruction Decode (ID)
    // ====================================================================
    decode_stage u_decode (
        .clk            (clk),
        .rst_n          (rst_n),
        .flush          (flush_id),
        .if_id_reg      (if_id_reg),
        .wb_reg_write   (mem_wb_reg.ctrl.reg_write),
        .wb_rd_addr     (mem_wb_reg.rd_addr),
        .wb_data        (wb_data),
        .id_ex_next     (id_ex_next),
        .rs1_addr       (id_rs1_addr),
        .rs2_addr       (id_rs2_addr)
    );

    // ====================================================================
    // Stage 3: Execute (EX)
    // ====================================================================
    execute_stage u_execute (
        .id_ex_reg      (id_ex_reg),
        .forward_a      (forward_a),
        .forward_b      (forward_b),
        .mem_fwd_data   (mem_fwd_data),
        .wb_fwd_data    (wb_data),
        .ex_mem_next    (ex_mem_next),
        .branch_taken   (branch_taken),
        .jump           (jump),
        .target_pc      (target_pc)
    );

    // ====================================================================
    // Stage 4: Memory Access (MEM)
    // ====================================================================
    memory_stage u_memory (
        .ex_mem_reg     (ex_mem_reg),
        .dmem_addr      (dmem_addr),
        .dmem_wdata     (dmem_wdata),
        .dmem_we        (dmem_we),
        .dmem_re        (dmem_re),
        .dmem_rdata     (dmem_rdata),
        .cim_enable     (cim_enable),
        .cim_base_weights(cim_base_weights),
        .cim_base_inputs(cim_base_inputs),
        .cim_funct3     (cim_funct3),
        .cim_result     (cim_result),
        .cim_done       (cim_done),
        .cim_busy       (cim_busy),
        .mem_wb_next    (mem_wb_next)
    );

    // ====================================================================
    // Stage 5: Writeback (WB)
    // ====================================================================
    writeback_stage u_writeback (
        .mem_wb_reg     (mem_wb_reg),
        .wb_data        (wb_data)
    );

    // ====================================================================
    // Hazard Detection & Forwarding Unit
    // ====================================================================
    hazard_unit u_hazard (
        // From ID stage (current instruction being decoded)
        .id_rs1_addr    (id_rs1_addr),
        .id_rs2_addr    (id_rs2_addr),
        // From ID/EX register (instruction in EX stage)
        .ex_rs1_addr    (id_ex_reg.rs1_addr),
        .ex_rs2_addr    (id_ex_reg.rs2_addr),
        .ex_rd_addr     (id_ex_reg.rd_addr),
        // From EX/MEM register (instruction in MEM stage)
        .mem_rd_addr    (ex_mem_reg.rd_addr),
        .mem_reg_write  (ex_mem_reg.ctrl.reg_write),
        // From MEM/WB register (instruction in WB stage)
        .wb_rd_addr     (mem_wb_reg.rd_addr),
        .wb_reg_write   (mem_wb_reg.ctrl.reg_write),
        // Load-use hazard detection
        .ex_mem_read    (id_ex_reg.ctrl.mem_read),
        // Branch/Jump from EX
        .branch_taken   (branch_taken),
        .jump           (jump),
        // CIM stall
        .cim_busy       (cim_busy),
        // Outputs
        .forward_a      (forward_a),
        .forward_b      (forward_b),
        .stall_if       (stall_if),
        .stall_id       (stall_id),
        .stall_ex       (stall_ex),
        .flush_id       (flush_id),
        .flush_ex       (flush_ex)
    );

    // ====================================================================
    // Pipeline Register Updates (Sequential Logic)
    // ====================================================================
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            // Reset all pipeline registers to zero (NOP)
            if_id_reg  <= '0;
            id_ex_reg  <= '0;
            ex_mem_reg <= '0;
            mem_wb_reg <= '0;
        end else begin

            // ---- IF/ID Register ----
            // Hold value during stall; insert NOP during flush
            if (!stall_id) begin
                if (flush_id)
                    if_id_reg <= '0;
                else
                    if_id_reg <= if_id_next;
            end

            // ---- ID/EX Register ----
            // Hold value during EX stall; insert NOP during flush
            if (!stall_ex) begin
                if (flush_ex)
                    id_ex_reg <= '0;
                else
                    id_ex_reg <= id_ex_next;
            end

            // ---- EX/MEM Register ----
            // Hold value while CIM is busy
            if (!cim_busy) begin
                ex_mem_reg <= ex_mem_next;
            end

            // ---- MEM/WB Register ----
            // Insert NOP while CIM is busy (don't write garbage)
            if (cim_busy) begin
                mem_wb_reg <= '0;
            end else begin
                mem_wb_reg <= mem_wb_next;
            end

        end
    end

endmodule
