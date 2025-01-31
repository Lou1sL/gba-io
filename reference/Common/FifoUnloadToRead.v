/*
	FifoUnloadToRead.v:  Little module to convert Standard FIFO into 
			     First Word Fall Through without adding a cycle of latency.

		  Ted Rossin 10-16-2024
	  		     11-16-2024	  
*/

`timescale 1ns / 1ps

module FifoUnloadToRead #(parameter DataCountWidth=3) (
     input Clk
    ,input Reset
    ,input Unload
    ,input Empty
    ,input[DataCountWidth-1:0] DataCountIn
    ,output Read
    ,output Valid
    ,output[DataCountWidth-1:0] DataCountOut
);
    wire ValidSet,ValidClear;
    reg FifoEmpty2,FifoValid;

    assign Read = Unload | (~FifoValid & (Empty | FifoEmpty2));
    assign ValidSet = Read & ~Empty;
    assign ValidClear = FifoValid & Unload & Empty;
    	// If the output is not used, synthesis will remove this logic.
    assign DataCountOut = DataCountIn+FifoValid;
    assign Valid = FifoValid;

    always @(posedge Clk) begin
	FifoEmpty2 <= Reset ? 1 : Empty;
	FifoValid <= Reset ? 0 
			   : ValidSet ? 1 
			   	      : ValidClear ? 0 
				      		   : FifoValid;
    end
endmodule
