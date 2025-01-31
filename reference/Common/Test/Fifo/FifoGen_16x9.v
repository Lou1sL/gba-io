/*
	FifoGen_16x9.v: Behavior version of 16x9 block RAM FIFO

		  Ted Rossin  9-27-2024
	  		     11-07-2024 

     Note: 
*/

`timescale 1ns / 1ps

module FifoGen_16x9(
     input clk
    ,input srst
    ,input[8:0] din
    ,input wr_en
    ,input rd_en
    ,output[8:0] dout
    ,output full
    ,output empty
    ,output prog_empty
    ,output[3:0] data_count
    ,output prog_full
    ,output valid
);

    BaseBlockRamFifo #(
	 .FirstWordFall(0)
	,.BuiltIn(0)
	,.Width(9)
	,.ProgFullValue(14)
	,.ProgEmptyValue(5)
	,.DataCountWidth(4)
	,.Depth(16)
    ) Fifo(
     	 .Clk(clk)
    	,.Reset(srst)
    	,.Write(wr_en)
    	,.Read(rd_en)
    	,.Din(din)
    	,.Dout(dout)
    	,.ProgFull(prog_full)
    	,.ProgEmpty(prog_empty)
    	,.DataCount(data_count)
    	,.Valid(valid)
    	,.Empty(empty)
    	,.Full(full)
    );
endmodule
