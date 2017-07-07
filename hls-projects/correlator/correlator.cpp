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
/*correlator.cpp - Used to generate RTL for correlator module used in RFNoC block noc_block_correlator.
  i_data - AXI stream input data (with tlast)
  o_data - AXI stream output data (with tlast)
  start  - User sent start signal, to start the correlation task
  pnseq  - PN sequence used for correlation wit the input data. As this port is setup as 'ap_hs', handshaking signals 'valid' and 'ack' are generated. All these 3 signals are connected to the PN sequence generator instance in noc_block_correlator
  pnseq_len - input parameter PN sequence length

*/
#include <hls_stream.h>
#include "ap_int.h"
#include "rfnoc.h"
// Uncomment to generate correlator size 256
//#define COR_SIZE_256
// Uncomment to generate correlator size 512
#define COR_SIZE_512

void correlator (hls::stream<rfnoc_axis> i_data, hls::stream<rfnoc_axis> o_data, ap_uint<1> start, hls::stream<ap_uint<1> > pnseq_in, ap_uint<10> pnseq_len)
{

#ifdef COR_SIZE_256
const int COR_SIZE = 256;
#endif

#ifdef COR_SIZE_512
const int COR_SIZE = 512;
#endif

#pragma HLS RESOURCE variable=o_data latency=1
#pragma HLS INTERFACE ap_hs port=pnseq_in
#pragma HLS INTERFACE ap_ctrl_none port=return
#pragma HLS INTERFACE axis port=o_data
#pragma HLS INTERFACE axis port=i_data
#pragma HLS PIPELINE II=1
  static ap_int<16> data_reg_i[COR_SIZE];
#pragma HLS RESET variable=data_reg_i
#pragma HLS ARRAY_PARTITION variable=data_reg_i complete dim=1
  static ap_int<16> data_reg_q[COR_SIZE];
#pragma HLS RESET variable=data_reg_q
#pragma HLS ARRAY_PARTITION variable=data_reg_q complete dim=1
  static ap_int<16> product_reg_i[COR_SIZE];
#pragma HLS ARRAY_PARTITION variable=product_reg_i complete dim=1
  static ap_int<16> product_reg_q[COR_SIZE];
#pragma HLS ARRAY_PARTITION variable=product_reg_q complete dim=1
  static ap_int<16> adder_in_reg_i[COR_SIZE];
#pragma HLS ARRAY_PARTITION variable=adder_in_reg_i complete dim=1
  static ap_int<16> adder_in_reg_q[COR_SIZE];
#pragma HLS ARRAY_PARTITION variable=adder_in_reg_q complete dim=1

  static ap_int<17> sum1_reg_i[COR_SIZE/2];
#pragma HLS ARRAY_PARTITION variable=sum1_reg_i complete dim=1
  static ap_int<17> sum1_reg_q[COR_SIZE/2];
#pragma HLS ARRAY_PARTITION variable=sum1_reg_q complete dim=1

  static ap_int<18> sum2_reg_i[COR_SIZE/4];
#pragma HLS ARRAY_PARTITION variable=sum2_reg_i complete dim=1
  static ap_int<18> sum2_reg_q[COR_SIZE/4];
#pragma HLS ARRAY_PARTITION variable=sum2_reg_q complete dim=1

  static ap_int<19> sum3_reg_i[COR_SIZE/8];
#pragma HLS ARRAY_PARTITION variable=sum3_reg_i complete dim=1
  static ap_int<19> sum3_reg_q[COR_SIZE/8];
#pragma HLS ARRAY_PARTITION variable=sum3_reg_q complete dim=1

  static ap_int<20> sum4_reg_i[COR_SIZE/16];
#pragma HLS ARRAY_PARTITION variable=sum4_reg_i complete dim=1
  static ap_int<20> sum4_reg_q[COR_SIZE/16];
#pragma HLS ARRAY_PARTITION variable=sum4_reg_q complete dim=1

  static ap_int<21> sum5_reg_i[COR_SIZE/32];
#pragma HLS ARRAY_PARTITION variable=sum5_reg_i complete dim=1
  static ap_int<21> sum5_reg_q[COR_SIZE/32];
#pragma HLS ARRAY_PARTITION variable=sum5_reg_q complete dim=1

  static ap_int<22> sum6_reg_i[COR_SIZE/64];
#pragma HLS ARRAY_PARTITION variable=sum6_reg_i complete dim=1
  static ap_int<22> sum6_reg_q[COR_SIZE/64];
#pragma HLS ARRAY_PARTITION variable=sum6_reg_q complete dim=1

  static ap_int<23> sum7_reg_i[COR_SIZE/128];
#pragma HLS ARRAY_PARTITION variable=sum7_reg_i complete dim=1
  static ap_int<23> sum7_reg_q[COR_SIZE/128];
#pragma HLS ARRAY_PARTITION variable=sum7_reg_q complete dim=1



  rfnoc_axis out_sample;

  static ap_uint<10> out_sample_cnt;
#pragma HLS RESET variable=out_sample_cnt

  static ap_uint<1> pn_seq[512];
#pragma HLS ARRAY_PARTITION variable=pn_seq complete dim=1

  rfnoc_axis tmp_data;

  static ap_uint<10> load_cnt;
#pragma HLS RESET variable=load_cnt
  static ap_uint<24> data_valid_reg;
  static ap_uint<10> pnseq_len_reg;

  enum correlatorState {ST_IDLE = 0, ST_LOAD, ST_GEN, ST_CORRELATE};
  static correlatorState currentState;
#pragma HLS RESET variable=currentState

  enum writeState {ST_NOWRITE = 0, ST_WRITE};
  static writeState currentwrState;
#pragma HLS RESET variable=currentwrState

#ifdef COR_SIZE_256

  static ap_int<24> sum_reg_i;
  static ap_int<24> sum_reg_q;

  static ap_int<48> sq_reg_i;
  static ap_int<48> sq_reg_q;

  static ap_int<49> sq_sum;

// Output write state machine
  switch(currentwrState) {
      case ST_NOWRITE:
          if(data_valid_reg[11])
                  currentwrState = ST_WRITE;
          break;
      case ST_WRITE:
          if(out_sample_cnt == pnseq_len_reg-1){
                   out_sample.last = 1;
                   out_sample_cnt = 0; }
          else{
                   out_sample.last = 0;
               out_sample_cnt = out_sample_cnt + 1;}

          if(!data_valid_reg[11])
                  currentwrState = ST_NOWRITE;
          else
                  currentwrState = ST_WRITE;

          out_sample.data = sq_sum.range(48,17);
          o_data.write(out_sample);

          break;
  }

// correlation power I^2 + Q^2
   sq_sum = (sq_reg_i + sq_reg_q);

   sq_reg_i = sum_reg_i*sum_reg_i; // I*I
   sq_reg_q = sum_reg_q*sum_reg_q; // Q*Q

//Last addder stage
   sum_reg_i = sum7_reg_i[0] + sum7_reg_i[1];
   sum_reg_q = sum7_reg_q[0] + sum7_reg_q[1];
#endif

#ifdef COR_SIZE_512

   static ap_int<24> sum8_reg_i[COR_SIZE/256];
   #pragma HLS ARRAY_PARTITION variable=sum8_reg_i complete dim=1
   static ap_int<24> sum8_reg_q[COR_SIZE/256];
   #pragma HLS ARRAY_PARTITION variable=sum8_reg_q complete dim=1

   static ap_int<25> sum_reg_i;
   static ap_int<25> sum_reg_q;

   static ap_int<50> sq_reg_i;
   static ap_int<50> sq_reg_q;

   static ap_int<51> sq_sum;

// Output write state machine
  switch(currentwrState) {
      case ST_NOWRITE:
          if(data_valid_reg[12])
                  currentwrState = ST_WRITE;
          break;
      case ST_WRITE:
          if(out_sample_cnt == pnseq_len_reg-1){
                   out_sample.last = 1;
                   out_sample_cnt = 0; }
          else{
                   out_sample.last = 0;
               out_sample_cnt = out_sample_cnt + 1;}

          if(!data_valid_reg[12])
                  currentwrState = ST_NOWRITE;
          else
                  currentwrState = ST_WRITE;

          out_sample.data = sq_sum.range(50,19);
          o_data.write(out_sample);

          break;
  }

// correlation power I^2 + Q^2
      sq_sum = (sq_reg_i + sq_reg_q);

      sq_reg_i = sum_reg_i*sum_reg_i; // I*I
      sq_reg_q = sum_reg_q*sum_reg_q; // Q*Q

//Last adder stage
      sum_reg_i = sum8_reg_i[0] + sum8_reg_i[1];
      sum_reg_q = sum8_reg_q[0] + sum8_reg_q[1];

// An additional adder stage for size 512
      ADDER_STAGE8_LOOP: for(int i = 0; i<COR_SIZE/256; i++){
      #pragma HLS UNROLL
         sum8_reg_i[i] = sum7_reg_i[2*i] + sum7_reg_i[2*i + 1];
         sum8_reg_q[i] = sum7_reg_q[2*i] + sum7_reg_q[2*i + 1];
      }

#endif

// 7 binary tree adder stages
  ADDER_STAGE7_LOOP: for(int i = 0; i<COR_SIZE/128; i++){
  #pragma HLS UNROLL
    sum7_reg_i[i] = sum6_reg_i[2*i] + sum6_reg_i[2*i + 1];
    sum7_reg_q[i] = sum6_reg_q[2*i] + sum6_reg_q[2*i + 1];
  }

  ADDER_STAGE6_LOOP: for(int i = 0; i<COR_SIZE/64; i++){
  #pragma HLS UNROLL
     sum6_reg_i[i] = sum5_reg_i[2*i] + sum5_reg_i[2*i + 1];
     sum6_reg_q[i] = sum5_reg_q[2*i] + sum5_reg_q[2*i + 1];
  }

  ADDER_STAGE5_LOOP: for(int i = 0; i<COR_SIZE/32; i++){
  #pragma HLS UNROLL
     sum5_reg_i[i] = sum4_reg_i[2*i] + sum4_reg_i[2*i + 1];
     sum5_reg_q[i] = sum4_reg_q[2*i] + sum4_reg_q[2*i + 1];
  }


  ADDER_STAGE4_LOOP: for(int i = 0; i<COR_SIZE/16; i++){
  #pragma HLS UNROLL
     sum4_reg_i[i] = sum3_reg_i[2*i] + sum3_reg_i[2*i + 1];
     sum4_reg_q[i] = sum3_reg_q[2*i] + sum3_reg_q[2*i + 1];
  }

  ADDER_STAGE3_LOOP: for(int i = 0; i<COR_SIZE/8; i++){
  #pragma HLS UNROLL
     sum3_reg_i[i] = sum2_reg_i[2*i] + sum2_reg_i[2*i + 1];
     sum3_reg_q[i] = sum2_reg_q[2*i] + sum2_reg_q[2*i + 1];
  }


  ADDER_STAGE2_LOOP: for(int i = 0; i<COR_SIZE/4; i++){
  #pragma HLS UNROLL
     sum2_reg_i[i] = sum1_reg_i[2*i] + sum1_reg_i[2*i + 1];
     sum2_reg_q[i] = sum1_reg_q[2*i] + sum1_reg_q[2*i + 1];
  }

  ADDER_STAGE1_LOOP: for(int i = 0; i<COR_SIZE/2; i++){
  #pragma HLS UNROLL
     sum1_reg_i[i] = adder_in_reg_i[2*i] + adder_in_reg_i[2*i + 1];
     sum1_reg_q[i] = adder_in_reg_q[2*i] + adder_in_reg_q[2*i + 1];
  }

  ADDER_INPUT_LOOP: for(int i = 0; i < COR_SIZE; i++){
   #pragma HLS UNROLL
         if(i < pnseq_len_reg){
          adder_in_reg_i[i] = product_reg_i[i];
          adder_in_reg_q[i] = product_reg_q[i];
         }
         else
         {
          adder_in_reg_i[i] = 0;
          adder_in_reg_q[i] = 0;
    }
  }


 // product or selection since the PN sequence is real, binary
  PRODUCT_REG_LOOP:for(int i = 0; i < COR_SIZE; i++){
  #pragma HLS UNROLL
   if(pn_seq[i] == 1){
         product_reg_i[i] = data_reg_i[i];
         product_reg_q[i]= 0 - data_reg_q[i];
   }
   else{
         product_reg_i[i] = 0 - data_reg_i[i];
         product_reg_q[i] = data_reg_q[i];
   }
  }

  data_valid_reg.range(23,1) = data_valid_reg.range(22,0);
// Read and shift state machine
// Waits for the 'start' signal, reads input samples and shifts them into the shift register storage
  switch(currentState) {
    case ST_IDLE:
          if(start) // wait for start signal. The same start signal is used to load PN sequence generator
                  currentState = ST_LOAD;
          break;
    case ST_LOAD:
          pnseq_len_reg = pnseq_len;  // register input parameters
          load_cnt = pnseq_len - 1;
          currentState = ST_GEN;
          break;
    case ST_GEN: // Read incoming PN sequence and store it locally
          pn_seq[load_cnt] = pnseq_in.read();
          if (load_cnt == 0){
                  currentState = ST_CORRELATE;
              load_cnt = pnseq_len_reg - 1;}
          else{
                  currentState = ST_GEN;
                  load_cnt = load_cnt - 1;}
          break;
     case ST_CORRELATE: // whenever there is valid input data, shift it in
          if(!i_data.empty())
          {
                  SHIFT_DATA: for(int i = COR_SIZE-1 ; i > 0 ; i--){
                  #pragma HLS UNROLL
                        data_reg_i[i] = data_reg_i[i - 1];
                                data_reg_q[i] = data_reg_q[i - 1];}

                   i_data.read(tmp_data);
                   data_reg_q[0] = tmp_data.data.range(15,0); // IM
                   data_reg_i[0] = tmp_data.data.range(31,16); // RE 
                   data_valid_reg[0] = 1;   // shift in valid pulse
          }
          else
                  data_valid_reg[0] = 0;
        break;
    }


}

