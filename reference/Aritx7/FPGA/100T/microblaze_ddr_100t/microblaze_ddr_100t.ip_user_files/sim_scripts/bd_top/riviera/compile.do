transcript off
onbreak {quit -force}
onerror {quit -force}
transcript on

vlib work
vlib riviera/xpm
vlib riviera/microblaze_v11_0_13
vlib riviera/xil_defaultlib
vlib riviera/lmb_v10_v3_0_14
vlib riviera/lmb_bram_if_cntlr_v4_0_24
vlib riviera/blk_mem_gen_v8_4_8
vlib riviera/axi_lite_ipif_v3_0_4
vlib riviera/mdm_v3_2_26
vlib riviera/lib_cdc_v1_0_3
vlib riviera/proc_sys_reset_v5_0_15
vlib riviera/lib_pkg_v1_0_4
vlib riviera/lib_srl_fifo_v1_0_4
vlib riviera/axi_uartlite_v2_0_35
vlib riviera/generic_baseblocks_v2_1_2
vlib riviera/axi_infrastructure_v1_1_0
vlib riviera/axi_register_slice_v2_1_31
vlib riviera/fifo_generator_v13_2_10
vlib riviera/axi_data_fifo_v2_1_30
vlib riviera/axi_crossbar_v2_1_32
vlib riviera/axi_protocol_converter_v2_1_31
vlib riviera/axi_clock_converter_v2_1_30
vlib riviera/axi_dwidth_converter_v2_1_31

vmap xpm riviera/xpm
vmap microblaze_v11_0_13 riviera/microblaze_v11_0_13
vmap xil_defaultlib riviera/xil_defaultlib
vmap lmb_v10_v3_0_14 riviera/lmb_v10_v3_0_14
vmap lmb_bram_if_cntlr_v4_0_24 riviera/lmb_bram_if_cntlr_v4_0_24
vmap blk_mem_gen_v8_4_8 riviera/blk_mem_gen_v8_4_8
vmap axi_lite_ipif_v3_0_4 riviera/axi_lite_ipif_v3_0_4
vmap mdm_v3_2_26 riviera/mdm_v3_2_26
vmap lib_cdc_v1_0_3 riviera/lib_cdc_v1_0_3
vmap proc_sys_reset_v5_0_15 riviera/proc_sys_reset_v5_0_15
vmap lib_pkg_v1_0_4 riviera/lib_pkg_v1_0_4
vmap lib_srl_fifo_v1_0_4 riviera/lib_srl_fifo_v1_0_4
vmap axi_uartlite_v2_0_35 riviera/axi_uartlite_v2_0_35
vmap generic_baseblocks_v2_1_2 riviera/generic_baseblocks_v2_1_2
vmap axi_infrastructure_v1_1_0 riviera/axi_infrastructure_v1_1_0
vmap axi_register_slice_v2_1_31 riviera/axi_register_slice_v2_1_31
vmap fifo_generator_v13_2_10 riviera/fifo_generator_v13_2_10
vmap axi_data_fifo_v2_1_30 riviera/axi_data_fifo_v2_1_30
vmap axi_crossbar_v2_1_32 riviera/axi_crossbar_v2_1_32
vmap axi_protocol_converter_v2_1_31 riviera/axi_protocol_converter_v2_1_31
vmap axi_clock_converter_v2_1_30 riviera/axi_clock_converter_v2_1_30
vmap axi_dwidth_converter_v2_1_31 riviera/axi_dwidth_converter_v2_1_31

vlog -work xpm  -incr "+incdir+../../../../microblaze_ddr_100t.gen/sources_1/bd/bd_top/ipshared/3242" "+incdir+../../../../microblaze_ddr_100t.gen/sources_1/bd/bd_top/ipshared/ec67/hdl" -l xpm -l microblaze_v11_0_13 -l xil_defaultlib -l lmb_v10_v3_0_14 -l lmb_bram_if_cntlr_v4_0_24 -l blk_mem_gen_v8_4_8 -l axi_lite_ipif_v3_0_4 -l mdm_v3_2_26 -l lib_cdc_v1_0_3 -l proc_sys_reset_v5_0_15 -l lib_pkg_v1_0_4 -l lib_srl_fifo_v1_0_4 -l axi_uartlite_v2_0_35 -l generic_baseblocks_v2_1_2 -l axi_infrastructure_v1_1_0 -l axi_register_slice_v2_1_31 -l fifo_generator_v13_2_10 -l axi_data_fifo_v2_1_30 -l axi_crossbar_v2_1_32 -l axi_protocol_converter_v2_1_31 -l axi_clock_converter_v2_1_30 -l axi_dwidth_converter_v2_1_31 \
"E:/ProgramTools/Xilinx/Vivado/2024.1/data/ip/xpm/xpm_cdc/hdl/xpm_cdc.sv" \
"E:/ProgramTools/Xilinx/Vivado/2024.1/data/ip/xpm/xpm_memory/hdl/xpm_memory.sv" \

vcom -work xpm -93  -incr \
"E:/ProgramTools/Xilinx/Vivado/2024.1/data/ip/xpm/xpm_VCOMP.vhd" \

vcom -work microblaze_v11_0_13 -93  -incr \
"../../../../microblaze_ddr_100t.gen/sources_1/bd/bd_top/ipshared/aa1c/hdl/microblaze_v11_0_vh_rfs.vhd" \

vcom -work xil_defaultlib -93  -incr \
"../../../bd/bd_top/ip/bd_top_microblaze_0_0/sim/bd_top_microblaze_0_0.vhd" \

vcom -work lmb_v10_v3_0_14 -93  -incr \
"../../../../microblaze_ddr_100t.gen/sources_1/bd/bd_top/ipshared/7495/hdl/lmb_v10_v3_0_vh_rfs.vhd" \

vcom -work xil_defaultlib -93  -incr \
"../../../bd/bd_top/ip/bd_top_dlmb_v10_0/sim/bd_top_dlmb_v10_0.vhd" \
"../../../bd/bd_top/ip/bd_top_ilmb_v10_0/sim/bd_top_ilmb_v10_0.vhd" \

vcom -work lmb_bram_if_cntlr_v4_0_24 -93  -incr \
"../../../../microblaze_ddr_100t.gen/sources_1/bd/bd_top/ipshared/3eb2/hdl/lmb_bram_if_cntlr_v4_0_vh_rfs.vhd" \

vcom -work xil_defaultlib -93  -incr \
"../../../bd/bd_top/ip/bd_top_dlmb_bram_if_cntlr_0/sim/bd_top_dlmb_bram_if_cntlr_0.vhd" \
"../../../bd/bd_top/ip/bd_top_ilmb_bram_if_cntlr_0/sim/bd_top_ilmb_bram_if_cntlr_0.vhd" \

