
// https://docs.amd.com/r/en-US/pg080-axi-fifo-mm-s/Protocol-Description

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

    localparam CODE_SIZE                     = 26'h01000000;
    localparam VIDEO_FEED_FRAME_SIZE         = 26'h00020000;
    localparam SOUND_FEED_FRAME_SIZE         = 26'h00000010;
    localparam KEY_AND_STATUS_SIZE           = 26'h00000020;
    localparam USB_TRANS_TYPE_NONE           = 3'b000; // 0
    localparam USB_TRANS_TYPE_CODE           = 3'b001; // 1
    localparam USB_TRANS_TYPE_V_BUFFER       = 3'b010; // 2
    localparam USB_TRANS_TYPE_SL_BUFFER      = 3'b110; // 6
    localparam USB_TRANS_TYPE_SR_BUFFER      = 3'b101; // 5
    localparam USB_TRANS_TYPE_KEY_AND_STATUS = 3'b011; // 3
    

    // fifo_data_tx, 0x02, OUT, read from fifo, pc -> fpga
    logic data_tx_ready; // out
    logic data_tx_valid; // in
    logic data_tx_pktend; // in
    logic [31:0] data_tx; // in

    assign data_tx_ready = mux_usb.usb_wr_ready & (trans_byte_remain > 0) & (
        current_trans_type == USB_TRANS_TYPE_CODE |
        current_trans_type == USB_TRANS_TYPE_V_BUFFER |
        current_trans_type == USB_TRANS_TYPE_SL_BUFFER |
        current_trans_type == USB_TRANS_TYPE_SR_BUFFER
    );
    assign mux_usb.usb_wr = data_tx_ready & data_tx_valid;
    assign mux_usb.usb_wr_data = 
        (data_tx_ready & data_tx_valid) ? data_tx :
        32'h0;

    // fifo_data_rx, 0x86, IN, write to fifo, fpga -> pc
    logic data_rx_ready; // in
    logic data_rx_valid; // out
    logic data_rx_pktend; // out
    logic [31:0] data_rx; // out

    assign data_rx_valid = data_rx_ready & mux_usb.usb_rd_ready & mux_usb.usb_rd_valid & (trans_byte_remain > 0) & (
        current_trans_type == USB_TRANS_TYPE_KEY_AND_STATUS
    );
    assign data_rx_pktend =
        data_rx_valid ? (trans_byte_remain <= 4) :
        1'b0;
    assign data_rx = 
        data_rx_valid ? mux_usb.usb_rd_data :
        32'h0;
    assign mux_usb.usb_rd = data_rx_valid;


    // fifo_ctrl_tx, 0x04, OUT, read from fifo, pc -> fpga
    logic ctrl_tx_ready; // Ready means the valid signal will be accepted
    logic ctrl_tx_valid; // Valid means data has already presented on the bus
    logic ctrl_tx_pktend;
    logic [31:0] ctrl_tx;

    bit [2:0] current_trans_type = USB_TRANS_TYPE_NONE;
    int trans_byte_remain = 0;
    assign ctrl_tx_ready = (trans_byte_remain <= 0);
    assign mux_usb.usb_trans_type = current_trans_type;

    always_ff @(posedge clk) begin
        if(rst) begin
            current_trans_type <= USB_TRANS_TYPE_NONE;
            trans_byte_remain <= 0;
        end else begin
            if(ctrl_tx_ready & ctrl_tx_valid) begin
                current_trans_type <= ctrl_tx[2:0];
                trans_byte_remain <=
                    (ctrl_tx[2:0] == USB_TRANS_TYPE_NONE) ? 0 :
                    (ctrl_tx[2:0] == USB_TRANS_TYPE_CODE) ? CODE_SIZE :
                    (ctrl_tx[2:0] == USB_TRANS_TYPE_V_BUFFER) ? VIDEO_FEED_FRAME_SIZE :
                    (ctrl_tx[2:0] == USB_TRANS_TYPE_SL_BUFFER) ? SOUND_FEED_FRAME_SIZE :
                    (ctrl_tx[2:0] == USB_TRANS_TYPE_SR_BUFFER) ? SOUND_FEED_FRAME_SIZE :
                    (ctrl_tx[2:0] == USB_TRANS_TYPE_KEY_AND_STATUS) ? KEY_AND_STATUS_SIZE :
                    0;
            end
            if(mux_usb.usb_rd) begin
                trans_byte_remain <= (trans_byte_remain - 4);
            end else if(mux_usb.usb_wr) begin
                trans_byte_remain <= (trans_byte_remain - 4);
            end
        end
    end


    // fifo_ctrl_rx, 0x88, IN, write to fifo, fpga -> pc
    logic ctrl_rx_ready;
    logic ctrl_rx_valid;
    logic ctrl_rx_pktend;
    logic [31:0] ctrl_rx; 

    localparam FINGERPRINT = 64'h47424120492F4F0A; // "GBA I/O\n"
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
            if(trans_byte_remain > 0) counter_rcv <= 1000000;
            else if(counter_rcv > 0) counter_rcv <= counter_rcv - 1;
        end
    end

endmodule
