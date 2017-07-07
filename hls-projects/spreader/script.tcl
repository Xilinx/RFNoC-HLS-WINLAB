############################################################
## This file is generated automatically by Vivado HLS.
## Please DO NOT edit it.
## Copyright (C) 2015 Xilinx Inc. All rights reserved.
############################################################
open_project spreading_fsm
set_top spreader
add_files spreader.cpp
open_solution "solution1"
set_part {xc7k410tffg900-2}
create_clock -period 5 -name default
set_clock_uncertainty 12%
config_interface -m_axi_offset off -register_io off -trim_dangling_port
config_rtl -encoding onehot -reset all -reset_level high
#source "./spreading_fsm/solution1/directives.tcl"
#csim_design
csynth_design
#cosim_design
export_design -format ip_catalog
