/*
	BlkRomGen_SpNoReg4kx9.v: Behavior version of block RAM

		  Ted Rossin 9-14-2024
	  		     9-24-2024 

     Note: This is modeling the default WRITE_FIRST or Transparent mode.
*/

`timescale 1ns / 1ps

module BlkRomGen_SpNoReg4kx9 (
     input clka
    ,input ena
    ,input[11:0] addra
    ,output[8:0] douta
);

    BaseBlockRam #(.AddrWidth(12),.DataWidth(9)) Ram(
	 .clka(clka)
    	,.ena(ena)
	,.wea(1'b0)
	,.regcea(1'b0)
	,.addra(addra)
	,.dina(9'd00)
	,.douta(douta)
	,.Regdouta()
    );

endmodule
