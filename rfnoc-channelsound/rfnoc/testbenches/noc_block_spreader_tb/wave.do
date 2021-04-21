onerror {resume}
quietly WaveActivateNextPane {} 0

add wave -noupdate -divider {noc_block_spreader}
add wave -noupdate /noc_block_spreader_tb/noc_block_spreader/*
add wave -noupdate -divider {spreader}
add wave -noupdate /noc_block_spreader_tb/noc_block_spreader/inst_spreader/*
#add wave -noupdate -divider {storeA}
#add wave -noupdate /noc_block_spreader_tb/noc_block_spreader/inst_spreader/storeA_V_U/*
add wave -noupdate -divider {pn_seq_gen}
add wave -noupdate /noc_block_spreader_tb/noc_block_spreader/inst_pn_seq_gen_lfsr/*
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {4735013 ps} 0}
quietly wave cursor active 1
configure wave -namecolwidth 470
configure wave -valuecolwidth 218
configure wave -justifyvalue left
configure wave -signalnamewidth 0
configure wave -snapdistance 10
configure wave -datasetprefix 0
configure wave -rowmargin 4
configure wave -childrowmargin 2
configure wave -gridoffset 0
configure wave -gridperiod 1
configure wave -griddelta 40
configure wave -timeline 0
configure wave -timelineunits ps
update
WaveRestoreZoom {4117229 ps} {16194911 ps}
set IgnoreFailure 1
set StdArithNoWarnings 1
set NumericStdNoWarnings 1
