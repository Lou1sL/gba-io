
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

    assign _gpif_pclk = ~clk;

    cart_mux_interface cart_mux_i();
    mux_buffer_interface mux_buffer_i();
    mux_usb_interface mux_usb_i();

    cart cart (
        .clk(clk),
        .rst(rst),
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
        .clk(clk),
        .rst(rst),
        .cart_mux(cart_mux_i.mux),
        .mux_buffer(mux_buffer_i.mux),
        .mux_usb(mux_usb_i.mux)
    );

    buffer buffer (
        .clk(clk),
        .rst(rst),
        .mux_buffer(mux_buffer_i.buffer)
    );

    usb usb (
        .clk(clk),
        .rst(rst),
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
