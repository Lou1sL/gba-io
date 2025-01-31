/*
	BlkMemGen_SpNoReg4kx9.v: Behavior version of block RAM

		  Ted Rossin 8-26-2024
	  		     9-24-2024 

     Note: This is modeling the default WRITE_FIRST or Transparent mode.
*/

`timescale 1ns / 1ps

module BlkMemGen_SpNoReg4kx9 (
     input clka
    ,input ena
    ,input wea
    ,input[11:0] addra
    ,input[8:0] dina
    ,output[8:0] douta
);

    BaseBlockRam #(.AddrWidth(12),.DataWidth(9)) Ram(
	 .clka(clka)
    	,.ena(ena)
	,.wea(wea)
	,.regcea(1'b0)
	,.addra(addra)
	,.dina(dina)
	,.douta(douta)
	,.Regdouta()
    );

endmodule
