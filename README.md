# RFNoC-HLS-WINLAB



Steps to build Channel sounder

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