vlog -work blk_mem_gen_v8_4_8  -incr -v2k5 "+incdir+../../../../microblaze_ddr_100t.gen/sources_1/bd/bd_top/ipshared/3242" "+incdir+../../../../microblaze_ddr_100t.gen/sources_1/bd/bd_top/ipshared/ec67/hdl" -l xpm -l microblaze_v11_0_13 -l xil_defaultlib -l lmb_v10_v3_0_14 -l lmb_bram_if_cntlr_v4_0_24 -l blk_mem_gen_v8_4_8 -l axi_lite_ipif_v3_0_4 -l mdm_v3_2_26 -l lib_cdc_v1_0_3 -l proc_sys_reset_v5_0_15 -l lib_pkg_v1_0_4 -l lib_srl_fifo_v1_0_4 -l axi_uartlite_v2_0_35 -l generic_baseblocks_v2_1_2 -l axi_infrastructure_v1_1_0 -l axi_register_slice_v2_1_31 -l fifo_generator_v13_2_10 -l axi_data_fifo_v2_1_30 -l axi_crossbar_v2_1_32 -l axi_protocol_converter_v2_1_31 -l axi_clock_converter_v2_1_30 -l axi_dwidth_converter_v2_1_31 \
"../../../../microblaze_ddr_100t.gen/sources_1/bd/bd_top/ipshared/09bd/simulation/blk_mem_gen_v8_4.v" \

vlog -work xil_defaultlib  -incr -v2k5 "+incdir+../../../../microblaze_ddr_100t.gen/sources_1/bd/bd_top/ipshared/3242" "+incdir+../../../../microblaze_ddr_100t.gen/sources_1/bd/bd_top/ipshared/ec67/hdl" -l xpm -l microblaze_v11_0_13 -l xil_defaultlib -l lmb_v10_v3_0_14 -l lmb_bram_if_cntlr_v4_0_24 -l blk_mem_gen_v8_4_8 -l axi_lite_ipif_v3_0_4 -l mdm_v3_2_26 -l lib_cdc_v1_0_3 -l proc_sys_reset_v5_0_15 -l lib_pkg_v1_0_4 -l lib_srl_fifo_v1_0_4 -l axi_uartlite_v2_0_35 -l generic_baseblocks_v2_1_2 -l axi_infrastructure_v1_1_0 -l axi_register_slice_v2_1_31 -l fifo_generator_v13_2_10 -l axi_data_fifo_v2_1_30 -l axi_crossbar_v2_1_32 -l axi_protocol_converter_v2_1_31 -l axi_clock_converter_v2_1_30 -l axi_dwidth_converter_v2_1_31 \
"../../../bd/bd_top/ip/bd_top_lmb_bram_0/sim/bd_top_lmb_bram_0.v" \

vcom -work axi_lite_ipif_v3_0_4 -93  -incr \
"../../../../microblaze_ddr_100t.gen/sources_1/bd/bd_top/ipshared/66ea/hdl/axi_lite_ipif_v3_0_vh_rfs.vhd" \

vcom -work mdm_v3_2_26 -93  -incr \
"../../../../microblaze_ddr_100t.gen/sources_1/bd/bd_top/ipshared/feb7/hdl/mdm_v3_2_vh_rfs.vhd" \

vcom -work xil_defaultlib -93  -incr \
"../../../bd/bd_top/ip/bd_top_mdm_1_0/sim/bd_top_mdm_1_0.vhd" \

vlog -work xil_defaultlib  -incr -v2k5 "+incdir+../../../../microblaze_ddr_100t.gen/sources_1/bd/bd_top/ipshared/3242" "+incdir+../../../../microblaze_ddr_100t.gen/sources_1/bd/bd_top/ipshared/ec67/hdl" -l xpm -l microblaze_v11_0_13 -l xil_defaultlib -l lmb_v10_v3_0_14 -l lmb_bram_if_cntlr_v4_0_24 -l blk_mem_gen_v8_4_8 -l axi_lite_ipif_v3_0_4 -l mdm_v3_2_26 -l lib_cdc_v1_0_3 -l proc_sys_reset_v5_0_15 -l lib_pkg_v1_0_4 -l lib_srl_fifo_v1_0_4 -l axi_uartlite_v2_0_35 -l generic_baseblocks_v2_1_2 -l axi_infrastructure_v1_1_0 -l axi_register_slice_v2_1_31 -l fifo_generator_v13_2_10 -l axi_data_fifo_v2_1_30 -l axi_crossbar_v2_1_32 -l axi_protocol_converter_v2_1_31 -l axi_clock_converter_v2_1_30 -l axi_dwidth_converter_v2_1_31 \
"../../../bd/bd_top/ip/bd_top_clk_wiz_1_0/bd_top_clk_wiz_1_0_clk_wiz.v" \
"../../../bd/bd_top/ip/bd_top_clk_wiz_1_0/bd_top_clk_wiz_1_0.v" \

vcom -work lib_cdc_v1_0_3 -93  -incr \
"../../../../microblaze_ddr_100t.gen/sources_1/bd/bd_top/ipshared/2a4f/hdl/lib_cdc_v1_0_rfs.vhd" \

vcom -work proc_sys_reset_v5_0_15 -93  -incr \
"../../../../microblaze_ddr_100t.gen/sources_1/bd/bd_top/ipshared/3a26/hdl/proc_sys_reset_v5_0_vh_rfs.vhd" \

vcom -work xil_defaultlib -93  -incr \
"../../../bd/bd_top/ip/bd_top_rst_clk_wiz_1_100M_0/sim/bd_top_rst_clk_wiz_1_100M_0.vhd" \

vcom -work lib_pkg_v1_0_4 -93  -incr \
"../../../../microblaze_ddr_100t.gen/sources_1/bd/bd_top/ipshared/8c68/hdl/lib_pkg_v1_0_rfs.vhd" \

vcom -work lib_srl_fifo_v1_0_4 -93  -incr \
"../../../../microblaze_ddr_100t.gen/sources_1/bd/bd_top/ipshared/1e5a/hdl/lib_srl_fifo_v1_0_rfs.vhd" \

vcom -work axi_uartlite_v2_0_35 -93  -incr \
"../../../../microblaze_ddr_100t.gen/sources_1/bd/bd_top/ipshared/2959/hdl/axi_uartlite_v2_0_vh_rfs.vhd" \

