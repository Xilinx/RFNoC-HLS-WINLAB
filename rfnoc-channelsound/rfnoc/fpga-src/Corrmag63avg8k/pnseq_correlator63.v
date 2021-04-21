/* pnseq_correlator
   output : complex correlation
            delayed IQ samples
   Let the input be r
   correlation and output IQ samples are given as follows:
   correlation at time n : corr(n) = sum(i=n-(pnseq_length-1) to n) r(i)*pnseq(n)
   output IQ sample at n : r(n-62)

   Latency : 11 clock cycles

   Format : input          {I[15:0],Q[15:0]} // signed 16_14
            output samples {I[15:0],Q[15:0]} // signed 16_14
                   corr    {I[15:0],Q[15:0]} // signed 16_6
 
*/
module pnseq_correlator63 
(
  input clk, input rst,
  input [31:0] i_tdata, input i_tvalid, input i_tlast, output i_tready,
  output [31:0] o_corr_tdata, output o_corr_tvalid, output o_corr_tlast, input o_corr_tready,
  output [31:0] o_tdata, output o_tvalid, output o_tlast, input o_tready,
  input i_start,
  input [8:0] i_pnseq_poly, input [8:0] i_pnseq_seed, input [3:0] i_pnseq_order, output [8:0] o_pnseq_length
);


reg signed [15:0] reg_i_data[72:0];
reg signed [15:0] reg_q_data[72:0];

reg signed [15:0] mux_i_data[63:0];
reg signed [15:0] mux_q_data[63:0];

reg signed [16:0] adder1_i[31:0];
reg signed [16:0] adder1_q[31:0];

reg signed [17:0] adder2_i[15:0];
reg signed [17:0] adder2_q[15:0];

reg signed [18:0] adder3_i[7:0];
reg signed [18:0] adder3_q[7:0];

reg signed [19:0] adder4_i[3:0];
reg signed [19:0] adder4_q[3:0];

reg signed [20:0] adder5_i[1:0];
reg signed [20:0] adder5_q[1:0];

//reg signed [21:0] adder6_i[3:0];
//reg signed [21:0] adder6_q[3:0];

//reg signed [22:0] adder7_i[1:0];
//reg signed [22:0] adder7_q[1:0];

reg signed [23:0] final_sum_i; // keeping 24 bits just as used for correlator 256
reg signed [23:0] final_sum_q;

reg signed [23:0] final_sum_i_reg1;
reg signed [23:0] final_sum_q_reg1;

reg signed [23:0] final_sum_i_reg2;
reg signed [23:0] final_sum_q_reg2;

reg [63:0]  pn_seq;

reg lfsr_load, lfsr_en, corr_en;
reg [1:0] correlator_state;
localparam ST_IDLE = 0;
localparam ST_PNSEQ_LOAD = 1;
localparam ST_CORR = 2;

reg [8:0] pnseq_cnt;

wire pnseq;
reg valid[10:0];
reg last[10:0]; 

reg [3:0] pnseq_order;
reg [8:0] pnseq_length;

reg [31:0] corr_tdata, tdata;
reg corr_tvalid, tvalid;

//for debug purposes
(* dont_touch="true",mark_debug="true"*)wire [15:0] in_data_i;
(* dont_touch="true",mark_debug="true"*)wire [15:0] in_data_q;
(* dont_touch="true",mark_debug="true"*)wire corr_in_valid;

assign in_data_i = i_tdata[15:0];
assign in_data_q = i_tdata[31:16];

gen_lfsr #(.WIDTH(9))
lfsr_inst(.clk(clk), .rst(rst),
         .load(lfsr_load), .en(lfsr_en),
         .i_pnseq_poly(i_pnseq_poly), .i_pnseq_seed(i_pnseq_seed), .i_pnseq_order(i_pnseq_order),
         .pnseq(pnseq)
        );

always @(posedge clk)
  if(rst)
    pnseq_length <= 0;
  else if(i_start) begin
    case(i_pnseq_order)
      3: pnseq_length <= 7;
      4: pnseq_length <= 15;
      5: pnseq_length <= 31;
      6: pnseq_length <= 63;
      7: pnseq_length <= 127;
      8: pnseq_length <= 255;
    endcase
  end

assign o_pnseq_length = pnseq_length;

always @(posedge clk)
  if(rst) begin
     correlator_state <= ST_IDLE;
     lfsr_load <= 1'b0;
     lfsr_en <= 1'b0;
     corr_en <= 1'b0;
     pnseq_order <= 0;
     pnseq_cnt <= 0;
  end else begin
     lfsr_load <= 1'b0;
     lfsr_en <= 1'b0;
     corr_en <= 1'b0;
     case(correlator_state)
       ST_IDLE:
         if(i_start) begin
           correlator_state <= ST_PNSEQ_LOAD;
           lfsr_load <= 1'b1;
           pnseq_order <= i_pnseq_order;
         end
       ST_PNSEQ_LOAD:
         if(pnseq_cnt == pnseq_length) begin
            correlator_state <= ST_CORR;
            pnseq_cnt <= 0;
            lfsr_en <= 1'b0;
         end else begin
            correlator_state <= ST_PNSEQ_LOAD;
            pnseq_cnt <= pnseq_cnt + 1;
            lfsr_en <= 1'b1;
         end         
       ST_CORR:
         if(rst) begin // Should be corr_rst 
           correlator_state <= ST_IDLE;
           corr_en <= 1'b0;
         end else begin
           correlator_state <= ST_CORR;
           corr_en <= 1'b1;
         end
     endcase
  end

