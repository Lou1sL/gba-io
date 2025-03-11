
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
    localparam CODE_OFFSET_MASK              = 26'h00FFFFFF;
    localparam VIDEO_FEED_FRAME_0_ADDRESS    = 26'h01000000;
    localparam VIDEO_FEED_FRAME_1_ADDRESS    = 26'h01020000;
    localparam VIDEO_FEED_FRAME_2_ADDRESS    = 26'h01040000;
    localparam VIDEO_FEED_FRAME_SIZE         = 26'h00020000;
    localparam VIDEO_FEED_FRAME_OFFSET_MASK  = 26'h0001FFFF;
    localparam VIDEO_FEED_SIZE               = 26'h00E00000;
    localparam SOUND_L_FEED_FRAME_0_ADDRESS  = 26'h01E00000;
    localparam SOUND_L_FEED_FRAME_1_ADDRESS  = 26'h01E00010;
    localparam SOUND_L_FEED_FRAME_2_ADDRESS  = 26'h01E00020;
    localparam SOUND_R_FEED_FRAME_0_ADDRESS  = 26'h01F00000;
    localparam SOUND_R_FEED_FRAME_1_ADDRESS  = 26'h01F00010;
    localparam SOUND_R_FEED_FRAME_2_ADDRESS  = 26'h01F00020;
    localparam SOUND_FEED_FRAME_SIZE         = 26'h00000010;
    localparam SOUND_FEED_FRAME_OFFSET_MASK  = 26'h0000000F;
    localparam SOUND_FEED_SIZE               = 26'h00100000;
    localparam KEY_AND_STATUS_ADDRESS        = 26'h02000000;
    localparam KEY_AND_STATUS_SIZE           = 26'h00000020;
    localparam KEY_AND_STATUS_OFFSET_MASK    = 26'h0000001F;

    localparam SEG_INDEX_CART_VIDEO_FEED   = 3'd0;
    localparam SEG_INDEX_CART_SOUND_L_FEED = 3'd1;
    localparam SEG_INDEX_CART_SOUND_R_FEED = 3'd2;
    localparam SEG_INDEX_USB_VIDEO_FEED    = 3'd3;
    localparam SEG_INDEX_USB_SOUND_L_FEED  = 3'd4;
    localparam SEG_INDEX_USB_SOUND_R_FEED  = 3'd5;
    localparam SEG_INDEX_NONE              = 3'b111;
    logic [3:0] current_seg_index;
    logic [25:0] current_base_address;
    logic [25:0] current_offset;
    assign mux_buffer.mem_addr = current_base_address + current_offset;
    always_comb begin
        if(mux_buffer.cart_usb_addr[25] == 1'b0) begin
            if(mux_buffer.cart_usb_addr[24] == 1'b0) begin
                current_seg_index = SEG_INDEX_NONE;
                current_base_address = CODE_ADDRESS;
                current_offset = mux_buffer.cart_usb_addr & CODE_OFFSET_MASK;
            end else if(mux_buffer.cart_usb_addr[24:20] == 5'b11110) begin
                current_seg_index =
                    mux_buffer.from_cart ? SEG_INDEX_CART_SOUND_L_FEED :
                    mux_buffer.from_usb ? SEG_INDEX_USB_SOUND_L_FEED :
                    SEG_INDEX_NONE;
                current_base_address = current_frame_occ_addr;
                current_offset = mux_buffer.cart_usb_addr & SOUND_FEED_FRAME_OFFSET_MASK;
            end else if(mux_buffer.cart_usb_addr[24:20] == 5'b11111) begin
                current_seg_index =
                    mux_buffer.from_cart ? SEG_INDEX_CART_SOUND_R_FEED :
                    mux_buffer.from_usb ? SEG_INDEX_USB_SOUND_R_FEED :
                    SEG_INDEX_NONE;
                current_base_address = current_frame_occ_addr;
                current_offset = mux_buffer.cart_usb_addr & SOUND_FEED_FRAME_OFFSET_MASK;
            end else begin
                current_seg_index =
                    mux_buffer.from_cart ? SEG_INDEX_CART_VIDEO_FEED :
                    mux_buffer.from_usb ? SEG_INDEX_USB_VIDEO_FEED :
                    SEG_INDEX_NONE;
                current_base_address = current_frame_occ_addr;
                current_offset = mux_buffer.cart_usb_addr & VIDEO_FEED_FRAME_OFFSET_MASK;
            end
        end else begin
            current_seg_index = SEG_INDEX_NONE;
            current_base_address = KEY_AND_STATUS_ADDRESS;
            current_offset = mux_buffer.cart_usb_addr & KEY_AND_STATUS_OFFSET_MASK;
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
        (current_seg_index == SEG_INDEX_CART_VIDEO_FEED  ) ? OCC_SEL_V  :
        (current_seg_index == SEG_INDEX_CART_SOUND_L_FEED) ? OCC_SEL_SL :
        (current_seg_index == SEG_INDEX_CART_SOUND_R_FEED) ? OCC_SEL_SR :
        (current_seg_index == SEG_INDEX_USB_VIDEO_FEED   ) ? OCC_SEL_V  :
        (current_seg_index == SEG_INDEX_USB_SOUND_L_FEED ) ? OCC_SEL_SL :
        (current_seg_index == SEG_INDEX_USB_SOUND_R_FEED ) ? OCC_SEL_SR :
        OCC_SEL_NONE;
    logic [1:0] current_seg_occupier;
    assign current_seg_occupier =
        (current_seg_index == SEG_INDEX_CART_VIDEO_FEED  ) ? OCCUPIER_CART :
        (current_seg_index == SEG_INDEX_CART_SOUND_L_FEED) ? OCCUPIER_CART :
        (current_seg_index == SEG_INDEX_CART_SOUND_R_FEED) ? OCCUPIER_CART :
        (current_seg_index == SEG_INDEX_USB_VIDEO_FEED   ) ? OCCUPIER_USB :
        (current_seg_index == SEG_INDEX_USB_SOUND_L_FEED ) ? OCCUPIER_USB :
        (current_seg_index == SEG_INDEX_USB_SOUND_R_FEED ) ? OCCUPIER_USB :
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
            frame_occ <= '{
                '{ OCCUPIER_NONE, OCCUPIER_CART, OCCUPIER_USB },
                '{ OCCUPIER_NONE, OCCUPIER_CART, OCCUPIER_USB },
                '{ OCCUPIER_NONE, OCCUPIER_CART, OCCUPIER_USB }
            };
        end else begin
            if(
                (current_seg_index != SEG_INDEX_NONE) &
                (current_seg_occ_sel != OCC_SEL_NONE) &
                (next_free_occ_index != OCC_INDEX_INVALID) &
                (current_offset == 26'h0)) begin
                frame_occ[current_seg_occ_sel][next_free_occ_index] <= current_seg_occupier;
                frame_occ[current_seg_occ_sel][current_occ_index] <= OCCUPIER_NONE;
            end
        end
    end
endmodule
