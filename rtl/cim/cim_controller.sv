`timescale 1ns / 1ps

module cim_controller (
    input  logic        clk,
    input  logic        rst_n,
    
    // Interface with RISC-V MEM stage
    input  logic        cim_enable,
    input  logic [31:0] base_addr_weights,
    input  logic [31:0] base_addr_inputs,
    input  logic [2:0]  funct3,
    output logic [31:0] cim_result,
    output logic        cim_done,
    output logic        cim_busy,
    
    // Interface with CIM SRAM/PE
    output logic [31:0] sram_addr,
    output logic        sram_wen,
    output logic [31:0] sram_wdata,
    input  logic [31:0] sram_rdata,
    
    output logic        mac_start,
    output logic [31:0] mac_weights,
    output logic [31:0] mac_inputs,
    input  logic [31:0] mac_result,
    input  logic        mac_done
);

    typedef enum logic [1:0] {
        IDLE    = 2'b00,
        LOAD    = 2'b01,
        COMPUTE = 2'b10,
        DONE    = 2'b11
    } state_t;

    state_t state_d, state_q;
    
    // Internal registers to hold loaded data
    logic [31:0] weights_d, weights_q;
    logic [31:0] inputs_d, inputs_q;
    
    // Step counter for loading data
    logic [1:0] step_d, step_q;
    
    always_comb begin
        state_d = state_q;
        step_d = step_q;
        weights_d = weights_q;
        inputs_d = inputs_q;
        
        cim_done = 1'b0;
        cim_busy = 1'b0;
        cim_result = '0;
        
        sram_addr = '0;
        sram_wen = 1'b0;
        sram_wdata = '0;
        
        mac_start = 1'b0;
        mac_weights = weights_q;
        mac_inputs = inputs_q;
        
        case (state_q)
            IDLE: begin
                if (cim_enable) begin
                    state_d = LOAD;
                    step_d = 2'b00;
                    cim_busy = 1'b1;
                end
            end
            
            LOAD: begin
                cim_busy = 1'b1;
                if (step_q == 2'b00) begin
                    // Read weights
                    sram_addr = base_addr_weights;
                    step_d = 2'b01;
                end else if (step_q == 2'b01) begin
                    weights_d = sram_rdata;
                    // Read inputs
                    sram_addr = base_addr_inputs;
                    step_d = 2'b10;
                end else if (step_q == 2'b10) begin
                    inputs_d = sram_rdata;
                    state_d = COMPUTE;
                end
            end
            
            COMPUTE: begin
                cim_busy = 1'b1;
                mac_start = 1'b1;
                if (mac_done) begin
                    state_d = DONE;
                end
            end
            
            DONE: begin
                cim_done = 1'b1;
                cim_result = mac_result;
                state_d = IDLE;
            end
            
            default: state_d = IDLE;
        endcase
    end

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state_q <= IDLE;
            step_q <= '0;
            weights_q <= '0;
            inputs_q <= '0;
        end else begin
            state_q <= state_d;
            step_q <= step_d;
            weights_q <= weights_d;
            inputs_q <= inputs_d;
        end
    end

endmodule
