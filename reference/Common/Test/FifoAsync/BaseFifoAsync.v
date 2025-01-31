/*
	BaseFifoAsync.v: Behavior version of Async FIFO

		  Ted Rossin 10-18-2024
	  		     11-10-2024 

    Note: Do not synthesize this module.  If need be copy to a new file and
          make the following changes for it to work.
		  -Add binary to gray code and gray code to binary logic
		   or the sampling of the pointers in the other domains will
		   contain errors.
		  -Make sure the true FIFO size (PhysDepth) is a power of two otherwise
		   the gray code will flip more than one bit when the pointers
		   wrap.
*/

`timescale 1ns / 1ps

module BaseFifoAsync #(
     parameter FirstWordFall=0
    ,parameter BuiltIn=0
    ,parameter Width=8
    ,parameter ProgFullValue=10
    ,parameter ProgEmptyValue=7
    ,parameter DataCountWidth=4
    ,parameter Depth=8
    ,parameter NumSync=2
) 
(
     input WrClk
    ,input RdClk
    ,input Reset
    ,output WrRstBusy
    ,output RdRstBusy
    ,input Write
    ,input Read
    ,input[Width-1:0] Din
    ,output[Width-1:0] Dout
    ,output ProgFull
    ,output reg[DataCountWidth-1:0] WrDataCount
    ,output[DataCountWidth-1:0] RdDataCount
    ,output Valid
    ,output Empty
    ,output ProgEmpty
    ,output Full
);
    	// This is how the Xilinx tool works
    parameter ExtDepth = (BuiltIn) ? FirstWordFall ? Depth-2 : Depth 
    				   : Depth-1;  
    parameter PhysDepth = (BuiltIn && !FirstWordFall) ? Depth+1 : Depth;
    parameter LatencyOffsetR = BuiltIn ? FirstWordFall ? 0 : 1
    				       : 2;   // Amazing that BuiltIn is faster.
    parameter LatencyOffsetW = BuiltIn ? 0 : 2;   // Amazing that BuiltIn is faster.
    parameter NumBits = $clog2(ExtDepth+1);
    parameter NonPow2 = PhysDepth[NumBits-1:0] != 0;
    parameter AddrWidth = $clog2(PhysDepth);
    parameter ProgFullThresh = FirstWordFall ? ProgFullValue-2 : ProgFullValue;
    parameter ProgEmptyThresh = FirstWordFall ? ProgEmptyValue-2 : ProgEmptyValue;

    wire ValidWrite,FifoValidRead;
    reg[AddrWidth-1:0] WrPtr,WrPtrGray,WrPtrGray2,RdPtr,RdPtr2,RdPtrGray;
    wire[AddrWidth-1:0] NextWrPtr,NextRdPtr;
    wire[AddrWidth-1:0] RdPtrW,WrPtrR;
    wire[NumBits-1:0] NumW,FixNumW,RawNumW;
    wire[NumBits-1:0] NumR,FixNumR,RawNumR;
    wire[NumBits-1:0] FixRdDataCount,RawRdDataCount;
    wire FifoEmpty,FifoRead;
    reg[Width-1:0] FifoDout;
    reg[Width-1:0] Dout2;
    reg[Width-1:0] Mem[0:PhysDepth-1];
    reg[AddrWidth-1:0] Wsync[0:10],Rsync[0:9];
    reg RawProgFull,RawProgEmpty;

    initial begin
    	if(NumSync<2 || NumSync>8) begin
	   $display("ERROR: BaseFifoAsync NumSync must be between 2 and 8.  %d is invalid\n",NumSync);
	   $finish;
    	end
    end
    
    reg FifoValid;
    wire ProgFullSet,ProgFullReset;
    wire ProgEmptySet,ProgEmptyReset;
    reg Valid2;

    reg[8:0] WrResetDelay,RdResetDelay;

    assign WrRstBusy = WrResetDelay[8];
    assign RdRstBusy = RdResetDelay[8];

    always @(posedge WrClk) begin
    	WrResetDelay <= Reset ? 9'h1ff : {WrResetDelay[7:0],1'b0};
    end
	
    always @(posedge RdClk) begin
    	RdResetDelay <= Reset ? 9'h1ff : {RdResetDelay[7:0],1'b0};
    end

    assign ValidWrite = Write & ~Full;
    assign FifoValidRead = FifoRead & ~FifoEmpty;
    assign FifoEmpty = (NumR==0) ? 1 : 0;
    assign ProgFullSet = (WrDataCount>=ProgFullThresh) ? 1 : 0;
    assign ProgFullReset = (WrDataCount<=ProgFullThresh-1) ? 1 : 0;

    assign ProgEmptyReset = (RdDataCount>=ProgEmptyThresh) ? 1 : 0;
    assign ProgEmptySet = (RdDataCount<=ProgEmptyThresh) ? 1 : 0;

    assign FifoRead = FirstWordFall ? U2RRead : Read;
    assign Empty = FirstWordFall ? ~Valid : FifoEmpty;
    assign Full = BuiltIn ? (FirstWordFall ? NumW==ExtDepth+1 : NumW==ExtDepth) ? 1 : 0
    			  : (WrDataCount==ExtDepth || NumW==ExtDepth) ? 1 : 0;
    assign Dout = FirstWordFall ? Dout2 : FifoDout;
    assign Valid = FirstWordFall ? Valid2 : FifoValid;
    assign ProgFull = RawProgFull | ProgFullSet;
    assign ProgEmpty = RawProgEmpty | ProgEmptySet;

    assign RawNumW = WrPtr-RdPtrW;
    	// Cheap modulo math for non-power of 2 roll over.
    assign FixNumW = RawNumW[NumBits-1] ? RawNumW+PhysDepth : RawNumW;
    assign NumW = NonPow2 ? FixNumW : RawNumW;

    assign RawNumR = WrPtrR-RdPtr;
    assign FixNumR = RawNumR[NumBits-1] ? RawNumR+PhysDepth+1 : RawNumR;
    assign NumR = NonPow2 ? FixNumR : RawNumR;


    assign NextRdPtr = (Reset) ? 0 
			 : FifoValidRead ? RdPtr==PhysDepth-1 ? 0 : RdPtr+1
			 	     : RdPtr;

	// U2R is Unload to Read.  This is logic to convert a Standard Xilinx
	// FIFO to an first word fall through without extra latency.	
	// For first word fall through, an extra cycle of latency is needed
	// and the read/write counters seem to only show the internal
	// standard FIFO depths.
    wire U2RValidSet,U2RValidClear,U2RRead,U2RUnload;
    reg U2RFifoEmpty2,U2RFifoValid;

    	// Unload FIFO if the FIFO output is not valid OR the storage register is not valid
    assign U2RUnload = Read | ~U2RFifoValid | ~Valid2;

    assign U2RRead = U2RUnload | (~U2RFifoValid & (FifoEmpty | U2RFifoEmpty2));
    assign U2RValidSet = U2RRead & ~FifoEmpty;
    assign U2RValidClear = U2RFifoValid & U2RUnload & FifoEmpty;

    	// This is just an emulator so OK to sync binary counters from other domains
	// Normally, a gray counter is needed where only 1 bit changes at a time.
    always @(posedge RdClk) begin
	RawProgEmpty <= (Reset) ? 1 : ProgEmptySet ? 1 : ProgEmptyReset ? 0 : ProgEmpty;
	U2RFifoEmpty2 <= Reset ? 1 : FifoEmpty;
	U2RFifoValid <= Reset ? 0 
			   : U2RValidSet ? 1 
			   	      : U2RValidClear ? 0 
				      		   : U2RFifoValid;
    	Valid2 <= (Reset) ? 0 
			  : Read|~Valid2 ? U2RFifoValid : Valid2;
	Dout2 <= (Reset) ? 0 : Read|~Valid2 ? FifoDout : Dout2;

	FifoValid <= (Reset) ? 0 : FifoValidRead;
 	RdPtr <= NextRdPtr;
	RdPtr2 <= RdPtr;
// REVISIT:  If this was to be synthesized, would need to convert to Gray code.
     	RdPtrGray <= NextRdPtr;
     	FifoDout <= (Reset) ? 0 : FifoValidRead ? Mem[RdPtr] : FifoDout;
	Rsync[0] <= (BuiltIn) ? WrPtrGray : WrPtrGray2;
	Rsync[1] <= Rsync[0];
	Rsync[2] <= Rsync[1];
	Rsync[3] <= Rsync[2];
	Rsync[4] <= Rsync[3];
	Rsync[5] <= Rsync[4];
	Rsync[6] <= Rsync[5];
	Rsync[7] <= Rsync[6];
	Rsync[8] <= Rsync[7];
	Rsync[9] <= Rsync[8];
    end

// REVISIT:  If this was to be synthesized, will need to convert from Gray code to binary.
    assign WrPtrR = Rsync[LatencyOffsetR+NumSync-1];
 //   assign RdDataCount = WrPtrR-RdPtr2;

    assign RawRdDataCount = WrPtrR-RdPtr2;
    assign FixRdDataCount = RawRdDataCount[NumBits-1] ? RawRdDataCount+PhysDepth : RawRdDataCount;
    assign RdDataCount = NonPow2 ? FixRdDataCount : RawRdDataCount;


    assign NextWrPtr = (Reset) ? 0 
    			 : ValidWrite
			 	? ((WrPtr==PhysDepth-1) ? 0 : WrPtr+1)
			 	: WrPtr;

    always @(posedge WrClk) begin
    	WrDataCount <= NumW;
	if(ValidWrite) Mem[WrPtr] = Din;
 	WrPtr <= NextWrPtr;
// REVISIT:  If this was to be synthesized, would need to convert to Gray code.
 	WrPtrGray <= NextWrPtr;
 	WrPtrGray2 <= WrPtrGray;
	RawProgFull <= (Reset) ? 0 : ProgFullSet ? 1 : ProgFullReset ? 0 : ProgFull;
        Wsync[0] <= RdPtrGray;
        Wsync[1] <= Wsync[0];
        Wsync[2] <= Wsync[1];
        Wsync[3] <= Wsync[2];
        Wsync[4] <= Wsync[3];
        Wsync[5] <= Wsync[4];
        Wsync[6] <= Wsync[5];
        Wsync[7] <= Wsync[6];
        Wsync[8] <= Wsync[7];
        Wsync[9] <= Wsync[8];
        Wsync[10]<= Wsync[9];
    end
// REVISIT:  If this was to be synthesized, would need to convert to Gray code to binary.
    assign RdPtrW = Wsync[1+LatencyOffsetW+NumSync-1];

endmodule
