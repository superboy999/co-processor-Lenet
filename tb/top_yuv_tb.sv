
`include "../rtl/global.v"


module tb_yuv();

	reg	rst_n;
	reg	clk;
	reg	[31:0] digit_cnt;

	wire go;
	wire [3:0] digit;
	wire ready;
	wire [9:0] aa_image;
	wire [`WD-1:0] image_input;

	itf_image_input 	itf(clk);	

	src_rom src_rom(
		.clk			(clk),
		.rst_n			(rst_n),
		.aa				(aa_image),
		.cena			(cena_image),
		.qa				(image_input)
		);
		
	top top(
		.clk				(clk),
		.rst_n				(rst_n),
		.go					(go),				
		.cena_image			(cena_image),
		.aa_image			(aa_image),
		.conv1_image		(image_input),
		.digit				(digit),		
		.ready				(ready)
		);

	assign go = itf.go;
	assign itf.ready = ready;

	initial begin
		rst_n = 1'b0;
		#(`RESET_DELAY); 
		$display("@ %d rst_n done#############################", $time);
		rst_n = 1'b1;
	end
	
	initial begin
		clk = 1;
		forever begin
			clk = ~clk;
			#(`CLK_PERIOD_DIV2);
		end
	end

	initial begin
		#(`RESET_DELAY)
		#(`RESET_DELAY)
		itf.drive_frame(10);
		#(100000)
		$finish();
	end	

	always @(posedge clk or negedge rst_n) begin
		if (!rst_n)			digit_cnt <= 0;
		else if (ready)	begin
			$display("@ %d ===============process %d image, digit is %d ===============", $time, digit_cnt, digit);
			digit_cnt <= digit_cnt + 1;
		end
	end


`ifdef DUMP_FSDB 
	initial begin
	$fsdbDumpfile("xx.fsdb");
	$fsdbDumpvars();
	end
`endif
	
endmodule


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

endmodule


interface itf_image_input(input clk);
	logic	go;
	logic	ready;
	
	clocking cb@( posedge clk);
		output	go;
		input 	ready;
	endclocking	
	

	task drive_frame(int num);

		integer	fd;

		static logic [256*8-1:0] sequence_name = "E:/lenet/jisy_cnn/cnn_lite/test_data/test_100f_4b.yuv";
		go	<= 0;
		@cb;
		@cb;
		
		fd = $fopen(sequence_name, "rb");
		
		for(int f=0; f<num; f++ ) begin
			@cb;
			@cb;
			for(int i = 0; i< 32*32; i++ ) begin
				$root.tb_yuv.src_rom.mem[i] <= $fgetc(fd);
			end
			@cb;
			@cb;
			go		 <= 1;
			@cb;
			go		 <= 0;
			@cb.ready;
			@cb;
			@cb;
		end
	endtask

/*
	task drive_frame(int num);

	go <= 0;
	@cb;
	@cb;
	
	for(int f = 0; f <num; f++) begin
		$readmemh("../cnn_lite_data2/test_4.txt", $root.tb.src_rom.mem);
		@cb;
		@cb;
		go <=1;
		@cb;
		go <=0;
		@cb.ready;
		@cb;
		@cb;
		end
	endtask
*/
endinterface
