// ============================================================================
// Module: multiplier
// Description: RV32M extension — Multiply / Divide / Remainder unit.
//              Single-cycle combinational implementation.
//              Supports: MUL, MULH, MULHSU, MULHU, DIV, DIVU, REM, REMU
//
// Note: Division by zero returns -1 (DIV) or 0xFFFFFFFF (DIVU) per RISC-V spec.
//       Remainder of division by zero returns the dividend per spec.
// ============================================================================
`timescale 1ns/1ps
import pkg_riscv::*;

module multiplier (
    input  logic [31:0] a,          // Operand A (rs1)
    input  logic [31:0] b,          // Operand B (rs2)
    input  mul_op_e     mul_ctrl,   // Operation select
    output logic [31:0] result      // 32-bit result
);

    // Full 64-bit multiply results for different signedness combinations
    logic signed [63:0] mul_signed;        // Signed × Signed
    logic signed [63:0] mul_signed_u;      // Signed × Unsigned
    logic        [63:0] mul_unsigned;      // Unsigned × Unsigned

    assign mul_signed   = $signed(a) * $signed(b);
    assign mul_signed_u = $signed(a) * $signed({1'b0, b});
    assign mul_unsigned = $unsigned(a) * $unsigned(b);

    always_comb begin
        case (mul_ctrl)
            // ----- Multiply -----
            MUL_MUL:    result = mul_unsigned[31:0];        // Lower 32 bits
            MUL_MULH:   result = mul_signed[63:32];         // Upper 32 bits (S×S)
            MUL_MULHSU: result = mul_signed_u[63:32];       // Upper 32 bits (S×U)
            MUL_MULHU:  result = mul_unsigned[63:32];        // Upper 32 bits (U×U)

            // ----- Divide -----
            MUL_DIV:    result = (b == 32'd0) ? 32'hFFFFFFFF :
                                 $unsigned($signed(a) / $signed(b));
            MUL_DIVU:   result = (b == 32'd0) ? 32'hFFFFFFFF :
                                 a / b;

            // ----- Remainder -----
            MUL_REM:    result = (b == 32'd0) ? a :
                                 $unsigned($signed(a) % $signed(b));
            MUL_REMU:   result = (b == 32'd0) ? a :
                                 a % b;

            default:    result = 32'd0;
        endcase
    end

endmodule
