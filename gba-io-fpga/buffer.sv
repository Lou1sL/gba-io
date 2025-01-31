
`timescale 1ns / 1ps
`include "gba_io_fpga_header.svh"

module buffer (
    input logic clk,
    input logic rst,
    mux_buffer_interface.buffer mux_buffer
);

    // Cartridge Bus Address Encoding
    //
    //   24        20        16        12        8         4         0
    // 0 0 │ 0 0 0 0 │ 0 0 0 0 │ 0 0 0 0 │ 0 0 0 0 │ 0 0 0 0 │ 0 0 0 0
    // │ │   │ │ │ │     │ │ │                           │ │         │
    // │ │   │ │ │ │     │ │ │                           │ │         └── 16-bit alignment shift fixed zero
    // │ │   │ │ │ │     │ │ │                           │ │
    // │ │   │ │ │ │     │ │ │                           └─┴──────────── 00: SOUND_X_FEED_FRAME_0, 01: SOUND_X_FEED_FRAME_1, 10: SOUND_X_FEED_FRAME_2
    // │ │   │ │ │ │     │ │ │
    // │ │   │ │ │ │     └─┴─┴────────────────────────────────────────── 000: VIDEO_FEED_FRAME_0, 010: VIDEO_FEED_FRAME_1, 100: VIDEO_FEED_FRAME_2
    // │ │   │ │ │ │
    // │ │   └─┴─┴─┴──────────────────────────────────────────────────── 1110: SOUND_L_FEED, 1111: SOUND_R_FEED, rest: VIDEO_FEED
    // │ │
    // │ └────────────────────────────────────────────────────────────── 0: CODE, 1: XXXX_FEED
    // │
    // └──────────────────────────────────────────────────────────────── 0: ^CS1 == 1, 1: ^CS2 == 1 (for SDRAM)

    localparam CODE_ADDRESS                  = 26'h00000000;
    localparam CODE_SIZE                     = 26'h01000000;
    localparam VIDEO_FEED_FRAME_0_ADDRESS    = 26'h01000000;
    localparam VIDEO_FEED_FRAME_1_ADDRESS    = 26'h01020000;
    localparam VIDEO_FEED_FRAME_2_ADDRESS    = 26'h01040000;
    localparam VIDEO_FEED_FRAME_SIZE         = 26'h00020000;
    localparam VIDEO_FEED_SIZE               = 26'h00E00000;
    localparam SOUND_L_FEED_FRAME_0_ADDRESS  = 26'h01E00000;
    localparam SOUND_L_FEED_FRAME_1_ADDRESS  = 26'h01E00010;
    localparam SOUND_L_FEED_FRAME_2_ADDRESS  = 26'h01E00020;
    localparam SOUND_R_FEED_FRAME_0_ADDRESS  = 26'h01F00000;
    localparam SOUND_R_FEED_FRAME_1_ADDRESS  = 26'h01F00010;
    localparam SOUND_R_FEED_FRAME_2_ADDRESS  = 26'h01F00020;
    localparam SOUND_FEED_FRAME_SIZE         = 26'h00000010;
    localparam SOUND_FEED_SIZE               = 26'h00100000;
    localparam KEY_AND_STATUS_ADDRESS        = 26'h02000000;
    localparam KEY_AND_STATUS_SIZE           = 26'h00000020;
    localparam USB_TRANS_TYPE_NONE           = 3'b000;
    localparam USB_TRANS_TYPE_CODE           = 3'b001;
    localparam USB_TRANS_TYPE_V_BUFFER       = 3'b010;
    localparam USB_TRANS_TYPE_SL_BUFFER      = 3'b110;
    localparam USB_TRANS_TYPE_SR_BUFFER      = 3'b101;
    localparam USB_TRANS_TYPE_KEY_AND_STATUS = 3'b011;

    // 0~2: Cart V, SL, SR; 3~7: USB Code, V, SL, SR, KS
    bit [25:0] current_seg_offset [8] = '{ 26'b0, 26'b0, 26'b0, 26'b0, 26'b0, 26'b0, 26'b0, 26'b0 };
    localparam SEG_INDEX_NONE = 4'b1111;
    logic [3:0] current_seg_index;
    logic [25:0] current_seg_size;
    assign current_seg_size =
        (current_seg_index == 0) ? VIDEO_FEED_SIZE :
        (current_seg_index == 1) ? SOUND_FEED_SIZE :
        (current_seg_index == 2) ? SOUND_FEED_SIZE :
        (current_seg_index == 3) ? CODE_SIZE :
        (current_seg_index == 4) ? VIDEO_FEED_SIZE :
        (current_seg_index == 5) ? SOUND_FEED_SIZE :
        (current_seg_index == 6) ? SOUND_FEED_SIZE :
        (current_seg_index == 7) ? KEY_AND_STATUS_SIZE :
        26'b0;
    always_comb begin
        if(mux_buffer.from_cart) begin
            if(mux_buffer.cart_addr[25] == 1'b0) begin
                if(mux_buffer.cart_addr[24] == 1'b0) begin
                    current_seg_index = SEG_INDEX_NONE;
                    mux_buffer.mem_addr = CODE_ADDRESS + mux_buffer.cart_addr;
                end
                else if(mux_buffer.cart_addr[24:20] == 5'b11110) begin
                    current_seg_index = 1; // Cart SL
                    mux_buffer.mem_addr = current_frame_occ_addr + current_seg_offset[1];
                end
                else if(mux_buffer.cart_addr[24:20] == 5'b11111) begin
                    current_seg_index = 2; // Cart SR
                    mux_buffer.mem_addr = current_frame_occ_addr + current_seg_offset[2];
                end
                else begin
                    current_seg_index = 0; // Cart V
                    mux_buffer.mem_addr = current_frame_occ_addr + current_seg_offset[0];
                end
            end
            else if(mux_buffer.cart_addr[25] == 1'b1) begin
                current_seg_index = SEG_INDEX_NONE; // Cart KS
                mux_buffer.mem_addr = KEY_AND_STATUS_ADDRESS + mux_buffer.cart_addr[15:0];
            end
        end
        else if(mux_buffer.from_usb) begin
            if(mux_buffer.usb_trans_type == USB_TRANS_TYPE_CODE) begin
                current_seg_index = 3;
                mux_buffer.mem_addr = CODE_ADDRESS + current_seg_offset[3];
            end
            else if(mux_buffer.usb_trans_type == USB_TRANS_TYPE_V_BUFFER) begin
                current_seg_index = 4;
                mux_buffer.mem_addr = current_frame_occ_addr + current_seg_offset[4];
            end
            else if(mux_buffer.usb_trans_type == USB_TRANS_TYPE_SL_BUFFER) begin
                current_seg_index = 5;
                mux_buffer.mem_addr = current_frame_occ_addr + current_seg_offset[5];
            end
            else if(mux_buffer.usb_trans_type == USB_TRANS_TYPE_SR_BUFFER) begin
                current_seg_index = 6;
                mux_buffer.mem_addr = current_frame_occ_addr + current_seg_offset[6];
            end
            else if(mux_buffer.usb_trans_type == USB_TRANS_TYPE_KEY_AND_STATUS) begin
                current_seg_index = 7;
                mux_buffer.mem_addr = KEY_AND_STATUS_ADDRESS + current_seg_offset[7];
            end
            else begin
                current_seg_index = SEG_INDEX_NONE;
                mux_buffer.mem_addr = 26'h0;
            end
        end
        else begin
            current_seg_index = SEG_INDEX_NONE;
            mux_buffer.mem_addr = 26'h0;
        end
    end

    // Triple Buffering
    localparam OCC_SEL_V = 2'b00;
    localparam OCC_SEL_SL = 2'b01;
    localparam OCC_SEL_SR = 2'b10;
    localparam OCC_SEL_NONE = 2'b11;
    localparam OCC_INDEX_INVALID = 2'b11;
    localparam OCCUPIER_NONE = 2'b00;
    localparam OCCUPIER_CART = 2'b01;
    localparam OCCUPIER_USB = 2'b10;
    localparam OCCUPIER_INVALID = 2'b11;

    bit [1:0] frame_occ [3][3] = '{
        '{ OCCUPIER_NONE, OCCUPIER_CART, OCCUPIER_USB },
        '{ OCCUPIER_NONE, OCCUPIER_CART, OCCUPIER_USB },
        '{ OCCUPIER_NONE, OCCUPIER_CART, OCCUPIER_USB }
    };
    logic [1:0] current_seg_occ_sel;
    assign current_seg_occ_sel =
        (current_seg_index == 0) ? OCC_SEL_V :
        (current_seg_index == 1) ? OCC_SEL_SL :
        (current_seg_index == 2) ? OCC_SEL_SR :
        (current_seg_index == 3) ? OCC_SEL_NONE :
        (current_seg_index == 4) ? OCC_SEL_V :
        (current_seg_index == 5) ? OCC_SEL_SL :
        (current_seg_index == 6) ? OCC_SEL_SR :
        (current_seg_index == 7) ? OCC_SEL_NONE :
        OCC_SEL_NONE;
    logic [1:0] current_seg_occupier;
    assign current_seg_occupier =
        (current_seg_index == 0) ? OCCUPIER_CART :
        (current_seg_index == 1) ? OCCUPIER_CART :
        (current_seg_index == 2) ? OCCUPIER_CART :
        (current_seg_index == 3) ? OCCUPIER_USB :
        (current_seg_index == 4) ? OCCUPIER_USB :
        (current_seg_index == 5) ? OCCUPIER_USB :
        (current_seg_index == 6) ? OCCUPIER_USB :
        (current_seg_index == 7) ? OCCUPIER_USB :
        OCCUPIER_INVALID;
    logic [1:0] next_free_occ_index;
    assign next_free_occ_index = 
        (current_seg_occ_sel == OCC_SEL_NONE) ? OCC_INDEX_INVALID :
        (frame_occ[current_seg_occ_sel][0] == OCCUPIER_NONE) ? 0 :
        (frame_occ[current_seg_occ_sel][1] == OCCUPIER_NONE) ? 1 :
        (frame_occ[current_seg_occ_sel][2] == OCCUPIER_NONE) ? 2 :
        OCC_INDEX_INVALID;
    logic [1:0] current_occ_index;
    assign current_occ_index =
        ((current_seg_occ_sel == OCC_SEL_NONE) | (current_seg_occupier == OCCUPIER_INVALID)) ? OCC_INDEX_INVALID :
        (frame_occ[current_seg_occ_sel][0] == current_seg_occupier) ? 0 :
        (frame_occ[current_seg_occ_sel][1] == current_seg_occupier) ? 1 :
        (frame_occ[current_seg_occ_sel][2] == current_seg_occupier) ? 2 :
        OCC_INDEX_INVALID;
    logic [25:0] current_frame_occ_addr;
    assign current_frame_occ_addr = 
        ((current_seg_occ_sel == OCC_SEL_V) & (current_occ_index == 0)) ?
            VIDEO_FEED_FRAME_0_ADDRESS :
        ((current_seg_occ_sel == OCC_SEL_V) & (current_occ_index == 1)) ?
            VIDEO_FEED_FRAME_1_ADDRESS :
        ((current_seg_occ_sel == OCC_SEL_V) & (current_occ_index == 2)) ?
            VIDEO_FEED_FRAME_2_ADDRESS :
        ((current_seg_occ_sel == OCC_SEL_SL) & (current_occ_index == 0)) ?
            SOUND_L_FEED_FRAME_0_ADDRESS :
        ((current_seg_occ_sel == OCC_SEL_SL) & (current_occ_index == 1)) ?
            SOUND_L_FEED_FRAME_1_ADDRESS :
        ((current_seg_occ_sel == OCC_SEL_SL) & (current_occ_index == 2)) ?
            SOUND_L_FEED_FRAME_2_ADDRESS :
        ((current_seg_occ_sel == OCC_SEL_SR) & (current_occ_index == 0)) ?
            SOUND_R_FEED_FRAME_0_ADDRESS :
        ((current_seg_occ_sel == OCC_SEL_SR) & (current_occ_index == 1)) ?
            SOUND_R_FEED_FRAME_1_ADDRESS :
        ((current_seg_occ_sel == OCC_SEL_SR) & (current_occ_index == 2)) ?
            SOUND_R_FEED_FRAME_2_ADDRESS :
        26'b0;

    always_ff @(posedge clk) begin
        if(rst) begin
            for(int i = 0; i < 8; i = i + 1) begin
                current_seg_offset[i] <= 26'h0;
            end
            frame_occ <= '{
                '{ OCCUPIER_NONE, OCCUPIER_CART, OCCUPIER_USB },
                '{ OCCUPIER_NONE, OCCUPIER_CART, OCCUPIER_USB },
                '{ OCCUPIER_NONE, OCCUPIER_CART, OCCUPIER_USB }
            };
        end
        else begin
            if(
                (current_seg_index != SEG_INDEX_NONE) &
                (current_seg_occ_sel != OCC_SEL_NONE) &
                (next_free_occ_index != OCC_INDEX_INVALID)) begin
                if(current_seg_offset[current_seg_index] >= current_seg_size) begin
                    frame_occ[current_seg_occ_sel][next_free_occ_index] <= current_seg_occupier;
                    frame_occ[current_seg_occ_sel][current_occ_index] <= OCCUPIER_NONE;
                    current_seg_offset[current_seg_index] <= 26'h0;
                end
                else current_seg_offset[current_seg_index] <= current_seg_offset[current_seg_index] + 1;
            end
        end
    end
endmodule