vcom -work xil_defaultlib -93  -incr \
"../../../bd/bd_top/ip/bd_top_axi_uartlite_0_0/sim/bd_top_axi_uartlite_0_0.vhd" \

vlog -work xil_defaultlib  -incr -v2k5 "+incdir+../../../../microblaze_ddr_100t.gen/sources_1/bd/bd_top/ipshared/3242" "+incdir+../../../../microblaze_ddr_100t.gen/sources_1/bd/bd_top/ipshared/ec67/hdl" -l xpm -l microblaze_v11_0_13 -l xil_defaultlib -l lmb_v10_v3_0_14 -l lmb_bram_if_cntlr_v4_0_24 -l blk_mem_gen_v8_4_8 -l axi_lite_ipif_v3_0_4 -l mdm_v3_2_26 -l lib_cdc_v1_0_3 -l proc_sys_reset_v5_0_15 -l lib_pkg_v1_0_4 -l lib_srl_fifo_v1_0_4 -l axi_uartlite_v2_0_35 -l generic_baseblocks_v2_1_2 -l axi_infrastructure_v1_1_0 -l axi_register_slice_v2_1_31 -l fifo_generator_v13_2_10 -l axi_data_fifo_v2_1_30 -l axi_crossbar_v2_1_32 -l axi_protocol_converter_v2_1_31 -l axi_clock_converter_v2_1_30 -l axi_dwidth_converter_v2_1_31 \
"../../../bd/bd_top/ip/bd_top_mig_7series_0_0/bd_top_mig_7series_0_0/user_design/rtl/axi/mig_7series_v4_2_axi_ctrl_addr_decode.v" \
"../../../bd/bd_top/ip/bd_top_mig_7series_0_0/bd_top_mig_7series_0_0/user_design/rtl/axi/mig_7series_v4_2_axi_ctrl_read.v" \
"../../../bd/bd_top/ip/bd_top_mig_7series_0_0/bd_top_mig_7series_0_0/user_design/rtl/axi/mig_7series_v4_2_axi_ctrl_reg.v" \
"../../../bd/bd_top/ip/bd_top_mig_7series_0_0/bd_top_mig_7series_0_0/user_design/rtl/axi/mig_7series_v4_2_axi_ctrl_reg_bank.v" \
"../../../bd/bd_top/ip/bd_top_mig_7series_0_0/bd_top_mig_7series_0_0/user_design/rtl/axi/mig_7series_v4_2_axi_ctrl_top.v" \
"../../../bd/bd_top/ip/bd_top_mig_7series_0_0/bd_top_mig_7series_0_0/user_design/rtl/axi/mig_7series_v4_2_axi_ctrl_write.v" \
"../../../bd/bd_top/ip/bd_top_mig_7series_0_0/bd_top_mig_7series_0_0/user_design/rtl/axi/mig_7series_v4_2_axi_mc.v" \
"../../../bd/bd_top/ip/bd_top_mig_7series_0_0/bd_top_mig_7series_0_0/user_design/rtl/axi/mig_7series_v4_2_axi_mc_ar_channel.v" \
"../../../bd/bd_top/ip/bd_top_mig_7series_0_0/bd_top_mig_7series_0_0/user_design/rtl/axi/mig_7series_v4_2_axi_mc_aw_channel.v" \
"../../../bd/bd_top/ip/bd_top_mig_7series_0_0/bd_top_mig_7series_0_0/user_design/rtl/axi/mig_7series_v4_2_axi_mc_b_channel.v" \
"../../../bd/bd_top/ip/bd_top_mig_7series_0_0/bd_top_mig_7series_0_0/user_design/rtl/axi/mig_7series_v4_2_axi_mc_cmd_arbiter.v" \
"../../../bd/bd_top/ip/bd_top_mig_7series_0_0/bd_top_mig_7series_0_0/user_design/rtl/axi/mig_7series_v4_2_axi_mc_cmd_fsm.v" \
"../../../bd/bd_top/ip/bd_top_mig_7series_0_0/bd_top_mig_7series_0_0/user_design/rtl/axi/mig_7series_v4_2_axi_mc_cmd_translator.v" \
"../../../bd/bd_top/ip/bd_top_mig_7series_0_0/bd_top_mig_7series_0_0/user_design/rtl/axi/mig_7series_v4_2_axi_mc_fifo.v" \
"../../../bd/bd_top/ip/bd_top_mig_7series_0_0/bd_top_mig_7series_0_0/user_design/rtl/axi/mig_7series_v4_2_axi_mc_incr_cmd.v" \
"../../../bd/bd_top/ip/bd_top_mig_7series_0_0/bd_top_mig_7series_0_0/user_design/rtl/axi/mig_7series_v4_2_axi_mc_r_channel.v" \
"../../../bd/bd_top/ip/bd_top_mig_7series_0_0/bd_top_mig_7series_0_0/user_design/rtl/axi/mig_7series_v4_2_axi_mc_simple_fifo.v" \
"../../../bd/bd_top/ip/bd_top_mig_7series_0_0/bd_top_mig_7series_0_0/user_design/rtl/axi/mig_7series_v4_2_axi_mc_wrap_cmd.v" \
"../../../bd/bd_top/ip/bd_top_mig_7series_0_0/bd_top_mig_7series_0_0/user_design/rtl/axi/mig_7series_v4_2_axi_mc_wr_cmd_fsm.v" \
"../../../bd/bd_top/ip/bd_top_mig_7series_0_0/bd_top_mig_7series_0_0/user_design/rtl/axi/mig_7series_v4_2_axi_mc_w_channel.v" \
"../../../bd/bd_top/ip/bd_top_mig_7series_0_0/bd_top_mig_7series_0_0/user_design/rtl/axi/mig_7series_v4_2_ddr_axic_register_slice.v" \
"../../../bd/bd_top/ip/bd_top_mig_7series_0_0/bd_top_mig_7series_0_0/user_design/rtl/axi/mig_7series_v4_2_ddr_axi_register_slice.v" \
"../../../bd/bd_top/ip/bd_top_mig_7series_0_0/bd_top_mig_7series_0_0/user_design/rtl/axi/mig_7series_v4_2_ddr_axi_upsizer.v" \
"../../../bd/bd_top/ip/bd_top_mig_7series_0_0/bd_top_mig_7series_0_0/user_design/rtl/axi/mig_7series_v4_2_ddr_a_upsizer.v" \
"../../../bd/bd_top/ip/bd_top_mig_7series_0_0/bd_top_mig_7series_0_0/user_design/rtl/axi/mig_7series_v4_2_ddr_carry_and.v" \
"../../../bd/bd_top/ip/bd_top_mig_7series_0_0/bd_top_mig_7series_0_0/user_design/rtl/axi/mig_7series_v4_2_ddr_carry_latch_and.v" \
"../../../bd/bd_top/ip/bd_top_mig_7series_0_0/bd_top_mig_7series_0_0/user_design/rtl/axi/mig_7series_v4_2_ddr_carry_latch_or.v" \
"../../../bd/bd_top/ip/bd_top_mig_7series_0_0/bd_top_mig_7series_0_0/user_design/rtl/axi/mig_7series_v4_2_ddr_carry_or.v" \
"../../../bd/bd_top/ip/bd_top_mig_7series_0_0/bd_top_mig_7series_0_0/user_design/rtl/axi/mig_7series_v4_2_ddr_command_fifo.v" \
"../../../bd/bd_top/ip/bd_top_mig_7series_0_0/bd_top_mig_7series_0_0/user_design/rtl/axi/mig_7series_v4_2_ddr_comparator.v" \
"../../../bd/bd_top/ip/bd_top_mig_7series_0_0/bd_top_mig_7series_0_0/user_design/rtl/axi/mig_7series_v4_2_ddr_comparator_sel.v" \
"../../../bd/bd_top/ip/bd_top_mig_7series_0_0/bd_top_mig_7series_0_0/user_design/rtl/axi/mig_7series_v4_2_ddr_comparator_sel_static.v" \
"../../../bd/bd_top/ip/bd_top_mig_7series_0_0/bd_top_mig_7series_0_0/user_design/rtl/axi/mig_7series_v4_2_ddr_r_upsizer.v" \
"../../../bd/bd_top/ip/bd_top_mig_7series_0_0/bd_top_mig_7series_0_0/user_design/rtl/axi/mig_7series_v4_2_ddr_w_upsizer.v" \
"../../../bd/bd_top/ip/bd_top_mig_7series_0_0/bd_top_mig_7series_0_0/user_design/rtl/clocking/mig_7series_v4_2_clk_ibuf.v" \
"../../../bd/bd_top/ip/bd_top_mig_7series_0_0/bd_top_mig_7series_0_0/user_design/rtl/clocking/mig_7series_v4_2_infrastructure.v" \
"../../../bd/bd_top/ip/bd_top_mig_7series_0_0/bd_top_mig_7series_0_0/user_design/rtl/clocking/mig_7series_v4_2_iodelay_ctrl.v" \
"../../../bd/bd_top/ip/bd_top_mig_7series_0_0/bd_top_mig_7series_0_0/user_design/rtl/clocking/mig_7series_v4_2_tempmon.v" \
"../../../bd/bd_top/ip/bd_top_mig_7series_0_0/bd_top_mig_7series_0_0/user_design/rtl/controller/mig_7series_v4_2_arb_mux.v" \
"../../../bd/bd_top/ip/bd_top_mig_7series_0_0/bd_top_mig_7series_0_0/user_design/rtl/controller/mig_7series_v4_2_arb_row_col.v" \
"../../../bd/bd_top/ip/bd_top_mig_7series_0_0/bd_top_mig_7series_0_0/user_design/rtl/controller/mig_7series_v4_2_arb_select.v" \
"../../../bd/bd_top/ip/bd_top_mig_7series_0_0/bd_top_mig_7series_0_0/user_design/rtl/controller/mig_7series_v4_2_bank_cntrl.v" \
"../../../bd/bd_top/ip/bd_top_mig_7series_0_0/bd_top_mig_7series_0_0/user_design/rtl/controller/mig_7series_v4_2_bank_common.v" \
"../../../bd/bd_top/ip/bd_top_mig_7series_0_0/bd_top_mig_7series_0_0/user_design/rtl/controller/mig_7series_v4_2_bank_compare.v" \
"../../../bd/bd_top/ip/bd_top_mig_7series_0_0/bd_top_mig_7series_0_0/user_design/rtl/controller/mig_7series_v4_2_bank_mach.v" \
"../../../bd/bd_top/ip/bd_top_mig_7series_0_0/bd_top_mig_7series_0_0/user_design/rtl/controller/mig_7series_v4_2_bank_queue.v" \
"../../../bd/bd_top/ip/bd_top_mig_7series_0_0/bd_top_mig_7series_0_0/user_design/rtl/controller/mig_7series_v4_2_bank_state.v" \
"../../../bd/bd_top/ip/bd_top_mig_7series_0_0/bd_top_mig_7series_0_0/user_design/rtl/controller/mig_7series_v4_2_col_mach.v" \
"../../../bd/bd_top/ip/bd_top_mig_7series_0_0/bd_top_mig_7series_0_0/user_design/rtl/controller/mig_7series_v4_2_mc.v" \
"../../../bd/bd_top/ip/bd_top_mig_7series_0_0/bd_top_mig_7series_0_0/user_design/rtl/controller/mig_7series_v4_2_rank_cntrl.v" \
"../../../bd/bd_top/ip/bd_top_mig_7series_0_0/bd_top_mig_7series_0_0/user_design/rtl/controller/mig_7series_v4_2_rank_common.v" \
"../../../bd/bd_top/ip/bd_top_mig_7series_0_0/bd_top_mig_7series_0_0/user_design/rtl/controller/mig_7series_v4_2_rank_mach.v" \
"../../../bd/bd_top/ip/bd_top_mig_7series_0_0/bd_top_mig_7series_0_0/user_design/rtl/controller/mig_7series_v4_2_round_robin_arb.v" \
"../../../bd/bd_top/ip/bd_top_mig_7series_0_0/bd_top_mig_7series_0_0/user_design/rtl/ecc/mig_7series_v4_2_ecc_buf.v" \
"../../../bd/bd_top/ip/bd_top_mig_7series_0_0/bd_top_mig_7series_0_0/user_design/rtl/ecc/mig_7series_v4_2_ecc_dec_fix.v" \
"../../../bd/bd_top/ip/bd_top_mig_7series_0_0/bd_top_mig_7series_0_0/user_design/rtl/ecc/mig_7series_v4_2_ecc_gen.v" \
"../../../bd/bd_top/ip/bd_top_mig_7series_0_0/bd_top_mig_7series_0_0/user_design/rtl/ecc/mig_7series_v4_2_ecc_merge_enc.v" \
"../../../bd/bd_top/ip/bd_top_mig_7series_0_0/bd_top_mig_7series_0_0/user_design/rtl/ecc/mig_7series_v4_2_fi_xor.v" \
"../../../bd/bd_top/ip/bd_top_mig_7series_0_0/bd_top_mig_7series_0_0/user_design/rtl/ip_top/mig_7series_v4_2_memc_ui_top_axi.v" \
"../../../bd/bd_top/ip/bd_top_mig_7series_0_0/bd_top_mig_7series_0_0/user_design/rtl/ip_top/mig_7series_v4_2_mem_intfc.v" \
"../../../bd/bd_top/ip/bd_top_mig_7series_0_0/bd_top_mig_7series_0_0/user_design/rtl/phy/mig_7series_v4_2_ddr_byte_group_io.v" \
"../../../bd/bd_top/ip/bd_top_mig_7series_0_0/bd_top_mig_7series_0_0/user_design/rtl/phy/mig_7series_v4_2_ddr_byte_lane.v" \
"../../../bd/bd_top/ip/bd_top_mig_7series_0_0/bd_top_mig_7series_0_0/user_design/rtl/phy/mig_7series_v4_2_ddr_calib_top.v" \
"../../../bd/bd_top/ip/bd_top_mig_7series_0_0/bd_top_mig_7series_0_0/user_design/rtl/phy/mig_7series_v4_2_ddr_if_post_fifo.v" \
"../../../bd/bd_top/ip/bd_top_mig_7series_0_0/bd_top_mig_7series_0_0/user_design/rtl/phy/mig_7series_v4_2_ddr_mc_phy.v" \
"../../../bd/bd_top/ip/bd_top_mig_7series_0_0/bd_top_mig_7series_0_0/user_design/rtl/phy/mig_7series_v4_2_ddr_mc_phy_wrapper.v" \
"../../../bd/bd_top/ip/bd_top_mig_7series_0_0/bd_top_mig_7series_0_0/user_design/rtl/phy/mig_7series_v4_2_ddr_of_pre_fifo.v" \
"../../../bd/bd_top/ip/bd_top_mig_7series_0_0/bd_top_mig_7series_0_0/user_design/rtl/phy/mig_7series_v4_2_ddr_phy_4lanes.v" \
"../../../bd/bd_top/ip/bd_top_mig_7series_0_0/bd_top_mig_7series_0_0/user_design/rtl/phy/mig_7series_v4_2_ddr_phy_ck_addr_cmd_delay.v" \
"../../../bd/bd_top/ip/bd_top_mig_7series_0_0/bd_top_mig_7series_0_0/user_design/rtl/phy/mig_7series_v4_2_ddr_phy_dqs_found_cal.v" \
"../../../bd/bd_top/ip/bd_top_mig_7series_0_0/bd_top_mig_7series_0_0/user_design/rtl/phy/mig_7series_v4_2_ddr_phy_dqs_found_cal_hr.v" \
"../../../bd/bd_top/ip/bd_top_mig_7series_0_0/bd_top_mig_7series_0_0/user_design/rtl/phy/mig_7series_v4_2_ddr_phy_init.v" \
"../../../bd/bd_top/ip/bd_top_mig_7series_0_0/bd_top_mig_7series_0_0/user_design/rtl/phy/mig_7series_v4_2_ddr_phy_ocd_cntlr.v" \
"../../../bd/bd_top/ip/bd_top_mig_7series_0_0/bd_top_mig_7series_0_0/user_design/rtl/phy/mig_7series_v4_2_ddr_phy_ocd_data.v" \
"../../../bd/bd_top/ip/bd_top_mig_7series_0_0/bd_top_mig_7series_0_0/user_design/rtl/phy/mig_7series_v4_2_ddr_phy_ocd_edge.v" \
"../../../bd/bd_top/ip/bd_top_mig_7series_0_0/bd_top_mig_7series_0_0/user_design/rtl/phy/mig_7series_v4_2_ddr_phy_ocd_lim.v" \
"../../../bd/bd_top/ip/bd_top_mig_7series_0_0/bd_top_mig_7series_0_0/user_design/rtl/phy/mig_7series_v4_2_ddr_phy_ocd_mux.v" \
"../../../bd/bd_top/ip/bd_top_mig_7series_0_0/bd_top_mig_7series_0_0/user_design/rtl/phy/mig_7series_v4_2_ddr_phy_ocd_po_cntlr.v" \
"../../../bd/bd_top/ip/bd_top_mig_7series_0_0/bd_top_mig_7series_0_0/user_design/rtl/phy/mig_7series_v4_2_ddr_phy_ocd_samp.v" \
"../../../bd/bd_top/ip/bd_top_mig_7series_0_0/bd_top_mig_7series_0_0/user_design/rtl/phy/mig_7series_v4_2_ddr_phy_oclkdelay_cal.v" \
"../../../bd/bd_top/ip/bd_top_mig_7series_0_0/bd_top_mig_7series_0_0/user_design/rtl/phy/mig_7series_v4_2_ddr_phy_prbs_rdlvl.v" \
"../../../bd/bd_top/ip/bd_top_mig_7series_0_0/bd_top_mig_7series_0_0/user_design/rtl/phy/mig_7series_v4_2_ddr_phy_rdlvl.v" \
"../../../bd/bd_top/ip/bd_top_mig_7series_0_0/bd_top_mig_7series_0_0/user_design/rtl/phy/mig_7series_v4_2_ddr_phy_tempmon.v" \
"../../../bd/bd_top/ip/bd_top_mig_7series_0_0/bd_top_mig_7series_0_0/user_design/rtl/phy/mig_7series_v4_2_ddr_phy_top.v" \
"../../../bd/bd_top/ip/bd_top_mig_7series_0_0/bd_top_mig_7series_0_0/user_design/rtl/phy/mig_7series_v4_2_ddr_phy_wrcal.v" \
"../../../bd/bd_top/ip/bd_top_mig_7series_0_0/bd_top_mig_7series_0_0/user_design/rtl/phy/mig_7series_v4_2_ddr_phy_wrlvl.v" \
"../../../bd/bd_top/ip/bd_top_mig_7series_0_0/bd_top_mig_7series_0_0/user_design/rtl/phy/mig_7series_v4_2_ddr_phy_wrlvl_off_delay.v" \
"../../../bd/bd_top/ip/bd_top_mig_7series_0_0/bd_top_mig_7series_0_0/user_design/rtl/phy/mig_7series_v4_2_ddr_prbs_gen.v" \
"../../../bd/bd_top/ip/bd_top_mig_7series_0_0/bd_top_mig_7series_0_0/user_design/rtl/phy/mig_7series_v4_2_ddr_skip_calib_tap.v" \
"../../../bd/bd_top/ip/bd_top_mig_7series_0_0/bd_top_mig_7series_0_0/user_design/rtl/phy/mig_7series_v4_2_poc_cc.v" \
"../../../bd/bd_top/ip/bd_top_mig_7series_0_0/bd_top_mig_7series_0_0/user_design/rtl/phy/mig_7series_v4_2_poc_edge_store.v" \
"../../../bd/bd_top/ip/bd_top_mig_7series_0_0/bd_top_mig_7series_0_0/user_design/rtl/phy/mig_7series_v4_2_poc_meta.v" \
"../../../bd/bd_top/ip/bd_top_mig_7series_0_0/bd_top_mig_7series_0_0/user_design/rtl/phy/mig_7series_v4_2_poc_pd.v" \
"../../../bd/bd_top/ip/bd_top_mig_7series_0_0/bd_top_mig_7series_0_0/user_design/rtl/phy/mig_7series_v4_2_poc_tap_base.v" \
"../../../bd/bd_top/ip/bd_top_mig_7series_0_0/bd_top_mig_7series_0_0/user_design/rtl/phy/mig_7series_v4_2_poc_top.v" \
"../../../bd/bd_top/ip/bd_top_mig_7series_0_0/bd_top_mig_7series_0_0/user_design/rtl/ui/mig_7series_v4_2_ui_cmd.v" \
"../../../bd/bd_top/ip/bd_top_mig_7series_0_0/bd_top_mig_7series_0_0/user_design/rtl/ui/mig_7series_v4_2_ui_rd_data.v" \
"../../../bd/bd_top/ip/bd_top_mig_7series_0_0/bd_top_mig_7series_0_0/user_design/rtl/ui/mig_7series_v4_2_ui_top.v" \
"../../../bd/bd_top/ip/bd_top_mig_7series_0_0/bd_top_mig_7series_0_0/user_design/rtl/ui/mig_7series_v4_2_ui_wr_data.v" \
"../../../bd/bd_top/ip/bd_top_mig_7series_0_0/bd_top_mig_7series_0_0/user_design/rtl/bd_top_mig_7series_0_0_mig_sim.v" \
"../../../bd/bd_top/ip/bd_top_mig_7series_0_0/bd_top_mig_7series_0_0/user_design/rtl/bd_top_mig_7series_0_0.v" \

