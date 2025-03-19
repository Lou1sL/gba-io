
// https://www.xilinx.com/support/documents/ip_documentation/mig_7series/v4_1/ug586_7Series_MIS.pdf

`timescale 1ps / 1ps
`include "gba_io_fpga_header.svh"

module mem #(
    parameter TCQ = 100,
    parameter DQS_WIDTH = 2,
    parameter ADDR_WIDTH = 29,
    parameter nCK_PER_CLK = 4,
    parameter ECC_TEST = "OFF",
    parameter DQ_WIDTH = 16
)(
    input logic clk,
    input logic sys_clk_i,
    input logic clk_ref_i,
    output logic ui_clk,
    input logic rst,
    output logic rst_ui_sync,
    output logic led_rdy,
    // DDR3 SDRAM
    inout logic [15:0] ddr3_dq,
    inout logic [1:0] ddr3_dqs_n,
    inout logic [1:0] ddr3_dqs_p,
    output logic [14:0] ddr3_addr,
    output logic [2:0] ddr3_ba,
    output logic ddr3_ras_n, ddr3_cas_n, ddr3_we_n, ddr3_reset_n,
    output logic [0:0] ddr3_ck_p,
    output logic [0:0] ddr3_ck_n,
    output logic [0:0] ddr3_cke,
    output logic [1:0] ddr3_dm,
    output logic [0:0] ddr3_odt,
    mux_mem_interface.mem mux_mem
);

    localparam DATA_WIDTH_0 = 2'b00;
    localparam DATA_WIDTH_8 = 2'b01;
    localparam DATA_WIDTH_16 = 2'b10;
    localparam DATA_WIDTH_32 = 2'b11;

    // DDR3 SDRAM
    localparam DATA_WIDTH = 16;
    localparam PAYLOAD_WIDTH = (ECC_TEST == "OFF") ? DATA_WIDTH : DQ_WIDTH;
    localparam APP_DATA_WIDTH = 2 * nCK_PER_CLK * PAYLOAD_WIDTH;
    localparam APP_MASK_WIDTH = APP_DATA_WIDTH / 8;

    logic init_calib_complete;
    logic [15:0] mem_wr_mask;

    logic [ADDR_WIDTH-1:0] mem_addr; // [28:0]
    localparam CMD_WRITE = 3'b000;
    localparam CMD_READ = 3'b001;
    logic [2:0] mem_cmd;
    logic mem_en;
    
    logic mem_ready;
    logic [APP_DATA_WIDTH-1:0] mem_rd_data; // [127:0]
    logic mem_rd_valid;
    logic [APP_DATA_WIDTH-1:0] mem_wr_data; // [127:0]
    logic mem_wr_ready;
    logic mem_wr_valid;

    sdram s (
        // System Clock Ports
        .sys_clk_i(sys_clk_i),
        // Reference Clock Ports
        .clk_ref_i(clk_ref_i),
        // XADC device temperature output, unconnected
        .device_temp(),
        // System reset - Default polarity of sys_rst pin is Active Low.
        // System reset polarity will change based on the option 
        // selected in GUI.
        .sys_rst(rst),

        /** DDR3 RAM Interface **/

        .ddr3_dq(ddr3_dq),
        .ddr3_dqs_n(ddr3_dqs_n),
        .ddr3_dqs_p(ddr3_dqs_p),
        .ddr3_addr(ddr3_addr),
        .ddr3_ba(ddr3_ba),
        .ddr3_ras_n(ddr3_ras_n),
        .ddr3_cas_n(ddr3_cas_n),
        .ddr3_we_n(ddr3_we_n),
        .ddr3_reset_n(ddr3_reset_n),
        .ddr3_ck_p(ddr3_ck_p),
        .ddr3_ck_n(ddr3_ck_n),
        .ddr3_cke(ddr3_cke),
        .ddr3_dm(ddr3_dm),
        .ddr3_odt(ddr3_odt),

        /** Application Interface **/

        // This input indicates the address for the request currently being submitted to the UI.
        // The UI aggregates all the address fields of the external SDRAM and presents a flat address space to you.
        .app_addr(mem_addr),
        // This input specifies the command for the request currently being submitted to the UI.
        // Read: 3'b001, Write: 3'b000
        .app_cmd(mem_cmd),
        // This input strobes in a request.
        // You must apply the desired values to app_addr[], app_cmd[2:0], and app_hi_pri, and then assert app_en to submit the request to the UI.
        // This initiates a handshake that the UI acknowledges by asserting app_rdy.
        .app_en(mem_en),
        // This output indicates to you whether the request currently being submitted to the UI is accepted.
        // If the UI does not assert this signal after app_en is asserted, the current request must be retried.
        // The app_rdy output is not asserted if:
        //   1. PHY/Memory initialization is not yet completed
        //   2. All the bank machines are occupied (can be viewed as the command buffer being full)
        //     2.1 A read is requested and the read buffer is full
        //     2.2 A write is requested and no write buffer pointers are available
        //   3. A periodic read is being inserted
        .app_rdy(mem_ready),
        // This output contains the data read from the external memory.
        .app_rd_data(mem_rd_data),
        // This output indicates that the data on the app_rd_data[] bus in the current cycle is the last data for the current request.
        // This active-High output indicates that the current clock cycle is the last cycle of output data on app_rd_data[].
        // This is valid only when app_rd_data_valid is active-High.
        // We leave it unconnected since we never need to stretch the request across multiple cycles.
        .app_rd_data_end(),
        // This output indicates that the data on the app_rd_data[] bus is valid.
        .app_rd_data_valid(mem_rd_valid),
        // This bus provides the data currently being written to the external memory.
        .app_wdf_data(mem_wr_data),
        // This input indicates that the data on the app_wdf_data[] bus in the current cycle is the last data for the current request.
        // We set it to mem_wr_valid since we do not need to strech the request accross multiple cycles now.
        .app_wdf_end(mem_wr_valid),
        // This bus indicates which bytes of app_wdf_data[] are written to the external memory and which bytes remain in their current state.
        // The bytes are masked by setting a value of 1 to the corresponding bits in app_wdf_mask.
        // For example, if the application data width is 256, the mask width takes a value of 32.
        // The least significant byte [7:0] of app_wdf_data is masked using Bit[0] of app_wdf_mask and the most significant byte [255:248] of app_wdf_data is masked using Bit[31] of app_wdf_mask.
        // Hence if you have to mask the last DWORD, that is, bytes 0, 1, 2, and 3 of app_wdf_data, the app_wdf_mask should be set to 32'h0000_000F. 
        .app_wdf_mask(mem_wr_mask),
        // This output indicates that the write data FIFO is ready to receive data.
        // Write data is accepted when (app_wdf_rdy === 1’b1 & app_wdf_wren === 1’b1).
        .app_wdf_rdy(mem_wr_ready),
        // This input indicates that the data on the app_wdf_data[] bus is valid.
        .app_wdf_wren(mem_wr_valid),
        // This input is reserved and should be tied to 0.
        .app_sr_req(1'b0),
        // This output is reserved.
        .app_sr_active(),
        // When asserted, this active-High input requests that the Memory Controller send a refresh command to the DRAM.
        // It must be pulsed for a single cycle to make the request and then deasserted at least until the app_ref_ack signal is asserted to acknowledge the request and indicate that it has been sent.
        // https://adaptivesupport.amd.com/s/question/0D52E00006hpbYkSAI/mig7-apprefreq-and-appzqreq-signals-do-i-have-to-controlthese-signals?language=en_US
        // It can be automatically refreshed so it's not required to be controlled by the user.
        .app_ref_req(1'b0),
        // When asserted, this active-High input acknowledges a refresh request and indicates that the command has been sent from the Memory Controller to the PHY.
        .app_ref_ack(),
        // When asserted, this active-High input requests that the Memory Controller send a ZQ calibration command to the DRAM.
        // It must be pulsed for a single cycle to make the request and then deasserted at least until the app_zq_ack signal is asserted to acknowledge the request and indicate that it has been sent.
        .app_zq_req(1'b0),
        // When asserted, this active-High input acknowledges a ZQ calibration request and indicates that the command has been sent from the Memory Controller to the PHY.
        .app_zq_ack(),
        // This is the output clock from the UI.
        // It must be a half or quarter the frequency of the clock going out to the external SDRAM, which depends on 2:1 or 4:1 mode selected in GUI.
        .ui_clk(ui_clk),
        // The PHY asserts init_calib_complete when calibration is finished.
        // The application has no need to wait for init_calib_complete before sending commands to the Memory Controller.
        .init_calib_complete(init_calib_complete),
        // This is the reset from the UI which is in synchronous with ui_clk.
        // It's an output, it takes sys_rst and output this rst that is synchronous with ui_clk.
        .ui_clk_sync_rst(rst_ui_sync)
    );

    logic [26:0] mem_start_address;
    assign mem_start_address = mux_mem.mem_addr & 26'h3FFFFF0;
    logic [3:0] mem_offset;
    assign mem_offset = 4'hF - mux_mem.mem_addr[3:0];

    // Memory -> Mux
    assign mux_mem.mem_rd_ready = init_calib_complete & mem_ready;
    assign mux_mem.mem_wr_ready = init_calib_complete & mem_ready & mem_wr_ready;
    assign mux_mem.mem_rd_data =
        (mux_mem.mem_data_width == DATA_WIDTH_8 ) ? { 24'h0, { mem_rd_data >> (mem_offset * 8) }[7:0] } :
        (mux_mem.mem_data_width == DATA_WIDTH_16) ? { 16'h0, { mem_rd_data >> ((mem_offset - 1) * 8) }[7:0], { mem_rd_data >> ((mem_offset - 1) * 8) }[15:8] } :
        (mux_mem.mem_data_width == DATA_WIDTH_32) ? { { mem_rd_data >> ((mem_offset - 3) * 8) }[7:0], { mem_rd_data >> ((mem_offset - 3) * 8) }[15:8], { mem_rd_data >> ((mem_offset - 3) * 8) }[23:16], { mem_rd_data >> ((mem_offset - 3) * 8) }[31:24] } :
        { 32'h0 };
    assign mux_mem.debug_mem_rd_data = mem_rd_data;
    assign mux_mem.mem_rd_valid = mem_rd_valid;

    // Mux -> Memory
    logic [15:0] wr_mask;
    always_comb begin
        wr_mask = 16'b11111111_11111111;
        case (mux_mem.mem_data_width)
            DATA_WIDTH_8: begin
                wr_mask[mem_offset] = 1'b0;
            end
            DATA_WIDTH_16: begin
                wr_mask[mem_offset] = 1'b0;
                wr_mask[mem_offset - 1] = 1'b0;
            end
            DATA_WIDTH_32: begin
                wr_mask[mem_offset] = 1'b0;
                wr_mask[mem_offset - 1] = 1'b0;
                wr_mask[mem_offset - 2] = 1'b0;
                wr_mask[mem_offset - 3] = 1'b0;
            end
        endcase
    end
    assign mem_wr_mask = wr_mask;
    assign mem_addr = { {(ADDR_WIDTH-27){ 1'b0 }}, mem_start_address };
    assign mem_cmd = mux_mem.mem_rd ? CMD_READ : mux_mem.mem_wr ? CMD_WRITE : 3'b000;
    assign mem_en = mux_mem.mem_rd | mux_mem.mem_wr;
    assign mem_wr_data =
        (mux_mem.mem_data_width == DATA_WIDTH_8 ) ?
            (128'({ mux_mem.mem_wr_data[7:0] }) << (mem_offset * 8)) :
        (mux_mem.mem_data_width == DATA_WIDTH_16) ?
            (128'({ mux_mem.mem_wr_data[7:0], mux_mem.mem_wr_data[15:8] }) << ((mem_offset - 1) * 8)) :
        (mux_mem.mem_data_width == DATA_WIDTH_32) ?
            (128'({ mux_mem.mem_wr_data[7:0], mux_mem.mem_wr_data[15:8], mux_mem.mem_wr_data[23:16], mux_mem.mem_wr_data[31:24] }) << ((mem_offset - 3) * 8)) :
        { 128'h0 };
    assign mem_wr_valid = mux_mem.mem_wr;

    // Status -> LED
    assign led_rdy = init_calib_complete & mem_ready;

    ila_mem i(
        .clk(clk),
        .probe0 (mem_addr),
        .probe1 (mem_cmd),
        .probe2 (mem_en),
        .probe3 (mem_ready),
        .probe4 (mem_rd_data),
        .probe5 (mem_rd_valid),
        .probe6 (mem_wr_data),
        .probe7 (mem_wr_valid),
        .probe8 (mem_wr_mask),
        .probe9 (mem_wr_ready),
        .probe10(mem_wr_valid),
        .probe11(init_calib_complete),
        .probe12(rst_ui_sync)
    );

endmodule
