// Copyright (c) 2017 - WINLAB, Rutgers University, USA
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.

// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.  IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.

//Team WINLAB
//RFNoC HLS Challenge
/*noc_block_correlator_tb.sv - used noc_block_skeleton.sv as a template.
Test bench for the correlator NOC block. Input for the correlator comes from the spreader NOC block
*/
`timescale 1ns/1ps
`define SIM_TIMEOUT_US 50000
`define NS_PER_TICK 1
`define NUM_TEST_CASES 5 
`include "sim_exec_report.vh"
`include "sim_rfnoc_lib.svh"


typedef logic pn_seq_t[$];
typedef logic[31:0] sample_t[$];

module noc_block_correlator_tb();

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


  `TEST_BENCH_INIT("noc_block_correlator_tb",`NUM_TEST_CASES,`NS_PER_TICK);
  localparam BUS_CLK_PERIOD = $ceil(1e9/166.67e6);
  localparam CE_CLK_PERIOD  = $ceil(1e9/200e6);
  localparam NUM_CE         = 2;
  localparam NUM_STREAMS    = 1;
  `RFNOC_SIM_INIT(NUM_CE, NUM_STREAMS, BUS_CLK_PERIOD, CE_CLK_PERIOD);
  // Instantiate spreader and correlator RFNoC blocks
  `RFNOC_ADD_BLOCK(noc_block_spec_spreader, 0 /* xbar port 0 */);
  `RFNOC_ADD_BLOCK(noc_block_correlator, 1 /* xbar port 1 */);

  localparam [9:0] gen_poly = 10'b0000100010;
  localparam [9:0] gen_seed = 10'b0000010000;
  localparam [3:0] gen_order = 4'd9;
  localparam [9:0] seq_len  = 10'd511;
  localparam num_samples = 272;

  localparam [9:0] gen_poly1 = 10'b0001110100;
  localparam [9:0] gen_seed1 = 10'b0000010000;
  localparam [3:0] gen_order1 = 4'd8;
  localparam [9:0] seq_len1  = 10'd255;
  localparam num_samples1 = 272;


  pn_seq_t seq; 
  sample_t sample;
  cvita_payload_t payload;// 64 bit word i.e., one payload word = 2 samples*/
  

  wire [19:0] gen_seed_poly = {gen_seed, gen_poly};
  wire [13:0] gen_order_len = {gen_order, seq_len};
  wire [19:0] gen_seed_poly1 = {gen_seed1, gen_poly1};
  wire [13:0] gen_order_len1 = {gen_order1, seq_len1};

  localparam NUM_ITERATIONS  = 10;

  /********************************************************
  ** Verification
  ********************************************************/
  initial begin : tb_main
    logic [63:0] readback;
    logic [31:0] out_val;
    logic [31:0] expected_word;
    logic last;

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
    tb_streamer.read_reg(sid_noc_block_correlator, RB_NOC_ID, readback);
    $display("Read CORRELATOR NOC ID: %16x", readback);
    `ASSERT_ERROR(readback == noc_block_correlator.NOC_ID, "Incorrect NOC ID");
    `TEST_CASE_DONE(1);

    /********************************************************
    ** Test 3 -- Connect RFNoC blocks
    ********************************************************/
    `TEST_CASE_START("Connect RFNoC blocks");
    // Test bench -> Spreader -> Correlator -> Test bench
    `RFNOC_CONNECT(noc_block_tb /* From */, noc_block_spec_spreader /* To */, SC16 /* Type */, 256 /* Samples per packet */);
    `RFNOC_CONNECT(noc_block_spec_spreader, noc_block_correlator, SC16, 256);
    `RFNOC_CONNECT(noc_block_correlator,noc_block_tb,SC16,64);
    `TEST_CASE_DONE(1);

    /*******************************************************************
    ** Test 4 -- Set up the module by writing to the setting registers 
    ********************************************************************/
    `TEST_CASE_START("Write to setting registers");
    tb_streamer.write_reg(sid_noc_block_correlator, noc_block_correlator.SR_GEN_SEED_POLY, gen_seed_poly);
    tb_streamer.write_reg(sid_noc_block_correlator, noc_block_correlator.SR_GEN_ORDER_LEN, gen_order_len);
    tb_streamer.write_reg(sid_noc_block_correlator, noc_block_correlator.SR_BLOCK_START, 1);
    tb_streamer.write_reg(sid_noc_block_correlator, noc_block_correlator.SR_BLOCK_START, 0);

    tb_streamer.write_reg(sid_noc_block_spec_spreader, noc_block_spec_spreader.SR_GEN_SEED_POLY, gen_seed_poly);
    tb_streamer.write_reg(sid_noc_block_spec_spreader, noc_block_spec_spreader.SR_GEN_ORDER_LEN, gen_order_len);
    `TEST_CASE_DONE(1);

    /********************************************************
    ** Test 5 -- Send Samples 
    ********************************************************/
    `TEST_CASE_START("Send samples");
    fork
    begin
      sample = get_random_samples(num_samples);
      payload = get_payload(sample, num_samples); // 64 bit word i.e., one payload word = 2 samples
      tb_streamer.send(payload);
    end
    begin
      for(int n = 0; n < num_samples ; n++) begin
       for(int i = 0; i < seq_len ; i++) begin
        tb_streamer.pull_word({out_val},last);
       end
      end
    end
    join
    `TEST_CASE_DONE(1);

    `TEST_BENCH_DONE;
  end
endmodule
