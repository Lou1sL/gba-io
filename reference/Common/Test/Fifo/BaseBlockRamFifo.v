/*
	BaseBlockRamFifo.v: Behavior version of block RAM FIFO

		  Ted Rossin  9-27-2024
	  		     11-08-2024 

     Note: 
*/

`timescale 1ns / 1ps

module BaseBlockRamFifo #(
     parameter FirstWordFall=0
    ,parameter BuiltIn=0
    ,parameter Width=8
    ,parameter ProgFullValue=10
    ,parameter ProgEmptyValue=3
    ,parameter DataCountWidth=4
    ,parameter Depth=8
) 
(
     input Clk
    ,input Reset
    ,input Write
    ,input Read
    ,input[Width-1:0] Din
    ,output[Width-1:0] Dout
    ,output reg ProgFull
    ,output reg ProgEmpty
    ,output[DataCountWidth-1:0] DataCount
    ,output Valid
    ,output Empty
    ,output Full
);
    parameter NumBits = $clog2(Depth+1);
    parameter AddrWidth = $clog2(Depth);
    wire ValidWrite,ValidRead,IntEmpty;
    reg RawValid,LastValidRead;
    reg[AddrWidth-1:0] WrPtr,RdPtr;
    reg[NumBits-1:0] Num,FwftNum;
    reg[Width-1:0] DoutRaw,Din2,Din3;
    reg[Width-1:0] Mem[0:Depth-1];
    reg ValidWrite2,ValidWrite3,Empty2,CrapIt,StandardValid;
    wire EnWord1,EnWord2,ProgFullSet,ProgFullReset,SetCrapIt;
    wire ProgEmptySet,ProgEmptyReset;

    assign ValidWrite = Write & ~Full;
    assign ValidRead = Read & ~RawEmpty;
    assign WrAddr = WrPtr;
    assign RdAddr = RdPtr;
    assign RawEmpty = (Num==0) ? 1 : 0;
    assign IntEmpty = FirstWordFall ? RawEmpty : Empty2;
    assign Empty = CrapIt ? 1'bx 
    			  : FirstWordFall ? RawEmpty : RawEmpty;
    assign ProgFullSet = (DataCount==ProgFullValue) ? 1 : 0;
    assign ProgFullReset = (DataCount==ProgFullValue-1) ? 1 : 0;
    assign ProgEmptyReset = (DataCount==ProgEmptyValue+1) ? 1 : 0;
    assign ProgEmptySet = (DataCount==ProgEmptyValue) ? 1 : 0;
    assign FwftFull = (Num==Depth) && ValidWrite2 && ValidWrite3;
    assign Full = CrapIt ? 1'bx : FirstWordFall ? FwftFull
    				: (Num==Depth) ? 1 : 0;
    assign Dout = FirstWordFall & ~Empty ? Mem[RdPtr] : DoutRaw;
    assign DataCount = FirstWordFall ? FwftNum : Num;
    assign EnWord1 = FirstWordFall 
    			? (~ValidWrite2 || ~ValidWrite3 || Num!=Depth) ? 1 : 0
	    		: 1'b1;
    assign EnWord2 = FirstWordFall 
    			? (~ValidWrite3 || Num!=Depth) ? 1 : 0
	    		: 1'b1;
    assign SetCrapIt = BuiltIn & Read & Empty;
    assign Valid = FirstWordFall ? ~Empty : StandardValid;

    always @(posedge Clk) begin
	StandardValid <= (Reset) ? 0 : Read & ~Empty;
	CrapIt <= (Reset) ? 0 : SetCrapIt ? 1 : CrapIt;
	Empty2 <= RawEmpty;
	Din2 <= EnWord1 ? Din : Din2;
	Din3 <= EnWord2 ? Din2 : Din3;
	ValidWrite2 <= Reset ? 0 : EnWord1 ? ValidWrite : ValidWrite2;
	ValidWrite3 <= Reset ? 0 : EnWord2 ? ValidWrite2 : ValidWrite3;
	if(FirstWordFall && ValidWrite3 && (Num!=Depth)) Mem[WrPtr] = Din3;
	if(!FirstWordFall && ValidWrite2) Mem[WrPtr] = Din2;
	LastValidRead <= ValidRead;
	RawValid <= ~IntEmpty & ~(~LastValidRead & ValidRead);
 	Num <= (Reset) ? 0 
		       : (FirstWordFall ? ValidWrite3 && (Num!=Depth) : ValidWrite)
		       	    ? (ValidRead ? Num : Num+1)
			    : (ValidRead ? Num-1 : Num);
 	FwftNum <= (Reset) ? 0 
		       : ValidWrite
		       	    ? (ValidRead ? FwftNum : FwftNum+1)
			    : (ValidRead ? (FwftNum-1) : FwftNum);
 	WrPtr <= (CrapIt) ? {AddrWidth{1'bx}} 
	       : (Reset) ? 0 
		         : (FirstWordFall ? ValidWrite3 && (Num!=Depth) : ValidWrite2)
			 	? ((WrPtr==Depth-1) ? 0 : WrPtr+1)
			 	: WrPtr;
 	RdPtr <= (CrapIt) ? {AddrWidth{1'bx}} 
 		:(Reset) ? 0 
			 : ValidRead ? RdPtr==Depth-1 ? 0 : RdPtr+1
			 	     : RdPtr;
     	DoutRaw <= (CrapIt) ? {Width{1'bx}}
		            : (Reset) ? 0 : ValidRead ? Mem[RdPtr] : DoutRaw;
	ProgFull <= (CrapIt) ? 1'bx 
			     : (Reset) ? 0 : ProgFullSet ? 1 : ProgFullReset ? 0 : ProgFull;
	ProgEmpty <= (CrapIt) ? 1'bx 
			     : (Reset) ? 1 : ProgEmptySet ? 1 : ProgEmptyReset ? 0 : ProgEmpty;
    end

endmodule
