module src_rom(
	input					clk,
	input					rst_n,
	input	[9:0]			aa,
	input					cena,
	output reg [`WD-1:0]	qa
	);

	logic [31:0] mem [0:32*32-1];
	//32*32*32	

	always @(posedge clk or negedge rst_n)
		if (!rst_n)			qa <= 0;
		else if (!cena)		qa <= mem[aa];
	initial begin
		$readmemh("E:/lenet/jisy_cnn/cnn_lite/test_data/data_txt/test_4.txt", mem);
	end

endmodule