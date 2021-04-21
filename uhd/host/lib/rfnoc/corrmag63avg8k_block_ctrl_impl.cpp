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
/* corrmag63avg8k_block_ctrl_impl.cpp - Block controller implementation for corrmag63avg8k NoC block
   Used Ettus provided block controllers for reference
*/
#include <uhd/rfnoc/corrmag63avg8k_block_ctrl.hpp>
#include <uhd/convert.hpp>

using namespace uhd::rfnoc;

class corrmag63avg8k_block_ctrl_impl : public corrmag63avg8k_block_ctrl
{
public:

    UHD_RFNOC_BLOCK_CONSTRUCTOR(corrmag63avg8k_block_ctrl)
    {
        //Set default generator polynomial - x^6+x^5+1, seed - 000001, pn seq len - 63 
        set_corrmag63avg8k("000011"/*poly*/, "000001"/*seed*/, 6/*pn seq order*/, 30/*threshold*/, 1024/*avg_size*/);
        //Set default generator polynomial - x^8+x^6+x^5+x^4+1, seed - 000001, pn seq len - 63
        //set_pn_seq_gen("00011101"/*poly*/, "000001"/*seed*/, 255/*pn seq len*/);
    }

    void set_corrmag63avg8k(const std::string poly, const std::string seed, const int order, const int threshold, const int avg_size)
    {
        UHD_RFNOC_BLOCK_TRACE() << "Set corrmag63avg8k" << std::endl;
        UHD_LOGGER_DEBUG("RFNOC") << "Configuring PN seq gen. Poly : " << poly << " Seed : " << seed << " Seq_order : " << order << " Threshold : " << threshold << " Avg size : " << avg_size;

        if(poly.length() > 6) {
           throw uhd::value_error(str(boost::format("Generator polynomial too long!! length should be <= 6")));
        }
        if(seed.length() > 6) {
           throw uhd::value_error(str(boost::format("Generator seed too long!! length should be <= 6")));
        }
        if(order > 6){
           throw uhd::value_error(str(boost::format("PN sequence too long!! order should be <= 6")));
        }
        if(threshold > 63){
           throw uhd::value_error(str(boost::format("Threshold should be <= 63")));
        }
        if(avg_size > 8192){
           throw uhd::value_error(str(boost::format("Averaging size is too high!! should be <= 8192")));
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

        int gen_poly = stoi(poly, nullptr, 2);
        int gen_seed = stoi(seed, nullptr, 2);
        gen_poly = gen_poly << (9 - poly.length());
        gen_seed = gen_seed << ((9 - seed.length()) + 12);
        gen_order = order << 24;
        uint32_t pnseq_params = gen_order + gen_seed + gen_poly;

        int pkt_size = 63;//(2^order) - 1;      
        uint32_t avg_params = (pkt_size << 16)+ avg_size; 

        sr_write("SR_PNSEQ_PARAMS", pnseq_params);
        sr_write("SR_THRESHOLD", threshold);
        sr_write("SR_AVG_PARAMS", avg_params);

        UHD_LOGGER_DEBUG("RFNOC") << "Writing " << boost::format("%08X") %pnseq_params <<" to SR_PNSEQ_PARAMS";  
        UHD_LOGGER_DEBUG("RFNOC") << "Writing " << boost::format("%08X") %threshold <<" to SR_THRESHOLD";  
        UHD_LOGGER_DEBUG("RFNOC") << "Writing " << boost::format("%08X") %avg_params <<" to SR_AVG_PARAMS";  

        //sr_write("SR_MODE", 1);
     }

    void start_corrmag63avg8k()
    {
      sr_write("SR_MODE", 1);
    }

    void stop_corrmag63avg8k()
    {
      sr_write("SR_MODE", 2);
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

UHD_RFNOC_BLOCK_REGISTER(corrmag63avg8k_block_ctrl, "Corrmag63avg8k");
