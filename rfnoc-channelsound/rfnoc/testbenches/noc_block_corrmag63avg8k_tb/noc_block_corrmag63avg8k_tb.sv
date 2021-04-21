/* 
 * Copyright 2019 <+YOU OR YOUR COMPANY+>.
 * 
 * This is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 3, or (at your option)
 * any later version.
 * 
 * This software is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 * 
 * You should have received a copy of the GNU General Public License
 * along with this software; see the file COPYING.  If not, write to
 * the Free Software Foundation, Inc., 51 Franklin Street,
 * Boston, MA 02110-1301, USA.
 */

`timescale 1ns/1ps
`define NS_PER_TICK 1
`define NUM_TEST_CASES 5

`include "sim_exec_report.vh"
`include "sim_clks_rsts.vh"
`include "sim_rfnoc_lib.svh"

typedef logic[31:0] sample_t[$];
typedef logic[7:0] sample_bytes_t[$];

module noc_block_corrmag63avg8k_tb();

function cvita_payload_t get_payload(sample_t sample, int num_samples);
  cvita_payload_t payload;
  begin
    for(int i = 0; i<num_samples/2; i++)
    begin
      payload[i] = {sample[2*i], sample[2*i + 1]};
      if((2*i + 1) == num_samples-2) // when num_samples is odd
      begin
        payload[i+1] = {sample[2*i + 2],32'd0};
      end
    end
  end
  return payload;
endfunction

  `TEST_BENCH_INIT("noc_block_corrmag63avg8k",`NUM_TEST_CASES,`NS_PER_TICK);
  localparam BUS_CLK_PERIOD = $ceil(1e9/166.67e6);
  localparam CE_CLK_PERIOD  = $ceil(1e9/200e6);
  localparam NUM_CE         = 1;  // Number of Computation Engines / User RFNoC blocks to simulate
  localparam NUM_STREAMS    = 1;  // Number of test bench streams
  `RFNOC_SIM_INIT(NUM_CE, NUM_STREAMS, BUS_CLK_PERIOD, CE_CLK_PERIOD);
  `RFNOC_ADD_BLOCK(noc_block_corrmag63avg8k, 0);

  sample_t sample;
  cvita_payload_t payload;
  localparam NUM_SAMPLE_BYTES = 38456; //7680;
  localparam NUM_REPEAT = 800;

  localparam SPP = 63; // Samples per packet

  /********************************************************
  ** Verification
  ********************************************************/
  initial begin : tb_main
    string s;
    logic [31:0] pnseq_params;
    logic [63:0] readback;

    logic [31:0] avg_mag;
    logic last;
    int fid;
    //reg[7:0] file_sample_bytes[NUM_SAMPLE_BYTES];
    sample_bytes_t file_sample_bytes, expected_bytes;
    int num_sample_bytes, num_expected_bytes, pkt_size, recv_size;

    int num_pkts, pkt_cnt;
    logic [31:0] first_sample, last_sample;

    /********************************************************
    ** Test 1 -- Reset
    ********************************************************/
    `TEST_CASE_START("Wait for Reset");
    while (bus_rst) @(posedge bus_clk);
    while (ce_rst) @(posedge ce_clk);
    `TEST_CASE_DONE(~bus_rst & ~ce_rst);

    /********************************************************
    ** Test 2 -- Check for correct NoC IDs
    ********************************************************/
    `TEST_CASE_START("Check NoC ID");
    // Read NOC IDs
    tb_streamer.read_reg(sid_noc_block_corrmag63avg8k, RB_NOC_ID, readback);
    $display("Read corrmag63avg8k NOC ID: %16x", readback);
    `ASSERT_ERROR(readback == noc_block_corrmag63avg8k.NOC_ID, "Incorrect NOC ID");
    `TEST_CASE_DONE(1);

    /********************************************************
    ** Test 3 -- Connect RFNoC blocks
    ********************************************************/
    `TEST_CASE_START("Connect RFNoC blocks");
    `RFNOC_CONNECT(noc_block_tb,noc_block_corrmag63avg8k,SC16,SPP);
    `RFNOC_CONNECT(noc_block_corrmag63avg8k,noc_block_tb,SC16,SPP);
    `TEST_CASE_DONE(1);

    /********************************************************
    ** Test 4 -- Write / readback user registers
    ********************************************************/
    `TEST_CASE_START("Write / readback user registers");
    tb_streamer.write_user_reg(sid_noc_block_corrmag63avg8k, noc_block_corrmag63avg8k.SR_MODE, 31'b0);
    tb_streamer.read_user_reg(sid_noc_block_corrmag63avg8k, 0, readback);
    $sformat(s, "User register 0 incorrect readback! Expected: %0d, Read %0d", 31'b0, readback[31:0]);
    `ASSERT_ERROR(readback[31:0] == 0, s);

    pnseq_params = {4'b0000,4'b0110,12'b000000001000,12'b000000011000}; //pnseq_length = 63
    //pnseq_params = {4'b0000,4'b1000,12'b000000000010,12'b000000111010};
    tb_streamer.write_user_reg(sid_noc_block_corrmag63avg8k, noc_block_corrmag63avg8k.SR_PNSEQ_PARAMS, pnseq_params);
    tb_streamer.read_user_reg(sid_noc_block_corrmag63avg8k, 1, readback);
    $sformat(s, "User register 1 incorrect readback! Expected: %0d, Read %0d", pnseq_params, readback[31:0]);
    `ASSERT_ERROR(readback[31:0] == pnseq_params, s);


    // Write threshold value
    tb_streamer.write_user_reg(sid_noc_block_corrmag63avg8k, noc_block_corrmag63avg8k.SR_THRESHOLD, 8'd5);
    // Avg params
    tb_streamer.write_user_reg(sid_noc_block_corrmag63avg8k, noc_block_corrmag63avg8k.SR_AVG_PARAMS, {14'd0, 8'd63, 16'd128}); 
    // Start the corrmag by writing 1 to the mode register
    tb_streamer.write_user_reg(sid_noc_block_corrmag63avg8k, noc_block_corrmag63avg8k.SR_MODE, 32'd1);
    `TEST_CASE_DONE(1);

    /********************************************************
    ** Test 5 -- Test sequence
    ********************************************************/
    `TEST_CASE_START("Input samples from file");
     fid = $fopen("/root/rfnoc-channelsound/rfnoc/testbenches/noc_block_corrmag63avg8k_tb/perfect_63_32sym.dat", "rb");
     //fid = $fopen("/root/uhd/host/build/examples/spread_63_5M_24_13.dat", "rb");
     $fread(file_sample_bytes, fid);
     $fclose(fid);
     $display("NUM SAMPLE BYTES : %d", file_sample_bytes.size());
     num_sample_bytes = file_sample_bytes.size();

     fork
     begin
       for(int i = 0; i < num_sample_bytes/4; i++) begin
         /*-----------------------------------------------------
         | 31       RE           16|15           IM            0|
         -------------------------------------------------------*/
         sample[i][31:24] = file_sample_bytes[(4*i)+1]; // MSB real
         sample[i][23:16] = file_sample_bytes[(4*i)];   // LSB real
         sample[i][15:8]  = file_sample_bytes[(4*i)+3]; // MSB imag
         sample[i][7:0]   = file_sample_bytes[(4*i)+2]; // LSByte imag
       end

       payload = get_payload(sample, num_sample_bytes/4);
       for(int i = 0; i < NUM_REPEAT; i++) begin
         tb_streamer.send(payload);
         #10us;
       end
     end
     begin
       cvita_payload_t recv_payload;
       cvita_metadata_t recv_md;
       pkt_cnt = 0;
       do begin
         tb_streamer.recv(recv_payload, recv_md);
         pkt_cnt = pkt_cnt+1;
       end while (pkt_cnt < 100);
     end
     join


     `TEST_CASE_DONE(1);


    `TEST_BENCH_DONE;

  end
endmodule
