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
/* corrmag63avg8k_block_ctrl.hpp - Block controller for corrmag63avg8k NoC block
   Used Ettus provided block controllers for reference
*/

#ifndef INCLUDED_LIBUHD_RFNOC_corrmag63avg8k_block_ctrl_HPP
#define INCLUDED_LIBUHD_RFNOC_corrmag63avg8k_block_ctrl_HPP

#include <uhd/rfnoc/source_block_ctrl_base.hpp>
#include <uhd/rfnoc/sink_block_ctrl_base.hpp>

namespace uhd {
    namespace rfnoc {

class UHD_RFNOC_API corrmag63avg8k_block_ctrl : public source_block_ctrl_base, public sink_block_ctrl_base
{
public:
    UHD_RFNOC_BLOCK_OBJECT(corrmag63avg8k_block_ctrl)

    //! Configure the PN sequence generator 
    //
    virtual void set_corrmag63avg8k(const std::string poly, const std::string seed, const int order, const int threshold, const int avg_size) = 0;

    virtual void start_corrmag63avg8k() = 0;
 
    virtual void stop_corrmag63avg8k() = 0;

}; /* class corrmag63avg8k_block_ctrl*/

}} /* namespace uhd::rfnoc */

#endif /* INCLUDED_LIBUHD_RFNOC_corrmag63avg8k_block_ctrl_HPP */
// vim: sw=4 et:
