# ==============================================================================
# File: run_synth_vivado.tcl
# Description: Vivado Synthesis and Implementation Script for RV32IM AXI Core
# ==============================================================================

# Target Artix-7 FPGA (Basys 3 / Nexys A7 family)
set_part xc7a35tcpg236-1

# Read all SystemVerilog sources
read_verilog -sv ./rtl/riscv_pkg.sv
read_verilog -sv ./rtl/reg_file.sv
read_verilog -sv ./rtl/alu.sv
read_verilog -sv ./rtl/multiplier.sv
read_verilog -sv ./rtl/divider.sv
read_verilog -sv ./rtl/imm_gen.sv
read_verilog -sv ./rtl/branch_eval.sv
read_verilog -sv ./rtl/if_stage.sv
read_verilog -sv ./rtl/id_stage.sv
read_verilog -sv ./rtl/ex_stage.sv
read_verilog -sv ./rtl/mem_stage.sv
read_verilog -sv ./rtl/wb_stage.sv
read_verilog -sv ./rtl/hazard_unit.sv
read_verilog -sv ./rtl/forwarding_unit.sv
read_verilog -sv ./rtl/pipeline_registers.sv
read_verilog -sv ./rtl/axi_lite_master.sv
read_verilog -sv ./rtl/axi_lite_slave_mem.sv
read_verilog -sv ./rtl/rv32im_core.sv
read_verilog -sv ./rtl/rv32im_axi_top.sv

# Run Synthesis targeting 100 MHz clock
synth_design -top rv32im_axi_top -part xc7a35tcpg236-1

# Apply 100 MHz Clock Constraint (10.0 ns)
create_clock -period 10.000 -name clk [get_ports clk]

# Generate Area / Utilization Report
report_utilization -file utilization_synth.txt
report_utilization -hierarchical -file utilization_hierarchical.txt

# Run Optimization, Placement and Routing
opt_design
place_design
route_design

# Generate Post-Implementation Reports
report_utilization -file utilization_impl.txt
report_timing_summary -file timing_summary.txt
report_power -file power_summary.txt

puts "=================================================================="
puts " SUCCESS: Vivado Synthesis and Implementation Reports Generated!"
puts " Files: utilization_synth.txt, timing_summary.txt, power_summary.txt"
puts "=================================================================="
