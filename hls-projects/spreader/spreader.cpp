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
//
//Team WINLAB
//RFNoC HLS Challenge
/* spreader.cpp - Used to generate RTL for the spreader module used in noc_block_spreader
   i_data - AXI stream input data (with tlast)
   o_data - AXI stream output data (with tlast)
   pnseq  - PN sequence used for spreading the input data. As this port is setup as 'ap_hs', handshaking signals 'valid' and 'ack' are generated. All these 3 signals are connected to the PN sequence generator instance in noc_block_spreader
   pnseq_len - input parameter PN sequence length
*/
#include <hls_stream.h>
#include "rfnoc.h"

ap_uint<1> spreader(hls::stream<rfnoc_axis> i_data, hls::stream<rfnoc_axis> o_data, hls::stream<ap_uint<1> > pnseq,ap_uint<10> pnseq_len){
#pragma HLS PIPELINE II=1
#pragma HLS INTERFACE ap_ctrl_none port=return
#pragma HLS INTERFACE ap_hs port=pnseq
#pragma HLS INTERFACE axis port=i_data
#pragma HLS INTERFACE axis port=o_data

static ap_uint<10> reg_pnseq_len, out_sample_cnt;
#pragma HLS RESET variable=out_sample_cnt
#pragma HLS RESET variable=reg_pnseq_len

static hls::stream<ap_uint<32> > data_fifo;
#pragma HLS STREAM variable=data_fifo depth=256 dim=1
#pragma HLS RESOURCE variable=data_fifo core=FIFO
 // internal FIFO with depth = 256, to store incoming data

static ap_uint<32> reg_data;
rfnoc_axis  out_sample, tmp_data;
static ap_uint<1> last_in_sample, load;
#pragma HLS RESET variable=last_in_sample

enum spreadState {ST_IDLE = 0, ST_LOAD, ST_WAIT, ST_READ, ST_SPREAD};
static spreadState currentState;

switch(currentState) {
case ST_IDLE:                    // Wait for incoming data
           load = 0;
           last_in_sample = 0;
           reg_pnseq_len = pnseq_len;
           if(!i_data.empty()){
                   data_fifo.write(i_data.read().data);
                   currentState = ST_LOAD;}
           else
                   currentState = ST_IDLE;
           break;

case ST_LOAD:
          load = 1;       // load the pn seq generator (generator polynomial and seed are loaded)
          currentState = ST_WAIT;
          break;

case ST_WAIT:
          currentState = ST_READ;
          break;

case ST_READ:
          load = 0;
          if(data_fifo.read_nb(reg_data)) // non-blocking read from data fifo.
                  currentState = ST_SPREAD;   // go to ST_SPREAD if the read is successful
          else
                  currentState = ST_IDLE;     // ST_IDLE when there is no data in the FIFO
          break;

case ST_SPREAD:
      load = 0;
          if(!last_in_sample  & !data_fifo.full()){   // Write into the FIFO when it is not full, and write only this frame
             if(i_data.read_nb(tmp_data)){            // a temporary data variable.
                 last_in_sample = tmp_data.last;
                 data_fifo.write(tmp_data.data);
             }
          }

          if (out_sample_cnt == reg_pnseq_len-1)
                  out_sample.last = 1;
          else
                  out_sample.last = 0;
          if(pnseq.read() == 1)
                  out_sample.data = reg_data;
          else{
                  out_sample.data.range(31,16) = (0 - reg_data.range(31,16));
                  out_sample.data.range(15,0)  = (0 - reg_data.range(15,0)); // IM, RE
          }
          if (out_sample_cnt == reg_pnseq_len-1)
          {
                  currentState = ST_LOAD;
                  out_sample_cnt = 0;
          }
          else
          {
                  currentState = ST_SPREAD;
                  out_sample_cnt = out_sample_cnt+1;
          }
          o_data.write(out_sample);

          break;
}

return load;
}

