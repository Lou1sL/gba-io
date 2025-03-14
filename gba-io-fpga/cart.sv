
`timescale 1ns / 1ps
`include "gba_io_fpga_header.svh"

module cart (
    input logic clk,
    input logic rst,
    output logic led_rd,
    output logic led_wr,
    // GBA Cartridge Edge Connector
    input logic gba_phi, gba_rd, gba_wr, gba_cs1, gba_cs2, gba_idreq,
    inout logic [15:0] gba_adl,
    inout logic [7:0] gba_adh,
    cart_mux_interface.cart cart_mux
);

    localparam DATA_WIDTH_0 = 2'b00;
    localparam DATA_WIDTH_8 = 2'b01;
    localparam DATA_WIDTH_16 = 2'b10;
    localparam DATA_WIDTH_32 = 2'b11;

    // CDC
    bit [0:2] cs1_history = 3'b0;
    bit [0:2] cs2_history = 3'b0;
    bit [0:2] rd_history = 3'b0;
    bit [0:2] wr_history = 3'b0;

    logic cs1_rising_edge, cs1_falling_edge, cs1_lo;
    assign cs1_rising_edge = (cs1_history[1] == 1'b1) & (cs1_history[2] == 1'b0);
    assign cs1_falling_edge = (cs1_history[1] == 1'b0) & (cs1_history[2] == 1'b1);
    assign cs1_lo = (cs1_history[1] == 1'b0) & (cs1_history[2] == 1'b0);
    logic cs2_rising_edge, cs2_falling_edge, cs2_lo;
    assign cs2_rising_edge = (cs2_history[1] == 1'b1) & (cs2_history[2] == 1'b0);
    assign cs2_falling_edge = (cs2_history[1] == 1'b0) & (cs2_history[2] == 1'b1);
    assign cs2_lo = (cs2_history[1] == 1'b0) & (cs2_history[2] == 1'b0);
    logic rd_rising_edge, rd_falling_edge, rd_lo;
    assign rd_rising_edge = (rd_history[1] == 1'b1) & (rd_history[2] == 1'b0);
    assign rd_falling_edge = (rd_history[1] == 1'b0) & (rd_history[2] == 1'b1);
    assign rd_lo = (rd_history[1] == 1'b0) & (rd_history[2] == 1'b0);
    logic wr_rising_edge, wr_falling_edge, wr_lo;
    assign wr_rising_edge = (wr_history[1] == 1'b1) & (wr_history[2] == 1'b0);
    assign wr_falling_edge = (wr_history[1] == 1'b0) & (wr_history[2] == 1'b1);
    assign wr_lo = (wr_history[1] == 1'b0) & (wr_history[2] == 1'b0);

    always_ff @(posedge clk) begin
        if(rst) begin
            cs1_history <= 3'b0;
            cs2_history <= 3'b0;
            rd_history <= 3'b0;
            wr_history <= 3'b0;
        end else begin
            // The first input from the external GBA console is always in a metastable state.
            // Which means, we cannot trust it's value, let alone using posedge to detect.
            cs1_history <= { gba_cs1, cs1_history[0:1] };
            cs2_history <= { gba_cs2, cs2_history[0:1] };
            rd_history <= { gba_rd, rd_history[0:1] };
            wr_history <= { gba_wr, wr_history[0:1] };
        end
    end

    // Cart Signals -> Mux Signals
    logic cs1_rd, cs1_wr, cs2_rd, cs2_wr;
    assign cs1_rd = cs1_lo & (rd_falling_edge | rd_lo);
    assign cs1_wr = cs1_lo & (wr_falling_edge | wr_lo);
    assign cs2_rd = cs2_lo & (rd_falling_edge | rd_lo); // TODO: Verify if it's cs2_lo or cs2_falling_edge
    assign cs2_wr = cs2_lo & (wr_falling_edge | wr_lo); // TODO: Verify if it's cs2_lo or cs2_falling_edge

    assign cart_mux.cart_rd = cs1_rd | cs2_rd;
    assign cart_mux.cart_wr = cs1_wr | cs2_wr;
    assign cart_mux.cart_data_width = 
        (cs1_rd | cs1_wr) ? DATA_WIDTH_16 :
        (cs2_rd | cs2_wr) ? DATA_WIDTH_8 :
        DATA_WIDTH_0;

    // Cart Address -> Address Holding Register, Mux Read Data -> Read Data Holding Registers
    bit [24:0] cart_bus_cs1_addr_hold = 25'h0;
    bit [15:0] cart_bus_rd_data_hold = 16'h0;

    always_ff @(posedge clk) begin
        if(rst) begin
            cart_bus_cs1_addr_hold <= 25'h0;
            cart_bus_rd_data_hold <= 16'h0;
        end else begin
            if(cs1_falling_edge)                           cart_bus_cs1_addr_hold <= { gba_adh, gba_adl, 1'b0 };
            if((rd_rising_edge | wr_rising_edge) & cs1_lo) cart_bus_cs1_addr_hold <= cart_bus_cs1_addr_hold + 2;
            if(cart_mux.cart_rd_valid)                     cart_bus_rd_data_hold <= cart_mux.cart_rd_data;
        end
    end

    // Read Data Holding Registers -> Cart Read Data
    assign gba_adl = (cs1_lo & rd_lo) ? cart_bus_rd_data_hold : 16'bz;
    assign gba_adh = (cs2_lo & rd_lo) ? cart_bus_rd_data_hold[7:0] : 8'bz;

    // Cart Address / Address Holding Register -> Mux Address
    assign cart_mux.cart_addr = 
        (cs1_rd | cs1_wr) ? { 1'b0, cart_bus_cs1_addr_hold } :
        // The address/data lines are prepared already before the r/w edges thus not in a metastable state
        (cs2_rd | cs2_wr) ? { 1'b1, 9'b0, gba_adl } :
        26'b0;

    // Cart Write Data -> Mux Write Data
    assign cart_mux.cart_wr_data =
        cs1_wr ? gba_adl :
        cs2_wr ? { 8'b0, gba_adh } :
        16'b0;

    // Cart Signal -> R/W LED
    int counter_rd = 0, counter_wr = 0;
    assign led_rd = counter_rd > 0;
    assign led_wr = counter_wr > 0;

    always_ff @(posedge clk) begin
        if(rst) begin
            counter_rd <= 0;
            counter_wr <= 0;
        end else begin
            if(cart_mux.cart_rd) counter_rd <= 1000000;
            else if(counter_rd > 0) counter_rd <= counter_rd - 1;
            if(cart_mux.cart_wr) counter_wr <= 1000000;
            else if(counter_wr > 0) counter_wr <= counter_wr - 1;
        end
    end

    ila_cart i(
        .clk(clk),
        .probe0 (cs1_rising_edge),
        .probe1 (cs1_falling_edge),
        .probe2 (cs1_lo),
        .probe3 (cs2_rising_edge),
        .probe4 (cs2_falling_edge),
        .probe5 (cs2_lo),
        .probe6 (rd_rising_edge),
        .probe7 (rd_falling_edge),
        .probe8 (rd_lo),
        .probe9 (wr_rising_edge),
        .probe10(wr_falling_edge),
        .probe11(wr_lo),
        .probe12(cart_bus_cs1_addr_hold),
        .probe13(cart_bus_rd_data_hold),
        .probe14(cs1_rd),
        .probe15(cs1_wr),
        .probe16(cs2_rd),
        .probe17(cs2_wr),
        .probe18(cart_mux.cart_rd),
        .probe19(cart_mux.cart_wr),
        .probe20(cart_mux.cart_addr),
        .probe21(cart_mux.cart_rd_data),
        .probe22(cart_mux.cart_wr_data),
        .probe23(cart_mux.cart_rd_valid),
        .probe24(gba_rd),
        .probe25(gba_wr),
        .probe26(gba_cs1),
        .probe27(gba_cs2),
        .probe28(gba_adl),
        .probe29(gba_adh),
        .probe30(cs1_history[0]),
        .probe31(cs1_history[2]),
        .probe32(cs1_history[1]),
        .probe33(cs2_history[0]),
        .probe34(cs2_history[2]),
        .probe35(cs2_history[1]),
        .probe36(rd_history[0]),
        .probe37(rd_history[2]),
        .probe38(rd_history[1]),
        .probe39(wr_history[0]),
        .probe40(wr_history[2]),
        .probe41(wr_history[1])
    );

endmodule
