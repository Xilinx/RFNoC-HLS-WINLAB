############################################################
## This file is generated automatically by Vivado HLS.
## Please DO NOT edit it.
## Copyright (C) 2015 Xilinx Inc. All rights reserved.
############################################################
open_project pn_seq_lfsr
set_top pn_seq_gen_lfsr
add_files pn_seq_gen_lfsr.cpp
open_solution "solution1"
set_part {xc7k410tffg900-2}
create_clock -period 5 -name default
#source "./pn_seq_lfsr/solution1/directives.tcl"
#csim_design
csynth_design
#cosim_design
export_design -format ip_catalog
