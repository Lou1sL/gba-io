/*
	Uart.v: Uart 

		  Ted Rossin 8-16-2023
	  		     8-22-2023	  
*/

`timescale 1ns / 1ps

`define RXSTATE_IDLE		0
`define RXSTATE_START		1
`define RXSTATE_GET_BITS	2
`define RXSTATE_GET_STOP	3

`define TXSTATE_IDLE		0
`define TXSTATE_SEND_BITS	1

	// BAUD_DIV is frequency/BAUD  for example 25000000/115200=217
module uart #(parameter BAUD_DIV=217) (
     input Clk
    ,input Reset	// Active high reset

    ,input Rx		// Serial input
    ,input RxEnable	// Enable receive logic
    ,input RxUnload	// Assert for one cycle to unload output buffer
    ,output[7:0] RxData	// Receive data
    ,output RxValid	// Receive data is valid (use RxUnload to get next byte)
    ,output RxFrameError// Receive machine did not see stop bit (assert Reset)
    ,output RxBufferOverflow  // New data arrived before output buffer was unloaded

    ,output Tx		// Serial output
    ,input[7:0] TxData	// Data to send
    ,input TxSend	// Assert for one cycle to load send buffer with TxData
    ,output TxEmpty	// The send buffer is empty so machine is ready for next TxData
);
parameter BAUD_BITS = $clog2(BAUD_DIV)-1;
    reg[BAUD_BITS:0] RxBaudCounter,TxBaudCounter;
    wire[BAUD_BITS:0] BaudValue;
    reg Rx0,RxSync,RxLast;
    reg RxLoadBaud,RxLoadHalfBaud,LoadRxBit,LoadRxBuf;
    reg TxLoadBaud,LoadTxShifter;
    reg SampleEn,TxBitEn,TxShiftEn;
    reg[2:0] RxBit;
    reg[7:0] RxAcc,RxBuf;
    reg[7:0] TxShifter,TxBuf;
    reg[1:0] RxState,NxtRxState;
    reg TxState,NxtTxState;
    reg[3:0] TxBit;
    reg RxOutValid;
    reg RxFrameError0,SetRxFrameError;
    reg RxBufferOverflow0,SetRxBufferOverflow;
    reg TxOut,TxBufValid,SendTxBit;
    wire NextTx,CleanTxSend;

    assign BaudValue = BAUD_DIV-1;
    assign RxData = RxBuf;
    assign RxValid = RxOutValid;
    assign RxFrameError = RxFrameError0;
    assign RxBufferOverflow = RxBufferOverflow0;
    assign Tx = TxOut;
    assign TxEmpty = ~TxBufValid;
    assign CleanTxSend = TxSend & TxEmpty;
    assign NextTx = (TxState==`TXSTATE_IDLE) ? 1 : (TxBit==0) ? 0 : TxShifter[0];

    always @(posedge Clk) begin
	RxBaudCounter <= (RxLoadBaud) 
			    ? BaudValue 
			    : (RxLoadHalfBaud)
			    	? BaudValue[BAUD_BITS:1]
				: (RxBaudCounter) ? RxBaudCounter - 1 : 0;
	TxBaudCounter <= (TxLoadBaud) 
			    ? BaudValue 
			    : (TxBaudCounter) ? TxBaudCounter - 1 : 0;
	SampleEn <= RxBaudCounter==1;
	TxBitEn <= TxBaudCounter==1;

	TxBuf <= CleanTxSend ? TxData : TxBuf;
	RxBit <= (Reset | RxState==`RXSTATE_START) 
			? 0 
			: LoadRxBit ? RxBit+1 : RxBit;
	TxBit <= (Reset | TxState==`TXSTATE_IDLE) 
			? 0 
			: SendTxBit ? TxBit+1 : TxBit;
	RxState <= Reset ? `RXSTATE_IDLE : NxtRxState;
	TxState <= Reset ? `TXSTATE_IDLE : NxtTxState;
	RxBuf <= LoadRxBuf ? RxAcc : RxBuf;
	RxAcc <= LoadRxBit ? {RxSync,RxAcc[7:1]} : RxAcc;
	Rx0 <= Rx;
	RxSync <= Rx0;
	RxLast <= RxSync;
	RxOutValid <= (Reset | (RxOutValid & RxUnload))
			? 0 
			: LoadRxBuf ? 1 : RxOutValid;
	RxFrameError0 <= Reset ? 0 : SetRxFrameError ? 1 : RxFrameError0;
	RxBufferOverflow0 <= Reset ? 0 : SetRxBufferOverflow ? 1 : RxBufferOverflow0;
	TxOut <= NextTx;
	TxBufValid <= (Reset | LoadTxShifter) ? 0 : CleanTxSend ? 1 : TxBufValid;
	TxShifter <= LoadTxShifter 
			? TxBuf 
			: TxShiftEn ? {1'b1,TxShifter[7:1]} : TxShifter;
    end

    always @(*) begin
	NxtRxState = RxState;
	RxLoadBaud = 0;  RxLoadHalfBaud = 0;  LoadRxBit = 0;
	LoadRxBuf = 0;   SetRxFrameError = 0;   SetRxBufferOverflow = 0;

 	casex(RxState) 
	    `RXSTATE_IDLE: begin
		    if(RxLast & ~RxSync) begin
		 	NxtRxState = `RXSTATE_START;
			RxLoadHalfBaud = 1;
		    end	
	    	end
	    `RXSTATE_START: begin
		    if(SampleEn) begin
			NxtRxState = `RXSTATE_GET_BITS;
			RxLoadBaud = 1;	
		    end
	    	end	    
	    `RXSTATE_GET_BITS: begin
		    if(SampleEn) begin
			RxLoadBaud = 1;	  LoadRxBit = 1; 
			if(RxBit==7) begin
			    NxtRxState = `RXSTATE_GET_STOP;
			end
		    end
	    	end	    

	    `RXSTATE_GET_STOP: begin
		    if(SampleEn) begin
			if(RxSync) begin
			    if(RxOutValid) begin
				SetRxBufferOverflow = 1;
			    end
			    else begin
			        LoadRxBuf = 1;
		    	    end
			end
			else begin
			    SetRxFrameError = 1;
			end
			NxtRxState = `RXSTATE_IDLE;
		    end	
  	    	end
	endcase
    end	

    always @(*) begin
	NxtTxState = TxState;
	TxLoadBaud = 0;  SendTxBit = 0;
	LoadTxShifter = 0;   TxShiftEn = 0;

 	casex(TxState) 
	    `TXSTATE_IDLE: begin
		    if(TxBufValid) begin
		 	NxtTxState = `TXSTATE_SEND_BITS;
			TxLoadBaud = 1;
			LoadTxShifter = 1;
		    end	
	    	end
	    `TXSTATE_SEND_BITS: begin
		    if(TxBitEn) begin
		  	SendTxBit = 1;
			TxLoadBaud = 1;	  
			TxShiftEn = (TxBit!=0) ? 1 : 0;
			if(TxBit==9) begin
			    NxtTxState = `TXSTATE_IDLE;
			end
		    end
	    	end	    
	endcase
    end	

endmodule
