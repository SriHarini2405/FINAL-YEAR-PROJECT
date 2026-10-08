`timescale 1ns / 1ps
import pkg_riscv::*;

module soc_top (
    input  logic        clk,
    input  logic        rst_n,
    
    // Debug outputs
    output logic [31:0] debug_pc
);

    // Instruction Memory interface
    logic [31:0] imem_addr;
    logic [31:0] imem_data;
    
    // Data Memory interface
    logic [31:0] dmem_addr;
    logic [31:0] dmem_wdata;
    logic [31:0] dmem_rdata;
    logic        dmem_we;
    logic        dmem_re;
    
    // CIM interface
    logic        cim_enable;
    logic [31:0] cim_base_weights;
    logic [31:0] cim_base_inputs;
    logic [2:0]  cim_funct3;
    logic [31:0] cim_result;
    logic        cim_done;
    logic        cim_busy;

    // Assign debug_pc from instruction address
    assign debug_pc = imem_addr;

    // =========================================================
    // RISC-V Core
    // =========================================================
    riscv_top u_riscv_core (
        .clk               (clk),
        .rst_n             (rst_n),
        
        // Instruction memory
        .imem_addr         (imem_addr),
        .imem_data         (imem_data),
        
        // Data memory
        .dmem_addr         (dmem_addr),
        .dmem_wdata        (dmem_wdata),
        .dmem_rdata        (dmem_rdata),
        .dmem_we           (dmem_we),
        .dmem_re           (dmem_re),
        
        // CIM interface
        .cim_enable        (cim_enable),
        .cim_base_weights  (cim_base_weights),
        .cim_base_inputs   (cim_base_inputs),
        .cim_funct3        (cim_funct3),
        .cim_result        (cim_result),
        .cim_done          (cim_done)
    );

    // =========================================================
    // CIM-SRAM MAC Accelerator
    // =========================================================
    cim_top u_cim_top (
        .clk               (clk),
        .rst_n             (rst_n),
        .cim_enable        (cim_enable),
        .base_addr_weights (cim_base_weights),
        .base_addr_inputs  (cim_base_inputs),
        .funct3            (cim_funct3),
        .cim_result        (cim_result),
        .cim_done          (cim_done),
        .cim_busy          (cim_busy)
    );

    // =========================================================
    // Instruction Memory (ROM)
    // =========================================================
    instruction_mem #(
        .DEPTH     (1024),
        .INIT_FILE ("imem.hex")
    ) u_imem (
        .addr  (imem_addr),
        .rdata (imem_data)
    );
    
    // =========================================================
    // Data Memory (RAM)
    // =========================================================
    data_mem #(
        .DEPTH     (1024),
        .INIT_FILE ("dmem.hex")
    ) u_dmem (
        .clk    (clk),
        .rst_n  (rst_n),
        .addr   (dmem_addr),
        .wdata  (dmem_wdata),
        .wen    (dmem_we),
        .funct3 (3'b010),       // Default to word access (LW/SW)
        .rdata  (dmem_rdata)
    );

endmodule
