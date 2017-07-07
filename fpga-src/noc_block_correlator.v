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
/*noc_block_correlator.v - used noc_block_skeleton.v as a template to wrap
 Vivado HLS generated modules, correlator.v and pn_seq_gen_lfsr.v into a noc_block.
*/

module noc_block_correlator #(
  parameter NOC_ID = 64'hFFFF_C100_0000_0000,
  parameter STR_SINK_FIFOSIZE = 11)
(
  input bus_clk, input bus_rst,
  input ce_clk, input ce_rst,
  input  [63:0] i_tdata, input  i_tlast, input  i_tvalid, output i_tready,
  output [63:0] o_tdata, output o_tlast, output o_tvalid, input  o_tready,
  output [63:0] debug
);

  ////////////////////////////////////////////////////////////
  //
  // RFNoC Shell
  //
  ////////////////////////////////////////////////////////////
  wire [31:0] set_data;
  wire [7:0]  set_addr;
  wire        set_stb;
  reg  [63:0] rb_data;
  wire [7:0]  rb_addr;

  wire [63:0] cmdout_tdata, ackin_tdata;
  wire        cmdout_tlast, cmdout_tvalid, cmdout_tready, ackin_tlast, ackin_tvalid, ackin_tready;

  wire [63:0] str_sink_tdata, str_src_tdata;
  wire        str_sink_tlast, str_sink_tvalid, str_sink_tready, str_src_tlast, str_src_tvalid, str_src_tready;

  wire        clear_tx_seqnum;
  wire [15:0] next_dst_sid;

  noc_shell #(
    .NOC_ID(NOC_ID),
    .STR_SINK_FIFOSIZE(STR_SINK_FIFOSIZE))
  noc_shell (
    .bus_clk(bus_clk), .bus_rst(bus_rst),
    .i_tdata(i_tdata), .i_tlast(i_tlast), .i_tvalid(i_tvalid), .i_tready(i_tready),
    .o_tdata(o_tdata), .o_tlast(o_tlast), .o_tvalid(o_tvalid), .o_tready(o_tready),
    // Computer Engine Clock Domain
    .clk(ce_clk), .reset(ce_rst),
    // Control Sink
    .set_data(set_data), .set_addr(set_addr), .set_stb(set_stb), .set_time(),
    .rb_stb(1'b1), .rb_data(rb_data), .rb_addr(rb_addr),
    // Control Source
    .cmdout_tdata(cmdout_tdata), .cmdout_tlast(cmdout_tlast), .cmdout_tvalid(cmdout_tvalid), .cmdout_tready(cmdout_tready),
    .ackin_tdata(ackin_tdata), .ackin_tlast(ackin_tlast), .ackin_tvalid(ackin_tvalid), .ackin_tready(ackin_tready),
    // Stream Sink
    .str_sink_tdata(str_sink_tdata), .str_sink_tlast(str_sink_tlast), .str_sink_tvalid(str_sink_tvalid), .str_sink_tready(str_sink_tready),
    // Stream Source
    .str_src_tdata(str_src_tdata), .str_src_tlast(str_src_tlast), .str_src_tvalid(str_src_tvalid), .str_src_tready(str_src_tready),
    // Misc
    .vita_time(64'd0), .clear_tx_seqnum(clear_tx_seqnum),
    .src_sid(), .next_dst_sid(next_dst_sid), .resp_in_dst_sid(), .resp_out_dst_sid(),
    .debug(debug));

  ////////////////////////////////////////////////////////////
  //
  // AXI Wrapper
  // Convert RFNoC Shell interface into AXI stream interface
  //
  ////////////////////////////////////////////////////////////
  localparam NUM_AXI_CONFIG_BUS = 1;
  
  wire [31:0] m_axis_data_tdata;
  wire        m_axis_data_tlast;
  wire        m_axis_data_tvalid;
  wire        m_axis_data_tready;
  
  wire [31:0] s_axis_data_tdata;
  wire        s_axis_data_tlast;
  wire        s_axis_data_tvalid;
  wire        s_axis_data_tready;
  
  wire [31:0] m_axis_config_tdata;
  wire        m_axis_config_tvalid;
  wire        m_axis_config_tready;
  
  localparam AXI_WRAPPER_BASE    = 128;
  localparam SR_AXI_CONFIG_BASE  = AXI_WRAPPER_BASE + 1;

  axi_wrapper #(
    .SIMPLE_MODE(1),
    .SR_AXI_CONFIG_BASE(SR_AXI_CONFIG_BASE),
    .NUM_AXI_CONFIG_BUS(NUM_AXI_CONFIG_BUS))
  inst_axi_wrapper (
    .clk(ce_clk), .reset(ce_rst),
    .clear_tx_seqnum(clear_tx_seqnum),
    .next_dst(next_dst_sid),
    .set_stb(set_stb), .set_addr(set_addr), .set_data(set_data),
    .i_tdata(str_sink_tdata), .i_tlast(str_sink_tlast), .i_tvalid(str_sink_tvalid), .i_tready(str_sink_tready),
    .o_tdata(str_src_tdata), .o_tlast(str_src_tlast), .o_tvalid(str_src_tvalid), .o_tready(str_src_tready),
    .m_axis_data_tdata(m_axis_data_tdata),
    .m_axis_data_tlast(m_axis_data_tlast),
    .m_axis_data_tvalid(m_axis_data_tvalid),
    .m_axis_data_tready(m_axis_data_tready),
    .m_axis_data_tuser(),
    .s_axis_data_tdata(s_axis_data_tdata),
    .s_axis_data_tlast(s_axis_data_tlast),
    .s_axis_data_tvalid(s_axis_data_tvalid),
    .s_axis_data_tready(s_axis_data_tready),
    .s_axis_data_tuser(),
    .m_axis_config_tdata(m_axis_config_tdata),
    .m_axis_config_tlast(),
    .m_axis_config_tvalid(m_axis_config_tvalid),
    .m_axis_config_tready(m_axis_config_tready),
    .m_axis_pkt_len_tdata(),
    .m_axis_pkt_len_tvalid(),
    .m_axis_pkt_len_tready());
  
  ////////////////////////////////////////////////////////////
  //
  // User code
  //
  ////////////////////////////////////////////////////////////
  
  // Control Source Unused
  assign cmdout_tdata  = 64'd0;
  assign cmdout_tlast  = 1'b0;
  assign cmdout_tvalid = 1'b0;
  assign ackin_tready  = 1'b1;

  localparam [7:0] SR_BLOCK_RESET     = 131;
  localparam [7:0] SR_BLOCK_START     = 132;
  localparam [7:0] SR_GEN_SEED_POLY   = 133;
  localparam [7:0] SR_GEN_ORDER_LEN   = 134;

  wire block_reset;
  wire block_start;
  wire [19:0] pnseq_gen_seed_poly;
  wire [13:0]  pnseq_gen_order_len;
  setting_reg #(
    .my_addr(SR_BLOCK_RESET), .awidth(8), .width(1))
  sr_block_reset (
    .clk(ce_clk), .rst(ce_rst),
    .strobe(set_stb), .addr(set_addr), .in(set_data), .out(block_reset), .changed());

  setting_reg #(
    .my_addr(SR_BLOCK_START), .awidth(8), .width(1))
  sr_block_start (
    .clk(ce_clk), .rst(ce_rst),
    .strobe(set_stb), .addr(set_addr), .in(set_data), .out(block_start), .changed());  // block start signal


  setting_reg #(
    .my_addr(SR_GEN_SEED_POLY), .awidth(8), .width(20))
  sr_gen_poly (
    .clk(ce_clk), .rst(ce_rst),
    .strobe(set_stb), .addr(set_addr), .in(set_data), .out(pnseq_gen_seed_poly), .changed());// [19:10] - seed, [9:0] - generator polynomial

  setting_reg #(
    .my_addr(SR_GEN_ORDER_LEN), .awidth(8), .width(14))
  sr_gen_seed(
    .clk(ce_clk), .rst(ce_rst),
    .strobe(set_stb), .addr(set_addr), .in(set_data), .out(pnseq_gen_order_len), .changed());// [13:10] - polynomial order, [9:0] - pn sequence length

  wire pnseq, pnseq_req, pnseq_load;
  wire [9:0] pnseq_gen_seed  = pnseq_gen_seed_poly[19:10];
  wire [9:0] pnseq_gen_poly  = pnseq_gen_seed_poly[9:0];
  wire [3:0] pnseq_gen_order = pnseq_gen_order_len[13:10];
  wire [9:0] pnseq_len       = pnseq_gen_order_len[9:0];

  reg block_start_reg;
  wire block_start_pulse;
  // start pulse for the correlator is generated from the user start signal, when it changes from 1 to 0.
  always @(posedge ce_clk) begin
      if (ce_rst) begin
       block_start_reg <= 1'b0;       
      end else begin
       block_start_reg <= block_start;
      end
  end

  assign block_start_pulse = block_start_reg && (! block_start);

  // pn_seq_gen_lfsr module
  pn_seq_gen_lfsr inst_pn_seq_gen_lfsr(
    .ap_clk(ce_clk), .ap_rst(ce_rst |block_reset),
    .load_V(block_start), // start signal is used as load input 
    .poly_V(pnseq_gen_poly),
    .seed_V(pnseq_gen_seed),
    .order_V(pnseq_gen_order),
    .pn_req_V(pnseq_req),
    .ap_return(pnseq));

  // correlator module
  correlator inst_correlator(
    .ap_clk(ce_clk), .ap_rst_n(~(ce_rst | block_reset)), 
    .i_data_TDATA(m_axis_data_tdata), // SC16
    .i_data_TVALID(m_axis_data_tvalid),
    .i_data_TREADY(m_axis_data_tready),
    .i_data_TLAST(m_axis_data_tlast),
    .o_data_TDATA(s_axis_data_tdata), // 32 bit integer 
    .o_data_TVALID(s_axis_data_tvalid),
    .o_data_TREADY(s_axis_data_tready),
    .o_data_TLAST(s_axis_data_tlast),
    .pnseq_in_V_V(pnseq),
    .pnseq_in_V_V_ap_ack(pnseq_req),
    .pnseq_in_V_V_ap_vld(1'b1),
    .pnseq_len_V(pnseq_len),
    .start_V(block_start_pulse));


  // Readback registers
  always @*
    case(rb_addr)
      8'd0    : rb_data <= {63'd0, block_reset};
      8'd1    : rb_data <= {63'd0, block_start};
      8'd2    : rb_data <= {44'd0, pnseq_gen_seed_poly};
      8'd3    : rb_data <= {50'd0, pnseq_gen_order_len};
      default : rb_data <= 64'h0BADC0DE0BADC0DE;
  endcase

endmodule
