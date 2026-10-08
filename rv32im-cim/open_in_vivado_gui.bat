@echo off
echo ============================================================
echo Opening Vivado GUI with clean project...
echo Path: C:\FINAL_YEAR_PROJECT\vivado_project\rv32im_soc.xpr
echo ============================================================
cd /d "C:\FINAL_YEAR_PROJECT\vivado_project"
start "" "C:\Xilinx\Vivado\2016.4\bin\vivado.bat" rv32im_soc.xpr
