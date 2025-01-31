/*
	BlkMemGen_TrueDpNoReg4kx9.v: Behavior version of block RAM

		  Ted Rossin 9-18-2024
	  		     9-25-2024 

     Note: This is modeling the default WRITE_FIRST or Transparent mode.
*/

`timescale 1ns / 1ps

module BlkMemGen_TrueDpNoReg4kx9 (
     input clka
    ,input ena
    ,input wea
    ,input[11:0] addra
    ,input[8:0] dina
    ,output[8:0] douta

    ,input clkb
    ,input enb
    ,input web
    ,input[11:0] addrb
    ,input[8:0] dinb
    ,output[8:0] doutb
);

    BaseBlockDpRam #(.AddrWidth(12),.DataWidth(9),.Async(0)) Ram(
	 .clka(clka)
    	,.ena(ena)
	,.regcea(1'b0)
	,.wea(wea)
	,.addra(addra)
	,.dina(dina)
	,.douta(douta)
	,.Regdouta()

	,.clkb(clkb)
    	,.enb(enb)
	,.regceb(1'b0)
	,.web(web)
	,.addrb(addrb)
	,.dinb(dinb)
	,.doutb(doutb)
	,.Regdoutb()
    );

endmodule
