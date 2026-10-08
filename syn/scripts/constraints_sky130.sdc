# ==============================================================================
# SDC Constraints for RISC-V Core in SkyWater 130nm (sky130_fd_sc_hd)
# Target Frequency: 50 MHz (Period: 20.0 ns) - easily achievable in Sky130
# (You can tighten this to 10.0 ns for 100 MHz if testing peak performance)
# ==============================================================================

# 1. Clock Definition
set CLK_PERIOD 20.0
create_clock -name clk -period $CLK_PERIOD [get_ports clk]

# 2. Clock Uncertainty (Jitter + Skew margin)
set_clock_uncertainty 0.3 [get_clocks clk]
set_clock_transition  0.15 [get_clocks clk]

# 3. Input Delays (assuming 20% of clock period)
set_input_delay -clock clk -max [expr 0.2 * $CLK_PERIOD] [all_inputs -no_clocks]
set_input_delay -clock clk -min 0.5                      [all_inputs -no_clocks]

# 4. Output Delays (assuming 20% of clock period)
set_output_delay -clock clk -max [expr 0.2 * $CLK_PERIOD] [all_outputs]
set_output_delay -clock clk -min 0.5                       [all_outputs]

# 5. Output Driving Load (standard 4X inverter load cap in Sky130 ~ 15-20 fF)
set_load -pin_load 0.020 [all_outputs]

# 6. False Paths
# Active-low reset is asynchronous assertion, so set false path for static timing
set_false_path -from [get_ports rst_n]

# 7. Design Rule Constraints (DRC)
set_max_fanout 16 [current_design]
set_max_transition 1.5 [current_design]
