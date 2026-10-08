# ==============================================================================
# Cadence Genus Synthesis Script for RISC-V Core
# Technology: SkyWater 130nm (sky130_fd_sc_hd)
# ==============================================================================

# ------------------------------------------------------------------------------
# 1. User Configuration & Library Paths
# ------------------------------------------------------------------------------
# Update this path to where the Sky130 standard cell library lives in your lab:
set SKY130_LIB_DIR "/home/vlsi/pdk/skywater-pdk/libraries/sky130_fd_sc_hd/latest/timing"

# Target typical corner: 1.8V, 25C
set TARGET_LIB "sky130_fd_sc_hd__tt_025C_1v80.lib"

# Set Genus search paths
set_db init_lib_search_path [list . $SKY130_LIB_DIR]
set_db target_library       [list $TARGET_LIB]
set_db link_library         [list * $TARGET_LIB]

# Directory paths
set RTL_DIR "../../rtl/core"
set SCRIPT_DIR "../scripts"
set REPORT_DIR "../reports"
set OUTPUT_DIR "../outputs"

file mkdir $REPORT_DIR
file mkdir $OUTPUT_DIR

# ------------------------------------------------------------------------------
# 2. Read SystemVerilog RTL (Order is critical: Package MUST be read first!)
# ------------------------------------------------------------------------------
set_db init_hdl_search_path [list $RTL_DIR]

puts "INFO: Reading SystemVerilog RTL files..."

# Package definition
read_hdl -sv $RTL_DIR/pkg_riscv.sv

# Submodules & Datapath components
read_hdl -sv $RTL_DIR/register_file.sv
read_hdl -sv $RTL_DIR/imm_gen.sv
read_hdl -sv $RTL_DIR/alu.sv
read_hdl -sv $RTL_DIR/multiplier.sv
read_hdl -sv $RTL_DIR/control_unit.sv
read_hdl -sv $RTL_DIR/hazard_unit.sv

# Pipeline stages
read_hdl -sv $RTL_DIR/fetch_stage.sv
read_hdl -sv $RTL_DIR/decode_stage.sv
read_hdl -sv $RTL_DIR/execute_stage.sv
read_hdl -sv $RTL_DIR/memory_stage.sv
read_hdl -sv $RTL_DIR/writeback_stage.sv

# Core Top-Level
read_hdl -sv $RTL_DIR/riscv_top.sv

# ------------------------------------------------------------------------------
# 3. Elaborate Top-Level Module
# ------------------------------------------------------------------------------
puts "INFO: Elaborating design: riscv_top..."
elaborate riscv_top

# Check for unresolved references or hierarchy issues
check_design -unresolved

# ------------------------------------------------------------------------------
# 4. Apply Timing Constraints (SDC)
# ------------------------------------------------------------------------------
puts "INFO: Applying SDC constraints..."
read_sdc $SCRIPT_DIR/constraints_sky130.sdc

# ------------------------------------------------------------------------------
# 5. Synthesis Steps (Generic -> Technology Mapping -> Optimization)
# ------------------------------------------------------------------------------
puts "INFO: Running generic synthesis..."
syn_generic

puts "INFO: Mapping to Sky130 standard cells..."
syn_map

puts "INFO: Optimizing timing and area..."
syn_opt

# ------------------------------------------------------------------------------
# 6. Generate Performance, Power, and Area (PPA) Reports
# ------------------------------------------------------------------------------
puts "INFO: Generating synthesis reports..."
report_timing > $REPORT_DIR/timing_riscv_top_sky130.rpt
report_area   > $REPORT_DIR/area_riscv_top_sky130.rpt
report_power  > $REPORT_DIR/power_riscv_top_sky130.rpt
report_qor    > $REPORT_DIR/qor_riscv_top_sky130.rpt
report_gates  > $REPORT_DIR/gates_riscv_top_sky130.rpt

# ------------------------------------------------------------------------------
# 7. Write Outputs for Innovus (P&R)
# ------------------------------------------------------------------------------
puts "INFO: Writing output netlist and constraints..."
write_hdl > $OUTPUT_DIR/riscv_top_sky130_netlist.v
write_sdc > $OUTPUT_DIR/riscv_top_sky130.sdc

puts "=========================================================================="
puts "SUCCESS: Synthesis completed! Reports saved in $REPORT_DIR/"
puts "=========================================================================="
