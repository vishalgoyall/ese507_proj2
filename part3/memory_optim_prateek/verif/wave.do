onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate /tbench2/dut/m_ready_y
add wave -noupdate /tbench2/dut/m_valid_y
add wave -noupdate /tbench2/dut/m_data_out_y
add wave -noupdate /tbench2/dut/clk
add wave -noupdate /tbench2/dut/reset
add wave -noupdate /tbench2/dut/conv_start
add wave -noupdate /tbench2/dut/conv_done
add wave -noupdate /tbench2/dut/x_mult_f
add wave -noupdate /tbench2/dut/ctrl_inst/s_valid
add wave -noupdate /tbench2/dut/ctrl_inst/conv_start
add wave -noupdate /tbench2/dut/ctrl_inst/m_ready
add wave -noupdate /tbench2/dut/ctrl_inst/xmem_wr_en
add wave -noupdate /tbench2/dut/ctrl_inst/xmem_full
add wave -noupdate /tbench2/dut/ctrl_inst/m_valid
add wave -noupdate /tbench2/dut/ctrl_inst/conv_done
add wave -noupdate /tbench2/dut/ctrl_inst/s_ready
add wave -noupdate /tbench2/dut/ctrl_inst/state
add wave -noupdate -radix unsigned /tbench2/dut/ctrl_inst/xmem_tracker
add wave -noupdate /tbench2/dut/ctrl_inst/s_ready_fsm
add wave -noupdate /tbench2/dut/ctrl_inst/en_cntr
add wave -noupdate -radix unsigned /tbench2/dut/ctrl_inst/X_MEM_ADDR_WIDTH
add wave -noupdate -radix unsigned /tbench2/dut/ctrl_inst/X_SIZE
add wave -noupdate -radix unsigned /tbench2/dut/ctrl_inst/F_SIZE
add wave -noupdate /tbench2/dut/xmem_inst/data_out
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {735 ns} 0}
quietly wave cursor active 1
configure wave -namecolwidth 293
configure wave -valuecolwidth 100
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
configure wave -timelineunits ns
update
WaveRestoreZoom {604 ns} {868 ns}
