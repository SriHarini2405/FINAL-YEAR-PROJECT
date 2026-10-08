@echo off
set VIVADO_BIN=C:\Xilinx\Vivado\2016.4\bin

echo =======================================================
echo Compiling SystemVerilog RTL and Testbench with xvlog...
echo =======================================================

call "%VIVADO_BIN%\xvlog.bat" -sv -i ./rtl ./rtl/riscv_pkg.sv ./rtl/reg_file.sv ./rtl/alu.sv ./rtl/multiplier.sv ./rtl/divider.sv ./rtl/imm_gen.sv ./rtl/branch_eval.sv ./rtl/if_stage.sv ./rtl/id_stage.sv ./rtl/ex_stage.sv ./rtl/mem_stage.sv ./rtl/wb_stage.sv ./rtl/hazard_unit.sv ./rtl/forwarding_unit.sv ./rtl/pipeline_registers.sv ./rtl/axi_lite_master.sv ./rtl/axi_lite_slave_mem.sv ./rtl/rv32im_core.sv ./rtl/rv32im_axi_top.sv ./sim/tb_rv32im_axi.sv

if %ERRORLEVEL% NEQ 0 (
    echo [ERROR] Compilation failed!
    exit /b %ERRORLEVEL%
)

echo =======================================================
echo Elaborating design with xelab...
echo =======================================================
call "%VIVADO_BIN%\xelab.bat" -top tb_rv32im_axi -snapshot tb_rv32im_axi_snapshot -timescale 1ns/1ps -debug typical

if %ERRORLEVEL% NEQ 0 (
    echo [ERROR] Elaboration failed!
    exit /b %ERRORLEVEL%
)

echo =======================================================
echo Running simulation with xsim...
echo =======================================================
call "%VIVADO_BIN%\xsim.bat" tb_rv32im_axi_snapshot -runall

echo =======================================================
echo Simulation finished.
echo =======================================================
