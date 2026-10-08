# ==============================================================================
# Cadence Genus Synthesis Script for RISC-V Core (RV32IM + Custom-0 CIM)
# Technology: 45nm (FreePDK45 / NangateOpenCellLibrary 45nm)
# ==============================================================================

# ------------------------------------------------------------------------------
# 1. Technology Library Configuration
# ------------------------------------------------------------------------------
# In 45nm, labs typically use either:
#   A) NangateOpenCellLibrary_typical.lib (Nangate 45nm)
#   B) gscl45nm.lib                      (OSU FreePDK45)
# Set your lab's library directory path and filename below:

set PDK_45NM_DIR "/cadence/pdk/FreePDK45/osu_soc/lib/files"
set TARGET_LIB   "gscl45nm.lib"

# If using Nangate45, comment above and uncomment below:
# set PDK_45NM_DIR "/cadence/pdk/NangateOpenCellLibrary_PDKv1_3_v2010_12/lib/Low_Temp"
# set TARGET_LIB   "NangateOpenCellLibrary_typical.lib"

# Set Genus search paths
set_db init_lib_search_path [list . $PDK_45NM_DIR]
set_db target_library       [list $TARGET_LIB]
set_db link_library         [list * $TARGET_LIB]

# Directory paths
set RTL_DIR    "../../rtl/core"
set SCRIPT_DIR "../scripts"
set REPORT_DIR "../reports_45nm"
set OUTPUT_DIR "../outputs_45nm"

file mkdir $REPORT_DIR
file mkdir $OUTPUT_DIR

# ------------------------------------------------------------------------------
# 2. Read SystemVerilog RTL (Order is critical: Package MUST be read first!)
# ------------------------------------------------------------------------------
set_db init_hdl_search_path [list $RTL_DIR]

puts "INFO: Reading SystemVerilog RTL files for RV32IM + Custom-0 CIM Core..."

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
puts "INFO: Applying SDC constraints for 45nm..."
read_sdc $SCRIPT_DIR/constraints_45nm.sdc

# ------------------------------------------------------------------------------
# 5. Synthesis Flow (Generic -> Mapping -> Optimization)
# ------------------------------------------------------------------------------
puts "INFO: Running generic synthesis..."
syn_generic

puts "INFO: Mapping to 45nm standard cells..."
syn_map

puts "INFO: Optimizing timing, power, and area..."
syn_opt

# ------------------------------------------------------------------------------
# 6. Generate Performance, Power, and Area (PPA) Reports
# ------------------------------------------------------------------------------
puts "INFO: Generating PPA reports..."
report_timing > $REPORT_DIR/timing_riscv_top_45nm.rpt
report_area   > $REPORT_DIR/area_riscv_top_45nm.rpt
report_power  > $REPORT_DIR/power_riscv_top_45nm.rpt
report_qor    > $REPORT_DIR/qor_riscv_top_45nm.rpt
report_gates  > $REPORT_DIR/gates_riscv_top_45nm.rpt

# ------------------------------------------------------------------------------
# 7. Write Outputs for Cadence Innovus (P&R)
# ------------------------------------------------------------------------------
puts "INFO: Exporting gate-level netlist and SDC for Innovus..."
write_hdl > $OUTPUT_DIR/riscv_top_45nm_netlist.v
write_sdc > $OUTPUT_DIR/riscv_top_45nm.sdc

puts "=========================================================================="
puts "SUCCESS: 45nm Synthesis completed! Reports saved in $REPORT_DIR/"
puts "=========================================================================="
