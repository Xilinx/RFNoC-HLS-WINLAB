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
/* correlator_block_ctrl_impl.cpp - Block controller implementation for correlator NoC block
   Used Ettus provided block controllers for reference
*/
#include <uhd/rfnoc/correlator_block_ctrl.hpp>
#include <uhd/convert.hpp>
#include <uhd/utils/msg.hpp>

using namespace uhd::rfnoc;

class correlator_block_ctrl_impl : public correlator_block_ctrl
{
public:

    UHD_RFNOC_BLOCK_CONSTRUCTOR(correlator_block_ctrl)
    {
        //Set default generator polynomial - x^6+x^5+1, seed - 000001, pn seq len - 63 
        set_pn_seq_gen("000011"/*poly*/, "000001"/*seed*/, 63/*pn seq len*/);
        //Set default generator polynomial - x^8+x^6+x^5+x^4+1, seed - 000001, pn seq len - 63
        //set_pn_seq_gen("00011101"/*poly*/, "000001"/*seed*/, 255/*pn seq len*/);
    }

    void set_pn_seq_gen(const std::string poly, const std::string seed, const int seq_len)
    {
        UHD_RFNOC_BLOCK_TRACE() << "spec_spreader::set_pn_seq_gen()" << std::endl;
        UHD_MSG(status) << "Configuring PN seq gen. Poly : " << poly << "Seed : " << seed << "Seq_len : " << seq_len << std::endl;

        if(poly.length() > 10) {
           throw uhd::value_error(str(boost::format("Generator polynomial too long!! length should be <= 10")));
        }
        if(seed.length() > 10) {
           throw uhd::value_error(str(boost::format("Generator seed too long!! length should be <= 10")));
        }
        if(seq_len > 1023){
           throw uhd::value_error(str(boost::format("PN sequence too long!! length should be <= 1023")));
        }

        int gen_order = 0;
        for(int i = 0; i < poly.length(); i++)
        {
           if(poly[i] == '1')
              gen_order = i+1;
           else if(poly[i] != '0')
              throw uhd::value_error(str(boost::format("Please specify the generator polynomial in binary format")));
        }
        for(int i = 0; i < seed.length(); i++)
        {
           if(seed[i] != '0' && seed[i] != '1')
              throw uhd::value_error(str(boost::format("Please specify the seed in binary format")));
        }

        sr_write("BLOCK_RESET", 1);
        sr_write("BLOCK_RESET", 0);
        int gen_poly = stoi(poly, nullptr, 2);
        int gen_seed = stoi(seed, nullptr, 2);
        gen_poly = gen_poly << (10 - poly.length());
        gen_seed = gen_seed << ((10 - seed.length()) + 10);
        uint32_t gen_seed_poly = gen_seed + gen_poly;

        sr_write("GEN_SEED_POLY", gen_seed_poly);
        
        gen_order = gen_order << 10;
        uint32_t gen_order_len = gen_order + seq_len; 

        sr_write("GEN_ORDER_LEN", gen_order_len);
        sr_write("BLOCK_START", 1);
        sr_write("BLOCK_START", 0);
     }


    /*std::string get_poly()
    {
       uint64_t gen_seed_poly = user_reg_read64(1);
       std::string poly;
       for (int i = 0; i < 10; i++)
       {
         if(gen_seed_poly & 1)
           poly = '1' + poly;
         else
           poly = '0' + poly;
         
         gen_seed_poly >> 1;
       }
       return poly;
    }*/
 

};

UHD_RFNOC_BLOCK_REGISTER(correlator_block_ctrl, "Correlator");
