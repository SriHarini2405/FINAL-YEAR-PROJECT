`timescale 1ns / 1ps

module cim_top (
    input  logic        clk,
    input  logic        rst_n,
    
    // Interface to RISC-V core
    input  logic        cim_enable,
    input  logic [31:0] base_addr_weights,
    input  logic [31:0] base_addr_inputs,
    input  logic [2:0]  funct3,
    
    output logic [31:0] cim_result,
    output logic        cim_done,
    output logic        cim_busy
);

    // Internal signals
    logic [31:0] sram_addr;
    logic        sram_wen;
    logic [31:0] sram_wdata;
    logic [31:0] sram_rdata;
    
    logic        mac_start;
    logic [31:0] mac_weights;
    logic [31:0] mac_inputs;
    logic [31:0] mac_result;
    logic        mac_done;

    cim_controller u_cim_controller (
        .clk               (clk),
        .rst_n             (rst_n),
        .cim_enable        (cim_enable),
        .base_addr_weights (base_addr_weights),
        .base_addr_inputs  (base_addr_inputs),
        .funct3            (funct3),
        .cim_result        (cim_result),
        .cim_done          (cim_done),
        .cim_busy          (cim_busy),
        
        .sram_addr         (sram_addr),
        .sram_wen          (sram_wen),
        .sram_wdata        (sram_wdata),
        .sram_rdata        (sram_rdata),
        
        .mac_start         (mac_start),
        .mac_weights       (mac_weights),
        .mac_inputs        (mac_inputs),
        .mac_result        (mac_result),
        .mac_done          (mac_done)
    );

    mac_unit u_mac_unit (
        .clk         (clk),
        .rst_n       (rst_n),
        .mac_start   (mac_start),
        .mac_weights (mac_weights),
        .mac_inputs  (mac_inputs),
        .mac_result  (mac_result),
        .mac_done    (mac_done)
    );
    
    cim_sram #(
        .DEPTH(256),
        .WIDTH(32)
    ) u_cim_sram (
        .clk   (clk),
        .rst_n (rst_n),
        .addr  (sram_addr),
        .wen   (sram_wen),
        .wdata (sram_wdata),
        .rdata (sram_rdata)
    );

endmodule
