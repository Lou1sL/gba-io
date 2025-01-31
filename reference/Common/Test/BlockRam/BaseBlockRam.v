/*
	BaseBlockRam.v: Behavior version of block RAM

		  Ted Rossin 8-26-2024
	  		     9-24-2024 

     Note:
*/

`timescale 1ns / 1ps

module BaseBlockRam #(parameter AddrWidth=12,parameter DataWidth=8) (
     input clka
    ,input ena
    ,input regcea
    ,input wea
    ,input[AddrWidth-1:0] addra
    ,input[DataWidth-1:0] dina
    ,output reg[DataWidth-1:0] douta
    ,output reg[DataWidth-1:0] Regdouta
);
    reg[DataWidth-1:0] Mem[0:(1<<AddrWidth)-1];

    always @(posedge clka) begin
	if(wea & ena) Mem[addra] = dina;
        douta = ena ? (wea ? dina : Mem[addra]) : douta;
    end
    always @(posedge clka) begin
	Regdouta <= regcea ? douta : Regdouta;
    end

endmodule
