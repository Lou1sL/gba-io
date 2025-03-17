
// https://docs.amd.com/r/en-US/pg080-axi-fifo-mm-s/Protocol-Description
// https://docs.amd.com/r/en-US/pg327-emb-fifo-gen/AXI-Interface-FIFOs

// Example Usage:
// 0x88 OUT -> 80 00000000 00000004
// 0x02 OUT -> 8C 8D 8E 8F
// 0x88 OUT -> 40 00000000 00000004
// 0x04 IN  <- 8C 8D 8E 8F

`timescale 1ns / 1ps

module usb (
    input logic clk,
    input logic rst,
    output logic led_rcv,
    // USB3.1 FX3 GPIF2 Interface
    inout logic [31:0] fdata,
    output logic [1:0] faddr,
    output logic slrd, slwr,
    input logic flaga, flagb, flagc, flagd,
    output logic sloe, slcs, pktend,
    mux_usb_interface.usb mux_usb
);

    // Transmission Code Encoding
    //
    // 64     32      0
    // 00 │ 0000 │ 0000
    // ││   ││││   ││││
    // ││   ││││   └┴┴┴── 32-bit transmission data size, 32-bit alignment required
    // ││   ││││
    // ││   └┴┴┴───────── 32-bit transmission address
    // ││
    // └┴──────────────── 0x00: DISABLE, 0x40: IN_RX, 0x80: OUT_TX

    localparam FINGERPRINT = 64'h47424120492F4F0A; // "GBA I/O\n"
    localparam TRANS_TYPE_DISABLE = 8'b0000; // 0x00
    localparam TRANS_TYPE_IN_RX   = 8'b0100; // 0x40
    localparam TRANS_TYPE_OUT_TX  = 8'b1000; // 0x80

    bit [7:0] transmit_type = TRANS_TYPE_DISABLE;
    bit [31:0] transmit_start_address;
    bit [31:0] transmit_size;
    bit [31:0] transmit_current_offset;
    assign mux_usb.usb_addr = transmit_start_address + transmit_current_offset;


    // fifo_ctrl_tx, m_axis, 0b10, 0x04, OUT, read from fifo, pc -> fpga
    logic ctrl_tx_ready; // Ready means the valid signal will be accepted
    logic ctrl_tx_valid; // Valid means data has already presented on the bus
    logic ctrl_tx_pktend;
    logic [31:0] ctrl_tx;
    byte ctrl_tx_pkt_index = 0;

    assign ctrl_tx_ready =
        (transmit_type == TRANS_TYPE_DISABLE) |
        ((transmit_type != TRANS_TYPE_DISABLE) & (transmit_current_offset >= transmit_size - 4));

    always_ff @(posedge clk) begin
        if(rst) begin
            transmit_type <= TRANS_TYPE_DISABLE;
            transmit_start_address <= 32'h0;
            transmit_size <= 32'h0;
            transmit_current_offset <= 32'h0;
            ctrl_tx_pkt_index <= 0;
        end else begin
            // It appears like the transmit_current_offset could be in a metastable state, however it's not the case.
            // Because, to assert the ctrl_tx_ready, the transmit_type must be disabled, but to assert the usb_rd or the usb_wr signal, the transmit_type must be something meaningful.
            if(ctrl_tx_ready & ctrl_tx_valid) begin
                if(ctrl_tx_pkt_index == 2) transmit_type <= ctrl_tx[7:0];
                if(ctrl_tx_pkt_index == 1) transmit_start_address <= ctrl_tx;
                if(ctrl_tx_pkt_index == 0) transmit_size <= ctrl_tx;
                transmit_current_offset <= 32'h0;
                if(ctrl_tx_pkt_index < 2) ctrl_tx_pkt_index <= ctrl_tx_pkt_index + 1;
                else ctrl_tx_pkt_index <= 0;
            end
            if(data_tx_ready | data_rx_valid) begin
                transmit_current_offset <= (transmit_current_offset + 4);
            end
        end
    end


    // fifo_ctrl_rx, s_axis, 0b11, 0x88, IN, write to fifo, fpga -> pc
    logic ctrl_rx_ready;
    logic ctrl_rx_valid;
    logic ctrl_rx_pktend;
    logic [31:0] ctrl_rx;

    bit current_fingerprint = 1'b0;
    assign ctrl_rx_valid = ctrl_rx_ready;
    assign ctrl_rx_pktend = current_fingerprint == 1'b1;
    assign ctrl_rx =
        current_fingerprint ? { << byte { FINGERPRINT[31:0] } } :
        { << byte { FINGERPRINT[63:32] } };

    always_ff @(posedge clk) begin
        if(rst) begin
            current_fingerprint <= 1'b0;
        end else if(ctrl_rx_ready) begin
            current_fingerprint <= ~current_fingerprint;
        end
    end


    // fifo_data_tx, m_axis, 0b00, 0x02, OUT, read from fifo, write to sdram, pc -> fpga
    logic data_tx_ready; // out
    logic data_tx_valid; // in
    logic data_tx_pktend; // in
    logic [31:0] data_tx; // in

    assign mux_usb.usb_wr = data_tx_valid & (transmit_type == TRANS_TYPE_OUT_TX) &
        (transmit_current_offset <= (transmit_size - 4));
    assign mux_usb.usb_wr_data = data_tx_valid ? data_tx : 32'h0;
    assign data_tx_ready = mux_usb.usb_wr & mux_usb.usb_wr_ready;


    // fifo_data_rx, s_axis, 0b01, 0x86, IN, write to fifo, read from sdram, fpga -> pc
    logic data_rx_ready; // in
    logic data_rx_valid; // out
    logic data_rx_pktend; // out
    logic [31:0] data_rx; // out

    assign mux_usb.usb_rd = data_rx_ready & (transmit_type == TRANS_TYPE_IN_RX) &
        (transmit_current_offset <= (transmit_size - 4));
    assign data_rx_valid = mux_usb.usb_rd & mux_usb.usb_rd_valid;
    assign data_rx_pktend = data_rx_valid ? (transmit_current_offset >= (transmit_size - 4)) : 1'b0;
    assign data_rx = data_rx_valid ? mux_usb.usb_rd_data : 32'h0;


    gpif2_to_fifo32 gpif2_to_fifo32 (
        // GPIF signals
        .gpif_clk(clk),
        .gpif_rst(rst),
        .gpif_enb(1'b1),
        .gpif_d(fdata),
        .gpif_ctl({flagd, flagc, flagb, flaga}),
        .sloe(sloe),
        .slrd(slrd),
        .slwr(slwr),
        .slcs(slcs),
        .pktend(pktend),
        .fifoadr(faddr),
        // fifo_data_tx 0b00 0x02
        .tx_tdata(data_tx), .tx_tlast(data_tx_pktend), .tx_tvalid(data_tx_valid), .tx_tready(data_tx_ready),
        // fifo_data_rx 0b01 0x86
        .rx_tdata(data_rx), .rx_tlast(data_rx_pktend), .rx_tvalid(data_rx_valid), .rx_tready(data_rx_ready),
        // fifo_ctrl_tx 0b10 0x04
        .ctrl_tdata(ctrl_tx), .ctrl_tlast(ctrl_tx_pktend), .ctrl_tvalid(ctrl_tx_valid), .ctrl_tready(ctrl_tx_ready),
        // fifo_ctrl_rx 0b11 0x88
        .resp_tdata(ctrl_rx), .resp_tlast(ctrl_rx_pktend), .resp_tvalid(ctrl_rx_valid), .resp_tready(ctrl_rx_ready)
    );

    // LED
    int counter_rcv = 0;
    assign led_rcv = counter_rcv > 0;
    always_ff @(posedge clk) begin
        if(rst) begin
            counter_rcv <= 0;
        end else begin
            if((transmit_type != TRANS_TYPE_DISABLE) & (transmit_current_offset == 26'h0)) counter_rcv <= 1000000;
            else if(counter_rcv > 0) counter_rcv <= counter_rcv - 1;
        end
    end

    ila_usb i(
        .clk(clk),
        .probe0 (1'b0),
        .probe1 (transmit_type),
        .probe2 (transmit_start_address),
        .probe3 (transmit_current_offset),
        .probe4 (ctrl_tx_ready),
        .probe5 (ctrl_tx_valid),
        .probe6 (ctrl_tx_pktend),
        .probe7 (ctrl_tx),
        .probe8 (ctrl_rx_ready),
        .probe9 (ctrl_rx_valid),
        .probe10(ctrl_rx_pktend),
        .probe11(ctrl_rx),
        .probe12(data_tx_ready),
        .probe13(data_tx_valid),
        .probe14(data_tx_pktend),
        .probe15(data_tx),
        .probe16(data_rx_ready),
        .probe17(data_rx_valid),
        .probe18(data_rx_pktend),
        .probe19(data_rx)
    );

endmodule
