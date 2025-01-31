// Pll2.b:  Fake PLL which uses a command line definition -DPLL_CYCLE=10
//         to define the frequency of the output.  For example =10 is a
//         100 MHz clock.
//		Ted Rossin  6-18-2024
// 			   10-21-2024

module clk_wiz_double( 
     output clk_out1
    ,output clk_out2
    ,output reg locked
    ,input clk_in1
);
`ifdef PLL_CYCLE1
    parameter Cycle1 = `PLL_CYCLE1;
    parameter Cycle2 = `PLL_CYCLE2;
`else
    parameter Cycle1 = 100;
    parameter Cycle2 = 60;
`endif
    reg pre_clk_out1,pre_clk_out2;
    reg Locked0,Locked1,Locked2,Locked3;
    reg Locked4,Locked5,Locked6,Locked7;

    always #(Cycle1*0.5) begin
	pre_clk_out1 = ~pre_clk_out1;
    end
    assign clk_out1 = locked ? pre_clk_out1 : clk_in1;

    always #(Cycle2*0.5) begin
	pre_clk_out2 = ~pre_clk_out2;
    end
    assign clk_out2 = locked ? pre_clk_out2 : clk_in1;

    always @(posedge clk_in1) begin
 	Locked0 <= 1;
 	Locked1 <= Locked0;
 	Locked2 <= Locked1;
 	Locked3 <= Locked2;
 	Locked4 <= Locked3;
 	Locked5 <= Locked4;
 	Locked6 <= Locked5;
 	Locked7 <= Locked6;
 	locked <= Locked7;
    end
    initial begin
	pre_clk_out1 = 0;
	pre_clk_out2 = 0;
	Locked0 = 0;
	Locked1 = 0;
	Locked2 = 0;
	Locked3 = 0;
	Locked4 = 0;
	Locked5 = 0;
	Locked6 = 0;
	Locked7 = 0;
	locked = 0;
    end
endmodule

