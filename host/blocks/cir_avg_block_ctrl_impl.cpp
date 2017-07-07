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
/* cir_avg_block_ctrl_impl.cpp - Block controller implementation for cir_avg NoC block
   Used Ettus provided block controllers for reference
*/
#include <uhd/rfnoc/cir_avg_block_ctrl.hpp>
#include <uhd/convert.hpp>
#include <uhd/utils/msg.hpp>

using namespace uhd::rfnoc;

class cir_avg_block_ctrl_impl : public cir_avg_block_ctrl
{
public:

    UHD_RFNOC_BLOCK_CONSTRUCTOR(cir_avg_block_ctrl)
    {
        set_cir_avg(0xFFFF/*threshold*/, 4/*log_avg_size*/, 255/*pn seq len*/);
    }

    void set_cir_avg(const uint32_t threshold, const int log_avg_size, const int seq_len)
    {
        UHD_RFNOC_BLOCK_TRACE() << "cir_avg::set_cir_avg()" << std::endl;
        UHD_MSG(status) << "Configuring CIR avg. Threshold : " << threshold << "Log2(avg_size) : " << log_avg_size << "Seq_len : " << seq_len << std::endl;

        if(log_avg_size > 7) {
           throw uhd::value_error(str(boost::format("log2(avg_size) should be <= 7 - Maximum averaging factor is 256")));
        }
        if(seq_len > 1023){
           throw uhd::value_error(str(boost::format("PN sequence too long!! length should be <= 1023")));
        }
        
        sr_write("BLOCK_RESET", 1);
        sr_write("BLOCK_RESET", 0);

        uint32_t log_avg_size_seq_len = (log_avg_size << 10) + seq_len;
        sr_write("THRESHOLD", threshold);
        
        sr_write("AVG_SIZE_SEQ_LEN", log_avg_size_seq_len );
     }

};

UHD_RFNOC_BLOCK_REGISTER(cir_avg_block_ctrl, "CIRAvg");
