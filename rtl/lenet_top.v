module lenet_top(
    input clk,
    input rst_n,
    input go,
    output ready,
    output [3:0] digit
);

    wire [9:0] aa_image;
    wire [`WD-1:0] image_input;
    wire cena_image;

    src_rom src_rom(
        .clk			(clk),
        .rst_n			(rst_n),
        .aa				(aa_image),
        .cena			(cena_image),
        .qa				(image_input)
    );
		
	lenet i_lenet(
		.clk				(clk),
		.rst_n				(rst_n),
		.go					(go),				
		.cena_image			(cena_image),
		.aa_image			(aa_image),
		.conv1_image		(image_input),
		.digit				(digit),		
		.ready				(ready)
    );

endmodule