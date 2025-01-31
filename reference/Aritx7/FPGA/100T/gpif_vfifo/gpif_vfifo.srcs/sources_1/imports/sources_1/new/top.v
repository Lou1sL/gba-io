`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2020/07/09 21:14:56
// Design Name: 
// Module Name: top
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module top(
//input reset_in_,            //input reset active low
	input clk,     
	input sys_clk_i_0,    
	
	output [14:0]DDR3_0_addr,
    output [2:0]DDR3_0_ba,
    output DDR3_0_cas_n,
    output [0:0]DDR3_0_ck_n,
    output [0:0]DDR3_0_ck_p,
    output [0:0]DDR3_0_cke,
    output [1:0]DDR3_0_dm,
    inout [15:0]DDR3_0_dq,
    inout [1:0]DDR3_0_dqs_n,
    inout [1:0]DDR3_0_dqs_p,
    output [0:0]DDR3_0_odt,
    output DDR3_0_ras_n,
    output DDR3_0_reset_n,
    output DDR3_0_we_n,        
	
// fx3 interface
	inout [31:0] fdata,  
	output [1:0] faddr,                //output fifo address  
	output slrd,                 //output read select
	output slwr,                 //output write select
	input flaga,
	input flagb,
	input flagc,
	input flagd,
	output sloe,                //output output enable select
	output clk_out,             //output clk 100 Mhz and 180 phase shift
	output slcs,                //output chip select
	output pktend,              //output pkt end
	
	output led0
); 


    wire clk_100;
    wire clk_ref;
    wire lock;
    wire reset_;

    assign reset_ = lock;
    
    wire CLKFBIN;

   // PLLE2_BASE: Base Phase Locked Loop (PLL)
   //             Artix-7
   // Xilinx HDL Language Template, version 2018.3

   PLLE2_BASE #(
      .BANDWIDTH("OPTIMIZED"),  // OPTIMIZED, HIGH, LOW
      .CLKFBOUT_MULT(10),        // Multiply value for all CLKOUT, (2-64)
      .CLKFBOUT_PHASE(0.0),     // Phase offset in degrees of CLKFB, (-360.000-360.000).
      .CLKIN1_PERIOD(10),      // Input clock period in ns to ps resolution (i.e. 33.333 is 30 MHz).
      // CLKOUT0_DIVIDE - CLKOUT5_DIVIDE: Divide amount for each CLKOUT (1-128)
      .CLKOUT0_DIVIDE(10),
      .CLKOUT1_DIVIDE(10),
      .CLKOUT2_DIVIDE(5),
      .CLKOUT3_DIVIDE(10),
      .CLKOUT4_DIVIDE(10),
      .CLKOUT5_DIVIDE(10),
      // CLKOUT0_DUTY_CYCLE - CLKOUT5_DUTY_CYCLE: Duty cycle for each CLKOUT (0.001-0.999).
      .CLKOUT0_DUTY_CYCLE(0.5),
      .CLKOUT1_DUTY_CYCLE(0.5),
      .CLKOUT2_DUTY_CYCLE(0.5),
      .CLKOUT3_DUTY_CYCLE(0.5),
      .CLKOUT4_DUTY_CYCLE(0.5),
      .CLKOUT5_DUTY_CYCLE(0.5),
      // CLKOUT0_PHASE - CLKOUT5_PHASE: Phase offset for each CLKOUT (-360.000-360.000).
      .CLKOUT0_PHASE(0.0),
      .CLKOUT1_PHASE(180),
      .CLKOUT2_PHASE(0.0),
      .CLKOUT3_PHASE(0.0),
      .CLKOUT4_PHASE(0.0),
      .CLKOUT5_PHASE(0.0),
      .DIVCLK_DIVIDE(1),        // Master division value, (1-56)
      .REF_JITTER1(0.0),        // Reference input jitter in UI, (0.000-0.999).
      .STARTUP_WAIT("FALSE")    // Delay DONE until PLL Locks, ("TRUE"/"FALSE")
   )
   PLLE2_BASE_inst (
      // Clock Outputs: 1-bit (each) output: User configurable clock outputs
      .CLKOUT0(clk_100),   // 1-bit output: CLKOUT0
      .CLKOUT1(clk_out),   // 1-bit output: CLKOUT1
      .CLKOUT2(clk_ref),   // 1-bit output: CLKOUT2
      .CLKOUT3(),   // 1-bit output: CLKOUT3
      .CLKOUT4(),   // 1-bit output: CLKOUT4
      .CLKOUT5(),   // 1-bit output: CLKOUT5
      // Feedback Clocks: 1-bit (each) output: Clock feedback ports
      .CLKFBOUT(CLKFBIN), // 1-bit output: Feedback clock
      .LOCKED(lock),     // 1-bit output: LOCK
      .CLKIN1(clk),     // 1-bit input: Input clock
      // Control Ports: 1-bit (each) input: PLL control ports
      .PWRDWN(1'b0),     // 1-bit input: Power-down
      .RST(1'b0),           // 1-bit input: Reset
      // Feedback Clocks: 1-bit (each) input: Clock feedback ports
      .CLKFBIN(CLKFBIN)    // 1-bit input: Feedback clock
   );

   // End of PLLE2_BASE_inst instantiation
   
   (* DONT_TOUCH = "yes" *)wire [31:0] data_tx;
   (* DONT_TOUCH = "yes" *)wire data_tx_pktend;
   (* DONT_TOUCH = "yes" *)wire data_tx_valid;
   (* DONT_TOUCH = "yes" *)wire data_tx_ready;
   
   wire [31:0] ctrl_tx;
   wire ctrl_tx_pktend;
   wire ctrl_tx_valid;
   wire ctrl_tx_ready;
   
   wire [31:0] ctrl_rx;
   wire ctrl_rx_pktend;
   wire ctrl_rx_valid;
   wire ctrl_rx_ready;
   
   wire s_data_tvalid;
   wire s_data_tready;
   wire [31:0] s_data_tdata;
   wire s_data_tlast;

    gpif2_to_fifo32 gpif2_to_fifo32_i (
        // GPIF signals
        .gpif_clk(clk_100),
        .gpif_rst(~reset_),
        .gpif_enb(1'b1),
        .gpif_d(fdata),
        .gpif_ctl({flagd, flagc, flagb, flaga}),
        .sloe(sloe),
        .slrd(slrd),
        .slwr(slwr),
        .slcs(slcs),
        .pktend(pktend),
        .fifoadr(faddr),
        // FIFO interfaces
        // TX Data interface - down stream
        .tx_tdata(data_tx), .tx_tlast(data_tx_pktend), .tx_tvalid(data_tx_valid), .tx_tready(data_tx_ready),
        // RX Data interface - up stream
        .rx_tdata(s_data_tdata), .rx_tlast(s_data_tlast), .rx_tvalid(s_data_tvalid), .rx_tready(s_data_tready),
        // Incomming control interface
        .ctrl_tdata(ctrl_tx), .ctrl_tlast(ctrl_tx_pktend), .ctrl_tvalid(ctrl_tx_valid), .ctrl_tready(ctrl_tx_ready),
        // Outgoing control interface
        .resp_tdata(ctrl_rx), .resp_tlast(ctrl_rx_pktend), .resp_tvalid(ctrl_rx_valid), .resp_tready(ctrl_rx_ready)
    );
    
    vfifo_wrapper vfifo_i (
    .DDR3_0_addr(DDR3_0_addr),
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
    .M_AXIS_0_tdata(s_data_tdata),
    .M_AXIS_0_tlast(s_data_tlast),
    .M_AXIS_0_tready(s_data_tready),
    .M_AXIS_0_tvalid(s_data_tvalid),
    .S_AXIS_0_tdata(data_tx),
    .S_AXIS_0_tlast(data_tx_pktend),
    .S_AXIS_0_tready(data_tx_ready),
    .S_AXIS_0_tvalid(data_tx_valid),
    .axis_aclk_0(clk_100),
    .clk_ref_i_0(clk_ref),
    .init_calib_complete_0(led0),
    .reset_rtl_0(reset_),
    .sys_clk_i_0(sys_clk_i_0)
    );
    
    // control path loopback
    assign ctrl_rx = ctrl_tx;
    assign ctrl_rx_pktend = ctrl_tx_pktend;
    assign ctrl_rx_valid = ctrl_tx_valid;
    assign ctrl_tx_ready = ctrl_rx_ready;
    
endmodule
