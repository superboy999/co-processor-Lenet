
module bhv_sram #
	(
	parameter  WWORD = 32,
	parameter  WADDR =  5,
	parameter  DEPTH = 24
	)
	(
	input						clk,
	output reg		[WWORD-1:0]	qa,
	input			[WADDR-1:0]	aa,
	input						cena,
	input			[WWORD-1:0]	db,
	input			[WADDR-1:0]	ab,
	input						cenb
	);
	reg				[WWORD-1:0]	mem[0:((1<<WADDR)-1)];
	
	always @(posedge clk) if (!cena) qa <= mem[aa];
	always @(posedge clk) if (!cenb && ab < DEPTH) mem[ab] <= db;
endmodule

