`timescale 1ns / 1ps

module mac_unit (
    input  logic        clk,
    input  logic        rst_n,
    
    input  logic        mac_start,
    input  logic [31:0] mac_weights, // 4 x 8-bit
    input  logic [31:0] mac_inputs,  // 4 x 8-bit
    
    output logic [31:0] mac_result,
    output logic        mac_done
);

    // 4 parallel 8x8 multipliers
    logic signed [7:0] w0, w1, w2, w3;
    logic signed [7:0] x0, x1, x2, x3;
    
    logic signed [15:0] p0, p1, p2, p3;
    logic signed [31:0] sum;
    
    assign {w3, w2, w1, w0} = mac_weights;
    assign {x3, x2, x1, x0} = mac_inputs;
    
    assign p0 = w0 * x0;
    assign p1 = w1 * x1;
    assign p2 = w2 * x2;
    assign p3 = w3 * x3;
    
    // Adder tree
    assign sum = p0 + p1 + p2 + p3;
    
    // 1-cycle registered output
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            mac_result <= '0;
            mac_done <= 1'b0;
        end else begin
            if (mac_start) begin
                mac_result <= sum;
                mac_done <= 1'b1;
            end else begin
                mac_done <= 1'b0;
            end
        end
    end

endmodule
