//Copyright 1986-2019 Xilinx, Inc. All Rights Reserved.
//--------------------------------------------------------------------------------
//Tool Version: Vivado v.2019.1 (win64) Build 2552052 Fri May 24 14:49:42 MDT 2019
//Date        : Tue Jul 19 21:57:15 2022
//Host        : DESKTOP-8P19OKJ running 64-bit major release  (build 9200)
//Command     : generate_target vfifo_wrapper.bd
//Design      : vfifo_wrapper
//Purpose     : IP block netlist
//--------------------------------------------------------------------------------
`timescale 1 ps / 1 ps

module vfifo_wrapper
   (DDR3_0_addr,
    DDR3_0_ba,
    DDR3_0_cas_n,
    DDR3_0_ck_n,
    DDR3_0_ck_p,
    DDR3_0_cke,
    DDR3_0_dm,
    DDR3_0_dq,
    DDR3_0_dqs_n,
    DDR3_0_dqs_p,
    DDR3_0_odt,
    DDR3_0_ras_n,
    DDR3_0_reset_n,
    DDR3_0_we_n,
    M_AXIS_0_tdata,
    M_AXIS_0_tlast,
    M_AXIS_0_tready,
    M_AXIS_0_tvalid,
    S_AXIS_0_tdata,
    S_AXIS_0_tlast,
    S_AXIS_0_tready,
    S_AXIS_0_tvalid,
    axis_aclk_0,
    clk_ref_i_0,
    init_calib_complete_0,
    reset_rtl_0,
    sys_clk_i_0);
  output [14:0]DDR3_0_addr;
  output [2:0]DDR3_0_ba;
  output DDR3_0_cas_n;
  output [0:0]DDR3_0_ck_n;
  output [0:0]DDR3_0_ck_p;
  output [0:0]DDR3_0_cke;
  output [1:0]DDR3_0_dm;
  inout [15:0]DDR3_0_dq;
  inout [1:0]DDR3_0_dqs_n;
  inout [1:0]DDR3_0_dqs_p;
  output [0:0]DDR3_0_odt;
  output DDR3_0_ras_n;
  output DDR3_0_reset_n;
  output DDR3_0_we_n;
  output [31:0]M_AXIS_0_tdata;
  output M_AXIS_0_tlast;
  input M_AXIS_0_tready;
  output M_AXIS_0_tvalid;
  input [31:0]S_AXIS_0_tdata;
  input S_AXIS_0_tlast;
  output S_AXIS_0_tready;
  input S_AXIS_0_tvalid;
  input axis_aclk_0;
  input clk_ref_i_0;
  output init_calib_complete_0;
  input reset_rtl_0;
  input sys_clk_i_0;

  wire [14:0]DDR3_0_addr;
  wire [2:0]DDR3_0_ba;
  wire DDR3_0_cas_n;
  wire [0:0]DDR3_0_ck_n;
  wire [0:0]DDR3_0_ck_p;
  wire [0:0]DDR3_0_cke;
  wire [1:0]DDR3_0_dm;
  wire [15:0]DDR3_0_dq;
  wire [1:0]DDR3_0_dqs_n;
  wire [1:0]DDR3_0_dqs_p;
  wire [0:0]DDR3_0_odt;
  wire DDR3_0_ras_n;
  wire DDR3_0_reset_n;
  wire DDR3_0_we_n;
  wire [31:0]M_AXIS_0_tdata;
  wire M_AXIS_0_tlast;
  wire M_AXIS_0_tready;
  wire M_AXIS_0_tvalid;
  wire [31:0]S_AXIS_0_tdata;
  wire S_AXIS_0_tlast;
  wire S_AXIS_0_tready;
  wire S_AXIS_0_tvalid;
  wire axis_aclk_0;
  wire clk_ref_i_0;
  wire init_calib_complete_0;
  wire reset_rtl_0;
  wire sys_clk_i_0;

  vfifo vfifo_i
       (.DDR3_0_addr(DDR3_0_addr),
        .DDR3_0_ba(DDR3_0_ba),
        .DDR3_0_cas_n(DDR3_0_cas_n),
        .DDR3_0_ck_n(DDR3_0_ck_n),
        .DDR3_0_ck_p(DDR3_0_ck_p),
        .DDR3_0_cke(DDR3_0_cke),
        .DDR3_0_dm(DDR3_0_dm),
        .DDR3_0_dq(DDR3_0_dq),
        .DDR3_0_dqs_n(DDR3_0_dqs_n),
        .DDR3_0_dqs_p(DDR3_0_dqs_p),
        .DDR3_0_odt(DDR3_0_odt),
        .DDR3_0_ras_n(DDR3_0_ras_n),
        .DDR3_0_reset_n(DDR3_0_reset_n),
        .DDR3_0_we_n(DDR3_0_we_n),
        .M_AXIS_0_tdata(M_AXIS_0_tdata),
        .M_AXIS_0_tlast(M_AXIS_0_tlast),
        .M_AXIS_0_tready(M_AXIS_0_tready),
        .M_AXIS_0_tvalid(M_AXIS_0_tvalid),
        .S_AXIS_0_tdata(S_AXIS_0_tdata),
        .S_AXIS_0_tlast(S_AXIS_0_tlast),
        .S_AXIS_0_tready(S_AXIS_0_tready),
        .S_AXIS_0_tvalid(S_AXIS_0_tvalid),
        .axis_aclk_0(axis_aclk_0),
        .clk_ref_i_0(clk_ref_i_0),
        .init_calib_complete_0(init_calib_complete_0),
        .reset_rtl_0(reset_rtl_0),
        .sys_clk_i_0(sys_clk_i_0));
endmodule
