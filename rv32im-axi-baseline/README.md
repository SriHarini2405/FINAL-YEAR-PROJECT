# 5-Stage Pipelined RV32IM Processor with AMBA AXI4-Lite Interconnect

A synthesizable, verified 5-stage pipelined **RISC-V (RV32IM)** processor core integrated with an **AMBA AXI4-Lite** master interface and unified dual-port on-chip memory. 

This repository serves as the **verified baseline architecture** for comparing against Compute-in-Memory (CiM) accelerator architectures for edge AI workloads.

---

## 🏛️ Microarchitecture Features

* **ISA Compliance:** RV32I Base Integer Instruction Set + RV32M Standard Extension for Hardware Multiplication and Division.
* **Pipeline Structure:** Classic 5-stage decoupled pipeline:
  1. **IF (Instruction Fetch):** Sequential PC generation, branch redirection, tightly-coupled instruction fetch.
  2. **ID (Instruction Decode):** 32-entry $\times$ 32-bit register file (dual-read, single-write with $x0 = 0$), immediate generator for I, S, B, U, J types, centralized control unit.
  3. **EX (Execute):** 32-bit ALU, hardware 32-bit signed/unsigned multiplier, 32-cycle sequential non-restoring divider, branch target calculator & condition evaluator.
  4. **MEM (Memory):** Load/store formatting (byte, halfword, word signed/unsigned), byte write-strobe generator, AMBA AXI4-Lite master bridge.
  5. **WB (Writeback):** Result multiplexer (ALU / Multiplier / Divider / Memory / PC+4) committing to register file.
* **Hazard Resolution Subsystem:**
  * **Data Hazards:** Full EX-to-EX and MEM-to-EX RAW (Read-After-Write) data forwarding unit.
  * **Load-Use Hazards:** 1-cycle automatic pipeline stall with synchronous bubble insertion.
  * **Control Hazards:** Branch misprediction flushes IF/ID and ID/EX stages on taken branches and jumps (`JAL`, `JALR`).
  * **Bus Latency & Stalls:** Dynamic pipeline freezing (`axi_stall`) during multi-cycle AXI4-Lite transactions.
  * **Multi-Cycle Divider Stall:** Sequential division stall (`div_stall`) for ~32 clock cycles.
* **Interconnect & Memory:**
  * Industry-standard **AMBA AXI4-Lite** protocol with separate Read Address (`AR`), Read Data (`R`), Write Address (`AW`), Write Data (`W`), and Write Response (`B`) channels.
  * 4 KB dual-port unified SRAM modeling on-chip instruction and data memory.

---

## 📂 Repository Structure

```text
FINAL_YEAR_PROJECT/
├── rtl/                          # Synthesizable SystemVerilog Source Files
│   ├── riscv_pkg.sv              # Enums, structs, opcodes, ALU & M-extension functions, AXI types
│   ├── reg_file.sv               # 32x32-bit Register File (dual read, single write, x0=0)
│   ├── alu.sv                    # 32-bit Arithmetic Logic Unit
│   ├── multiplier.sv             # RV32M 32x32 signed/unsigned hardware multiplier
│   ├── divider.sv                # RV32M 32-cycle non-restoring sequential divider
│   ├── imm_gen.sv                # Immediate generator (I, S, B, U, J types)
│   ├── branch_eval.sv            # Branch condition evaluator (BEQ, BNE, BLT, BGE, etc.)
│   ├── if_stage.sv               # Instruction Fetch stage & PC logic
│   ├── id_stage.sv               # Instruction Decode stage & Control Unit
│   ├── ex_stage.sv               # Execution stage integrating ALU, Multiplier & Divider
│   ├── mem_stage.sv              # Memory stage with load/store formatting & AXI Master
│   ├── wb_stage.sv               # Writeback stage multiplexer
│   ├── hazard_unit.sv            # Hazard detection, AXI wait-state stalls, pipeline flushing
│   ├── forwarding_unit.sv        # RAW hazard data forwarding unit
│   ├── pipeline_registers.sv     # Synchronous IF/ID, ID/EX, EX/MEM, MEM/WB registers
│   ├── axi_lite_master.sv        # AXI4-Lite Master Bridge (translating CPU requests to AXI)
│   ├── axi_lite_slave_mem.sv     # Dual-port AXI4-Lite Slave Memory (4 KB unified)
│   ├── rv32im_core.sv            # 5-stage CPU Core connecting all stages & hazard logic
│   └── rv32im_axi_top.sv         # Top-level SoC integrating Core + AXI Bus + Memory
│
├── sim/                          # Verification Testbenches & Firmware
│   ├── tb_rv32im_axi.sv          # Complete self-checking testbench
│   └── test_firmware.hex         # Assembly machine code for 4-element MAC + Division
│
├── scripts/                      # Automation Scripts
│   ├── run_sim.bat               # 1-Click command-line compile, elaborate & simulate script
│   ├── run_sim_vivado.tcl        # Vivado XSim batch simulation script
│   ├── run_synth_vivado.tcl      # Vivado batch FPGA synthesis & timing/power report script
│   └── create_project.tcl        # Vivado project generation script
│
├── vivado_project/               # Clean Vivado IDE Project
│   └── rv32im_soc.xpr            # Vivado Project File
│
├── open_in_vivado_gui.bat        # 1-Click launcher to open Vivado IDE GUI
├── open_waveforms_gui.bat        # 1-Click launcher for direct waveform viewing
├── .gitignore                    # Git ignore file for EDA tool artifacts
└── README.md                     # Project documentation
```

