set_property SRC_FILE_INFO {cfile:e:/Projects/Hardware/gba-io/reference/Aritx7/FPGA/100T/microblaze_ddr_100t/microblaze_ddr_100t.gen/sources_1/bd/bd_top/ip/bd_top_clk_wiz_1_0/bd_top_clk_wiz_1_0.xdc rfile:../../../microblaze_ddr_100t.gen/sources_1/bd/bd_top/ip/bd_top_clk_wiz_1_0/bd_top_clk_wiz_1_0.xdc id:1 order:EARLY scoped_inst:inst} [current_design]
current_instance inst
set_property src_info {type:SCOPED_XDC file:1 line:54 export:INPUT save:INPUT read:READ} [current_design]
set_input_jitter [get_clocks -of_objects [get_ports clk_in1]] 0.100
