# Synthesis Directory Guide for Cadence Genus (45nm)

This directory contains the automation scripts to synthesize the **RV32IM + Custom-0 CIM Core** using **Cadence Genus** targeted to **45nm** (FreePDK45 / Nangate45).

---

## 📁 Directory Layout

```text
syn/
├── scripts/
│   ├── synth_45nm.tcl            # Genus synthesis flow script for 45nm
│   └── constraints_45nm.sdc      # 200 MHz (5.0 ns) timing constraints for 45nm
├── reports_45nm/                 # Generated automatically: timing, area, power, gates
└── outputs_45nm/                 # Generated automatically: gate-level netlist (.v) & SDC
```

---

## 🚀 How to Run in Cadence Genus

### 1. Verify your 45nm Library Path
Open [`syn/scripts/synth_45nm.tcl`](scripts/synth_45nm.tcl) and ensure `PDK_45NM_DIR` and `TARGET_LIB` point to your lab's library (e.g., `gscl45nm.lib` or `NangateOpenCellLibrary_typical.lib`).

### 2. Launch Genus
From your terminal, navigate to `syn/scripts/` and run:

```bash
cd syn/scripts

# Non-GUI batch synthesis (fast):
genus -files synth_45nm.tcl -log synth_45nm.log

# OR interactive GUI mode:
genus -gui -files synth_45nm.tcl
```


---

## 📊 Outputs Produced

After synthesis finishes:
1. **Timing Report (`reports/timing_riscv_top_sky130.rpt`)**: Shows worst negative slack (WNS), critical data paths, and data arrival times.
2. **Area Report (`reports/area_riscv_top_sky130.rpt`)**: Shows total standard cell count and total silicon area in $\mu\text{m}^2$.
3. **Power Report (`reports/power_riscv_top_sky130.rpt`)**: Leakage power, internal switching power, and net switching power at 1.8V.
4. **Gate-Level Netlist (`outputs/riscv_top_sky130_netlist.v`)**: Synthesized netlist ready for **Cadence Innovus (P&R)** or gate-level simulation in **NCSim**.
