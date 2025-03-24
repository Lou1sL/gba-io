
`timescale 1ns / 1ps
`include "gba_io_fpga_header.svh"

module mux (
    input logic clk,
    input logic rst,
    cart_mux_interface.mux cart_mux,
    mux_buffer_interface.mux mux_buffer,
    mux_usb_interface.mux mux_usb
);

    localparam DATA_WIDTH_0 = 2'b00;
    localparam DATA_WIDTH_8 = 2'b01;
    localparam DATA_WIDTH_16 = 2'b10;
    localparam DATA_WIDTH_32 = 2'b11;

    localparam COMPACT_BRAM_SIZE = 'h62080;

    (* ram_style = "block", keep = "true" *) reg [31:0] BRAM [0:(COMPACT_BRAM_SIZE >> 2)-1];
    initial begin
        $readmemh("./init_bram.hex", BRAM);
    end

    localparam CMD_IDLE = 2'b00;
    localparam CMD_READ = 2'b01;
    localparam CMD_WRITE = 2'b10;
    bit [18:0] temp_address;
    bit [31:0] temp_rd_data;
    bit [31:0] temp_wr_data;
    bit [1:0] mem_cmd;
    always_ff @ (posedge clk) begin
        if (rst) begin
            temp_address <= 19'h0;
            temp_rd_data <= 32'h0;
            temp_wr_data <= 32'h0;
            mem_cmd <= CMD_IDLE;
        end else begin
            case (mem_cmd)
            CMD_READ: begin
                temp_rd_data <= BRAM[temp_address];
            end
            CMD_WRITE: begin
                BRAM[temp_address] <= temp_wr_data;
            end
            default: mem_cmd <= CMD_IDLE;
            endcase
        end
    end

    localparam IDLE = 4'd0;
    localparam CART_RD = 4'd1;
    localparam CART_RD_VALID = 4'd2;
    localparam CART_WR = 4'd3;
    localparam CART_WR_READY = 4'd4;
    localparam USB_RD = 4'd5;
    localparam USB_RD_VALID = 4'd6;
    localparam USB_WR = 4'd7;
    localparam USB_WR_READY = 4'd8;

    bit [3:0] state = IDLE;

    always_ff @ (posedge clk) begin
        if (rst) begin
            state <= IDLE;
        end else begin
            case (state)
            IDLE: begin
                cart_mux.cart_rd_data <= 16'h0;
                cart_mux.cart_rd_valid <= 1'b0;
                mux_usb.usb_rd_data <= 32'h0;
                mux_usb.usb_wr_ready <= 1'b0;
                mux_usb.usb_rd_valid <= 1'b0;
                temp_address <= 19'h0;
                temp_wr_data <= 32'h0;
                mem_cmd <= CMD_IDLE;
                if (cart_mux.cart_rd) begin
                    mux_buffer.from_cart <= 1'b1;
                    mux_buffer.from_usb <= 1'b0;
                    mux_buffer.cart_usb_addr <= cart_mux.cart_addr;
                    state <= CART_RD;
                end else if (cart_mux.cart_wr) begin
                    mux_buffer.from_cart <= 1'b1;
                    mux_buffer.from_usb <= 1'b0;
                    mux_buffer.cart_usb_addr <= cart_mux.cart_addr;
                    state <= CART_WR;
                end else if (mux_usb.usb_rd) begin
                    mux_buffer.from_cart <= 1'b0;
                    mux_buffer.from_usb <= 1'b1;
                    mux_buffer.cart_usb_addr <= mux_usb.usb_addr;
                    state <= USB_RD;
                end else if (mux_usb.usb_wr) begin
                    mux_buffer.from_cart <= 1'b0;
                    mux_buffer.from_usb <= 1'b1;
                    mux_buffer.cart_usb_addr <= mux_usb.usb_addr;
                    state <= USB_WR;
                end else begin
                    mux_buffer.from_cart <= 1'b0;
                    mux_buffer.from_usb <= 1'b0;
                    mux_buffer.cart_usb_addr <= 26'b0;
                    state <= IDLE;
                end
            end
            CART_RD: begin
                mux_buffer.from_cart <= 1'b0;
                mux_buffer.cart_usb_addr <= 26'b0;
                mem_cmd <= CMD_READ;
                temp_address <= mux_buffer.compact_addr[18:2];
                state <= CART_RD_VALID;
            end
            CART_RD_VALID: begin
                mem_cmd <= CMD_IDLE;
                temp_address <= 19'h0;
                cart_mux.cart_rd_data <= 
                    (cart_mux.cart_data_width == DATA_WIDTH_8) ?
                        {
                            8'h0,
                            { temp_rd_data >> ((2'b11 - mux_buffer.compact_addr[1:0]) << 3) }[7:0]
                        } :
                    (cart_mux.cart_data_width == DATA_WIDTH_16) ?
                        {
                            { temp_rd_data >> (((2'b11 - mux_buffer.compact_addr[1:0]) - 1) << 3) }[7:0],
                            { temp_rd_data >> (((2'b11 - mux_buffer.compact_addr[1:0]) - 1) << 3) }[15:8]
                        } :
                    { 16'hDEAD };
                cart_mux.cart_rd_valid <= 1'b1;
                state <= IDLE;
            end
            CART_WR: begin
                mux_buffer.from_cart <= 1'b0;
                mux_buffer.cart_usb_addr <= 26'b0;
                mem_cmd <= CMD_READ;
                temp_address <= mux_buffer.compact_addr[18:2];
                state <= CART_WR_READY;
            end
            CART_WR_READY: begin
                mem_cmd <= CMD_WRITE;
                if(cart_mux.cart_data_width == DATA_WIDTH_8) begin
                    temp_wr_data <=
                        (temp_rd_data & (32'hFFFFFF00 << ((2'b11 - mux_buffer.compact_addr[1:0]) << 3))) |
                        (32{ 24'h0, cart_mux.cart_wr_data[7:0] } << ((2'b11 - mux_buffer.compact_addr[1:0]) << 3));
                end else if(cart_mux.cart_data_width == DATA_WIDTH_16) begin
                    temp_wr_data <=
                        (temp_rd_data & (32'hFFFF0000 << ((2'b11 - mux_buffer.compact_addr[1:0] - 1) << 3))) |
                        (32{ 16'h0, cart_mux.cart_wr_data[7:0], cart_mux.cart_wr_data[15:8] } << ((2'b11 - mux_buffer.compact_addr[1:0] - 1) << 3));
                end
                state <= IDLE;
            end
            USB_RD: begin
                mux_buffer.from_usb <= 1'b0;
                mux_buffer.cart_usb_addr <= 26'b0;
                mem_cmd <= CMD_READ;
                temp_address <= mux_buffer.compact_addr[18:2];
                state <= USB_RD_VALID;
            end
            USB_RD_VALID: begin
                mem_cmd <= CMD_IDLE;
                temp_address <= 19'h0;
                mux_usb.usb_rd_data <= temp_rd_data;
                mux_usb.usb_rd_valid <= 1'b1;
                state <= IDLE;
            end
            USB_WR: begin
                mux_buffer.from_usb <= 1'b0;
                mux_buffer.cart_usb_addr <= 26'b0;
                temp_address <= mux_buffer.compact_addr[18:2];
                state <= USB_WR_READY;
            end
            USB_WR_READY: begin
                mem_cmd <= CMD_WRITE;
                temp_wr_data <= mux_usb.usb_wr_data;
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
