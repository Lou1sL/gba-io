#!/bin/sh

# 
# Vivado(TM)
# runme.sh: a Vivado-generated Runs Script for UNIX
# Copyright 1986-2022 Xilinx, Inc. All Rights Reserved.
# Copyright 2022-2024 Advanced Micro Devices, Inc. All Rights Reserved.
# 

echo "This script was generated under a different operating system."
echo "Please update the PATH and LD_LIBRARY_PATH variables below, before executing this script"
exit

if [ -z "$PATH" ]; then
  PATH=E:/ProgramTools/Xilinx/Vivado/2024.1/ids_lite/ISE/bin/nt64;E:/ProgramTools/Xilinx/Vivado/2024.1/ids_lite/ISE/lib/nt64:E:/ProgramTools/Xilinx/Vivado/2024.1/bin
else
  PATH=E:/ProgramTools/Xilinx/Vivado/2024.1/ids_lite/ISE/bin/nt64;E:/ProgramTools/Xilinx/Vivado/2024.1/ids_lite/ISE/lib/nt64:E:/ProgramTools/Xilinx/Vivado/2024.1/bin:$PATH
fi
export PATH

if [ -z "$LD_LIBRARY_PATH" ]; then
  LD_LIBRARY_PATH=
else
  LD_LIBRARY_PATH=:$LD_LIBRARY_PATH
fi
export LD_LIBRARY_PATH

HD_PWD='E:/Projects/Hardware/gba-io/reference/Aritx7/FPGA/100T/microblaze_ddr_100t/microblaze_ddr_100t.runs/bd_top_rst_mig_7series_0_100M_0_synth_1'
cd "$HD_PWD"

HD_LOG=runme.log
/bin/touch $HD_LOG

ISEStep="./ISEWrap.sh"
EAStep()
{
     $ISEStep $HD_LOG "$@" >> $HD_LOG 2>&1
     if [ $? -ne 0 ]
     then
         exit
     fi
}

EAStep vivado -log bd_top_rst_mig_7series_0_100M_0.vds -m64 -product Vivado -mode batch -messageDb vivado.pb -notrace -source bd_top_rst_mig_7series_0_100M_0.tcl
