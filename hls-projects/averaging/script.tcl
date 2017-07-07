############################################################
## This file is generated automatically by Vivado HLS.
## Please DO NOT edit it.
## Copyright (C) 2015 Xilinx Inc. All rights reserved.
############################################################
open_project averaging
set_top averaging
add_files averaging.cpp
open_solution "solution1"
set_part {xc7k410tffg900-2}
create_clock -period 5 -name default
#source "./averaging/solution1/directives.tcl"
#csim_design
csynth_design
#cosim_design
export_design -format ip_catalog
