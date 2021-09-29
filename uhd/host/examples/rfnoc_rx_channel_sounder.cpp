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

#include <uhd/types/tune_request.hpp>
#include <uhd/types/sensors.hpp>
#include <uhd/utils/thread.hpp>
#include <uhd/utils/safe_main.hpp>
#include <uhd/device3.hpp>
#include <uhd/usrp/multi_usrp.hpp>
#include <uhd/rfnoc/radio_ctrl.hpp>
#include <uhd/rfnoc/source_block_ctrl_base.hpp>
#include <uhd/rfnoc/corrmag63avg8k_block_ctrl.hpp>
#include <uhd/exception.hpp>
#include <boost/program_options.hpp>
#include <boost/format.hpp>
#include <boost/foreach.hpp>
#include <boost/thread.hpp>
#include <boost/asio.hpp>
#include <boost/algorithm/string.hpp>
#include <iostream>
#include <fstream>
#include <csignal>
#include <complex>
#include <climits>
#include <cmath>



namespace po = boost::program_options;


static bool stop_signal_called = false;
void sig_int_handler(int){stop_signal_called = true;}


///////////////////////////////////////////////////////////////////////////////////////////////////////////

int UHD_SAFE_MAIN(int argc, char *argv[]){
    uhd::set_thread_priority_safe();

    //variables to be set by po
    std::string args, file, ant, subdev, ref, streamargs, ddc_args, specsense_args, sync, radio_args, pn_seed, pn_poly;
    size_t total_num_samps, spb, spp, num_reqd_samps;
    double rate, freq, gain, bw, total_time, setup_time;
    int pn_order, avg, thres;


    //setup the program options
    po::options_description desc("Allowed options");
    desc.add_options()
        ("help", "help message")
        ("file", po::value<std::string>(&file)->default_value("usrp_samples.dat"), "name of the file to write binary samples to")
        ("duration", po::value<double>(&total_time)->default_value(0), "total number of seconds to receive (will stream continuously if set to 0)")
        ("nsamps", po::value<size_t>(&num_reqd_samps)->default_value(63000), "total number of samples to receive (will stream continouosly if set to 0)")
        ("spp", po::value<size_t>(&spp)->default_value(63), "samples per packet")
        ("continue", "don't abort on a bad packet")
	("args", po::value<std::string>(&args)->default_value("type=x300,skip_ddc,skip_duc"), "USRP device address args")
        ("setup", po::value<double>(&setup_time)->default_value(1.0), "seconds of setup time")
        ("freq", po::value<double>(&freq)->default_value(3e9), "RF center frequency in Hz")
        ("gain", po::value<double>(&gain)->default_value(10), "gain for the RF chain")
        ("ant", po::value<std::string>(&ant), "antenna selection")
        ("ref", po::value<std::string>(&ref)->default_value("internal"), "reference source (internal, external, mimo)")
        ("sync", po::value<std::string>(&sync)->default_value("now"), "Sync (now (for no sync) or pps)")
	("skip-lo", "skip checking LO lock status")
        ("int-n", "tune USRP with integer-N tuning")
        ("ddc-args", po::value<std::string>(&ddc_args)->default_value("input_rate=200000000.0,output_rate=50000000.0"), "These args are passed straight to the DDC block.")
        ("PN-order", po::value<int>(&pn_order)->default_value(6), "PN Sequence generator order (default = 6)")
        ("PN-seed", po::value<std::string>(&pn_seed)->default_value("000001"), "Seed polynomial (default = 000001)")
        ("PN-gen-poly", po::value<std::string>(&pn_poly)->default_value("000011"), "Generator polynomial (default = 000011)")
        ("avg", po::value<int>(&avg)->default_value(256), "\"avg\" times the correlator output will be averaged")
        ("threshold", po::value<int>(&thres)->default_value(0), "correlator threshold (peaks below this threshold will not be considered)")
        ("streamargs", po::value<std::string>(&streamargs)->default_value(""), "additional stream args")

    ;
    po::variables_map vm;
    po::store(po::parse_command_line(argc, argv, desc), vm);
    po::notify(vm);

    //print the help message
    if (vm.count("help")) {
        std::cout << boost::format("CIR to file %s") % desc << std::endl;
        std::cout
            << std::endl
            << "This application streams CIR from one USRP.\n"
            << std::endl;
        return ~0;
    }


    // Receiver streamer continues even if a bad packet is received
    bool continue_on_bad_packet = vm.count("continue") > 0;

    /************************************************************************
     * Create device 
     ***********************************************************************/
    //Creating multi-usrp pointer to handle control of multiple channels and converting to device3 pointer to give RFNoC graph commands
    uhd::usrp::multi_usrp::sptr usrp_temp = uhd::usrp::multi_usrp::make(args);
    uhd::device3::sptr usrp = usrp_temp->get_device3();
	
    
    //Set clock reference for all devices
    if (vm.count("ref")) {
        usrp_temp->set_clock_source(ref);
    }
	
    boost::this_thread::sleep(boost::posix_time::milliseconds(long(setup_time*1000))); //allow for some setup time
	

    // Set center frequency for all rx chains
    std::cout << boost::format("Setting RX Freq: %f MHz...") % (freq/1e6) << std::endl;
    uhd::tune_request_t tune_request(freq);
    if(vm.count("int-n")) {
        tune_request.args = uhd::device_addr_t("mode_n=integer");
    }
    usrp_temp->set_rx_freq(freq);
    std::cout << boost::format("Actual RX Freq: %f MHz...") % (usrp_temp->get_rx_freq()/1e6) << std::endl << std::endl;

    // Set the RF gain
    if(vm.count("gain")) {
        std::cout << boost::format("Setting RX Gain: %f dB...") % gain << std::endl;
        usrp_temp->set_rx_gain(gain);
        std::cout << boost::format("Actual RX Gain: %f dB...") % usrp_temp->get_rx_gain() << std::endl << std::endl;
    }


    // Set the antenna
    if(vm.count("ant")) {
        usrp_temp->set_rx_antenna(ant);
    }
    

    boost::this_thread::sleep(boost::posix_time::milliseconds(long(setup_time*1000))); //allow for some setup time

     /* Set up RF
     **********************************************************************/
    uhd::device_addr_t ddc_args_map(ddc_args);
    rate = std::stof(ddc_args_map.get("output_rate"));
    std::cout << "Rate from DDC args : " << rate << std::endl;

    /************************************************************************
     * Set up RFNoC flow graph
     ***********************************************************************/

    uhd::device_addr_t streamer_args(streamargs);
    uhd::rfnoc::graph::sptr rx_graph;
    uhd::rfnoc::block_id_t radio_ctrl_id(0, "Radio", 0);
    std::string ddc_id("0/DDC_0");
    std::string corr_id("0/Corrmag63avg8k_0");

    uhd::rfnoc::source_block_ctrl_base::sptr ddc_ctrl=usrp->get_block_ctrl<uhd::rfnoc::source_block_ctrl_base>(ddc_id);
    uhd::rfnoc::corrmag63avg8k_block_ctrl::sptr corr_ctrl=usrp->get_block_ctrl<uhd::rfnoc::corrmag63avg8k_block_ctrl>(corr_id);;
    rx_graph = usrp->create_graph("rfnoc_corr_rx_to_file");
    usrp->clear();

    ddc_ctrl->set_args(uhd::device_addr_t(ddc_args));
    corr_ctrl->stop_corrmag63avg8k();
    corr_ctrl->set_corrmag63avg8k(pn_poly,pn_seed,pn_order,thres,avg);
    std::cout << "Connecting " << radio_ctrl_id << " ==> " << ddc_ctrl->get_block_id() << std::endl;
    rx_graph->connect(radio_ctrl_id, 0, ddc_ctrl->get_block_id(), uhd::rfnoc::ANY_PORT);
    std::cout << "Connecting " << ddc_ctrl->get_block_id() << " ==> " << corr_ctrl->get_block_id() << std::endl;
    rx_graph->connect(ddc_ctrl->get_block_id(), uhd::rfnoc::ANY_PORT, corr_ctrl->get_block_id(), uhd::rfnoc::ANY_PORT);
    streamer_args["block_id"] = corr_id;

    corr_ctrl->start_corrmag63avg8k();       
    


    //Setting the samples per packet for streaming
    std::cout << "Samples per packet: " << spp << std::endl;
    uhd::stream_args_t stream_args("item32", "item32"); 
    stream_args.args = streamer_args;
    stream_args.args["spp"] = boost::lexical_cast<std::string>(spp);
    std::cout << "Using streamer args: " << stream_args.args.to_string() << std::endl;
    uhd::rx_streamer::sptr rx_stream = usrp->get_rx_stream(stream_args);
    

    // Open receive write file
    std::ofstream rx_file;
    if(not file.empty()){
	 rx_file.open(file.c_str(), std::ofstream::binary);   
    }

    std::vector<uint32_t> buff(spp);

    // Start streaming	
    uhd::stream_cmd_t stream_cmd(uhd::stream_cmd_t::STREAM_MODE_START_CONTINUOUS);
    stream_cmd.stream_now = true;
    stream_cmd.time_spec = uhd::time_spec_t(15.0);
    std::cout << "Issueing stream cmd" << std::endl;
    rx_stream->issue_stream_cmd(stream_cmd);
    std::cout << "Done" << std::endl;

    std::cout << "Read Samples " << std::endl;
    uhd::rx_metadata_t md;
    bool overflow_message = true;

    total_num_samps = 0;
    do
    {
        size_t num_rx_samps = rx_stream->recv(&buff.front(), spp, md, 13.0);

        if (md.error_code == uhd::rx_metadata_t::ERROR_CODE_TIMEOUT) {
            std::cout << boost::format("Timeout while streaming") << std::endl;
            break;
        }
        if (md.error_code == uhd::rx_metadata_t::ERROR_CODE_OVERFLOW){
            if (overflow_message) {
                overflow_message = false;
                std::cerr << boost::format(
                    "Got an overflow indication. Please consider the following:\n"
                    "  Your write medium must sustain the receive rate.\n"
                    "  Dropped samples will not be written to the file.\n"
                    "  Please modify this example for your purposes.\n"
                    "  This message will not appear again.\n"
                );
            }
            continue;
        }
        if (md.error_code != uhd::rx_metadata_t::ERROR_CODE_NONE){
            std::string error = str(boost::format("Receiver error: %s") % md.strerror());
            if (continue_on_bad_packet){
                std::cerr << error << std::endl;
                continue;
            }
            else
                throw std::runtime_error(error);
        }
	if((num_rx_samps > 0)&&(rx_file.is_open()))
	{
	    rx_file.write((const char*)&buff.front(), num_rx_samps*sizeof(uint32_t));
	}
	total_num_samps += num_rx_samps;

    }while(total_num_samps < num_reqd_samps);
    rx_file.close();

    //std::cout << "Stop signal called" << std::endl;

    stream_cmd.stream_mode = uhd::stream_cmd_t::STREAM_MODE_STOP_CONTINUOUS;
    std::cout << "Issueing stop stream cmd" << std::endl;
    rx_stream->issue_stream_cmd(stream_cmd);
    std::cout << "Done" << std::endl;


    
    return EXIT_SUCCESS;
}
