# ==============================================================================
# Script: run_sim_vivado.tcl
# Description: Vivado XSim Batch / GUI Simulation Script for RV32IM AXI SoC
# ==============================================================================

# Create in-memory project
create_project -in_memory -part xc7a35tcpg236-1

# Read SystemVerilog RTL files
read_verilog -sv {
    ./rtl/riscv_pkg.sv
    ./rtl/reg_file.sv
    ./rtl/alu.sv
    ./rtl/multiplier.sv
    ./rtl/divider.sv
    ./rtl/imm_gen.sv
    ./rtl/branch_eval.sv
    ./rtl/if_stage.sv
    ./rtl/id_stage.sv
    ./rtl/ex_stage.sv
    ./rtl/mem_stage.sv
    ./rtl/wb_stage.sv
    ./rtl/hazard_unit.sv
    ./rtl/forwarding_unit.sv
    ./rtl/pipeline_registers.sv
    ./rtl/axi_lite_master.sv
    ./rtl/axi_lite_slave_mem.sv
    ./rtl/rv32im_core.sv
    ./rtl/rv32im_axi_top.sv
}

# Read Simulation Testbench
read_verilog -sv ./sim/tb_rv32im_axi.sv

# Set Top Module
set_property top tb_rv32im_axi [get_filesets sim_1]

# Launch Simulation
launch_simulation -mode behavioral

# Run Simulation
run all