vcom -work xil_defaultlib -93  -incr \
"../../../bd/bd_top/ip/bd_top_rst_mig_7series_0_100M_0/sim/bd_top_rst_mig_7series_0_100M_0.vhd" \

vlog -work generic_baseblocks_v2_1_2  -incr -v2k5 "+incdir+../../../../microblaze_ddr_100t.gen/sources_1/bd/bd_top/ipshared/3242" "+incdir+../../../../microblaze_ddr_100t.gen/sources_1/bd/bd_top/ipshared/ec67/hdl" -l xpm -l microblaze_v11_0_13 -l xil_defaultlib -l lmb_v10_v3_0_14 -l lmb_bram_if_cntlr_v4_0_24 -l blk_mem_gen_v8_4_8 -l axi_lite_ipif_v3_0_4 -l mdm_v3_2_26 -l lib_cdc_v1_0_3 -l proc_sys_reset_v5_0_15 -l lib_pkg_v1_0_4 -l lib_srl_fifo_v1_0_4 -l axi_uartlite_v2_0_35 -l generic_baseblocks_v2_1_2 -l axi_infrastructure_v1_1_0 -l axi_register_slice_v2_1_31 -l fifo_generator_v13_2_10 -l axi_data_fifo_v2_1_30 -l axi_crossbar_v2_1_32 -l axi_protocol_converter_v2_1_31 -l axi_clock_converter_v2_1_30 -l axi_dwidth_converter_v2_1_31 \
"../../../../microblaze_ddr_100t.gen/sources_1/bd/bd_top/ipshared/0c28/hdl/generic_baseblocks_v2_1_vl_rfs.v" \

