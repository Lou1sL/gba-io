
// https://docs.amd.com/r/en-US/pg080-axi-fifo-mm-s/Protocol-Description
// https://docs.amd.com/r/en-US/pg327-emb-fifo-gen/AXI-Interface-FIFOs

// Example Usage:
// 0x04 OUT -> 80 00000000 00000004
// 0x02 OUT -> 1F 1E 1D 1C
// 0x04 OUT -> 40 00000000 00000040
// 0x86 IN  <- 1F 1E 1D 1C ....
// TODO: Fix big size failure issue

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
    // 64          32           0
    // 00 │ 0000 0000 │ 0000 0000
    // ││   ││││ ││││   ││││ ││││
    // ││   ││││ ││││   └┴┴┴─┴┴┴┴── 32-bit transmission data size, 32-bit alignment required
    // ││   ││││ ││││
    // ││   └┴┴┴─┴┴┴┴────────────── 32-bit transmission address
    // ││
    // └┴────────────────────────── 0x00: DISABLE, 0x40: IN_RX, 0x80: OUT_TX

    localparam ADDRESS_SPACE_SIZE = 32'h20000000;
    localparam FINGERPRINT = 64'h47424120492F4F0A; // "GBA I/O\n"
    localparam TRANS_TYPE_DISABLE = 8'h00;
    localparam TRANS_TYPE_IN_RX   = 8'h40;
    localparam TRANS_TYPE_OUT_TX  = 8'h80;

    bit [7:0] transmit_type = TRANS_TYPE_DISABLE;
    bit [31:0] transmit_start_address;
    bit [31:0] transmit_size;
    bit [31:0] transmit_offset;
    assign mux_usb.usb_addr = transmit_start_address + transmit_offset;
    logic last_pkt;
    assign last_pkt = transmit_offset >= (transmit_size - 4);


    // fifo_ctrl_tx, m_axis, 0b10, 0x04, OUT, read from fifo, pc -> fpga
    logic ctrl_tx_ready; // Ready means the valid signal will be accepted
    logic ctrl_tx_valid; // Valid means data has already presented on the bus
    logic ctrl_tx_pktend;
    logic [31:0] ctrl_tx;

    assign ctrl_tx_ready = (transmit_type == TRANS_TYPE_DISABLE);

    byte ctrl_tx_pkt_index = 0;
    bit [71:0] transmit_code_buffer;
    always_ff @(posedge clk) begin
        if(rst) begin
            transmit_type <= TRANS_TYPE_DISABLE;
            transmit_start_address <= 32'h0;
            transmit_size <= 32'h0;
            transmit_offset <= 32'h0;
            ctrl_tx_pkt_index <= 0;
            transmit_code_buffer <= 96'h0;
        end else begin
            if(ctrl_tx_ready & ctrl_tx_valid) begin
                case(ctrl_tx_pkt_index)
                0: begin
                    transmit_code_buffer[71:64] <= ctrl_tx[7:0];
                    transmit_code_buffer[63:56] <= ctrl_tx[15:8];
                    transmit_code_buffer[55:48] <= ctrl_tx[23:16];
                    transmit_code_buffer[47:40] <= ctrl_tx[31:24];
                    ctrl_tx_pkt_index <= 1;
                end
                1: begin
                    transmit_code_buffer[39:32] <= ctrl_tx[7:0];
                    transmit_code_buffer[32:25] <= ctrl_tx[15:8];
                    transmit_code_buffer[24:16] <= ctrl_tx[23:16];
                    transmit_code_buffer[15:8] <= ctrl_tx[31:24];
                    ctrl_tx_pkt_index <= 2;
                end
                2: begin
                    transmit_code_buffer[7:0] <= ctrl_tx[7:0];
                    if(
                        ((transmit_code_buffer[71:64] == TRANS_TYPE_IN_RX) | (transmit_code_buffer[71:64] == TRANS_TYPE_OUT_TX)) &
                        ((transmit_code_buffer[63:32] + { transmit_code_buffer[31:8], ctrl_tx[7:0] }) < ADDRESS_SPACE_SIZE) &
                        ({ transmit_code_buffer[31:8], ctrl_tx[7:0] } > 0)
                    ) begin
                        transmit_type <= transmit_code_buffer[71:64];
                        transmit_start_address <= transmit_code_buffer[63:32];
                        transmit_size <= { transmit_code_buffer[31:8], ctrl_tx[7:0] };
                        transmit_offset <= 32'h0;
                    end
                    transmit_code_buffer <= 64'h0;
                    ctrl_tx_pkt_index <= 0;
                end
                endcase
            end
            if(transmit_type != TRANS_TYPE_DISABLE) begin
                if(transmit_offset <= (transmit_size - 4)) begin
                    if(data_tx_ready | data_rx_valid) begin
                        transmit_offset <= (transmit_offset + 4);
                    end
                end else begin
                    transmit_type <= TRANS_TYPE_DISABLE;
                    transmit_start_address <= 32'h0;
                    transmit_size <= 32'h0;
                    transmit_offset <= 32'h0;
                end
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

    assign mux_usb.usb_wr = data_tx_valid & (transmit_type == TRANS_TYPE_OUT_TX);
    assign mux_usb.usb_wr_data = data_tx;
    assign data_tx_ready = mux_usb.usb_wr & mux_usb.usb_wr_ready;


    // fifo_data_rx, s_axis, 0b01, 0x86, IN, write to fifo, read from sdram, fpga -> pc
    logic data_rx_full; // in
    logic data_rx_ready; // in
    logic data_rx_valid; // out
    logic data_rx_pktend; // out
    logic [31:0] data_rx; // out

    assign mux_usb.usb_rd = data_rx_ready & (transmit_type == TRANS_TYPE_IN_RX) & ~data_rx_full;
    assign data_rx_valid = mux_usb.usb_rd & mux_usb.usb_rd_valid;
    assign data_rx_pktend = last_pkt;
    assign data_rx = mux_usb.usb_rd_data;


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
        .rx_tdata(data_rx), .rx_tlast(data_rx_pktend), .rx_tvalid(data_rx_valid), .rx_tready(data_rx_ready), .rx_full(data_rx_full),
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
            if((transmit_type != TRANS_TYPE_DISABLE) & (transmit_offset == 26'h0)) counter_rcv <= 1000000;
            else if(counter_rcv > 0) counter_rcv <= counter_rcv - 1;
        end
    end

    ila_usb i(
        .clk(clk),
        .probe0 (transmit_type),
        .probe1 (transmit_start_address),
        .probe2 (transmit_size),
        .probe3 (transmit_offset),
        .probe4 (last_pkt),
        .probe5 (ctrl_tx_pkt_index),
        .probe6 (transmit_code_buffer),
        .probe7 (ctrl_tx_ready),
        .probe8 (ctrl_tx_valid),
        .probe9 (ctrl_tx_pktend),
        .probe10(ctrl_tx),
        .probe11(ctrl_rx_ready),
        .probe12(ctrl_rx_valid),
        .probe13(ctrl_rx_pktend),
        .probe14(ctrl_rx),
        .probe15(data_tx_ready),
        .probe16(data_tx_valid),
        .probe17(data_tx_pktend),
        .probe18(data_tx),
        .probe19(data_rx_ready),
        .probe20(data_rx_valid),
        .probe21(data_rx_pktend),
        .probe22(data_rx)
    );

endmodule
