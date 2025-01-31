// Copyright 1986-2019 Xilinx, Inc. All Rights Reserved.
// --------------------------------------------------------------------------------
// Tool Version: Vivado v.2019.1 (win64) Build 2552052 Fri May 24 14:49:42 MDT 2019
// Date        : Tue Jul 19 21:58:40 2022
// Host        : DESKTOP-8P19OKJ running 64-bit major release  (build 9200)
// Command     : write_verilog -force -mode synth_stub
//               F:/workspace/gpif_vfifo/gpif_vfifo.srcs/sources_1/bd/vfifo/ip/vfifo_axis_switch_1_0/vfifo_axis_switch_1_0_stub.v
// Design      : vfifo_axis_switch_1_0
// Purpose     : Stub declaration of top-level module interface
// Device      : xc7a100tfgg484-2
// --------------------------------------------------------------------------------

// This empty module with port declaration file causes synthesis tools to infer a black box for IP.
// The synthesis directives are for Synopsys Synplify support to prevent IO buffer insertion.
// Please paste the declaration into a Verilog source file or add the file as an additional source.
(* X_CORE_INFO = "axis_switch_v1_1_19_axis_switch,Vivado 2019.1" *)
module vfifo_axis_switch_1_0(aclk, aresetn, s_axis_tvalid, s_axis_tready, 
  s_axis_tdata, s_axis_tstrb, s_axis_tkeep, s_axis_tlast, s_axis_tid, s_axis_tdest, 
  m_axis_tvalid, m_axis_tready, m_axis_tdata, m_axis_tstrb, m_axis_tkeep, m_axis_tlast, 
  m_axis_tid, m_axis_tdest, s_decode_err)
/* synthesis syn_black_box black_box_pad_pin="aclk,aresetn,s_axis_tvalid[0:0],s_axis_tready[0:0],s_axis_tdata[31:0],s_axis_tstrb[3:0],s_axis_tkeep[3:0],s_axis_tlast[0:0],s_axis_tid[0:0],s_axis_tdest[0:0],m_axis_tvalid[1:0],m_axis_tready[1:0],m_axis_tdata[63:0],m_axis_tstrb[7:0],m_axis_tkeep[7:0],m_axis_tlast[1:0],m_axis_tid[1:0],m_axis_tdest[1:0],s_decode_err[0:0]" */;
  input aclk;
  input aresetn;
  input [0:0]s_axis_tvalid;
  output [0:0]s_axis_tready;
  input [31:0]s_axis_tdata;
  input [3:0]s_axis_tstrb;
  input [3:0]s_axis_tkeep;
  input [0:0]s_axis_tlast;
  input [0:0]s_axis_tid;
  input [0:0]s_axis_tdest;
  output [1:0]m_axis_tvalid;
  input [1:0]m_axis_tready;
  output [63:0]m_axis_tdata;
  output [7:0]m_axis_tstrb;
  output [7:0]m_axis_tkeep;
  output [1:0]m_axis_tlast;
  output [1:0]m_axis_tid;
  output [1:0]m_axis_tdest;
  output [0:0]s_decode_err;
endmodule
