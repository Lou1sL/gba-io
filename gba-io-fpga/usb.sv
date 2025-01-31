
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
    localparam USB_TRANS_TYPE_NONE           = 3'b000;
    localparam USB_TRANS_TYPE_CODE           = 3'b001;
    localparam USB_TRANS_TYPE_V_BUFFER       = 3'b010;
    localparam USB_TRANS_TYPE_SL_BUFFER      = 3'b110;
    localparam USB_TRANS_TYPE_SR_BUFFER      = 3'b101;
    localparam USB_TRANS_TYPE_KEY_AND_STATUS = 3'b011;
    

    // fifo_data_tx, 0x02, OUT, read from fifo, pc -> fpga
    logic data_tx_ready;
    logic data_tx_valid;
    logic data_tx_pktend;
    logic [31:0] data_tx;

    assign data_tx_ready = (mux_usb.mux_wr_valid | 1'b1) & (trans_byte_remain > 0) & ( // TODO: remove | 1'b1
        current_trans_type == USB_TRANS_TYPE_CODE |
        current_trans_type == USB_TRANS_TYPE_V_BUFFER |
        current_trans_type == USB_TRANS_TYPE_SL_BUFFER |
        current_trans_type == USB_TRANS_TYPE_SR_BUFFER
    );
    always_ff @(posedge clk) begin
        if(rst) begin
        end else if(data_tx_ready & data_tx_valid) begin
            mux_usb.usb_rd = 1'b0;
            mux_usb.usb_wr = 1'b1;
            mux_usb.usb_trans_type = current_trans_type;
            mux_usb.usb_wr_data = data_tx;
        end else begin
            // TODO: data rx
        end
    end


    // fifo_data_rx, 0x86, IN, write to fifo, fpga -> pc
    logic data_rx_ready; // in
    logic data_rx_valid; // out
    logic data_rx_pktend; // out
    logic [31:0] data_rx; // out

    localparam TEST_INPUT_LEN = 32;
    logic [7:0] TEST_INPUT_0 [TEST_INPUT_LEN] = {
        8'b0, 8'b0, 8'b0, 8'b0,
        8'b0, 8'b0, 8'b0, 8'b0,
        8'b0, 8'b0,
        8'b0, 8'b0,
        8'b0, 8'b0, 8'b0, 8'b0,
        8'b10011111, 8'b11111111,
        8'b0, 8'b0, 8'b0, 8'b0, 8'b0, 8'b0, 
        8'b0, 8'b0,
        8'b0, 8'b0,
        8'b0, 8'b0,
        8'b0, 8'b0
    };
    logic [7:0] TEST_INPUT_1 [TEST_INPUT_LEN] = {
        8'b0, 8'b0, 8'b0, 8'b0,
        8'b0, 8'b0, 8'b0, 8'b0,
        8'b0, 8'b0,
        8'b0, 8'b0,
        8'b0, 8'b0, 8'b0, 8'b0,
        8'b01101111, 8'b11111111,
        8'b0, 8'b0, 8'b0, 8'b0, 8'b0, 8'b0, 
        8'b0, 8'b0,
        8'b0, 8'b0,
        8'b0, 8'b0,
        8'b0, 8'b0
    };
    bit current_test_input_sel = 1'b0;
    logic [7:0] current_test_input [TEST_INPUT_LEN];
    assign current_test_input = current_test_input_sel ? TEST_INPUT_1 : TEST_INPUT_0;
    int current_test_input_index = 0;
    assign data_rx_valid = data_rx_ready;
    assign data_rx_pktend = current_test_input_index == (TEST_INPUT_LEN - 4);
    assign data_rx = {
        current_test_input[current_test_input_index + 3],
        current_test_input[current_test_input_index + 2],
        current_test_input[current_test_input_index + 1],
        current_test_input[current_test_input_index + 0]
    };
    int counter = 0;

    always_ff @(posedge clk) begin
        if(rst) begin
            current_test_input_sel <= 1'b0;
            current_test_input_index <= 0;
            counter <= 0;
        end else begin
            counter <= counter + 1;
            if(counter >= 100000000) begin
                counter <= 0;
                current_test_input_sel <= ~current_test_input_sel;
            end
            if(data_rx_ready) begin
                current_test_input_index <=
                    (current_test_input_index >= (TEST_INPUT_LEN - 4)) ? 'd0 :
                    (current_test_input_index + 4);
            end
        end
    end


    // fifo_ctrl_tx, 0x04, OUT, read from fifo, pc -> fpga
    logic ctrl_tx_ready; // Ready means the valid signal will be accepted
    logic ctrl_tx_valid; // Valid means data has already presented on the bus
    logic ctrl_tx_pktend;
    logic [31:0] ctrl_tx;

    bit [2:0] current_trans_type = USB_TRANS_TYPE_NONE;
    int trans_byte_remain = 0;
    assign ctrl_tx_ready = (trans_byte_remain <= 0);

    always_ff @(posedge clk) begin
        if(rst) begin
            current_trans_type <= USB_TRANS_TYPE_NONE;
            trans_byte_remain <= 0;
        end else if(ctrl_tx_ready & ctrl_tx_valid) begin
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
