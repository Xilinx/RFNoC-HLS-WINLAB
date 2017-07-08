# RFNoC-HLS-WINLAB

Bhargav Gokalgandhi bvg8@scarletmail.rutgers.edu

Prasanthi Maddala prasanti@winlab.rutgers.edu

Ivan Seskar seskar@winlab.rutgers.edu

## Introduction
This project aims at building a real-time wide band channel sounder using USRPs, which computes the power delay profile of a multi-path channel, and focuses mainly on large scale antenna systems as shown below.

![channel_sounding_demo](https://user-images.githubusercontent.com/9439021/27981986-ee9480fa-6364-11e7-8bd5-c1f9374eb964.jpg)

A spread spectrum channel sounder as shown below is implemented.
![channel_sounder_block_diagram](https://user-images.githubusercontent.com/9439021/27981984-e9af8008-6364-11e7-981e-91cf151f054d.jpg)

To enable real-time channel sounding at multiple receive antennas at high bandwidths, the computationally intensive task of correlation has been moved to the FPGA. Also, the correlation power (output of correlation module) obtained is averaged over a given number of data symbols in order to reduce the USRP to host data rate.

The system has been tested using USRP X310s on ORBIT testbed. All the X310s in the testbed are synchronized with an external reference clock. 

## RFNoC Blocks implemented

1) [Spreader](hls-projects/spreader/README.md)
2) [Correlator](hls-projects/correlator/README.md)
3) Averaging Block

## Steps to build Channel sounder

1) Generate HDL using Vivado HLS
   Go to each of the 4 HLS projects (@hls-projects) and run script.tcl - vivado_hls script.tcl
   Generated verilog files can be found @solution1/syn/verilog of each folder.
   NOTE : while generating correlator uncomment either COR_SIZE_256 or COR_SIZE_512 to select a size 256 or size 512 correlator
   
2) Move HDL files 
   Move all the contents of fpga-src folder to your local RFNoC installation folder uhd/fpga-src/usrp3/lib/rfnoc/
   Move all the HLS generated verilog files (from all the 4 projects) to uhd/fpga-src/usrp3/lib/rfnoc/
   
3) Test NoC Blocks
   In uhd/fpga-src/usrp3/lib/rfnoc/, go to each test bench folder (noc_block_spec_spreader_tb) and run make vsim to run the test bench using Modelsim or run make xsim to use Vivado simulator.
   
4) Build Channel sounder Tx
   In uhd/fpga-src/usrp3/tools/scripts/ run
   ./uhd_image_builder.py duc spec_spreader -m 4 --fill-with-fifos -d x310 -t X310_RFNOC_HG
   
5) Build Channel sounder Rx
   To use 1 Rx channel in X310 - In uhd/fpga-src/usrp3/tools/scripts/ run
   ./uhd_image_builder.py ddc correlator cir_avg -m 4 --fill-with-fifos -d x310 -t X310_RFNOC_HG
   
   To use 2 Rx channels in X310 - In uhd/fpga-src/usrp3/tools/scripts/ run
   ./uhd_image_builder.py ddc ddc correlator correlator cir_avg cir_avg -m 7 --fill-with-fifos -d x310 -t X310_RFNOC_HG

## Run the Channel sounder
Host side application files for the transmit and receive hosts can be found at host/examples. These files and how to run them will be explained in detail in the demo video which will be posted soon.
