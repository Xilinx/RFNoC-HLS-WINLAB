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
/* pn_seq_gen_lfsr.cpp - Used to generate RTL for LFSR based PN sequence generator
   load - load input to load the generator polynomial and seed
   pn_req - request for next bit in the sequence. Works like an enable signal for the LFSR
   poly  - generator polynomial input. Maximum order 10
   seed  - Initial seed for the LFSR
   order - generator polynomial order
*/

#include "ap_int.h"

// Maximum order of generator polynomial = 10
ap_uint<1> pn_seq_gen_lfsr(ap_uint<1> load, ap_uint<1> pn_req, ap_uint<10> poly, ap_uint<10> seed, ap_uint<4> order){
//#pragma HLS INTERFACE ap_none port=out_bit
#pragma HLS INTERFACE ap_ctrl_none port=return
// For a 63 length (maximal) length sequence, the generator poly is x^6 + x^5 + 1. Let's say the seed is 000001
// Input poly : 0000110000    Input Seed : 0000010000
	ap_uint<1> out_bit, next_bit;
#pragma HLS RESET variable=next_bit
	static ap_uint<10> poly_reg, shift_reg, next_reg_state;
#pragma HLS RESET variable=next_reg_state
#pragma HLS RESET variable=shift_reg
#pragma HLS RESET variable=poly_reg


	next_bit = (shift_reg & poly_reg).xor_reduce();
	next_reg_state = (next_bit, shift_reg(9,1)); // shift all the bits
	out_bit = shift_reg[10 - order];// take output only in the middle of the register (or the LSB for order = 10)

	if(load){
		shift_reg = seed;
	    poly_reg = poly;
	}
	else
        {
		if(pn_req){
			shift_reg = next_reg_state;
		}
    }
	return out_bit;

}
