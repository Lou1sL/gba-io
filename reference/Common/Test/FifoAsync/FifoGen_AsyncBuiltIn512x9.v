/*
	FifoGen_AsyncBuiltIn512x9.v: Behavior version of 512x9 built in RAM FIFO

		  Ted Rossin 10-18-2024
	  		     11-05-2024 

     Note: 
*/

`timescale 1ns / 1ps

module FifoGen_AsyncBuiltIn512x9(
     input wr_clk
    ,input rd_clk
    ,input rst
    ,input[8:0] din
    ,input wr_en
    ,input rd_en
    ,output[8:0] dout
    ,output full
    ,output empty
    ,output prog_empty
    ,output prog_full
    ,output valid
);

    BaseFifoAsync #(
	 .FirstWordFall(0)
	,.BuiltIn(1)
	,.Depth(512)
    	,.Width(9)
	,.ProgEmptyValue(10)
	,.ProgFullValue(14)
	,.DataCountWidth(10)
	,.NumSync(2)
    ) Fifo(
     	 .WrClk(wr_clk)
     	,.RdClk(rd_clk)
    	,.Reset(rst)
	,.RdRstBusy()
	,.WrRstBusy()
    	,.Write(wr_en)
    	,.Read(rd_en)
    	,.Din(din)
    	,.Dout(dout)
    	,.ProgFull(prog_full)
    	,.WrDataCount()
    	,.RdDataCount()
    	,.Valid(valid)
    	,.Empty(empty)
	,.ProgEmpty(prog_empty)
    	,.Full(full)
    );
endmodule
