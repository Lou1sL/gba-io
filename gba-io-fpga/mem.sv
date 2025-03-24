
`timescale 1ns / 1ps
`include "gba_io_fpga_header.svh"

module mem (
    input logic clk,
    input logic rst,
    mux_mem_interface.mem mux_mem
);

    // localparam COMPACT_BRAM_SIZE = 'h62080;
    localparam COMPACT_BRAM_SIZE = 'h22080;

    (* ram_style = "block", keep = "true" *) reg [31:0] BRAM [0:(COMPACT_BRAM_SIZE >> 2)-1];
    initial begin
        $readmemh("./init_bram.hex", BRAM);
    end

    localparam CMD_IDLE = 2'b00;
    localparam CMD_READ = 2'b01;
    localparam CMD_WRITE = 2'b10;

    always_ff @ (posedge clk) begin
            case (mux_mem.mem_cmd)
            CMD_READ: begin
                mux_mem.mem_rd_data <= BRAM[mux_mem.mem_addr];
            end
            CMD_WRITE: begin
                BRAM[mux_mem.mem_addr] <= mux_mem.mem_wr_data;
            end
            default: begin end
            endcase
    end

endmodule
