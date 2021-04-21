onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate -divider {NOC_BLOCK_CORRMAG}
add wave -noupdate /noc_block_corrmag63avg8k_tb/noc_block_corrmag63avg8k/*
add wave -noupdate -divider {CORRMAG_TOP}
add wave -noupdate /noc_block_corrmag63avg8k_tb/noc_block_corrmag63avg8k/inst_corrmag_top/*
add wave -noupdate /noc_block_corrmag63avg8k_tb/noc_block_corrmag63avg8k/inst_corrmag_top/data_in_reg
add wave -noupdate /noc_block_corrmag63avg8k_tb/noc_block_corrmag63avg8k/inst_corrmag_top/valid_in_reg
#add wave -noupdate /noc_block_corrmag63avg8k_tb/noc_block_corrmag63avg8k/inst_corrmag_top/new_sample_energy/*
#add wave -noupdate /noc_block_corrmag63avg8k_tb/noc_block_corrmag63avg8k/inst_corrmag_top/old_sample_energy/*
add wave -noupdate /noc_block_corrmag63avg8k_tb/noc_block_corrmag63avg8k/inst_corrmag_top/recv_energy_valid
#add wave -noupdate /noc_block_corrmag63avg8k_tb/noc_block_corrmag63avg8k/inst_corrmag_top/recv_energy_shifted
#add wave -noupdate /noc_block_corrmag63avg8k_tb/noc_block_corrmag63avg8k/inst_corrmag_top/corrmag_reg
add wave -noupdate /noc_block_corrmag63avg8k_tb/noc_block_corrmag63avg8k/inst_corrmag_top/inst_corrmag_avg/*
add wave -noupdate -divider {PNSEQ_CORRELATOR}
add wave -noupdate /noc_block_corrmag63avg8k_tb/noc_block_corrmag63avg8k/inst_corrmag_top/pnseq_correlator_inst/*
