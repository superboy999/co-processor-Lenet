`include "global.v"

module max_pool #(
	parameter INPUT_NUM = 6   
	)(
	input												clk,
	input												rst_n,
	input												aa_en,
	input												aa_first_data,
	input												aa_last_data,
	input		[`WD*INPUT_NUM-1:0]					data_i,
	output  											q_en,
	output  	[`WD*INPUT_NUM-1:0]					q
	);
	
	reg first_data;
	reg last_data;
	reg en;
	reg [0:INPUT_NUM-1][`WD-1:0] max_temp ;
    reg last_data_d1;

	wire [0:INPUT_NUM-1][`WD-1:0] d_in;

    assign d_in = data_i;
    assign q = last_data_d1 ? max_temp : 0;
    assign q_en = last_data_d1;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) first_data <= 0;
        else first_data <= aa_first_data;
    end

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) last_data <= 0;
        else last_data <= aa_last_data;
    end

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) en <= 0;
        else en <= aa_en;
    end

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) 
            last_data_d1 <= 0;
        else 
            last_data_d1 <= last_data;
    end

	genvar i;
	generate 
		for (i=0; i<INPUT_NUM; i=i+1) begin : max_pool_num
			always @(posedge clk or negedge rst_n) begin
				if (!rst_n) 
                    max_temp[i] <= 0;
				else begin 
                    if (!en) max_temp[i] <= 0;
                    else begin
                        if (first_data)
                            max_temp[i] <= d_in[i];
				        else if ($signed(d_in[i]) > $signed(max_temp[i]))	
                            max_temp[i] <= d_in[i];
                    end
                end
            end
        end
	endgenerate

endmodule

