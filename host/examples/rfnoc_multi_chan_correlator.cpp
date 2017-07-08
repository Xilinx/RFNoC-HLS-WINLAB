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
#include <uhd/utils/thread_priority.hpp>
#include <uhd/utils/safe_main.hpp>
#include <uhd/device3.hpp>
#include <uhd/usrp/multi_usrp.hpp>
#include <uhd/rfnoc/radio_ctrl.hpp>
#include <uhd/rfnoc/source_block_ctrl_base.hpp>
#include <uhd/rfnoc/correlator_block_ctrl.hpp>
#include <uhd/rfnoc/cir_avg_block_ctrl.hpp>
#include <uhd/exception.hpp>
#include <boost/program_options.hpp>
#include <boost/format.hpp>
#include <boost/foreach.hpp>
#include <boost/thread.hpp>
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

// Receiver streamer function
template<typename samp_type> void recv_to_file(
    uhd::rx_streamer::sptr rx_stream,
    const std::string &file,
    const size_t samps_per_buff,
    const double rx_rate,
    const unsigned long long num_requested_samples,
    double time_requested = 0.0,
    bool continue_on_bad_packet = false,
	int num_usrp = 1,
	int num_chan = 1,
	uhd::usrp::multi_usrp::sptr usrp_temp = 0
){
    unsigned long long num_total_samps = 0;
    uhd::rx_metadata_t md;
	std::vector<std::vector<samp_type> > buff(
        num_usrp*num_chan, std::vector<samp_type>(samps_per_buff)
    );
	std::vector<samp_type *> buff_ptrs;
	for (size_t i = 0; i < buff.size(); i++) buff_ptrs.push_back(&buff[i].front());
    bool overflow_message = true;
	std::ofstream outfile;
	std::string outfilename;

    //setup streaming
    uhd::stream_cmd_t stream_cmd(uhd::stream_cmd_t::STREAM_MODE_START_CONTINUOUS);
    stream_cmd.stream_now = false;
	stream_cmd.time_spec = usrp_temp->get_time_now() + uhd::time_spec_t(1.0);
	double timeout = stream_cmd.time_spec.get_real_secs() + 0.5;
    std::cout << "Issuing stream cmd" << std::endl;
    rx_stream->issue_stream_cmd(stream_cmd);
    std::cout << "Done" << std::endl;
	
	// If want to stream packets for certain duration
    boost::system_time start = boost::get_system_time();
    unsigned long long ticks_requested = (long)(time_requested * (double)boost::posix_time::time_duration::ticks_per_second());
    boost::posix_time::time_duration ticks_diff;
    //boost::system_time last_update = start;
    //unsigned long long last_update_samps = 0;

    while(not stop_signal_called) {
        boost::system_time now = boost::get_system_time();

        size_t num_rx_samps = rx_stream->recv(buff_ptrs, samps_per_buff, md, timeout);
		stream_cmd.stream_now = true;
		timeout = 0.5;
        if (md.error_code == uhd::rx_metadata_t::ERROR_CODE_TIMEOUT) {
            std::cout << boost::format("Timeout while streaming") << std::endl;
            break;
        }
        if (md.error_code == uhd::rx_metadata_t::ERROR_CODE_OVERFLOW){
            if (overflow_message) {
                overflow_message = false;
                std::cerr << boost::format(
                    "Got an overflow indication. Please consider the following:\n"
                    "  Your write medium must sustain a rate of %fMB/s.\n"
                    "  Dropped samples will not be written to the file.\n"
                    "  Please modify this example for your purposes.\n"
                    "  This message will not appear again.\n"
                ) % (rx_rate*sizeof(samp_type)/1e6);
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
		if (num_requested_samples > 0) {
			if (not file.empty()) {
				for (int i = 0; i < num_usrp*num_chan; i++) {
					outfilename = file + "_ch_" + boost::lexical_cast<std::string>(i) + "_binary";
					outfile.open(outfilename.c_str(), std::ofstream::binary);
					outfile.write((const char*)buff_ptrs.at(i), samps_per_buff*sizeof(samp_type));
					if (outfile.is_open()) {
						outfile.close();
					}
				}
			}
			num_total_samps += num_rx_samps;
			if (num_total_samps >= num_rx_samps) {
				break;
			}
		}
        ticks_diff = now - start;
        if (ticks_requested > 0){
            if ((unsigned long long)ticks_diff.ticks() > ticks_requested) {
                break;
			}
        }
    }
    stream_cmd.stream_mode = uhd::stream_cmd_t::STREAM_MODE_STOP_CONTINUOUS;
    std::cout << "Issuing stop stream cmd" << std::endl;
    rx_stream->issue_stream_cmd(stream_cmd);
    std::cout << "Done" << std::endl;
}


int UHD_SAFE_MAIN(int argc, char *argv[]){
    uhd::set_thread_priority_safe();

    //variables to be set by po
    std::string args, file, ant, subdev, ref, streamargs, ddc_args, corr_args, pn_seed, pn_poly, sync, radio_args;
    size_t total_num_samps, spb;
    double rate, freq, gain, bw, total_time, setup_time;
	int pn_len, num_usrp, num_chan, avg, thres;


    //setup the program options
    po::options_description desc("Allowed options");
    desc.add_options()
        ("help", "help message")
        ("file", po::value<std::string>(&file)->default_value("usrp_samples"), "name of the file to write binary samples to")
        ("duration", po::value<double>(&total_time)->default_value(0), "total number of seconds to receive (will stream continuously if set to 0)")
        ("nsamps", po::value<size_t>(&total_num_samps)->default_value(0), "total number of samples to receive (will stream continouosly if set to 0)")
        ("spb", po::value<size_t>(&spb)->default_value(10000), "samples per buffer")
        ("continue", "don't abort on a bad packet")
		("args", po::value<std::string>(&args)->default_value(""), "USRP device address args")
        ("setup", po::value<double>(&setup_time)->default_value(1.0), "seconds of setup time")
		("subdev", po::value<std::string>(&subdev), "subdev spec (homogeneous across motherboards)")
        ("rate", po::value<double>(&rate)->default_value(1e6), "RX rate of the radio block")
        ("freq", po::value<double>(&freq)->default_value(0.0), "RF center frequency in Hz")
        ("gain", po::value<double>(&gain), "gain for the RF chain")
        ("ant", po::value<std::string>(&ant), "antenna selection")
        ("bw", po::value<double>(&bw), "analog frontend filter bandwidth in Hz")
        ("ref", po::value<std::string>(&ref), "reference source (internal, external, mimo)")
        ("sync", po::value<std::string>(&sync)->default_value("now"), "Sync (now (for no sync) or pps)")
		("skip-lo", "skip checking LO lock status")
        ("int-n", "tune USRP with integer-N tuning")
        ("ddc-args", po::value<std::string>(&ddc_args)->default_value(""), "These args are passed straight to the DDC block.")
		("PN-length", po::value<int>(&pn_len)->default_value(255), "length of PN Sequence (default = 255)")
		("PN-seed", po::value<std::string>(&pn_seed)->default_value("00000001"), "Seed polynomial (default = 00000001)")
		("PN-gen-poly", po::value<std::string>(&pn_poly)->default_value("00011101"), "Generator polynomial (default = 00011101)")
		("num-usrp", po::value<int>(&num_usrp)->default_value(1), "number of devices to use")
		("radio-args", po::value<std::string>(&radio_args)->default_value("0"), "Radio args (0, 1, (0,1))")
		("avg", po::value<int>(&avg)->default_value(4), "\"2^avg\" times the correlator output will be averaged")
		("threshold", po::value<int>(&thres)->default_value(0xFFFF), "correlator threshold (peaks below this threshold will not be considered)")
		("streamargs", po::value<std::string>(&streamargs)->default_value(""), "additional stream args")
    ;
    po::variables_map vm;
    po::store(po::parse_command_line(argc, argv, desc), vm);
    po::notify(vm);

    //print the help message
    if (vm.count("help")) {
        std::cout << boost::format("UHD/RFNoC RX samples to file %s") % desc << std::endl;
        std::cout
            << std::endl
            << "This application streams the Channel Impulse Resonse (CIR) output from multiple USRPs based on certain PN sequence.\n"
            << std::endl;
        return ~0;
    }
	
	// Receiver streamer continues even if a bad packet is received
    bool continue_on_bad_packet = vm.count("continue") > 0;

    /************************************************************************
     * Create device and block controls
     ***********************************************************************/
    std::cout << std::endl;
    std::cout << boost::format("Creating the USRP device with: %s...") % args << std::endl;
	std::vector<uhd::rfnoc::radio_ctrl::sptr> radio_ctrl_vector;
	//Creating multi-usrp pointer to handle control of multiple channels and converting to device3 pointer to give RFNoC graph commands
	uhd::usrp::multi_usrp::sptr usrp_temp = uhd::usrp::multi_usrp::make(args);
	uhd::device3::sptr usrp = usrp_temp->get_device3();
	
    std::vector<std::string> radio_arg_vec;
	boost::split(radio_arg_vec, radio_args, boost::is_any_of("\"',"));
	num_chan = radio_arg_vec.size();
	if (num_chan > 2 or num_chan < 1) {
		std::cout << "Radio arguments should be 0,1,or (0,1)..." << std::endl;
		return ~0;
	}
	
	for (int i = 0; i < num_usrp; i++) {
		for (int ch = 0; ch < num_chan; ch++) {
			uhd::rfnoc::block_id_t radio_ctrl_id(i, "Radio", boost::lexical_cast<int>(radio_arg_vec[ch]));
			// This next line will fail if the radio is not actually available
			radio_ctrl_vector.push_back(usrp->get_block_ctrl< uhd::rfnoc::radio_ctrl >(radio_ctrl_id));
			std::cout << "Using radio " << i << ", channel " << radio_arg_vec[ch] << std::endl;
		}
	}
	
	//Set clock reference for all devices
    if (vm.count("ref")) {
        usrp_temp->set_clock_source(ref);
    }
	
	
	for (int i = 0; i < num_usrp*num_chan; ++i) {
		// Set center frequency for all rx chains
		if (vm.count("freq")) {
			std::cout << boost::format("Setting RX Freq: %f MHz...") % (freq/1e6) << std::endl;
			uhd::tune_request_t tune_request(freq);
			if (vm.count("int-n")) {
				tune_request.args = uhd::device_addr_t("mode_n=integer");
			}
			usrp_temp->set_rx_freq(freq, i);
			std::cout << boost::format("Actual RX Freq: %f MHz...") % (usrp_temp->get_rx_freq(i)/1e6) << std::endl << std::endl;
		}

		// Set the RF gain
		if (vm.count("gain")) {
			std::cout << boost::format("Setting RX Gain: %f dB...") % gain << std::endl;
			usrp_temp->set_rx_gain(gain, i);
			std::cout << boost::format("Actual RX Gain: %f dB...") % usrp_temp->get_rx_gain(i) << std::endl << std::endl;
		}

		//set the IF filter bandwidth
		if (vm.count("bw")) {
			std::cout << boost::format("Setting RX Bandwidth: %f MHz...") % (bw/1e6) << std::endl;
			usrp_temp->set_rx_bandwidth(bw, i);
			std::cout << boost::format("Actual RX Bandwidth: %f MHz...") % (usrp_temp->get_rx_bandwidth(i)/1e6) << std::endl << std::endl;
		}

		// Set the antenna
		if (vm.count("ant")) {
			usrp_temp->set_rx_antenna(ant, i);
		}
	}
    boost::this_thread::sleep(boost::posix_time::milliseconds(long(setup_time*1000))); //allow for some setup time
	
	if (sync == "now") {
			usrp_temp->set_time_now(uhd::time_spec_t(0.0));
	}
	else if (sync == "pps") {
		usrp_temp->set_time_source("external");
		usrp_temp->set_time_unknown_pps(uhd::time_spec_t(0.0));
		boost::this_thread::sleep(boost::posix_time::seconds(2)); //wait for pps sync pulse
	}
    /************************************************************************
     * Set up streaming
     ***********************************************************************/
	
	
	uhd::device_addr_t streamer_args(streamargs);
	uhd::rx_streamer::sptr rx_stream;
	uhd::rfnoc::graph::sptr rx_graph;
	uhd::rfnoc::source_block_ctrl_base::sptr ddc_ctrl;
	uhd::rfnoc::correlator_block_ctrl::sptr corr_ctrl;
	uhd::rfnoc::cir_avg_block_ctrl::sptr cir_avg_ctrl;
	rx_graph = usrp->create_graph("rfnoc_corr_rx_to_file");
	usrp->clear();

	for (size_t i = 0; i < num_usrp; i++) {
		for (int ch = 0; ch < num_chan; ch++) {
			uhd::rfnoc::block_id_t radio_ctrl_id(i, "Radio", boost::lexical_cast<int>(radio_arg_vec[ch]));
			std::string ddc_id(boost::lexical_cast<std::string>(i)+"/DDC_"+radio_arg_vec[ch]);
			std::string corr_id(boost::lexical_cast<std::string>(i)+"/Correlator_"+radio_arg_vec[ch]);
			std::string cir_avg_id(boost::lexical_cast<std::string>(i)+"/CIRAvg_"+radio_arg_vec[ch]);
			ddc_ctrl = usrp->get_block_ctrl<uhd::rfnoc::source_block_ctrl_base>(ddc_id);
			corr_ctrl = usrp->get_block_ctrl<uhd::rfnoc::correlator_block_ctrl>(corr_id);
			cir_avg_ctrl = usrp->get_block_ctrl<uhd::rfnoc::cir_avg_block_ctrl>(cir_avg_id);

			ddc_ctrl->set_args(uhd::device_addr_t(ddc_args));
			corr_ctrl->set_pn_seq_gen(pn_poly,pn_seed,pn_len);
			cir_avg_ctrl->set_cir_avg(thres, avg, pn_len);
			std::cout << "Connecting " << radio_ctrl_id << " ==> " << ddc_ctrl->get_block_id() << std::endl;    
			rx_graph->connect(radio_ctrl_id, ch, ddc_ctrl->get_block_id(), uhd::rfnoc::ANY_PORT);
			std::cout << "Connecting " << ddc_ctrl->get_block_id() << " ==> " << corr_ctrl->get_block_id() << std::endl;
			rx_graph->connect(ddc_ctrl->get_block_id(), uhd::rfnoc::ANY_PORT, corr_ctrl->get_block_id(), uhd::rfnoc::ANY_PORT);
			std::cout << "Connecting " << corr_ctrl->get_block_id() << " ==> " << cir_avg_ctrl->get_block_id() << std::endl;
			rx_graph->connect(corr_ctrl->get_block_id(), uhd::rfnoc::ANY_PORT, cir_avg_ctrl->get_block_id(), uhd::rfnoc::ANY_PORT);
			streamer_args["block_id"+boost::lexical_cast<std::string>(ch + i*num_chan)] = cir_avg_id;
		}
	}

	
    //create a receive streamer
	//Setting the samples per packet for streaming
    size_t spp = pn_len;
	UHD_MSG(status) << "Samples per packet: " << spp << std::endl;
    uhd::stream_args_t stream_args("sc16", "sc16"); // We should read the wire format from the blocks
    stream_args.args = streamer_args;
    stream_args.args["spp"] = boost::lexical_cast<std::string>(spp);
	std::vector<size_t> usrp_nums;
	for (int i = 0; i < num_usrp*num_chan; i++) {
		usrp_nums.push_back(i);
	}
	stream_args.channels = usrp_nums;
    UHD_MSG(status) << "Using streamer args: " << stream_args.args.to_string() << std::endl;
    rx_stream = usrp->get_rx_stream(stream_args);

    if (total_num_samps == 0) {
        std::signal(SIGINT, &sig_int_handler);
        std::cout << "Press Ctrl + C to stop streaming..." << std::endl;
    }
#define recv_to_file_args() \
    (rx_stream, file, spb, rate, total_num_samps, total_time, continue_on_bad_packet, num_usrp, num_chan, usrp_temp)
    //recv to file
	recv_to_file<std::complex<short> >recv_to_file_args();
    //finished
    std::cout << std::endl << "Done!" << std::endl << std::endl;

    return EXIT_SUCCESS;
}
