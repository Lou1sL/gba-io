/*
	BaseBlockDpRam.v: Behavioral version of block RAM

		  Ted Rossin 8-26-2024
	  		     9-22-2024 

     Note: 
*/

`timescale 1ns / 1ps

module BaseBlockDpRam #(parameter AddrWidth=12,parameter DataWidth=8,parameter Async=0) (
     input clka
    ,input ena
    ,input regcea
    ,input wea
    ,input[AddrWidth-1:0] addra
    ,input[DataWidth-1:0] dina
    ,output reg[DataWidth-1:0] douta
    ,output reg[DataWidth-1:0] Regdouta

    ,input clkb
    ,input enb
    ,input regceb
    ,input web
    ,input[AddrWidth-1:0] addrb
    ,input[DataWidth-1:0] dinb
    ,output reg[DataWidth-1:0] doutb
    ,output reg[DataWidth-1:0] Regdoutb
);
    reg[DataWidth-1:0] Mem[0:(1<<AddrWidth)-1];
    reg[AddrWidth-1:0] Addr1a,Addr1b;
    reg En1a,En1b,We1a,We1b;


    always @(posedge clka) begin
    	if(Async) begin
	    Addr1a <= addra;  En1a <= ena;  We1a<=wea;
	    if(addra==Addr1b) begin
	    	if(En1b & ena & We1b & wea & clkb) begin // write data collision
	 	    douta = dina;
		    //Mem[addra] = douta;  // Write is suppressed!
	    	end
	    	else if(ena & wea & (~We1b | ~En1b)) begin // not writing other port
            	    douta = dina;
	            Mem[addra] = dina;
	    	end
	    	else begin
	            if(wea & ena) Mem[addra] = dina;
            	    douta = ena ? (wea ? dina : Mem[addra]) : douta;
    	    	end
	    end
	    else begin
	        if(wea & ena) Mem[addra] = dina;
            	douta = ena ? (wea ? dina : Mem[addra]) : douta;
    	    end
    	end
	else begin  // Clocks tied together
	    if(addra==addrb) begin
	    	if(enb & ena & web & wea) begin // write data collision
	 	    douta = dina;
		    //Mem[addra] = douta;  // Write is suppressed!
	    	end
	    	else if(ena & wea & (~web | ~enb)) begin // not writing other port
            	    douta = dina;
	            Mem[addra] = dina;
	    	end
	    	else begin
	            if(wea & ena) Mem[addra] = dina;
		    	// Crazyland.  If port A and B have the same address and 
			// port A is written, both port A and B show the output.  
			// But, if port B is written, only port B show the new output value
            	    douta = ena ? (wea ? dina : web ? douta : Mem[addra]) : douta;
    	    	end
	    end
	    else begin
	        if(wea & ena) Mem[addra] = dina;
            	douta = ena ? (wea ? dina : Mem[addra]) : douta;
    	    end
	end
    end


    always @(posedge clkb) begin
    	if(Async) begin
	    Addr1b <= addrb;  En1b <= enb;  We1b<=web;
	    if(Addr1a==addrb) begin
	    	if(En1a & enb & We1a & web & clka) begin // write data collision
	 	    doutb = dinb;
		    //Mem[addrb] = doutb;  // Write is suppressed!
	    	end
	    	else if(enb & web & (~We1a | ~En1a)) begin // not writing other port
            	    doutb = dinb;
	            Mem[addrb] = dinb;
	    	end
	    	else begin
	            if(web & enb) Mem[addrb] = dinb;
            	    doutb = enb ? (web ? dinb : Mem[addrb]) : doutb;
    	    	end
	    end
	    else begin
	        if(web & enb) Mem[addrb] = dinb;
            	doutb = enb ? (web ? dinb : Mem[addrb]) : doutb;
    	    end
    	end
	else begin  // Clocks tied together
	    if(addra==addrb) begin
	    	if(ena & enb & wea & web) begin // write data collision
	 	    doutb = dinb;
		    //Mem[addrb] = doutb;  // Write is suppressed!
	    	end
	    	else if(enb & web & (~wea | ~ena)) begin // not writing other port
            	    doutb = dinb;
	            Mem[addrb] = dinb;
	    	end
	    	else begin
	            if(web & enb) Mem[addrb] = dinb;
		    	// Crazyland.  If port A and B have the same address and 
			// port A is written, both port A and B show the output.  
			// But, if port B is written, only port B show the new output value
            	    doutb = enb ? (web ? dinb : wea ? dina : Mem[addrb]) : doutb;
    	    	end
	    end
	    else begin
	        if(web & enb) Mem[addrb] = dinb;
            	doutb = enb ? (web ? dinb : Mem[addrb]) : doutb;
    	    end
    	end
    end

    always @(posedge clka) begin
	Regdouta <= regcea ? douta : Regdouta;
    end
    always @(posedge clkb) begin
	Regdoutb <= regceb ? doutb : Regdoutb;
    end

endmodule
