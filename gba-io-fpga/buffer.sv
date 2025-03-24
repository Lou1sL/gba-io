
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

    localparam COMPACT_CODE_ADDRESS                  = 19'h00000;
    localparam COMPACT_CODE_SIZE                     = 19'h02000;
    localparam COMPACT_CODE_OFFSET_MASK              = 19'h01FFF;
    localparam COMPACT_VIDEO_FEED_FRAME_0_ADDRESS    = 19'h02000;
    // localparam COMPACT_VIDEO_FEED_FRAME_1_ADDRESS    = 19'h22000;
    localparam COMPACT_VIDEO_FEED_FRAME_1_ADDRESS    = 19'h02000;
    // localparam COMPACT_VIDEO_FEED_FRAME_2_ADDRESS    = 19'h42000;
    localparam COMPACT_VIDEO_FEED_FRAME_2_ADDRESS    = 19'h02000;
    localparam COMPACT_VIDEO_FEED_FRAME_SIZE         = 19'h20000;
    localparam COMPACT_VIDEO_FEED_FRAME_OFFSET_MASK  = 19'h1FFFF;
    // localparam COMPACT_VIDEO_FEED_SIZE               = 19'h60000;
    localparam COMPACT_VIDEO_FEED_SIZE               = 19'h20000;
    // localparam COMPACT_SOUND_L_FEED_FRAME_0_ADDRESS  = 19'h62000;
    localparam COMPACT_SOUND_L_FEED_FRAME_0_ADDRESS  = 19'h22000;
    // localparam COMPACT_SOUND_L_FEED_FRAME_1_ADDRESS  = 19'h62010;
    localparam COMPACT_SOUND_L_FEED_FRAME_1_ADDRESS  = 19'h22010;
    // localparam COMPACT_SOUND_L_FEED_FRAME_2_ADDRESS  = 19'h62020;
    localparam COMPACT_SOUND_L_FEED_FRAME_2_ADDRESS  = 19'h22020;
    // localparam COMPACT_SOUND_R_FEED_FRAME_0_ADDRESS  = 19'h62030;
    localparam COMPACT_SOUND_R_FEED_FRAME_0_ADDRESS  = 19'h22030;
    // localparam COMPACT_SOUND_R_FEED_FRAME_1_ADDRESS  = 19'h62040;
    localparam COMPACT_SOUND_R_FEED_FRAME_1_ADDRESS  = 19'h22040;
    // localparam COMPACT_SOUND_R_FEED_FRAME_2_ADDRESS  = 19'h62050;
    localparam COMPACT_SOUND_R_FEED_FRAME_2_ADDRESS  = 19'h22050;
    localparam COMPACT_SOUND_FEED_FRAME_SIZE         = 19'h00010;
    localparam COMPACT_SOUND_FEED_FRAME_OFFSET_MASK  = 19'h0000F;
    localparam COMPACT_SOUND_FEED_SIZE               = 19'h00030;
    // localparam COMPACT_KEY_AND_STATUS_ADDRESS        = 19'h62060;
    localparam COMPACT_KEY_AND_STATUS_ADDRESS        = 19'h22060;
    localparam COMPACT_KEY_AND_STATUS_SIZE           = 19'h00020;
    localparam COMPACT_KEY_AND_STATUS_OFFSET_MASK    = 19'h0001F;

    localparam SEG_CART_VIDEO_FEED   = 3'd0;
    localparam SEG_CART_SOUND_L_FEED = 3'd1;
    localparam SEG_CART_SOUND_R_FEED = 3'd2;
    localparam SEG_USB_VIDEO_FEED    = 3'd3;
    localparam SEG_USB_SOUND_L_FEED  = 3'd4;
    localparam SEG_USB_SOUND_R_FEED  = 3'd5;
    localparam SEG_NONE              = 3'b111;

    localparam OCC_SEL_V = 2'b00;
    localparam OCC_SEL_SL = 2'b01;
    localparam OCC_SEL_SR = 2'b10;
    localparam OCC_SEL_NONE = 2'b11;
    localparam OCC_INDEX_INVALID = 2'b11;
    localparam OCCUPIER_NONE = 2'b00;
    localparam OCCUPIER_CART = 2'b01;
    localparam OCCUPIER_USB = 2'b10;
    localparam OCCUPIER_INVALID = 2'b11;

    bit [3:0] current_seg;
    bit [25:0] current_base_address;
    bit [25:0] current_offset;
    bit [18:0] current_compact_base_address;
    bit [18:0] current_compact_offset;
    assign mux_buffer.mem_addr = current_base_address + current_offset;
    assign mux_buffer.compact_addr = current_compact_base_address + current_compact_offset;

    bit [1:0] frame_occ [3][3] = '{
        '{ OCCUPIER_NONE, OCCUPIER_CART, OCCUPIER_USB },
        '{ OCCUPIER_NONE, OCCUPIER_CART, OCCUPIER_USB },
        '{ OCCUPIER_NONE, OCCUPIER_CART, OCCUPIER_USB }
    };
    logic [1:0] current_seg_occ_sel;
    assign current_seg_occ_sel =
        (current_seg == SEG_CART_VIDEO_FEED  ) ? OCC_SEL_V  :
        (current_seg == SEG_CART_SOUND_L_FEED) ? OCC_SEL_SL :
        (current_seg == SEG_CART_SOUND_R_FEED) ? OCC_SEL_SR :
        (current_seg == SEG_USB_VIDEO_FEED   ) ? OCC_SEL_V  :
        (current_seg == SEG_USB_SOUND_L_FEED ) ? OCC_SEL_SL :
        (current_seg == SEG_USB_SOUND_R_FEED ) ? OCC_SEL_SR :
        OCC_SEL_NONE;
    logic [1:0] current_seg_occupier;
    assign current_seg_occupier =
        (current_seg == SEG_CART_VIDEO_FEED  ) ? OCCUPIER_CART :
        (current_seg == SEG_CART_SOUND_L_FEED) ? OCCUPIER_CART :
        (current_seg == SEG_CART_SOUND_R_FEED) ? OCCUPIER_CART :
        (current_seg == SEG_USB_VIDEO_FEED   ) ? OCCUPIER_USB :
        (current_seg == SEG_USB_SOUND_L_FEED ) ? OCCUPIER_USB :
        (current_seg == SEG_USB_SOUND_R_FEED ) ? OCCUPIER_USB :
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
    logic [18:0] current_frame_occ_compact_addr;
    assign current_frame_occ_compact_addr = 
        ((current_seg_occ_sel == OCC_SEL_V) & (current_occ_index == 0)) ?
            COMPACT_VIDEO_FEED_FRAME_0_ADDRESS :
        ((current_seg_occ_sel == OCC_SEL_V) & (current_occ_index == 1)) ?
            COMPACT_VIDEO_FEED_FRAME_1_ADDRESS :
        ((current_seg_occ_sel == OCC_SEL_V) & (current_occ_index == 2)) ?
            COMPACT_VIDEO_FEED_FRAME_2_ADDRESS :
        ((current_seg_occ_sel == OCC_SEL_SL) & (current_occ_index == 0)) ?
            COMPACT_SOUND_L_FEED_FRAME_0_ADDRESS :
        ((current_seg_occ_sel == OCC_SEL_SL) & (current_occ_index == 1)) ?
            COMPACT_SOUND_L_FEED_FRAME_1_ADDRESS :
        ((current_seg_occ_sel == OCC_SEL_SL) & (current_occ_index == 2)) ?
            COMPACT_SOUND_L_FEED_FRAME_2_ADDRESS :
        ((current_seg_occ_sel == OCC_SEL_SR) & (current_occ_index == 0)) ?
            COMPACT_SOUND_R_FEED_FRAME_0_ADDRESS :
        ((current_seg_occ_sel == OCC_SEL_SR) & (current_occ_index == 1)) ?
            COMPACT_SOUND_R_FEED_FRAME_1_ADDRESS :
        ((current_seg_occ_sel == OCC_SEL_SR) & (current_occ_index == 2)) ?
            COMPACT_SOUND_R_FEED_FRAME_2_ADDRESS :
        19'b0;

    always_ff @(posedge clk) begin
        if(rst) begin
            current_seg <= 4'h0;
            current_base_address <= 26'h0;
            current_offset <= 26'h0;
            current_compact_base_address <= 19'h0;
            current_compact_offset <= 19'h0;
            frame_occ <= '{
                '{ OCCUPIER_NONE, OCCUPIER_CART, OCCUPIER_USB },
                '{ OCCUPIER_NONE, OCCUPIER_CART, OCCUPIER_USB },
                '{ OCCUPIER_NONE, OCCUPIER_CART, OCCUPIER_USB }
            };
        end else if(mux_buffer.from_cart | mux_buffer.from_usb) begin
            if(mux_buffer.cart_usb_addr[25] == 1'b0) begin
                if(mux_buffer.cart_usb_addr[24] == 1'b0) begin
                    current_seg <= SEG_NONE;
                    current_base_address <= CODE_ADDRESS;
                    current_offset <= mux_buffer.cart_usb_addr & CODE_OFFSET_MASK;
                    current_compact_base_address <= COMPACT_CODE_ADDRESS;
                    current_compact_offset <= mux_buffer.cart_usb_addr & COMPACT_CODE_OFFSET_MASK;
                end else if(mux_buffer.cart_usb_addr[24:20] == 5'b11110) begin
                    current_seg <=
                        mux_buffer.from_cart ? SEG_CART_SOUND_L_FEED :
                        mux_buffer.from_usb ? SEG_USB_SOUND_L_FEED :
                        SEG_NONE;
                    current_base_address <= current_frame_occ_addr;
                    current_offset <= mux_buffer.cart_usb_addr & SOUND_FEED_FRAME_OFFSET_MASK;
                    current_compact_base_address <= current_frame_occ_compact_addr;
                    current_compact_offset <= mux_buffer.cart_usb_addr & COMPACT_SOUND_FEED_FRAME_OFFSET_MASK;
                    if((next_free_occ_index != OCC_INDEX_INVALID) &
                        (mux_buffer.cart_usb_addr & SOUND_FEED_FRAME_OFFSET_MASK == 26'h0)) begin
                        if(mux_buffer.from_cart) begin
                            frame_occ[current_seg_occ_sel][next_free_occ_index] <= OCCUPIER_CART;
                            frame_occ[current_seg_occ_sel][current_occ_index] <= OCCUPIER_NONE;
                        end else if(mux_buffer.from_usb) begin
                            frame_occ[current_seg_occ_sel][next_free_occ_index] <= OCCUPIER_USB;
                            frame_occ[current_seg_occ_sel][current_occ_index] <= OCCUPIER_NONE;
                        end
                    end
                end else if(mux_buffer.cart_usb_addr[24:20] == 5'b11111) begin
                    current_seg <=
                        mux_buffer.from_cart ? SEG_CART_SOUND_R_FEED :
                        mux_buffer.from_usb ? SEG_USB_SOUND_R_FEED :
                        SEG_NONE;
                    current_base_address <= current_frame_occ_addr;
                    current_offset <= mux_buffer.cart_usb_addr & SOUND_FEED_FRAME_OFFSET_MASK;
                    current_compact_base_address <= current_frame_occ_compact_addr;
                    current_compact_offset <= mux_buffer.cart_usb_addr & COMPACT_SOUND_FEED_FRAME_OFFSET_MASK;
                    if((next_free_occ_index != OCC_INDEX_INVALID) &
                        (mux_buffer.cart_usb_addr & SOUND_FEED_FRAME_OFFSET_MASK == 26'h0)) begin
                        if(mux_buffer.from_cart) begin
                            frame_occ[current_seg_occ_sel][next_free_occ_index] <= OCCUPIER_CART;
                            frame_occ[current_seg_occ_sel][current_occ_index] <= OCCUPIER_NONE;
                        end else if(mux_buffer.from_usb) begin
                            frame_occ[current_seg_occ_sel][next_free_occ_index] <= OCCUPIER_USB;
                            frame_occ[current_seg_occ_sel][current_occ_index] <= OCCUPIER_NONE;
                        end
                    end
                end else begin
                    current_seg <=
                        mux_buffer.from_cart ? SEG_CART_VIDEO_FEED :
                        mux_buffer.from_usb ? SEG_USB_VIDEO_FEED :
                        SEG_NONE;
                    current_base_address <= current_frame_occ_addr;
                    current_offset <= mux_buffer.cart_usb_addr & VIDEO_FEED_FRAME_OFFSET_MASK;
                    current_compact_base_address <= current_frame_occ_compact_addr;
                    current_compact_offset <= mux_buffer.cart_usb_addr & COMPACT_VIDEO_FEED_FRAME_OFFSET_MASK;
                    if((next_free_occ_index != OCC_INDEX_INVALID) &
                        (mux_buffer.cart_usb_addr & VIDEO_FEED_FRAME_OFFSET_MASK == 26'h0)) begin
                        if(mux_buffer.from_cart) begin
                            frame_occ[current_seg_occ_sel][next_free_occ_index] <= OCCUPIER_CART;
                            frame_occ[current_seg_occ_sel][current_occ_index] <= OCCUPIER_NONE;
                        end else if(mux_buffer.from_usb) begin
                            frame_occ[current_seg_occ_sel][next_free_occ_index] <= OCCUPIER_USB;
                            frame_occ[current_seg_occ_sel][current_occ_index] <= OCCUPIER_NONE;
                        end
                    end
                end
            end else begin
                current_seg <= SEG_NONE;
                current_base_address <= KEY_AND_STATUS_ADDRESS;
                current_offset <= mux_buffer.cart_usb_addr & KEY_AND_STATUS_OFFSET_MASK;
                current_compact_base_address <= COMPACT_KEY_AND_STATUS_ADDRESS;
                current_compact_offset <= mux_buffer.cart_usb_addr & COMPACT_KEY_AND_STATUS_OFFSET_MASK;
            end
        end
    end

    ila_buffer i(
        .clk(clk),
        .probe0 (current_seg),
        .probe1 (current_base_address),
        .probe2 (current_offset),
        .probe3 (current_compact_base_address),
        .probe4 (current_compact_offset),
        .probe5 (frame_occ[0][0]),
        .probe6 (frame_occ[0][1]),
        .probe7 (frame_occ[0][2]),
        .probe8 (frame_occ[1][0]),
        .probe9 (frame_occ[1][1]),
        .probe10(frame_occ[1][2]),
        .probe11(frame_occ[2][0]),
        .probe12(frame_occ[2][1]),
        .probe13(frame_occ[2][2]),
        .probe14(current_seg_occ_sel),
        .probe15(current_seg_occupier),
        .probe16(next_free_occ_index),
        .probe17(current_occ_index),
        .probe18(current_frame_occ_addr),
        .probe19(current_frame_occ_compact_addr),
        .probe20(mux_buffer.from_cart),
        .probe21(mux_buffer.from_usb)
    );

endmodule
