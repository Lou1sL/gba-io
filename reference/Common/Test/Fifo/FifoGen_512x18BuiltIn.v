/*
	FifoGen_512x18BuiltIn.v: Behavior version of 512x18 built in FIFO

		  Ted Rossin 10-04-2024
	  		     11-07-2024 

     Note: This code does not model the behavior of the built in FIFO
	     where if rd_en is asserted while empty is asserted, the
	     flags all go to X.
*/

`timescale 1ns / 1ps

module FifoGen_512x18BuiltIn(
     input clk
    ,input rst
    ,input[17:0] din
    ,input wr_en
    ,input rd_en
    ,output[17:0] dout
    ,output valid
    ,output full
    ,output empty
    ,output prog_empty
    ,output prog_full
);

    BaseBlockRamFifo #(
	 .FirstWordFall(0)
	,.BuiltIn(1)
	,.Width(18)
	,.ProgFullValue(14)
	,.ProgEmptyValue(5)
	,.DataCountWidth(9)
	,.Depth(512)
    ) Fifo(
     	 .Clk(clk)
    	,.Reset(rst)
    	,.Write(wr_en)
    	,.Read(rd_en)
    	,.Din(din)
    	,.Dout(dout)
    	,.ProgFull(prog_full)
    	,.ProgEmpty(prog_empty)
    	,.DataCount()
    	,.Valid(valid)
    	,.Empty(empty)
    	,.Full(full)
    );
endmodule
