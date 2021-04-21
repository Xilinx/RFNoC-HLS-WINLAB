module corrmag63avg8k_top #(
  parameter SR_MODE = 0,
  parameter SR_PNSEQ_PARAMS = 1,
  parameter SR_THRESHOLD = 2,
  parameter SR_AVG_PARAMS = 3)
(
  input clk, input rst,
  input set_stb, input [7:0] set_addr, input [31:0] set_data, input [7:0] rb_addr, output [63:0] rb_data, 
  input [31:0] i_tdata, input i_tlast, input i_tvalid, output i_tready, input [127:0] i_tuser,
  output [31:0] o_tdata, output o_tlast, output o_tvalid, input o_tready, output [127:0] o_tuser
);

 ////////////////////////////////////////////////////////////
  //
  // User code
  //
  ////////////////////////////////////////////////////////////
  // NoC Shell registers 0 - 127,
  // User register address space starts at 128
  localparam SR_USER_REG_BASE = 128;
  
  // Control Source Unused
  assign cmdout_tdata  = 64'd0;
  assign cmdout_tlast  = 1'b0;
  assign cmdout_tvalid = 1'b0;
  assign ackin_tready  = 1'b1;

  // Settings registers
  //
  // - The settings register bus is a simple strobed interface.
  // - Transactions include both a write and a readback.
  // - The write occurs when set_stb is asserted.
  //   The settings register with the address matching set_addr will
  //   be loaded with the data on set_data.
  // - Readback occurs when rb_stb is asserted. The read back strobe
  //   must assert at least one clock cycle after set_stb asserts /
  //   rb_stb is ignored if asserted on the same clock cycle of set_stb.
  //   Example valid and invalid timing:
  //              __    __    __    __
  //   clk     __|  |__|  |__|  |__|  |__
  //               _____
  //   set_stb ___|     |________________
  //                     _____
  //   rb_stb  _________|     |__________     (Valid)
  //                           _____
  //   rb_stb  _______________|     |____     (Valid)
  //           __________________________
  //   rb_stb                                 (Valid if readback data is a constant)
  //               _____
  //   rb_stb  ___|     |________________     (Invalid / ignored, same cycle as set_stb)
  //


  //localparam [7:0] SR_MODE = SR_USER_REG_BASE; // 128
  //localparam [7:0] SR_PNSEQ_PARAM = SR_USER_REG_BASE + 1; // 129
  //localparam [7:0] SR_THRESHOLD = SR_USER_REG_BASE + 2 // 130


  // mode_reg = {mode,stop,start}
  wire [2:0] mode_reg;
  setting_reg #(
    .my_addr(SR_MODE), .awidth(8), .width(3))
  sr_mode (
    .clk(clk), .rst(rst),
    .strobe(set_stb), .addr(set_addr), .in(set_data), .out(mode_reg), .changed());

  wire [31:0] pnseq_params;
  setting_reg #(
    .my_addr(SR_PNSEQ_PARAMS), .awidth(8), .width(32))
  sr_pnseq_params (
    .clk(clk), .rst(rst),
    .strobe(set_stb), .addr(set_addr), .in(set_data), .out(pnseq_params), .changed());

  wire [31:0] threshold; // REVISIT threshold width
  setting_reg #(
    .my_addr(SR_THRESHOLD), .awidth(8), .width(32))
  sr_threshold (
    .clk(clk), .rst(rst),
    .strobe(set_stb), .addr(set_addr), .in(set_data), .out(threshold), .changed());

  wire [31:0] avg_params; 
  setting_reg #(
    .my_addr(SR_AVG_PARAMS), .awidth(8), .width(32))
  sr_avg_params (
    .clk(clk), .rst(rst),
    .strobe(set_stb), .addr(set_addr), .in(set_data), .out(avg_params), .changed());


  // Readback registers
  // rb_stb set to 1'b1 on NoC Shell
  reg [63:0] int_rb_data;
  always @(posedge clk) begin
    case(rb_addr)
      8'd0 : int_rb_data <= {29'd0, mode_reg};
      8'd1 : int_rb_data <= {pnseq_params};
      8'd2 : int_rb_data <= {threshold};
      8'd3 : int_rb_data <= {avg_params};
      default : int_rb_data <= 64'h0BADC0DE0BADC0DE;
    endcase
  end

  assign rb_data = int_rb_data;

  wire signed [31:0] corr_tdata, sample_tdata;
  wire corr_tvalid, sample_tvalid;
  wire corr_tlast, sample_tlast;
  wire corr_start, corr_stop;
  wire [8:0] pnseq_length;

