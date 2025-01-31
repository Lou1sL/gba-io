
`timescale 1ns / 1ps
`include "gba_io_fpga_header.svh"

module top (
    input logic clk,
    output logic led_0, led_1, led_2,
    output logic led_rd, led_wr,
    input logic button_0,
    // GBA Cartridge Edge Connector
    input logic gba_phi, gba_rd, gba_wr, gba_cs1, gba_cs2, gba_idreq,
    inout logic [15:0] gba_adl,
    inout logic [7:0] gba_adh,
    // DDR3 SDRAM
    input logic sys_clk_i,
    inout logic [15:0] ddr3_dq,
    inout logic [1:0] ddr3_dqs_n,
    inout logic [1:0] ddr3_dqs_p,
    output logic [14:0] ddr3_addr,
    output logic [2:0] ddr3_ba,
    output logic ddr3_ras_n, ddr3_cas_n, ddr3_we_n, ddr3_reset_n,
    output logic [0:0] ddr3_ck_p,
    output logic [0:0] ddr3_ck_n,
    output logic [0:0] ddr3_cke,
    output logic [1:0] ddr3_dm,
    output logic [0:0] ddr3_odt,
    // USB3.1 FX3 GPIF2 Interface
    output logic _gpif_pclk,
    inout logic [31:0] fdata,
    output logic [1:0] faddr,
    output logic slrd, slwr,
    input logic flaga, flagb, flagc, flagd,
    output logic sloe, slcs, pktend
);

    logic rst;
    assign rst = button_0;
    assign led_0 = button_0;

    logic _ddr3_ref_clk, _ddr3_ui_clk, ddr3_rst_ui_sync;
    assign _gpif_pclk = ~_ddr3_ui_clk;

    clk_wiz clk_wiz (
        .clk(clk),
        .reset(rst),
        .ddr3_ref_clk(_ddr3_ref_clk)
    );

    cart_mux_interface cart_mux_i();
    mux_buffer_interface mux_buffer_i();
    mux_mem_interface mux_mem_i();
    mux_usb_interface mux_usb_i();

    cart cart (
        .clk(_ddr3_ui_clk),
        .rst(ddr3_rst_ui_sync),
        .led_rd(led_rd),
        .led_wr(led_wr),
        // GBA Cartridge Edge Connector
        .gba_phi(gba_phi),
        .gba_rd(gba_rd),
        .gba_wr(gba_wr),
        .gba_cs1(gba_cs1),
        .gba_cs2(gba_cs2),
        .gba_idreq(gba_idreq),
        .gba_adl(gba_adl),
        .gba_adh(gba_adh),
        .cart_mux(cart_mux_i.cart)
    );

    mux mux (
        .clk(_ddr3_ui_clk),
        .rst(ddr3_rst_ui_sync),
        .cart_mux(cart_mux_i.mux),
        .mux_buffer(mux_buffer_i.mux),
        .mux_mem(mux_mem_i.mux),
        .mux_usb(mux_usb_i.mux)
    );

    buffer buffer (
        .clk(_ddr3_ui_clk),
        .rst(ddr3_rst_ui_sync),
        .mux_buffer(mux_buffer_i.buffer)
    );

    mem #() mem (
        .clk(clk),
        .sys_clk_i(sys_clk_i),
        .clk_ref_i(_ddr3_ref_clk),
        .ui_clk(_ddr3_ui_clk),
        .rst(rst),
        .rst_ui_sync(ddr3_rst_ui_sync),
        .led_rdy(led_1),
        // DDR3 SDRAM
        .ddr3_dq(ddr3_dq),
        .ddr3_dqs_n(ddr3_dqs_n),
        .ddr3_dqs_p(ddr3_dqs_p),
        .ddr3_addr(ddr3_addr),
        .ddr3_ba(ddr3_ba),
        .ddr3_ras_n(ddr3_ras_n),
        .ddr3_cas_n(ddr3_cas_n),
        .ddr3_we_n(ddr3_we_n),
        .ddr3_reset_n(ddr3_reset_n),
        .ddr3_ck_p(ddr3_ck_p),
        .ddr3_ck_n(ddr3_ck_n),
        .ddr3_cke(ddr3_cke),
        .ddr3_dm(ddr3_dm),
        .ddr3_odt(ddr3_odt),
        .mux_mem(mux_mem_i.mem)
    );

    usb usb (
        .clk(_ddr3_ui_clk),
        .rst(ddr3_rst_ui_sync),
        .led_rcv(led_2),
        // USB3.1 FX3 GPIF2 Interface
        .fdata(fdata),
        .faddr(faddr),
        .slrd(slrd),
        .slwr(slwr),
        .flaga(flaga),
        .flagb(flagb),
        .flagc(flagc),
        .flagd(flagd),
        .sloe(sloe),
        .slcs(slcs),
        .pktend(pktend),
        .mux_usb(mux_usb_i.usb)
    );

endmodule