vlog -work axi_infrastructure_v1_1_0  -incr -v2k5 "+incdir+../../../../microblaze_ddr_100t.gen/sources_1/bd/bd_top/ipshared/3242" "+incdir+../../../../microblaze_ddr_100t.gen/sources_1/bd/bd_top/ipshared/ec67/hdl" -l xpm -l microblaze_v11_0_13 -l xil_defaultlib -l lmb_v10_v3_0_14 -l lmb_bram_if_cntlr_v4_0_24 -l blk_mem_gen_v8_4_8 -l axi_lite_ipif_v3_0_4 -l mdm_v3_2_26 -l lib_cdc_v1_0_3 -l proc_sys_reset_v5_0_15 -l lib_pkg_v1_0_4 -l lib_srl_fifo_v1_0_4 -l axi_uartlite_v2_0_35 -l generic_baseblocks_v2_1_2 -l axi_infrastructure_v1_1_0 -l axi_register_slice_v2_1_31 -l fifo_generator_v13_2_10 -l axi_data_fifo_v2_1_30 -l axi_crossbar_v2_1_32 -l axi_protocol_converter_v2_1_31 -l axi_clock_converter_v2_1_30 -l axi_dwidth_converter_v2_1_31 \
"../../../../microblaze_ddr_100t.gen/sources_1/bd/bd_top/ipshared/ec67/hdl/axi_infrastructure_v1_1_vl_rfs.v" \

