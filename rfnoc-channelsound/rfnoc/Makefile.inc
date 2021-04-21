# specify all relevant Makefiles to include

RFNOC_CHANNELSOUND_DIR := $(OOT_DIR)
include $(abspath $(RFNOC_CHANNELSOUND_DIR)/fpga-src/Makefile.inc)
include $(abspath $(RFNOC_CHANNELSOUND_DIR)/ip/Makefile.inc)