integer i;

always @(posedge clk)
  if(rst || lfsr_load) begin
    for(i = 0 ; i < 256; i = i+1) begin
      pn_seq[i] <= 0;
    end
  end else begin
    if(lfsr_en) begin
      pn_seq[0] <= pnseq;
      for(i = 1 ; i < 256; i = i+1) begin
        pn_seq[i] <= pn_seq[i-1];
      end
    end     
  end
       
assign corr_in_valid = i_tvalid & corr_en;

always @(posedge clk)
begin
  valid[0] <= corr_in_valid;
  last [0] <= i_tlast;
  for(i = 1 ; i < 11; i=i+1) begin 
    valid[i] <= valid[i-1];
  end
  for(i = 1 ; i < 11; i=i+1) begin
    last[i] <= last[i-1];
  end
end


always @(posedge clk)
  if(rst) begin
    for(i = 0 ; i < 73; i = i+1) begin
      reg_i_data[i] <= 0;
      reg_q_data[i] <= 0;
    end
    corr_tvalid <= 1'b0;
    tvalid <= 1'b0;    
  end else begin
    
    if(i_tvalid) begin// AND current_state = ST_CORRELATE  
      reg_i_data[0] <= in_data_i; //i_tdata[15:0];
      reg_q_data[0] <= in_data_q; //i_tdata[31:16];
      for(i = 1 ; i < 73; i = i+1) begin
        reg_i_data[i] <= reg_i_data[i-1];
        reg_q_data[i] <= reg_q_data[i-1];
      end
    end

    if(valid[0]) begin
      for(i = 0; i < 64; i=i+1) begin
        if(i < pnseq_length) begin
          mux_i_data[i] <= (pn_seq[i] == 1) ? reg_i_data[i] : (-reg_i_data[i]); // TODO 
          mux_q_data[i] <= (pn_seq[i] == 1) ? reg_q_data[i] : (-reg_q_data[i]); // TODO         
        end else begin
          mux_i_data[i] <= 0;
          mux_q_data[i] <= 0;
        end
      end
    end

    if(valid[1]) begin
      for(i = 0 ; i < 32; i = i+1) begin
        adder1_i[i] <= mux_i_data[2*i] + mux_i_data[2*i + 1];
        adder1_q[i] <= mux_q_data[2*i] + mux_q_data[2*i + 1];
      end
    end

    if(valid[2]) begin
      for(i = 0 ; i < 16; i = i+1) begin 
        adder2_i[i] <= adder1_i[2*i] + adder1_i[2*i + 1];
        adder2_q[i] <= adder1_q[2*i] + adder1_q[2*i + 1];
      end 
    end

    if(valid[3]) begin
      for(i = 0 ; i < 8; i = i+1) begin
        adder3_i[i] <= adder2_i[2*i] + adder2_i[2*i + 1];
        adder3_q[i] <= adder2_q[2*i] + adder2_q[2*i + 1];
      end
    end

    if(valid[4]) begin
      for(i = 0 ; i < 4; i = i+1) begin
        adder4_i[i] <= adder3_i[2*i] + adder3_i[2*i + 1];
        adder4_q[i] <= adder3_q[2*i] + adder3_q[2*i + 1];
      end
    end

    if(valid[5]) begin
      for(i = 0 ; i < 2; i = i+1) begin
        adder5_i[i] <= adder4_i[2*i] + adder4_i[2*i + 1];
        adder5_q[i] <= adder4_q[2*i] + adder4_q[2*i + 1];
      end
    end

    /*if(valid[6]) begin
      for(i = 0 ; i < 4; i = i+1) begin
        adder6_i[i] <= adder5_i[2*i] + adder5_i[2*i + 1];
        adder6_q[i] <= adder5_q[2*i] + adder5_q[2*i + 1];
      end
    end

    if(valid[7]) begin
      for(i = 0 ; i < 2; i = i+1) begin
        adder7_i[i] <= adder6_i[2*i] + adder6_i[2*i + 1];
        adder7_q[i] <= adder6_q[2*i] + adder6_q[2*i + 1];
      end
    end*/

    if(valid[6]) begin
      final_sum_i <= adder5_i[0] + adder5_i[1];
      final_sum_q <= adder5_q[0] + adder5_q[1];
    end

    // adding 2 extra delays just to keep correlator latency same as 256 length correlator
    if(valid[7]) begin
      final_sum_i_reg1 <= final_sum_i;
      final_sum_q_reg1 <= final_sum_q;
    end

    if(valid[8]) begin
      final_sum_i_reg2 <= final_sum_i_reg1;
      final_sum_q_reg2 <= final_sum_q_reg1;
    end

    
    if(valid[9]) begin
      corr_tdata <= {final_sum_i_reg2[23:8], final_sum_q_reg2[23:8]};// discard lower 8 bits
      //corr_tvalid <= 1'b1;
      tdata <= {reg_i_data[pnseq_length + 9], reg_q_data[pnseq_length + 9]}; // for pnseq_length = 63, reg_i_data[72]
      tvalid <= 1'b1;       
    end else begin
      //corr_tvalid <= 1'b0;
      tvalid <= 1'b0;
    end    
  end

  assign o_corr_tdata = corr_tdata;
  assign o_corr_tvalid = valid[10];
  assign o_corr_tlast = last[10];
  assign o_tdata = tdata;
  assign o_tvalid = tvalid;
  assign o_tlast = last[10];
  assign i_tready = 1'b1;
  
endmodule
    