vlog -work axi_register_slice_v2_1_31  -incr -v2k5 "+incdir+../../../../microblaze_ddr_100t.gen/sources_1/bd/bd_top/ipshared/3242" "+incdir+../../../../microblaze_ddr_100t.gen/sources_1/bd/bd_top/ipshared/ec67/hdl" -l xpm -l microblaze_v11_0_13 -l xil_defaultlib -l lmb_v10_v3_0_14 -l lmb_bram_if_cntlr_v4_0_24 -l blk_mem_gen_v8_4_8 -l axi_lite_ipif_v3_0_4 -l mdm_v3_2_26 -l lib_cdc_v1_0_3 -l proc_sys_reset_v5_0_15 -l lib_pkg_v1_0_4 -l lib_srl_fifo_v1_0_4 -l axi_uartlite_v2_0_35 -l generic_baseblocks_v2_1_2 -l axi_infrastructure_v1_1_0 -l axi_register_slice_v2_1_31 -l fifo_generator_v13_2_10 -l axi_data_fifo_v2_1_30 -l axi_crossbar_v2_1_32 -l axi_protocol_converter_v2_1_31 -l axi_clock_converter_v2_1_30 -l axi_dwidth_converter_v2_1_31 \
"../../../../microblaze_ddr_100t.gen/sources_1/bd/bd_top/ipshared/92b2/hdl/axi_register_slice_v2_1_vl_rfs.v" \