---

## 🧪 Verification & Simulation Results

The processor is verified using a self-checking testbench executing an edge AI vector **Multiply-Accumulate (MAC)** kernel over the AXI bus, followed by RV32M hardware division:

* **Workload Input Vector $X$:** `[3, 7, -4, 5]` (stored at AXI address `0x100`)
* **Workload Weight Vector $W$:** `[2, -3, 6, 4]` (stored at AXI address `0x110`)
* **MAC Mathematical Formula:**
  $$\text{Acc} = \sum_{i=0}^{3} X[i] \times W[i] = (3 \times 2) + (7 \times -3) + (-4 \times 6) + (5 \times 4) = 6 - 21 - 24 + 20 = -19$$
* **Hardware Division:**
  $$\text{Quotient} = -19 / 4 = -4, \quad \text{Remainder} = -19 \pmod 4 = -3$$

### Simulation Summary Output (Vivado XSim):

```text
==================================================================
                   SIMULATION RESULTS & VERIFICATION
==================================================================
 Total Clock Cycles Executed : 145
 Total AXI Memory Reads      : 8
 Total AXI Memory Writes     : 1
 ------------------------------------------------------------------
 MAC Stored in Memory [0x120] : -19 (Expected: -19)
 MAC Accumulator Reg (a3)     : -19 (Expected: -19)
 Division Result Reg (t2)     : -4 (Expected: -4)
 Remainder Result Reg (t3)    : -3 (Expected: -3)
 ------------------------------------------------------------------
 [SUCCESS] ALL CHECKS PASSED!
 Hardware MAC and RV32M Division Verified on AXI4-Lite Bus.
==================================================================
$finish called at time : 1465 ns
```

---

## 🚀 How to Run

### Method 1: Open Vivado IDE GUI (Recommended)
1. Double-click `open_in_vivado_gui.bat` (or open `vivado_project/rv32im_soc.xpr` in Vivado).
2. In the left Flow Navigator, click **Run Simulation $\rightarrow$ Run Behavioral Simulation**.
3. In the Waveform window, right-click registers `a3`, `t2`, `t3` and set **Radix $\rightarrow$ Signed Decimal**.
4. Type `run all` in the Tcl Console or click **Run All** ($\rhd\rhd$) to view the completed waveforms up to 1465 ns.

### Method 2: Fast Command-Line Simulation
Run the automated batch script in Windows CMD / PowerShell:
```cmd
cd C:\FINAL_YEAR_PROJECT
scripts\run_sim.bat
```
This automatically compiles with `xvlog`, elaborates with `xelab`, and runs behavioral simulation with `xsim` in under 10 seconds.

### Method 3: FPGA Synthesis & Utilization
To run batch synthesis targeting Xilinx Artix-7 (`xc7a35tcpg236-1`):
```cmd
vivado -mode batch -source scripts\run_synth_vivado.tcl
```
Generates `utilization_synth.txt`, `timing_summary.txt`, and `power_summary.txt`.


