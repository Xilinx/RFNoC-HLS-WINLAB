./rfnoc_tx_spreader --args="addr=<tx n310 ip addr>,type=n3xx,skip_ddc,skip_duc" --duc-args="input_rate=31250000.0,output_rate=125000000.0" --nsamps 200 --gain 50
./rfnoc_rx_channel_sounder --args="addr=<rx n310 ip addr>,type=n3xx,skip_ddc,skip_duc" --gain 40 --freq 3e9 --ddc-args="input_rate=125000000.0,output_rate=31250000.0"

