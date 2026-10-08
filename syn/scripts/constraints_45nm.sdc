# ==============================================================================
# SDC Constraints for RISC-V Core in 45nm (FreePDK45 / Nangate45)
# Target Frequency: 200 MHz (Clock Period: 5.0 ns)
# ==============================================================================

# 1. Clock Definition (5.0 ns = 200 MHz)
set CLK_PERIOD 5.0
create_clock -name clk -period $CLK_PERIOD [get_ports clk]

# 2. Clock Uncertainty & Slew
set_clock_uncertainty 0.1 [get_clocks clk]
set_clock_transition  0.08 [get_clocks clk]

# 3. Input Delays (20% of cycle = 1.0 ns)
set_input_delay -clock clk -max [expr 0.2 * $CLK_PERIOD] [all_inputs -no_clocks]
set_input_delay -clock clk -min 0.2                      [all_inputs -no_clocks]

# 4. Output Delays (20% of cycle = 1.0 ns)
set_output_delay -clock clk -max [expr 0.2 * $CLK_PERIOD] [all_outputs]
set_output_delay -clock clk -min 0.2                       [all_outputs]

# 5. Output Pin Load Capacitance (Nangate45 std cell load ~ 5-10 fF)
set_load -pin_load 0.010 [all_outputs]

# 6. False Paths
# Asynchronous active-low reset
set_false_path -from [get_ports rst_n]

# 7. Design Rule Constraints (DRC)
set_max_fanout 16 [current_design]
set_max_transition 0.5 [current_design]
