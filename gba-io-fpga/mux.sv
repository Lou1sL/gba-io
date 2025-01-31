
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
    assign mux_buffer.from_cart = cart_mux.cart_rd | cart_mux.cart_wr;
    assign mux_buffer.cart_addr = cart_mux.cart_addr;
    assign mux_buffer.from_usb = 1'b0; // TODO: Allowing USB when (~mux_buffer.from_cart)
    assign mux_buffer.usb_trans_type = 3'b000;

    // Testing With Block RAM
    bit [7:0] TEST_RAM [0:2047];
    initial begin
        $readmemh("./test_rom.hex", TEST_RAM);
    end
    assign cart_mux.cart_rd_data =
        cart_mux.cart_rd ? (
            (cart_mux.cart_addr[10:0] >= 'hE0) ?
                16'hFF :
                { TEST_RAM[cart_mux.cart_addr[10:0] + 1], TEST_RAM[cart_mux.cart_addr[10:0]] }
        ) : 16'hz;
    always_ff @(posedge clk) begin
        if(cart_mux.cart_wr) begin
            // TEST_RAM[cart_mux.cart_addr[10:1]] <= cart_mux.cart_wr_data;
        end
    end

    // Mux -> Memory
    // assign mux_mem.mem_rd = cart_mux.cart_rd; // TODO: Add USB
    // assign mux_mem.mem_wr = cart_mux.cart_wr; // TODO: Add USB
    // assign mux_mem.mem_data_width = cart_mux.cart_data_width; // TODO: Add USB
    // assign mux_mem.mem_addr = mux_buffer.mem_addr;
    // assign mux_mem.mem_rd_data = cart_mux.cart_rd_data; // TODO: Add USB
    // assign mux_mem.mem_wr_data = cart_mux.cart_wr_data; // TODO: Add USB
    // assign mux_mem.mem_rd_valid = cart_mux.mux_rd_valid;

    // Testing
    assign mux_mem.mem_data_width = 2'b11; // 32-bit
    bit result_passed = 1'b0;
    bit result_failed = 1'b0;
    bit [31:0] data_to_write = 32'h0123ABCD;
    bit [31:0] data_read_from_memory = 32'd0;

    localparam IDLE = 3'd0;
    localparam WRITE = 3'd1;
    localparam READ = 3'd2;
    localparam READ_DONE = 3'd3;
    localparam PARK = 3'd4;
    bit [2:0] state = IDLE;

    always_ff @ (posedge clk) begin
        if (rst) begin
            result_passed <= 1'b0;
            result_failed <= 1'b0;
            data_to_write <= 32'h0123ABCD;
            data_read_from_memory <= 32'd0;
            mux_mem.mem_rd <= 1'b0;
            mux_mem.mem_wr <= 1'b0;
            mux_mem.mem_addr <= 26'h0;
            state <= IDLE;
        end else begin
            case (state)
            IDLE: begin
                state <= WRITE;
            end
            WRITE: begin
                if (mux_mem.mem_wr_ready) begin
                    mux_mem.mem_rd <= 1'b0;
                    mux_mem.mem_wr <= 1'b1;
                    mux_mem.mem_addr <= 26'h0;
                    mux_mem.mem_wr_data <= data_to_write;
                    state <= READ;
                end
            end
            READ: begin
                if (mux_mem.mem_rd_ready) begin
                    mux_mem.mem_rd <= 1'b1;
                    mux_mem.mem_wr <= 1'b0;
                    mux_mem.mem_addr <= 26'h0;
                    state <= READ_DONE;
                end
            end
            READ_DONE: begin
                if (mux_mem.mem_rd_valid) begin
                    data_read_from_memory <= mux_mem.mem_rd_data;
                    state <= PARK;
                end
            end
            PARK: begin
                result_passed <= (data_to_write == data_read_from_memory);
                result_failed <= (data_to_write != data_read_from_memory);
            end
            default: state <= IDLE;
        endcase
        end
    end

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

    // USB -> Mux
    // TODO: Add USB



endmodule