vlog -work fifo_generator_v13_2_10  -incr -v2k5 "+incdir+../../../../microblaze_ddr_100t.gen/sources_1/bd/bd_top/ipshared/3242" "+incdir+../../../../microblaze_ddr_100t.gen/sources_1/bd/bd_top/ipshared/ec67/hdl" -l xpm -l microblaze_v11_0_13 -l xil_defaultlib -l lmb_v10_v3_0_14 -l lmb_bram_if_cntlr_v4_0_24 -l blk_mem_gen_v8_4_8 -l axi_lite_ipif_v3_0_4 -l mdm_v3_2_26 -l lib_cdc_v1_0_3 -l proc_sys_reset_v5_0_15 -l lib_pkg_v1_0_4 -l lib_srl_fifo_v1_0_4 -l axi_uartlite_v2_0_35 -l generic_baseblocks_v2_1_2 -l axi_infrastructure_v1_1_0 -l axi_register_slice_v2_1_31 -l fifo_generator_v13_2_10 -l axi_data_fifo_v2_1_30 -l axi_crossbar_v2_1_32 -l axi_protocol_converter_v2_1_31 -l axi_clock_converter_v2_1_30 -l axi_dwidth_converter_v2_1_31 \
"../../../../microblaze_ddr_100t.gen/sources_1/bd/bd_top/ipshared/1443/simulation/fifo_generator_vlog_beh.v" \

vcom -work fifo_generator_v13_2_10 -93  -incr \
"../../../../microblaze_ddr_100t.gen/sources_1/bd/bd_top/ipshared/1443/hdl/fifo_generator_v13_2_rfs.vhd" \

vlog -work fifo_generator_v13_2_10  -incr -v2k5 "+incdir+../../../../microblaze_ddr_100t.gen/sources_1/bd/bd_top/ipshared/3242" "+incdir+../../../../microblaze_ddr_100t.gen/sources_1/bd/bd_top/ipshared/ec67/hdl" -l xpm -l microblaze_v11_0_13 -l xil_defaultlib -l lmb_v10_v3_0_14 -l lmb_bram_if_cntlr_v4_0_24 -l blk_mem_gen_v8_4_8 -l axi_lite_ipif_v3_0_4 -l mdm_v3_2_26 -l lib_cdc_v1_0_3 -l proc_sys_reset_v5_0_15 -l lib_pkg_v1_0_4 -l lib_srl_fifo_v1_0_4 -l axi_uartlite_v2_0_35 -l generic_baseblocks_v2_1_2 -l axi_infrastructure_v1_1_0 -l axi_register_slice_v2_1_31 -l fifo_generator_v13_2_10 -l axi_data_fifo_v2_1_30 -l axi_crossbar_v2_1_32 -l axi_protocol_converter_v2_1_31 -l axi_clock_converter_v2_1_30 -l axi_dwidth_converter_v2_1_31 \
"../../../../microblaze_ddr_100t.gen/sources_1/bd/bd_top/ipshared/1443/hdl/fifo_generator_v13_2_rfs.v" \

vlog -work axi_data_fifo_v2_1_30  -incr -v2k5 "+incdir+../../../../microblaze_ddr_100t.gen/sources_1/bd/bd_top/ipshared/3242" "+incdir+../../../../microblaze_ddr_100t.gen/sources_1/bd/bd_top/ipshared/ec67/hdl" -l xpm -l microblaze_v11_0_13 -l xil_defaultlib -l lmb_v10_v3_0_14 -l lmb_bram_if_cntlr_v4_0_24 -l blk_mem_gen_v8_4_8 -l axi_lite_ipif_v3_0_4 -l mdm_v3_2_26 -l lib_cdc_v1_0_3 -l proc_sys_reset_v5_0_15 -l lib_pkg_v1_0_4 -l lib_srl_fifo_v1_0_4 -l axi_uartlite_v2_0_35 -l generic_baseblocks_v2_1_2 -l axi_infrastructure_v1_1_0 -l axi_register_slice_v2_1_31 -l fifo_generator_v13_2_10 -l axi_data_fifo_v2_1_30 -l axi_crossbar_v2_1_32 -l axi_protocol_converter_v2_1_31 -l axi_clock_converter_v2_1_30 -l axi_dwidth_converter_v2_1_31 \
"../../../../microblaze_ddr_100t.gen/sources_1/bd/bd_top/ipshared/9692/hdl/axi_data_fifo_v2_1_vl_rfs.v" \

vlog -work axi_crossbar_v2_1_32  -incr -v2k5 "+incdir+../../../../microblaze_ddr_100t.gen/sources_1/bd/bd_top/ipshared/3242" "+incdir+../../../../microblaze_ddr_100t.gen/sources_1/bd/bd_top/ipshared/ec67/hdl" -l xpm -l microblaze_v11_0_13 -l xil_defaultlib -l lmb_v10_v3_0_14 -l lmb_bram_if_cntlr_v4_0_24 -l blk_mem_gen_v8_4_8 -l axi_lite_ipif_v3_0_4 -l mdm_v3_2_26 -l lib_cdc_v1_0_3 -l proc_sys_reset_v5_0_15 -l lib_pkg_v1_0_4 -l lib_srl_fifo_v1_0_4 -l axi_uartlite_v2_0_35 -l generic_baseblocks_v2_1_2 -l axi_infrastructure_v1_1_0 -l axi_register_slice_v2_1_31 -l fifo_generator_v13_2_10 -l axi_data_fifo_v2_1_30 -l axi_crossbar_v2_1_32 -l axi_protocol_converter_v2_1_31 -l axi_clock_converter_v2_1_30 -l axi_dwidth_converter_v2_1_31 \
"../../../../microblaze_ddr_100t.gen/sources_1/bd/bd_top/ipshared/e9d8/hdl/axi_crossbar_v2_1_vl_rfs.v" \

vlog -work xil_defaultlib  -incr -v2k5 "+incdir+../../../../microblaze_ddr_100t.gen/sources_1/bd/bd_top/ipshared/3242" "+incdir+../../../../microblaze_ddr_100t.gen/sources_1/bd/bd_top/ipshared/ec67/hdl" -l xpm -l microblaze_v11_0_13 -l xil_defaultlib -l lmb_v10_v3_0_14 -l lmb_bram_if_cntlr_v4_0_24 -l blk_mem_gen_v8_4_8 -l axi_lite_ipif_v3_0_4 -l mdm_v3_2_26 -l lib_cdc_v1_0_3 -l proc_sys_reset_v5_0_15 -l lib_pkg_v1_0_4 -l lib_srl_fifo_v1_0_4 -l axi_uartlite_v2_0_35 -l generic_baseblocks_v2_1_2 -l axi_infrastructure_v1_1_0 -l axi_register_slice_v2_1_31 -l fifo_generator_v13_2_10 -l axi_data_fifo_v2_1_30 -l axi_crossbar_v2_1_32 -l axi_protocol_converter_v2_1_31 -l axi_clock_converter_v2_1_30 -l axi_dwidth_converter_v2_1_31 \
"../../../bd/bd_top/ip/bd_top_xbar_0/sim/bd_top_xbar_0.v" \

