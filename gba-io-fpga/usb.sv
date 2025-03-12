
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

    localparam CODE_ADDRESS                  = 26'h00000000;
    localparam CODE_SIZE                     = 26'h01000000;
    localparam VIDEO_FEED_FRAME_0_ADDRESS    = 26'h01000000;
    localparam VIDEO_FEED_FRAME_SIZE         = 26'h00020000;
    localparam SOUND_L_FEED_FRAME_0_ADDRESS  = 26'h01E00000;
    localparam SOUND_R_FEED_FRAME_0_ADDRESS  = 26'h01F00000;
    localparam SOUND_FEED_FRAME_SIZE         = 26'h00000010;
    localparam KEY_AND_STATUS_ADDRESS        = 26'h02000000;
    localparam KEY_AND_STATUS_SIZE           = 26'h00000020;

    localparam USB_TRANS_DIR_NONE            = 4'b0000; // 0x0X
    localparam USB_TRANS_DIR_IN_RX           = 4'b0100; // 0x4X
    localparam USB_TRANS_DIR_OUT_TX          = 4'b1000; // 0x8X
    localparam USB_TRANS_SEG_NONE            = 4'd0; // 0xX0
    localparam USB_TRANS_SEG_CODE            = 4'd1; // 0xX1
    localparam USB_TRANS_SEG_V_BUFFER        = 4'd2; // 0xX2
    localparam USB_TRANS_SEG_SL_BUFFER       = 4'd3; // 0xX3
    localparam USB_TRANS_SEG_SR_BUFFER       = 4'd4; // 0xX4
    localparam USB_TRANS_SEG_KEY_AND_STATUS  = 4'd5; // 0xX5
    
    bit [3:0] current_seg = USB_TRANS_SEG_NONE;
    bit [3:0] current_dir = USB_TRANS_DIR_NONE;

    logic [25:0] current_seg_size;
    assign current_seg_size =
        current_seg == USB_TRANS_SEG_NONE ? 26'h0 :
        current_seg == USB_TRANS_SEG_CODE ? CODE_SIZE :
        current_seg == USB_TRANS_SEG_V_BUFFER ? VIDEO_FEED_FRAME_SIZE :
        current_seg == USB_TRANS_SEG_SL_BUFFER ? SOUND_FEED_FRAME_SIZE :
        current_seg == USB_TRANS_SEG_SR_BUFFER ? SOUND_FEED_FRAME_SIZE :
        current_seg == USB_TRANS_SEG_KEY_AND_STATUS ? KEY_AND_STATUS_SIZE :
        26'h0;
    logic [25:0] current_base_address;
    assign current_base_address =
        current_seg == USB_TRANS_SEG_NONE ? 26'h0 :
        current_seg == USB_TRANS_SEG_CODE ? CODE_ADDRESS :
        current_seg == USB_TRANS_SEG_V_BUFFER ? VIDEO_FEED_FRAME_0_ADDRESS :
        current_seg == USB_TRANS_SEG_SL_BUFFER ? SOUND_L_FEED_FRAME_0_ADDRESS :
        current_seg == USB_TRANS_SEG_SR_BUFFER ? SOUND_R_FEED_FRAME_0_ADDRESS :
        current_seg == USB_TRANS_SEG_KEY_AND_STATUS ? KEY_AND_STATUS_ADDRESS :
        26'h0;
    bit [25:0] current_offset;
    assign mux_usb.usb_addr = current_base_address + current_offset;


    // fifo_ctrl_tx, 0x04, OUT, read from fifo, pc -> fpga
    logic ctrl_tx_ready; // Ready means the valid signal will be accepted
    logic ctrl_tx_valid; // Valid means data has already presented on the bus
    logic ctrl_tx_pktend;
    logic [31:0] ctrl_tx;

    assign ctrl_tx_ready =
        (current_seg == USB_TRANS_SEG_NONE) |
        (current_dir == USB_TRANS_DIR_NONE) |
        ((current_seg != USB_TRANS_SEG_NONE) & (current_dir != USB_TRANS_DIR_NONE) & (current_offset >= current_seg_size - 4));

    always_ff @(posedge clk) begin
        if(rst) begin
            current_seg <= USB_TRANS_SEG_NONE;
            current_dir <= USB_TRANS_DIR_NONE;
            current_offset <= 26'h0;
        end else begin
            // It appears like the current_offset could be in a metastable state, however it's not the case.
            // Because, to assert the ctrl_tx_ready, the current_seg must be NONE, but to assert the usb_rd or the usb_wr signal, the current_seg must be something meaningful.
            if(ctrl_tx_ready & ctrl_tx_valid) begin
                current_seg <= ctrl_tx[3:0];
                current_dir <= ctrl_tx[7:4];
                current_offset <= 26'h0;
            end
            if(mux_usb.usb_rd | mux_usb.usb_wr) begin
                current_offset <= (current_offset + 4);
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


    // fifo_data_tx, 0x02, OUT, read from fifo, pc -> fpga
    logic data_tx_ready; // out
    logic data_tx_valid; // in
    logic data_tx_pktend; // in
    logic [31:0] data_tx; // in

    assign data_tx_ready = mux_usb.usb_wr_ready & (current_dir == USB_TRANS_DIR_OUT_TX) &
        (current_offset <= (current_seg_size - 4)) & (current_seg != USB_TRANS_SEG_NONE);
    assign mux_usb.usb_wr = data_tx_ready & data_tx_valid;
    assign mux_usb.usb_wr_data = 
        (data_tx_ready & data_tx_valid) ? data_tx :
        32'h0;

    // fifo_data_rx, 0x86, IN, write to fifo, fpga -> pc
    logic data_rx_ready; // in
    logic data_rx_valid; // out
    logic data_rx_pktend; // out
    logic [31:0] data_rx; // out

    assign data_rx_valid = data_rx_ready & mux_usb.usb_rd_ready & mux_usb.usb_rd_valid & (current_dir == USB_TRANS_DIR_IN_RX) &
        (current_offset <= (current_seg_size - 4)) & (current_seg != USB_TRANS_SEG_NONE);
    assign data_rx_pktend =
        data_rx_valid ? (current_offset >= (current_seg_size - 4)) :
        1'b0;
    assign data_rx = 
        data_rx_valid ? mux_usb.usb_rd_data :
        32'h0;
    assign mux_usb.usb_rd = data_rx_valid;


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
            if((current_seg != USB_TRANS_SEG_NONE) & (current_offset == 26'h0)) counter_rcv <= 1000000;
            else if(counter_rcv > 0) counter_rcv <= counter_rcv - 1;
        end
    end

endmodule
