
`ifndef _gba_io_fpga_header_svh_
`define _gba_io_fpga_header_svh_

interface cart_mux_interface();
    logic cart_rd, cart_wr, cart_rd_valid;
    logic [1:0] cart_data_width; // 01: 8-bit cart cs2, 10: 16-bit cart cs1
    logic [25:0] cart_addr; // cs1: { 1'b0, 25-bit }, cs2: { 1'b1, 9'b0, 16-bit }
    logic [15:0] cart_rd_data; // cs1: 16-bit, cs2: 8-bit
    logic [15:0] cart_wr_data; // cs1: 16-bit, cs2: 8-bit
    modport cart (
        input cart_rd_data, cart_rd_valid,
        output cart_rd, cart_wr, cart_data_width, cart_addr, cart_wr_data);
    modport mux (
        input cart_rd, cart_wr, cart_data_width, cart_addr, cart_wr_data,
        output cart_rd_data, cart_rd_valid);
endinterface

interface mux_buffer_interface();
    logic from_cart, from_usb;
    logic [25:0] cart_usb_addr;
    logic [25:0] mem_addr;
    modport mux (
        input mem_addr,
        output from_cart, from_usb, cart_usb_addr);
    modport buffer (
        input from_cart, from_usb, cart_usb_addr,
        output mem_addr);
endinterface

interface mux_mem_interface();
    logic mem_rd, mem_rd_ready, mem_rd_valid;
    logic mem_wr, mem_wr_ready;
    logic [1:0] mem_data_width; // 01: 8-bit cart cs2, 10: 16-bit cart cs1, 11: 32-bit usb
    logic [25:0] mem_addr;
    logic [31:0] mem_rd_data;
    logic [31:0] mem_wr_data;
    modport mux (
        input mem_rd_ready, mem_wr_ready, mem_rd_data, mem_rd_valid,
        output mem_addr, mem_rd, mem_wr, mem_data_width, mem_wr_data);
    modport mem (
        input mem_addr, mem_rd, mem_wr, mem_data_width, mem_wr_data,
        output mem_rd_ready, mem_wr_ready, mem_rd_data, mem_rd_valid);
endinterface

interface mux_usb_interface();
    logic usb_rd, usb_rd_ready, usb_rd_valid;
    logic usb_wr, usb_wr_ready;
    logic [25:0] usb_addr;
    logic [31:0] usb_rd_data;
    logic [31:0] usb_wr_data;
    modport mux (
        input usb_addr, usb_rd, usb_wr, usb_wr_data,
        output usb_rd_ready, usb_wr_ready, usb_rd_data, usb_rd_valid
    );
    modport usb (
        input usb_rd_ready, usb_wr_ready, usb_rd_data, usb_rd_valid,
        output usb_addr, usb_rd, usb_wr, usb_wr_data
    );
endinterface

`endif
