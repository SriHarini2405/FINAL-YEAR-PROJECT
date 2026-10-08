# ==============================================================================
# Script: create_project.tcl (for C:/FINAL_YEAR_PROJECT)
# ==============================================================================
set project_name "rv32im_soc"
set project_dir  "C:/FINAL_YEAR_PROJECT/vivado_project"
set part_name    "xc7a35tcpg236-1"

# Create project
create_project -force $project_name $project_dir -part $part_name
set_property target_language Verilog [current_project]

# Add RTL source files
add_files -fileset sources_1 [glob C:/FINAL_YEAR_PROJECT/rtl/*.sv]
set_property file_type SystemVerilog [get_files -of_objects [get_filesets sources_1]]

# Set Top Module
set_property top rv32im_axi_top [current_fileset]
update_compile_order -fileset sources_1

# Add Simulation source files
add_files -fileset sim_1 C:/FINAL_YEAR_PROJECT/sim/tb_rv32im_axi.sv
set_property file_type SystemVerilog [get_files -of_objects [get_filesets sim_1]]

# Set Simulation Top
set_property top tb_rv32im_axi [get_filesets sim_1]
set_property top_lib xil_defaultlib [get_filesets sim_1]
update_compile_order -fileset sim_1

# Turn off multithreaded xelab to prevent any Windows file locks
set_property -name {xsim.elaborate.xelab.more_options} -value {-mt off} -objects [get_filesets sim_1]

puts "============================================================"
puts "SUCCESS: Project created cleanly in C:/FINAL_YEAR_PROJECT/vivado_project!"
puts "============================================================"
