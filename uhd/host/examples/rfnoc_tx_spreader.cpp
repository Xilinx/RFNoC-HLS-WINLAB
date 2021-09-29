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
#include <uhd/usrp/multi_usrp.hpp>
#include <uhd/device3.hpp>
#include <uhd/rfnoc/radio_ctrl.hpp>
#include <uhd/rfnoc/source_block_ctrl_base.hpp>
#include <uhd/rfnoc/spreader_block_ctrl.hpp>
#include <uhd/exception.hpp>
#include <boost/program_options.hpp>
#include <boost/format.hpp>
#include <boost/thread.hpp>
#include <iostream>
#include <fstream>
#include <csignal>
#include <complex>
#include <cmath>
#include <ctime>

namespace po = boost::program_options;

static bool stop_signal_called = false;
void sig_int_handler(int){stop_signal_called = true;}


int UHD_SAFE_MAIN(int argc, char *argv[]){
    uhd::set_thread_priority_safe();

    //variables to be set by po
    std::string args, file, format, ant, subdev, ref, wirefmt, streamargs, duc_args, spreader_args, pn_seed, pn_poly;
    size_t total_num_samps, radio_id;
    double freq, gain, setup_time;
    int pn_len;

    //setup the program options
    po::options_description desc("Allowed options");
    desc.add_options()
        ("help", "help message")
        ("nsamps", po::value<size_t>(&total_num_samps)->default_value(2000), "total number of samples to transmit")
        ("args", po::value<std::string>(&args)->default_value("type=x300,skip_ddc,skip_duc"), "USRP device address args")
        ("setup", po::value<double>(&setup_time)->default_value(1.0), "seconds of setup time")
        ("radio-id", po::value<size_t>(&radio_id)->default_value(0), "Radio ID to use (0 or 1).")
        ("freq", po::value<double>(&freq)->default_value(3e9), "RF center frequency in Hz")
        ("gain", po::value<double>(&gain)->default_value(30.0), "gain for the RF chain")
        ("ant", po::value<std::string>(&ant)->default_value("TX/RX"), "antenna selection")
        ("ref", po::value<std::string>(&ref)->default_value("internal"), "reference source (internal, external, mimo)")
        ("PN-length", po::value<int>(&pn_len)->default_value(63), "length of PN Sequence (default = 63)")
	("PN-seed", po::value<std::string>(&pn_seed)->default_value("000001"), "Seed polynomial (default = 000001)")
	("PN-gen-poly", po::value<std::string>(&pn_poly)->default_value("000011"), "Generator polynomial (default = 000011)")
        ("duc-args", po::value<std::string>(&duc_args)->default_value("input_rate=50000000.0,output_rate=200000000.0"), "These args are passed straight to the block.")
        ("streamargs", po::value<std::string>(&streamargs)->default_value(""), "additional stream args")
    ;
    po::variables_map vm;
    po::store(po::parse_command_line(argc, argv, desc), vm);
    po::notify(vm);

    //print the help message
    if (vm.count("help")) {
        std::cout << boost::format("RFNoC Spec Spreader %s") % desc << std::endl;
        std::cout
            << std::endl
            << "This application demonstrates RFNoC based spectrum spreading using PN sequences\n"
            << std::endl;
        return ~0;
    }

    /************************************************************************
     * Create device and block controls
     ***********************************************************************/
    uhd::usrp::multi_usrp::sptr usrp_temp = uhd::usrp::multi_usrp::make(args);
	uhd::device3::sptr usrp = usrp_temp->get_device3();
    // Create handle for radio object
    uhd::rfnoc::block_id_t radio_ctrl_id(0, "Radio", radio_id);
    // This next line will fail if the radio is not actually available
    uhd::rfnoc::radio_ctrl::sptr radio_ctrl = usrp->get_block_ctrl< uhd::rfnoc::radio_ctrl >(radio_ctrl_id);

    /************************************************************************
     * Set up radio
     ***********************************************************************/
    
	//Setting clock reference for the device
    if (vm.count("ref")) {
        usrp_temp->set_clock_source(ref);
    }

    //set the center frequency
    std::cout << boost::format("Setting TX Freq: %f MHz...") % (freq/1e6) << std::endl;
    uhd::tune_request_t tune_request(freq);
    radio_ctrl->set_tx_frequency(freq, radio_id);
    std::cout << boost::format("Actual TX Freq: %f MHz...") % (radio_ctrl->get_tx_frequency(radio_id)/1e6) << std::endl << std::endl;

    //set the rf gain
    if (vm.count("gain")) {
        std::cout << boost::format("Setting TX Gain: %f dB...") % gain << std::endl;
        radio_ctrl->set_tx_gain(gain, radio_id);
        std::cout << boost::format("Actual TX Gain: %f dB...") % radio_ctrl->get_tx_gain(radio_id) << std::endl << std::endl;
    }

    //set the antenna
    if (vm.count("ant")) {
        radio_ctrl->set_tx_antenna(ant, radio_id);
    }
	
    boost::this_thread::sleep(boost::posix_time::milliseconds(long(setup_time*1000))); //allow for some setup time

    /************************************************************************
     * Set up streaming
     ***********************************************************************/
    uhd::device_addr_t streamer_args(streamargs);

    uhd::rfnoc::graph::sptr tx_graph = usrp->create_graph("rfnoc_spreader");
    usrp->clear();
	// Setting the PN sequence properties and connecting the Spreader block
	//----------------------------------------------------------------------
    std::string duc_id("0/DUC_0");
    std::string spreader_id("0/Spreader_0");
    //std::string dmafifo_id("0/DmaFIFO_0");

    uhd::rfnoc::spreader_block_ctrl::sptr spreader_ctrl = usrp->get_block_ctrl<uhd::rfnoc::spreader_block_ctrl>(spreader_id);
    uhd::rfnoc::sink_block_ctrl_base::sptr duc_ctrl = usrp->get_block_ctrl<uhd::rfnoc::sink_block_ctrl_base>(duc_id);
    //uhd::rfnoc::sink_block_ctrl_base::sptr dmafifo_ctrl = usrp->get_block_ctrl<uhd::rfnoc::sink_block_ctrl_base>(dmafifo_id);
    
    duc_ctrl->set_args(uhd::device_addr_t(duc_args));
    spreader_ctrl->set_pn_seq_gen(pn_poly,pn_seed,pn_len);

    std::cout << "RFNOC Flowgraph :" << std::endl;
    std::cout << "Connecting " << duc_ctrl->get_block_id() <<" ==> " << radio_ctrl_id << std::endl;             
    tx_graph->connect(duc_ctrl->get_block_id(), uhd::rfnoc::ANY_PORT, radio_ctrl_id, radio_id);
    //std::cout << "Connecting " << dmafifo_ctrl->get_block_id() << " ==> " <<  duc_ctrl->get_block_id() << std::endl;
    //tx_graph->connect(dmafifo_ctrl->get_block_id(), 0, duc_ctrl->get_block_id(), uhd::rfnoc::ANY_PORT);
    //std::cout << "Connecting " << spreader_ctrl->get_block_id() << " ==> " <<  dmafifo_ctrl->get_block_id() << std::endl;
    //tx_graph->connect(spreader_ctrl->get_block_id(), uhd::rfnoc::ANY_PORT, dmafifo_ctrl->get_block_id(), 0);

    std::cout << "Connecting " << spreader_ctrl->get_block_id() << " ==> " <<  duc_ctrl->get_block_id() << std::endl;
    tx_graph->connect(spreader_ctrl->get_block_id(), uhd::rfnoc::ANY_PORT, duc_ctrl->get_block_id(), uhd::rfnoc::ANY_PORT);

    streamer_args["block_id"] = spreader_ctrl->get_block_id().to_string();
	//----------------------------------------------------------------------
 

    std::cout << std::endl;
    std::cout << "Bandwidth : " << duc_ctrl->get_arg<double>("input_rate") << std::endl;
    //Creating a transmit streamer
    uhd::stream_args_t stream_args("fc32", "sc16"); // We should read the wire format from the blocks
    stream_args.args = streamer_args;
    std::cout << "Using streamer args: " << stream_args.args.to_string() << std::endl;
    uhd::tx_streamer::sptr tx_stream = usrp->get_tx_stream(stream_args);

	//Creating a packet to stream same symbol to the device multiple times
	uhd::tx_metadata_t md;
	std::vector<std::complex<float> > buff(total_num_samps);
	for (int i = 0; i < buff.size(); i++) {
		buff.at(i) = 0.707 + 0.707i;
	}
	
	//Transmit streamer metadata properties
	md.start_of_burst = true;
	md.end_of_burst   = false;
	md.has_time_spec = false;
	std::cout << "Sending samples...\n";
	std::signal(SIGINT, &sig_int_handler);
	std::cout << "Press Ctrl + C to stop streaming..." << std::endl;
	//md.time_spec = usrp->get_time_now();
    while (not stop_signal_called) {
        tx_stream->send(&buff.front(), buff.size(), md);
		//md.start_of_burst = false;
    }

    //finished
    std::cout << std::endl << "Done!" << std::endl << std::endl;

    return EXIT_SUCCESS;
}
