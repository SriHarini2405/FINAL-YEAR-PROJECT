// ============================================================================
// Module: hazard_unit
// Description: Detects data hazards and generates forwarding/stall/flush
//              signals for the 5-stage pipeline.
//
// Handles:
//   1. Data Forwarding: EX→EX (forward_a/b = 10), MEM→EX (forward_a/b = 01)
//   2. Load-Use Hazard: Stall IF+ID, insert bubble in EX (1-cycle penalty)
//   3. Control Hazard: Flush IF/ID on branch taken or jump
//   4. CIM Stall: Freeze entire pipeline while CIM PE is busy
// ============================================================================
`timescale 1ns/1ps

module hazard_unit (
    // Source register addresses from ID stage (current instruction)
    input  logic [4:0] id_rs1_addr,
    input  logic [4:0] id_rs2_addr,

    // Register addresses from pipeline registers (for forwarding)
    input  logic [4:0] ex_rs1_addr,     // ID/EX.rs1 (needed for forwarding check)
    input  logic [4:0] ex_rs2_addr,     // ID/EX.rs2
    input  logic [4:0] ex_rd_addr,      // ID/EX.rd (for load-use detection)
    input  logic [4:0] mem_rd_addr,     // EX/MEM.rd
    input  logic [4:0] wb_rd_addr,      // MEM/WB.rd

    // Write-enable signals from later stages
    input  logic       mem_reg_write,   // EX/MEM stage writes to rd?
    input  logic       wb_reg_write,    // MEM/WB stage writes to rd?

    // Load-use detection
    input  logic       ex_mem_read,     // ID/EX stage is a LOAD instruction?

    // Branch/Jump from EX stage
    input  logic       branch_taken,
    input  logic       jump,

    // CIM busy from MEM stage
    input  logic       cim_busy,

    // ---- Forwarding Mux Controls ----
    // 00 = no forwarding (use register file value)
    // 01 = forward from MEM/WB (wb_data)
    // 10 = forward from EX/MEM (alu_result)
    output logic [1:0] forward_a,
    output logic [1:0] forward_b,

    // ---- Stall Signals ----
    output logic       stall_if,        // Freeze PC and IF/ID register
    output logic       stall_id,        // Freeze ID/EX register
    output logic       stall_ex,        // Freeze EX/MEM register

    // ---- Flush Signals ----
    output logic       flush_id,        // Insert NOP into ID/EX
    output logic       flush_ex         // Insert NOP into EX/MEM
);

    // ====================================================================
    // 1. Data Forwarding Logic
    //    Priority: EX/MEM (more recent) > MEM/WB (older)
    // ====================================================================
    always_comb begin
        // Default: no forwarding
        forward_a = 2'b00;
        forward_b = 2'b00;

        // ---- Forward to ALU input A (rs1) ----
        if (mem_reg_write && (mem_rd_addr != 5'd0) && (mem_rd_addr == ex_rs1_addr)) begin
            forward_a = 2'b10;  // Forward from EX/MEM
        end else if (wb_reg_write && (wb_rd_addr != 5'd0) && (wb_rd_addr == ex_rs1_addr)) begin
            forward_a = 2'b01;  // Forward from MEM/WB
        end

        // ---- Forward to ALU input B (rs2) ----
        if (mem_reg_write && (mem_rd_addr != 5'd0) && (mem_rd_addr == ex_rs2_addr)) begin
            forward_b = 2'b10;  // Forward from EX/MEM
        end else if (wb_reg_write && (wb_rd_addr != 5'd0) && (wb_rd_addr == ex_rs2_addr)) begin
            forward_b = 2'b01;  // Forward from MEM/WB
        end
    end

    // ====================================================================
    // 2. Load-Use Hazard Detection
    //    If the instruction in EX is a LOAD and the instruction in ID
    //    needs its result, we must stall for 1 cycle.
    // ====================================================================
    logic load_use_hazard;
    assign load_use_hazard = ex_mem_read
                           && (ex_rd_addr != 5'd0)
                           && ((ex_rd_addr == id_rs1_addr) || (ex_rd_addr == id_rs2_addr));

    // ====================================================================
    // 3. Stall Signals
    //    - Load-use: stall IF + ID for 1 cycle
    //    - CIM busy: stall IF + ID + EX until CIM completes
    // ====================================================================
    assign stall_if = load_use_hazard | cim_busy;
    assign stall_id = load_use_hazard | cim_busy;
    assign stall_ex = cim_busy;

    // ====================================================================
    // 4. Flush Signals
    //    - Branch taken / jump: flush IF/ID and ID/EX (kill wrong-path)
    //    - Load-use stall: insert bubble into EX (flush ID/EX)
    // ====================================================================
    assign flush_id = branch_taken | jump;
    assign flush_ex = branch_taken | jump | load_use_hazard;

endmodule
