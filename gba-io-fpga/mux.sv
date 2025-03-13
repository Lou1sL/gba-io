
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

    // Cart Address / USB FIFO Trans Type -> Buffer Combinational Translation -> Translated Address
    logic [25:0] buffer_tranlated_addr;
    always_comb begin
        mux_buffer.from_cart = (state == CART_RD) | (state == CART_RD_VALID) | (state == CART_WR);
        mux_buffer.from_usb = (state == USB_RD) | (state == USB_RD_VALID) | (state == USB_WR);
        mux_buffer.cart_usb_addr =
            mux_buffer.from_cart ? cart_mux.cart_addr :
            mux_buffer.from_usb ? mux_usb.usb_addr :
            26'h0;
        buffer_tranlated_addr = mux_buffer.mem_addr;
    end

    // Mux State Machine
    localparam IDLE = 3'd0;
    localparam CART_RD = 3'd1;
    localparam CART_RD_VALID = 3'd2;
    localparam CART_WR = 3'd3;
    localparam USB_RD = 3'd4;
    localparam USB_RD_VALID = 3'd5;
    localparam USB_WR = 3'd6;

    bit [2:0] state = IDLE;

    localparam DATA_WIDTH_0 = 2'b00;
    localparam DATA_WIDTH_8 = 2'b01;
    localparam DATA_WIDTH_16 = 2'b10;
    localparam DATA_WIDTH_32 = 2'b11;

    always_ff @ (posedge clk) begin
        if (rst) begin
            state <= IDLE;
        end else begin
            case (state)
            IDLE: begin
                cart_mux.cart_rd_data <= 16'h0;
                cart_mux.cart_rd_valid <= 1'b0;
                mux_mem.mem_addr <= 26'h0;
                mux_mem.mem_rd <= 1'b0;
                mux_mem.mem_wr <= 1'b0;
                mux_mem.mem_data_width <= DATA_WIDTH_0;
                mux_mem.mem_wr_data <= 32'h0;
                mux_usb.usb_wr_ready <= 1'b0;
                mux_usb.usb_rd_data <= 32'h0;
                mux_usb.usb_rd_valid <= 1'b0;
                if (cart_mux.cart_rd) begin
                    state <= CART_RD;
                end else if (cart_mux.cart_wr) begin
                    state <= CART_WR;
                end else if (mux_usb.usb_rd) begin
                    state <= USB_RD;
                end else if (mux_usb.usb_wr) begin
                    state <= USB_WR;
                end else begin
                    state <= IDLE;
                end
            end
            CART_RD: begin
                if (mux_mem.mem_rd_ready) begin
                    // mux_mem.mem_addr <= buffer_tranlated_addr;
                    mux_mem.mem_addr <= cart_mux.cart_addr;
                    mux_mem.mem_rd <= 1'b1;
                    mux_mem.mem_wr <= 1'b0;
                    mux_mem.mem_data_width <= cart_mux.cart_data_width;
                    mux_mem.mem_wr_data <= 32'h0;
                    state <= CART_RD_VALID;
                end
            end
            CART_RD_VALID: begin
                if (mux_mem.mem_rd_valid) begin
                    cart_mux.cart_rd_data <= mux_mem.mem_rd_data;
                    cart_mux.cart_rd_valid <= 1'b1;
                    state <= IDLE;
                end
            end
            CART_WR: begin
                if (mux_mem.mem_wr_ready) begin
                    // mux_mem.mem_addr <= buffer_tranlated_addr;
                    mux_mem.mem_addr <= cart_mux.cart_addr;
                    mux_mem.mem_rd <= 1'b0;
                    mux_mem.mem_wr <= 1'b1;
                    mux_mem.mem_data_width <= cart_mux.cart_data_width;
                    mux_mem.mem_wr_data <= cart_mux.cart_wr_data;
                    state <= IDLE;
                end
            end
            USB_RD: begin
                if (mux_mem.mem_rd_ready) begin
                    // mux_mem.mem_addr <= buffer_tranlated_addr;
                    mux_mem.mem_addr <= mux_usb.usb_addr;
                    mux_mem.mem_rd <= 1'b1;
                    mux_mem.mem_wr <= 1'b0;
                    mux_mem.mem_data_width <= DATA_WIDTH_32;
                    mux_mem.mem_wr_data <= 32'h0;
                    state <= USB_RD_VALID;
                end
            end
            USB_RD_VALID: begin
                if (mux_mem.mem_rd_valid) begin
                    mux_usb.usb_wr_ready <= 1'b0;
                    mux_usb.usb_rd_data <= mux_mem.mem_rd_data;
                    mux_usb.usb_rd_valid <= 1'b1;
                    state <= IDLE;
                end
            end
            USB_WR: begin
                if (mux_mem.mem_wr_ready) begin
                    // mux_mem.mem_addr <= buffer_tranlated_addr;
                    mux_mem.mem_addr <= mux_usb.usb_addr;
                    mux_mem.mem_rd <= 1'b0;
                    mux_mem.mem_wr <= 1'b1;
                    mux_mem.mem_data_width <= DATA_WIDTH_32;
                    mux_mem.mem_wr_data <= mux_usb.usb_wr_data;
                    mux_usb.usb_wr_ready <= 1'b1;
                    mux_usb.usb_rd_data <= 32'h0;
                    mux_usb.usb_rd_valid <= 1'b0;
                    state <= IDLE;
                end
            end
            default: state <= IDLE;
            endcase
        end
    end


    // // Testing With Block RAM
    // bit [7:0] TEST_RAM [0:2047];
    // initial begin
    //     $readmemh("./test_rom.hex", TEST_RAM);
    // end
    // assign cart_mux.cart_rd_data =
    //     cart_mux.cart_rd ? (
    //         (cart_mux.cart_addr[10:0] >= 'hE0) ?
    //             16'hFF :
    //             { TEST_RAM[cart_mux.cart_addr[10:0] + 1], TEST_RAM[cart_mux.cart_addr[10:0]] }
    //     ) : 16'hz;
    // always_ff @(posedge clk) begin
    //     if(cart_mux.cart_wr) begin
    //         // TEST_RAM[cart_mux.cart_addr[10:1]] <= cart_mux.cart_wr_data;
    //     end
    // end

    // ila_mem ila_mem(
    //     .clk(clk),
    //     .probe0 (mux_mem.mem_rd_ready),
    //     .probe1 (mux_mem.mem_wr_ready),
    //     .probe2 (mux_mem.mem_addr),
    //     .probe3 (mux_mem.mem_rd),
    //     .probe4 (mux_mem.mem_wr),
    //     .probe5 (mux_mem.mem_data_width),
    //     .probe6 (mux_mem.mem_rd_data),
    //     .probe7 (mux_mem.mem_wr_data),
    //     .probe8 (mux_mem.mem_rd_valid),
    //     .probe9 (data_read_from_memory),
    //     .probe10(result_passed),
    //     .probe11(result_failed),
    //     .probe12(state)
    // );

    // // Testing
    // localparam TEST_INPUT_LEN = 32;
    // logic [7:0] TEST_INPUT_0 [TEST_INPUT_LEN] = {
    //     8'b0, 8'b0, 8'b0, 8'b0,
    //     8'b0, 8'b0, 8'b0, 8'b0,
    //     8'b0, 8'b0,
    //     8'b0, 8'b0,
    //     8'b0, 8'b0, 8'b0, 8'b0,
    //     8'b10011111, 8'b11111111,
    //     8'b0, 8'b0, 8'b0, 8'b0, 8'b0, 8'b0, 
    //     8'b0, 8'b0,
    //     8'b0, 8'b0,
    //     8'b0, 8'b0,
    //     8'b0, 8'b0
    // };
    // logic [7:0] TEST_INPUT_1 [TEST_INPUT_LEN] = {
    //     8'b0, 8'b0, 8'b0, 8'b0,
    //     8'b0, 8'b0, 8'b0, 8'b0,
    //     8'b0, 8'b0,
    //     8'b0, 8'b0,
    //     8'b0, 8'b0, 8'b0, 8'b0,
    //     8'b01101111, 8'b11111111,
    //     8'b0, 8'b0, 8'b0, 8'b0, 8'b0, 8'b0, 
    //     8'b0, 8'b0,
    //     8'b0, 8'b0,
    //     8'b0, 8'b0,
    //     8'b0, 8'b0
    // };
    // bit current_test_input_sel = 1'b0;
    // logic [7:0] current_test_input [TEST_INPUT_LEN];
    // assign current_test_input = current_test_input_sel ? TEST_INPUT_1 : TEST_INPUT_0;
    // int current_test_input_index = 0;
    // assign mux_usb.usb_rd_valid = 1'b1;
    // assign mux_usb.usb_rd_data = {
    //     current_test_input[current_test_input_index + 3],
    //     current_test_input[current_test_input_index + 2],
    //     current_test_input[current_test_input_index + 1],
    //     current_test_input[current_test_input_index + 0]
    // };
    // int counter = 0;
    // always_ff @(posedge clk) begin
    //     if(rst) begin
    //         current_test_input_sel <= 1'b0;
    //         current_test_input_index <= 0;
    //         counter <= 0;
    //     end else begin
    //         counter <= counter + 1;
    //         if(counter >= 100000000) begin
    //             counter <= 0;
    //             current_test_input_sel <= ~current_test_input_sel;
    //         end
    //         if(mux_usb.usb_rd & mux_usb.usb_rd_valid) begin
    //             current_test_input_index <=
    //                 (current_test_input_index >= (TEST_INPUT_LEN - 4)) ? 'd0 :
    //                 (current_test_input_index + 4);
    //         end
    //     end
    // end

endmodule
