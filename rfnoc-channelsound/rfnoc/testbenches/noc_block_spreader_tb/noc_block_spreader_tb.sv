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

typedef logic pn_seq_t[$];
typedef logic[31:0] sample_t[$];

module noc_block_spreader_tb();

function pn_seq_t get_pn_seq(int seq_len, int gen_poly, int gen_order, int gen_seed);
  logic [9:0] shift_reg, tmp_reg;
  logic new_bit;
  pn_seq_t seq;
  begin
    shift_reg = gen_seed;
    for(int i = 0; i<seq_len; i++)
    begin
      seq[i] = shift_reg[10-gen_order];
      tmp_reg = shift_reg &  gen_poly;
      new_bit = ^ tmp_reg;
      shift_reg >>= 1;
      shift_reg[9] = new_bit;
      $display ("sequence[%d] - %b", i,seq[i]);
    end
  end
  return seq;
endfunction

function sample_t get_random_samples(int num_samples);
  sample_t sample;
  begin
    for(int i = 0; i<num_samples; i++)
    begin
      sample[i] = $random;
    end
  end
  return sample;
endfunction;

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

  `TEST_BENCH_INIT("noc_block_spreader",`NUM_TEST_CASES,`NS_PER_TICK);
  localparam BUS_CLK_PERIOD = $ceil(1e9/166.67e6);
  localparam CE_CLK_PERIOD  = $ceil(1e9/200e6);
  localparam NUM_CE         = 1;  // Number of Computation Engines / User RFNoC blocks to simulate
  localparam NUM_STREAMS    = 1;  // Number of test bench streams
  `RFNOC_SIM_INIT(NUM_CE, NUM_STREAMS, BUS_CLK_PERIOD, CE_CLK_PERIOD);
  `RFNOC_ADD_BLOCK(noc_block_spreader, 0);

  localparam [9:0] gen_poly = 10'b0000110000;
  localparam [9:0] gen_seed = 10'b0000010000;
  localparam [3:0] gen_order = 4'd6;
  localparam [9:0] seq_len  = 10'd63;
  localparam num_samples = 300;

  localparam [9:0] gen_poly1 = 10'b0001110100;
  localparam [9:0] gen_seed1 = 10'b0000010000;
  localparam [3:0] gen_order1 = 4'd8;
  localparam [9:0] seq_len1  = 10'd255;
  localparam num_samples1 = 272;

  pn_seq_t seq; //
  sample_t sample;//
  cvita_payload_t payload;// 64 bit word i.e., one payload word = 2 samples*/


  wire [19:0] gen_seed_poly = {gen_seed, gen_poly};
  wire [13:0] gen_order_len = {gen_order, seq_len};
  wire [19:0] gen_seed_poly1 = {gen_seed1, gen_poly1};
  wire [13:0] gen_order_len1 = {gen_order1, seq_len1};

  localparam NUM_ITERATIONS  = 10;


  localparam SPP = 256; // Samples per packet

  /********************************************************
  ** Verification
  ********************************************************/
  initial begin : tb_main
    logic [63:0] readback;
    logic [31:0] out_val;
    logic [31:0] expected_word;
    logic last;	  
    string s;

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
    tb_streamer.read_reg(sid_noc_block_spreader, RB_NOC_ID, readback);
    $display("Read spreader NOC ID: %16x", readback);
    `ASSERT_ERROR(readback == noc_block_spreader.NOC_ID, "Incorrect NOC ID");
    `TEST_CASE_DONE(1);

    /********************************************************
    ** Test 3 -- Connect RFNoC blocks
    ********************************************************/
    `TEST_CASE_START("Connect RFNoC blocks");
    `RFNOC_CONNECT(noc_block_tb,noc_block_spreader,SC16,SPP);
    `RFNOC_CONNECT(noc_block_spreader,noc_block_tb,SC16,SPP);
    `TEST_CASE_DONE(1);

    /********************************************************
    ** Test 4 -- Write / readback user registers
    ********************************************************/
    `TEST_CASE_START("Write to setting registers");
    tb_streamer.write_reg(sid_noc_block_spreader, noc_block_spreader.SR_GEN_SEED_POLY, gen_seed_poly);
    tb_streamer.write_reg(sid_noc_block_spreader, noc_block_spreader.SR_GEN_ORDER_LEN, gen_order_len);
    `TEST_CASE_DONE(1);

    /********************************************************
    ** Test 5 -- Send Samples
    ********************************************************/
    `TEST_CASE_START("Send samples");
    fork
    begin
      seq = get_pn_seq(seq_len, gen_poly, gen_order, gen_seed);
      sample = get_random_samples(num_samples);
      payload = get_payload(sample, num_samples); // 64 bit word i.e., one payload word = 2 samples
      tb_streamer.send(payload);
    end
    begin
      for(int n = 0; n < num_samples ; n++) begin
       for(int i = 0; i < seq_len ; i++) begin
        tb_streamer.pull_word({out_val},last);
        if(seq[i] == 1'b0) begin
          //$info("***");
          expected_word[31:16] = (~sample[n][31:16] + 1'b1);
          expected_word[15:0] =  (~sample[n][15:0]  + 1'b1);
        end else begin
          expected_word = sample[n];
        end
         if(expected_word != out_val) begin
          $info("expected: %d, output : %d, i : %d", expected_word, out_val, i);
         end

        `ASSERT_ERROR(expected_word == out_val, "Bad output value!!");
        if(i == seq_len-1) begin
          `ASSERT_ERROR(last == 1'b1, "Detected late tlast!");
        end else begin
          `ASSERT_ERROR(last == 1'b0, "Detected early tlast!");
        end
       end
      end
    end
    join
    `TEST_CASE_DONE(1);

    `TEST_BENCH_DONE;

  end
endmodule