vlog -work axi_protocol_converter_v2_1_31  -incr -v2k5 "+incdir+../../../../microblaze_ddr_100t.gen/sources_1/bd/bd_top/ipshared/3242" "+incdir+../../../../microblaze_ddr_100t.gen/sources_1/bd/bd_top/ipshared/ec67/hdl" -l xpm -l microblaze_v11_0_13 -l xil_defaultlib -l lmb_v10_v3_0_14 -l lmb_bram_if_cntlr_v4_0_24 -l blk_mem_gen_v8_4_8 -l axi_lite_ipif_v3_0_4 -l mdm_v3_2_26 -l lib_cdc_v1_0_3 -l proc_sys_reset_v5_0_15 -l lib_pkg_v1_0_4 -l lib_srl_fifo_v1_0_4 -l axi_uartlite_v2_0_35 -l generic_baseblocks_v2_1_2 -l axi_infrastructure_v1_1_0 -l axi_register_slice_v2_1_31 -l fifo_generator_v13_2_10 -l axi_data_fifo_v2_1_30 -l axi_crossbar_v2_1_32 -l axi_protocol_converter_v2_1_31 -l axi_clock_converter_v2_1_30 -l axi_dwidth_converter_v2_1_31 \
"../../../../microblaze_ddr_100t.gen/sources_1/bd/bd_top/ipshared/3c06/hdl/axi_protocol_converter_v2_1_vl_rfs.v" \

vlog -work axi_clock_converter_v2_1_30  -incr -v2k5 "+incdir+../../../../microblaze_ddr_100t.gen/sources_1/bd/bd_top/ipshared/3242" "+incdir+../../../../microblaze_ddr_100t.gen/sources_1/bd/bd_top/ipshared/ec67/hdl" -l xpm -l microblaze_v11_0_13 -l xil_defaultlib -l lmb_v10_v3_0_14 -l lmb_bram_if_cntlr_v4_0_24 -l blk_mem_gen_v8_4_8 -l axi_lite_ipif_v3_0_4 -l mdm_v3_2_26 -l lib_cdc_v1_0_3 -l proc_sys_reset_v5_0_15 -l lib_pkg_v1_0_4 -l lib_srl_fifo_v1_0_4 -l axi_uartlite_v2_0_35 -l generic_baseblocks_v2_1_2 -l axi_infrastructure_v1_1_0 -l axi_register_slice_v2_1_31 -l fifo_generator_v13_2_10 -l axi_data_fifo_v2_1_30 -l axi_crossbar_v2_1_32 -l axi_protocol_converter_v2_1_31 -l axi_clock_converter_v2_1_30 -l axi_dwidth_converter_v2_1_31 \
"../../../../microblaze_ddr_100t.gen/sources_1/bd/bd_top/ipshared/80bf/hdl/axi_clock_converter_v2_1_vl_rfs.v" \

vlog -work axi_dwidth_converter_v2_1_31  -incr -v2k5 "+incdir+../../../../microblaze_ddr_100t.gen/sources_1/bd/bd_top/ipshared/3242" "+incdir+../../../../microblaze_ddr_100t.gen/sources_1/bd/bd_top/ipshared/ec67/hdl" -l xpm -l microblaze_v11_0_13 -l xil_defaultlib -l lmb_v10_v3_0_14 -l lmb_bram_if_cntlr_v4_0_24 -l blk_mem_gen_v8_4_8 -l axi_lite_ipif_v3_0_4 -l mdm_v3_2_26 -l lib_cdc_v1_0_3 -l proc_sys_reset_v5_0_15 -l lib_pkg_v1_0_4 -l lib_srl_fifo_v1_0_4 -l axi_uartlite_v2_0_35 -l generic_baseblocks_v2_1_2 -l axi_infrastructure_v1_1_0 -l axi_register_slice_v2_1_31 -l fifo_generator_v13_2_10 -l axi_data_fifo_v2_1_30 -l axi_crossbar_v2_1_32 -l axi_protocol_converter_v2_1_31 -l axi_clock_converter_v2_1_30 -l axi_dwidth_converter_v2_1_31 \
"../../../../microblaze_ddr_100t.gen/sources_1/bd/bd_top/ipshared/14b9/hdl/axi_dwidth_converter_v2_1_vl_rfs.v" \

vlog -work xil_defaultlib  -incr -v2k5 "+incdir+../../../../microblaze_ddr_100t.gen/sources_1/bd/bd_top/ipshared/3242" "+incdir+../../../../microblaze_ddr_100t.gen/sources_1/bd/bd_top/ipshared/ec67/hdl" -l xpm -l microblaze_v11_0_13 -l xil_defaultlib -l lmb_v10_v3_0_14 -l lmb_bram_if_cntlr_v4_0_24 -l blk_mem_gen_v8_4_8 -l axi_lite_ipif_v3_0_4 -l mdm_v3_2_26 -l lib_cdc_v1_0_3 -l proc_sys_reset_v5_0_15 -l lib_pkg_v1_0_4 -l lib_srl_fifo_v1_0_4 -l axi_uartlite_v2_0_35 -l generic_baseblocks_v2_1_2 -l axi_infrastructure_v1_1_0 -l axi_register_slice_v2_1_31 -l fifo_generator_v13_2_10 -l axi_data_fifo_v2_1_30 -l axi_crossbar_v2_1_32 -l axi_protocol_converter_v2_1_31 -l axi_clock_converter_v2_1_30 -l axi_dwidth_converter_v2_1_31 \
"../../../bd/bd_top/ip/bd_top_auto_us_1/sim/bd_top_auto_us_1.v" \
"../../../bd/bd_top/ip/bd_top_auto_ds_0/sim/bd_top_auto_ds_0.v" \
"../../../bd/bd_top/ip/bd_top_auto_pc_0/sim/bd_top_auto_pc_0.v" \
"../../../bd/bd_top/ip/bd_top_auto_us_0/sim/bd_top_auto_us_0.v" \
"../../../bd/bd_top/ip/bd_top_auto_cc_0/sim/bd_top_auto_cc_0.v" \
"../../../bd/bd_top/sim/bd_top.v" \

vlog -work xil_defaultlib \
"glbl.v"

