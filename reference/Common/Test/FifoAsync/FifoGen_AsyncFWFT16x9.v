/*
	FifoGen_AsyncFWFT16x9.v: Behavior version of 16x9 block RAM FIFO

		  Ted Rossin 10-18-2024
	  		     11-05-2024 

     Note: 
*/

`timescale 1ns / 1ps

module FifoGen_AsyncFWFT16x9(
     input wr_clk
    ,input rd_clk
    ,input rst
    ,output wr_rst_busy
    ,output rd_rst_busy
    ,input[8:0] din
    ,input wr_en
    ,input rd_en
    ,output[8:0] dout
    ,output full
    ,output empty
    ,output prog_empty
    ,output[3:0] wr_data_count
    ,output[3:0] rd_data_count
    ,output prog_full
    ,output valid
);

    BaseFifoAsync #(
	 .FirstWordFall(1)
	,.BuiltIn(0)
    	,.Width(9)
	,.ProgEmptyValue(5)
	,.ProgFullValue(12)
	,.DataCountWidth(4)
	,.Depth(16)
	,.NumSync(2)
    ) Fifo(
     	 .WrClk(wr_clk)
     	,.RdClk(rd_clk)
    	,.Reset(rst)
	,.RdRstBusy(rd_rst_busy)
	,.WrRstBusy(wr_rst_busy)
    	,.Write(wr_en)
    	,.Read(rd_en)
    	,.Din(din)
    	,.Dout(dout)
    	,.ProgFull(prog_full)
    	,.WrDataCount(wr_data_count)
    	,.RdDataCount(rd_data_count)
    	,.Valid(valid)
    	,.Empty(empty)
	,.ProgEmpty(prog_empty)
    	,.Full(full)
    );
endmodule
