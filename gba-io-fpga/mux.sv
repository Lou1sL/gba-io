
`timescale 1ns / 1ps
`include "gba_io_fpga_header.svh"

module mux (
    input logic clk,
    input logic rst,
    cart_mux_interface.mux cart_mux,
    mux_buffer_interface.mux mux_buffer,
    mux_mem_interface.mux mux_mem,
    mux_usb_interface.mux mux_usb
);

    localparam DATA_WIDTH_0 = 2'b00;
    localparam DATA_WIDTH_8 = 2'b01;
    localparam DATA_WIDTH_16 = 2'b10;
    localparam DATA_WIDTH_32 = 2'b11;

    localparam CMD_IDLE = 2'b00;
    localparam CMD_READ = 2'b01;
    localparam CMD_WRITE = 2'b10;

    localparam IDLE = 0;
    localparam CART_RD_ADDR = 1;
    localparam CART_RD = 2;
    localparam CART_RD_PREP = 3;
    localparam CART_RD_VALID = 4;
    localparam CART_WR_ADDR = 5;
    localparam CART_WR = 6;
    localparam CART_WR_PREP = 7;
    localparam CART_WR_READY = 8;
    localparam USB_RD_ADDR = 9;
    localparam USB_RD = 10;
    localparam USB_RD_PREP = 11;
    localparam USB_RD_VALID = 12;
    localparam USB_WR_ADDR = 13;
    localparam USB_WR = 14;
    localparam USB_WR_PREP = 15;
    localparam USB_WR_READY = 16;

    byte state = IDLE;

    always_ff @ (posedge clk) begin
        if (rst) begin
            state <= IDLE;
        end else begin
            case (state)
            IDLE: begin
                cart_mux.cart_rd_data <= 16'h0;
                cart_mux.cart_rd_valid <= 1'b0;
                mux_mem.mem_cmd <= CMD_IDLE;
                mux_mem.mem_addr <= 17'h0;
                mux_mem.mem_wr_data <= 32'h0;
                mux_usb.usb_rd_data <= 32'h0;
                mux_usb.usb_wr_ready <= 1'b0;
                mux_usb.usb_rd_valid <= 1'b0;
                if (cart_mux.cart_rd) begin
                    mux_buffer.from_cart <= 1'b1;
                    mux_buffer.from_usb <= 1'b0;
                    mux_buffer.cart_usb_addr <= cart_mux.cart_addr;
                    state <= CART_RD_ADDR;
                end else if (cart_mux.cart_wr) begin
                    mux_buffer.from_cart <= 1'b1;
                    mux_buffer.from_usb <= 1'b0;
                    mux_buffer.cart_usb_addr <= cart_mux.cart_addr;
                    state <= CART_WR_ADDR;
                end else if (mux_usb.usb_rd) begin
                    mux_buffer.from_cart <= 1'b0;
                    mux_buffer.from_usb <= 1'b1;
                    mux_buffer.cart_usb_addr <= mux_usb.usb_addr;
                    state <= USB_RD_ADDR;
                end else if (mux_usb.usb_wr) begin
                    mux_buffer.from_cart <= 1'b0;
                    mux_buffer.from_usb <= 1'b1;
                    mux_buffer.cart_usb_addr <= mux_usb.usb_addr;
                    state <= USB_WR_ADDR;
                end else begin
                    mux_buffer.from_cart <= 1'b0;
                    mux_buffer.from_usb <= 1'b0;
                    mux_buffer.cart_usb_addr <= 26'b0;
                    state <= IDLE;
                end
            end
            CART_RD_ADDR: begin
                mux_buffer.from_cart <= 1'b0;
                mux_buffer.cart_usb_addr <= 26'b0;
                state <= CART_RD;
            end
            CART_RD: begin
                mux_mem.mem_cmd <= CMD_READ;
                mux_mem.mem_addr <= mux_buffer.compact_addr[18:2];
                state <= CART_RD_PREP;
            end
            CART_RD_PREP: begin
                mux_mem.mem_cmd <= CMD_IDLE;
                mux_mem.mem_addr <= 17'h0;
                state <= CART_RD_VALID;
            end
            CART_RD_VALID: begin
                cart_mux.cart_rd_data <= 
                    (cart_mux.cart_data_width == DATA_WIDTH_8) ?
                        {
                            8'h0,
                            { mux_mem.mem_rd_data >> ((2'b11 - mux_buffer.compact_addr[1:0]) << 3) }[7:0]
                        } :
                    (cart_mux.cart_data_width == DATA_WIDTH_16) ?
                        {
                            { mux_mem.mem_rd_data >> (((2'b11 - mux_buffer.compact_addr[1:0]) - 1) << 3) }[7:0],
                            { mux_mem.mem_rd_data >> (((2'b11 - mux_buffer.compact_addr[1:0]) - 1) << 3) }[15:8]
                        } :
                    { 16'hDEAD };
                cart_mux.cart_rd_valid <= 1'b1;
                state <= IDLE;
            end
            CART_WR_ADDR: begin
                mux_buffer.from_cart <= 1'b0;
                mux_buffer.cart_usb_addr <= 26'b0;
                state <= CART_WR;
            end
            CART_WR: begin
                mux_mem.mem_cmd <= CMD_READ;
                mux_mem.mem_addr <= mux_buffer.compact_addr[18:2];
                state <= CART_WR_PREP;
            end
            CART_WR_PREP: begin
                mux_mem.mem_cmd <= CMD_IDLE;
                mux_mem.mem_addr <= 17'h0;
                state <= CART_WR_READY;
            end
            CART_WR_READY: begin
                mux_mem.mem_cmd <= CMD_WRITE;
                if(cart_mux.cart_data_width == DATA_WIDTH_8) begin
                    mux_mem.mem_wr_data <=
                        (mux_mem.mem_rd_data & (32'hFFFFFF00 << ((2'b11 - mux_buffer.compact_addr[1:0]) << 3))) |
                        ({ 32{ 24'h0, cart_mux.cart_wr_data[7:0] } } << ((2'b11 - mux_buffer.compact_addr[1:0]) << 3));
                end else if(cart_mux.cart_data_width == DATA_WIDTH_16) begin
                    mux_mem.mem_wr_data <=
                        (mux_mem.mem_rd_data & (32'hFFFF0000 << ((2'b11 - mux_buffer.compact_addr[1:0] - 1) << 3))) |
                        ({ 32{ 16'h0, cart_mux.cart_wr_data[7:0], cart_mux.cart_wr_data[15:8] } } << ((2'b11 - mux_buffer.compact_addr[1:0] - 1) << 3));
                end
                state <= IDLE;
            end
            USB_RD_ADDR: begin
                mux_buffer.from_usb <= 1'b0;
                mux_buffer.cart_usb_addr <= 26'b0;
                state <= USB_RD;
            end
            USB_RD: begin
                mux_mem.mem_cmd <= CMD_READ;
                mux_mem.mem_addr <= mux_buffer.compact_addr[18:2];
                state <= USB_RD_PREP;
            end
            USB_RD_PREP: begin
                mux_mem.mem_cmd <= CMD_IDLE;
                mux_mem.mem_addr <= 17'h0;
                state <= USB_RD_VALID;
            end
            USB_RD_VALID: begin
                mux_usb.usb_rd_data <= mux_mem.mem_rd_data;
                mux_usb.usb_rd_valid <= 1'b1;
                state <= IDLE;
            end
            USB_WR_ADDR: begin
                mux_buffer.from_usb <= 1'b0;
                mux_buffer.cart_usb_addr <= 26'b0;
                state <= USB_WR;
            end
            USB_WR: begin
                mux_mem.mem_cmd <= CMD_READ;
                mux_mem.mem_addr <= mux_buffer.compact_addr[18:2];
                state <= USB_WR_PREP;
            end
            USB_WR_PREP: begin
                mux_mem.mem_cmd <= CMD_IDLE;
                mux_mem.mem_addr <= 17'h0;
                state <= USB_WR_READY;
            end
            USB_WR_READY: begin
                mux_mem.mem_cmd <= CMD_WRITE;
                mux_mem.mem_wr_data <= mux_usb.usb_wr_data;
                mux_usb.usb_wr_ready <= 1'b1;
                state <= IDLE;
            end
            default: state <= IDLE;
            endcase
        end
    end


    // Testing
    ila_mux i(
        .clk(clk),
        .probe0(state),
        .probe1(mux_usb.usb_rd),
        .probe2(mux_usb.usb_rd_valid),
        .probe3(mux_usb.usb_wr),
        .probe4(mux_usb.usb_wr_ready),
        .probe5(mux_usb.usb_addr),
        .probe6(mux_usb.usb_wr_data),
        .probe7(mux_usb.usb_rd_data)
    );

endmodule
