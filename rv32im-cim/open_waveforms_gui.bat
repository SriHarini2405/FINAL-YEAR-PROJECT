@echo off
echo ============================================================
echo Opening Vivado Simulation GUI Waveform Viewer directly...
echo ============================================================
cd /d "C:\FINAL_YEAR_PROJECT"
start "" "C:\Xilinx\Vivado\2016.4\bin\xsim.bat" tb_rv32im_axi_snapshot -gui
