# RFNoC-HLS-WINLAB

Bhargav Gokalgandhi bvg8@scarletmail.rutgers.edu

Prasanthi Maddala prasanti@winlab.rutgers.edu

Ivan Seskar seskar@winlab.rutgers.edu

## Introduction
This project aims at building a real-time wide band channel sounder using USRPs, which computes the power delay profile of a multi-path channel, and focuses mainly on large scale antenna systems as shown below. This channel sounder is used for computation of  the power delay profile of a multipath channel in a massive multiple antenna system in the ORCA framework (https://www.orca-project.eu/).

![channel_sounding_demo](https://user-images.githubusercontent.com/9439021/27981986-ee9480fa-6364-11e7-8bd5-c1f9374eb964.jpg)

A spread spectrum channel sounder as shown below is implemented.
![channel_sounder_block_diagram](https://user-images.githubusercontent.com/9439021/27981984-e9af8008-6364-11e7-981e-91cf151f054d.jpg)

To enable real-time channel sounding at multiple receive antennas at high bandwidths, the computationally intensive task of correlation has been moved to the FPGA. Also, the correlation power (output of correlation module) obtained is averaged over a given number of data symbols in order to reduce the USRP to host data rate.

The system has been tested using USRP X310s on ORBIT testbed. All the X310s in the testbed are synchronized with an external reference clock. 

## RFNoC Blocks implemented

1) [Spreader](hls-projects/spreader/README.md)
2) [Correlator](hls-projects/correlator/README.md)
3) Averaging Block


## Build and Test instructions

### Setup Environment 
 - Xilinx Vivado 2018.3
 - Modelsim 10.6c
 - UHD UHD 3.14.1.HEAD-0-g0347a6d8
 - Clone this repository 
   git clone -b v3.14 

### Simulate the modules 

cd rfnoc-channelsound
mkdir build && cd build
cmake -DUHD_FPGA_DIR=/root/uhd/fpga-src ../
cd ../rfnoc/testbenches/noc_block_corrmag63avg8k_tb
make vsim 
[This should start the modelsim simulation. To use custom waveform script, break the current simulation and copy .do script 
pwd
# /root/RFNoC-HLS-WINLAB/rfnoc-channelsound/rfnoc/testbenches/noc_block_corrmag63avg8k_tb/modelsim_proj/modelsim_proj.sim/sim_1/behav/modelsim
cp ../../../../../noc_block_corrmag63avg8k_tb_simulate.do .]
Rerun the simulation 
do noc_block_corrmag63avg8k_tb_simulate.do .
run 100 us

cd ../rfnoc/testbenches/noc_block_spreader_tb
make vsim

Build bitstream
Use the commands in uhd/fpga-src/usrp3/tools/scripts/channelsounder_build_x310.yml

Test on USRP



