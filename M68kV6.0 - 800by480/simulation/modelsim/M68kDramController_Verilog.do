onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate /tb_M68kDramController_Verilog/Clock
add wave -noupdate /tb_M68kDramController_Verilog/dut/CurrentState
add wave -noupdate /tb_M68kDramController_Verilog/dut/NextState
add wave -noupdate /tb_M68kDramController_Verilog/dut/CPUReset_L
add wave -noupdate /tb_M68kDramController_Verilog/dut/ResetOut_L
add wave -noupdate /tb_M68kDramController_Verilog/dut/TimerValue
add wave -noupdate /tb_M68kDramController_Verilog/dut/Timer
add wave -noupdate /tb_M68kDramController_Verilog/dut/initflag
add wave -noupdate /tb_M68kDramController_Verilog/dut/Reset_L
add wave -noupdate /tb_M68kDramController_Verilog/dut/SDram_CS_L
add wave -noupdate /tb_M68kDramController_Verilog/dut/SDram_WE_L
add wave -noupdate /tb_M68kDramController_Verilog/dut/SDram_RAS_L
add wave -noupdate /tb_M68kDramController_Verilog/dut/SDram_CAS_L
add wave -noupdate /tb_M68kDramController_Verilog/dut/SDram_CKE_H
add wave -noupdate /tb_M68kDramController_Verilog/dut/TimerDone_H
add wave -noupdate /tb_M68kDramController_Verilog/dut/TimerLoad_H
add wave -noupdate /tb_M68kDramController_Verilog/dut/count
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {1200 ns} 0}
quietly wave cursor active 1
configure wave -namecolwidth 150
configure wave -valuecolwidth 149
configure wave -justifyvalue left
configure wave -signalnamewidth 1
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
WaveRestoreZoom {1060 ns} {1220 ns}