/*////////////////////////////////////////////////////////////////////////
// pnseq_correaltion, latency = 11
//////////////////////////////////////////////////////////////////////////*/
 
  assign corr_start = mode_reg[0];
  assign corr_stop = mode_reg[1];
  pnseq_correlator63 pnseq_correlator_inst(
    .clk(clk), .rst(rst),
    .i_tdata(i_tdata), .i_tlast(i_tlast), .i_tvalid(i_tvalid), .i_tready(i_tready),
    .o_corr_tdata(corr_tdata), .o_corr_tvalid(corr_tvalid), .o_corr_tlast(corr_tlast),.o_corr_tready(1'b1),
    .o_tdata(sample_tdata), .o_tlast(sample_tlast), .o_tvalid(sample_tvalid), .o_tready(1'b1),
    .i_start(corr_start),
    .i_pnseq_poly(pnseq_params[8:0]), .i_pnseq_seed(pnseq_params[20:12]), .i_pnseq_order(pnseq_params[27:24]), .o_pnseq_length(pnseq_length)
  );

/*////////////////////////////////////////////////////////////////////////
// Detect presence of signal
// when mag(correlation) > recv_energy*threshold
// recv_energy*threshold computation, latency = 9
//////////////////////////////////////////////////////////////////////////*/

////////// recv_energy computation, latency = 5 /////////////////////

  wire [31:0] magsq0_tdata, magsqN_tdata;
  wire magsq0_tvalid, magsqN_tvalid;
  reg [39:0] recv_energy;
  reg recv_energy_valid[5:0];
  reg [31:0] data_in_reg[7:0];
  reg valid_in_reg[7:0];
  integer i;

// shift the incoming data till correlation and sample 0 (old sample) arrive
  always @(posedge clk) begin
    if(i_tvalid) begin
      data_in_reg[0] <= i_tdata;      
      for(i = 1; i < 8; i = i+1) begin
        data_in_reg[i] <= data_in_reg[i-1];
      end
    end
    valid_in_reg[0] <= i_tvalid;
    for(i = 1; i < 8; i = i+1) begin
      valid_in_reg[i] <= valid_in_reg[i-1];
    end
  end

//latency = 4
//magsq0_tdata, magsqN_tdata : unsigned 32_28
  complex_to_magsq #(.WIDTH(16))  new_sample_energy(
    .clk(clk), .reset(rst), .clear(rst),
    .i_tdata(data_in_reg[7]), .i_tlast(1'b0), .i_tvalid(valid_in_reg[7]), .i_tready(),
    .o_tdata(magsq0_tdata), .o_tlast(), .o_tvalid(magsq0_tvalid), .o_tready(1'b1));

  complex_to_magsq #(.WIDTH(16))  old_sample_energy(
    .clk(clk), .reset(rst), .clear(rst),
    .i_tdata(sample_tdata), .i_tlast(1'b0), .i_tvalid(sample_tvalid), .i_tready(),
    .o_tdata(magsqN_tdata), .o_tlast(), .o_tvalid(magsqN_tvalid), .o_tready(1'b1));

//latency +=1 
//recv_energy : unsigned 40_28
  always @(posedge clk)
    if(rst) begin
      recv_energy <= 0;
      recv_energy_valid[0] <= 0;
    end else begin
      recv_energy_valid[0] <= magsq0_tvalid;
      if(magsqN_tvalid) begin
        recv_energy <= recv_energy + {8'b0, magsq0_tdata} - {8'b0, magsqN_tdata};         
      end 
    end

//////////// recv_energy * threshold, latency = 4/////////////

//shift-add operations for multiplication 

  reg [31:0] recv_energy_shifted[7:0];
  reg [31:0] recv_energy_sum1[3:0];
  reg [31:0] recv_energy_sum2[1:0];
  reg [31:0] recv_energy_sum;

  always @(posedge clk)
    if(rst) begin
      for(i = 0; i < 8; i = i+1)
        recv_energy_shifted[i] <= 0;
      for(i = 0; i < 4; i =i+1)
        recv_energy_sum1[i] <= 0;
      for(i = 0; i < 2; i =i+1)
        recv_energy_sum2[i] <= 0;
      recv_energy_sum <= 0;
    end
    else begin
      for(i = 1; i < 4; i = i+1) begin
        recv_energy_valid[i] <= recv_energy_valid[i-1];
      end

      // 8 left shifted recv_energy regs for each bit of threshold
      for(i=0; i<8; i=i+1) begin
        if(recv_energy_valid[0] & threshold[i])
          recv_energy_shifted[i] <= recv_energy[39:16] << i;  // latency += 1 // discard 16 LSBs of recv_energy: unsigned 24_12
        else
          recv_energy_shifted[i] <= 0;
      end

      // binary adder tree to add the shifted values
      if(recv_energy_valid[1]) // latency += 1
        for(i=0; i<4; i=i+1) begin
          recv_energy_sum1[i] <= recv_energy_shifted[(2*i)] + recv_energy_shifted[(2*i)+1];
        end

      if(recv_energy_valid[2]) begin // latency += 1
        recv_energy_sum2[0] <= recv_energy_sum1[0] + recv_energy_sum1[1];
        recv_energy_sum2[1] <= recv_energy_sum1[2]+ recv_energy_sum1[3];
      end

      if(recv_energy_valid[3]) begin // latency += 1
        recv_energy_sum <= recv_energy_sum2[0] + recv_energy_sum2[1]; // recv_energy_sum : unsigned 32_12
      end

    end

///////////// mag(correlation), latency = 4 //////////////////////////////
wire [31:0] corrmag_tdata;
reg [31:0] corrmag_reg[6:0];
wire corrmag_tvalid;
reg corrmag_valid_reg[6:0];
wire corrmag_tlast;
reg corrmag_tlast_reg[6:0];

// latency 4 
// corrmag_tdata: unsigned 32_12
  complex_to_magsq #(.WIDTH(16))  corr_mag(
    .clk(clk), .reset(rst), .clear(rst),
    .i_tdata(corr_tdata), .i_tlast(corr_tlast), .i_tvalid(corr_tvalid), .i_tready(),
    .o_tdata(corrmag_tdata), .o_tlast(corrmag_tlast), .o_tvalid(corrmag_tvalid), .o_tready(1'b1));


// delay mag(correlation) by 5 to match the 9 clock cycle latency of recv_energy*threshold
  always @(posedge clk) begin
    corrmag_reg[0] <= corrmag_tdata;
    for(i = 1; i < 7; i = i+1) begin
      corrmag_reg[i] <= corrmag_reg[i-1];
    end
    corrmag_valid_reg[0] <= corrmag_tvalid;
    for(i = 1; i < 7; i = i+1) begin
      corrmag_valid_reg[i] <= corrmag_valid_reg[i-1];
    end
    corrmag_tlast_reg[0] <= corrmag_tlast;
    for(i = 1; i < 7; i = i+1) begin
      corrmag_tlast_reg[i] <= corrmag_tlast_reg[i-1];
    end
  end

///////// Finite state machine ///////////////////////////////////////////

reg [2:0] correlator_top_state;
localparam ST_IDLE = 0;
localparam ST_START = 1;
localparam ST_WAIT_PROC = 2;
localparam ST_PEAK_DETECT = 3;
localparam ST_SEND_CORR = 4;

reg [8:0] samp_in_count;
reg [5:0] wait_count;
reg send_corr_en;

always @(posedge clk)
  if(rst) begin
    correlator_top_state <= ST_IDLE;
    send_corr_en <= 1'b0;
    samp_in_count <= 0;
    wait_count <= 0;
  end else begin
    case(correlator_top_state)
      ST_IDLE: 
        if(corr_start) begin
          correlator_top_state <= ST_START;
        end
      ST_START: 
        // wait for pnseq_length samples to come in, so that corr and recv_energy stabilize
        if(i_tvalid) begin
          if(samp_in_count == pnseq_length-1) begin
            samp_in_count <= 0;
            correlator_top_state <= ST_WAIT_PROC;
          end else begin
            samp_in_count <= samp_in_count + 1;
            correlator_top_state <= ST_START;
          end
        end
      ST_WAIT_PROC:
        // wait for 20 clk cycles for corr and recv_energy processing
        if(wait_count == 18) begin
          wait_count <= 0;
          correlator_top_state <= ST_PEAK_DETECT;
        end else begin
          wait_count <= wait_count + 1;
          correlator_top_state <= ST_WAIT_PROC;
        end
      ST_PEAK_DETECT: 
        if(corrmag_reg[4] > recv_energy_sum) begin
          correlator_top_state <= ST_SEND_CORR;
        end else begin
          correlator_top_state <= ST_PEAK_DETECT;
        end
      ST_SEND_CORR: 
        if(corr_stop) begin
          send_corr_en <= 1'b0;
          correlator_top_state <= ST_IDLE; 
        end else begin
          send_corr_en <= 1'b1;
          correlator_top_state <= ST_SEND_CORR;
        end        
    endcase
  end
  
/*reg [31:0] corr_reg[11:0];
reg corr_valid_reg[11:0];

always @(posedge clk)
  if(rst) begin
    for(i = 0; i < 12; i=i+1) begin
      corr_valid_reg[i] <= 0;
    end
  end else begin
    corr_reg[0] <= corr_tdata;
    for(i = 1 ; i < 12 ; i=i+1) begin
      corr_reg[i] <= corr_reg[i-1];
    end
    corr_valid_reg[0] <= corr_tvalid;
    for(i = 1; i < 12; i=i+1) begin
      corr_valid_reg[i] <= corr_valid_reg[i-1];
    end
  end
*/

(* dont_touch="true",mark_debug="true"*)wire [31:0] avg_in_tdata;
(* dont_touch="true",mark_debug="true"*)wire avg_in_tvalid;
(* dont_touch="true",mark_debug="true"*)wire avg_in_tlast;
 
assign avg_in_tdata = corrmag_reg[6];  // 2 clk cycle delay in FSM for peak detection 
assign avg_in_tvalid = corrmag_valid_reg[6] & send_corr_en;
assign avg_in_tlast = corrmag_tlast_reg[6];


pkt_avg_v2 #(
  .MAX_PKT_SIZE_LOG2(8),
  .MAX_AVG_SIZE_LOG2(14),
  .WIDTH(32)
)inst_corrmag_avg(
  .clk(clk), .reset(corr_stop | rst),
  .i_tdata(avg_in_tdata[31:0]), .i_tlast(avg_in_tlast), .i_tvalid(avg_in_tvalid), .i_tready(),
  .o_tdata(o_tdata), .o_tlast(o_tlast), .o_tvalid(o_tvalid), .o_tready(o_tready),
  .i_pkt_size(avg_params[23:16]), .i_avg_size(avg_params[13:0])
);

endmodule
