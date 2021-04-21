#############################################
# RFNoC Sources
#############################################

RFNOC_SRCS += $(addprefix $(RFNOC_CHANNELSOUND_DIR)/fpga-src/, \
Corrmag63avg8k/noc_block_corrmag63avg8k.v \
Corrmag63avg8k/corrmag63avg8k_top.v \
Corrmag63avg8k/pnseq_correlator63.v \
Spreader/noc_block_spreader.v \
Spreader/spreader.v \
Spreader/FIFO_spreader_data_fifo_V_V.v \
Spreader/pn_seq_gen_lfsr.v \
)
