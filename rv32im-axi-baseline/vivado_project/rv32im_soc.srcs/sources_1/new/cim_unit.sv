// =============================================================================
// File: cim_mac_unit.sv
// Description: CIM MAC unit for the imu_mac custom-0 instruction.
//   Packed INT8 dot product on 32-bit registers (4 lanes):
//     rd = sum_{i=0..3} signed(rs1[8i+7:8i]) * signed(rs2[8i+7:8i])
//   rs1 = 4 x int8 weights, rs2 = 4 x int8 activations.
//   Combinational, single-cycle. Result range +/-65536, no 32-bit overflow.
// =============================================================================
module cim_mac_unit (
    input  wire [31:0] rs1_data,   // packed weights     {w3,w2,w1,w0}
    input  wire [31:0] rs2_data,   // packed activations {a3,a2,a1,a0}
    output wire [31:0] result      // signed 32-bit sum of products
);

    wire signed [7:0] w0 = rs1_data[7:0];
    wire signed [7:0] w1 = rs1_data[15:8];
    wire signed [7:0] w2 = rs1_data[23:16];
    wire signed [7:0] w3 = rs1_data[31:24];

    wire signed [7:0] a0 = rs2_data[7:0];
    wire signed [7:0] a1 = rs2_data[15:8];
    wire signed [7:0] a2 = rs2_data[23:16];
    wire signed [7:0] a3 = rs2_data[31:24];

    wire signed [15:0] p0 = w0 * a0;
    wire signed [15:0] p1 = w1 * a1;
    wire signed [15:0] p2 = w2 * a2;
    wire signed [15:0] p3 = w3 * a3;

    wire signed [31:0] sum = p0 + p1 + p2 + p3;

    assign result = sum;

endmodule