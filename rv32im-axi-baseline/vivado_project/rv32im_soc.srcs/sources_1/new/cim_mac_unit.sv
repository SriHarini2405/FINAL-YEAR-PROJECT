module cim_mac_unit (
    input  logic [31:0] rs1_data,
    input  logic [31:0] rs2_data,
    output logic [31:0] result
);
    assign result = $signed(rs1_data) * $signed(rs2_data);  // placeholder; swap in your CIM logic later
endmodule