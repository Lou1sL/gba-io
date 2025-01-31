/*
	BlkMemGen_SpNoReg4kx9.v: Behavior version of block RAM

		  Ted Rossin 9-22-2024
	  		     9-22-2024 

     Note: This is modeling the default WRITE_FIRST or Transparent mode.
*/

`timescale 1ns / 1ps

module BlkMemGen_SpNoReg128kx9 (
     input clka
    ,input ena

    ,input wea
    ,input[16:0] addra
    ,input[8:0] dina
    ,output[8:0] douta
);

    BaseBlockRam #(.AddrWidth(17),.DataWidth(9)) Ram(
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
