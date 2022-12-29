`include "global.v"

module conv_in4 #(
    parameter INPUT_NUM = 4,//stable
    parameter OUTPUT_NUM = 16,
    parameter SHIFT = 15
    )(
    input clk,
    input rst_n,
    input aa_en,
    input aa_first_data,
    input aa_last_data,
    input [`WD*INPUT_NUM-1:0]                image,
    input [`WD_BIAS*OUTPUT_NUM-1:0]          bias,
    input [`WD*INPUT_NUM*OUTPUT_NUM-1:0]     weight,
    output [`WD*OUTPUT_NUM-1:0]              q,
    output q_en
    );

    reg first_data;
    reg last_data;
    reg en;
    
    wire [0:OUTPUT_NUM-1][0:INPUT_NUM-1][`WD-1:0]  weight_in;
    wire [0:OUTPUT_NUM-1][`WD_BIAS-1:0]            bias_in;
    wire [0:OUTPUT_NUM-1]                           acc_q_en;
	wire [0:OUTPUT_NUM-1][`WD-1:0]                 acc_q; 

    assign weight_in = weight;
    assign bias_in = bias;
    assign q = acc_q;
    assign q_en = acc_q_en[0];

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

    genvar i;
    generate
        for (i=0; i<OUTPUT_NUM; i=i+1) begin : acc_in6
            conv_in4_acc #(
                .INPUT_NUM  (INPUT_NUM),
                .SHIFT      (SHIFT)
            )u_conv_in4_acc(
                .clk            (clk),
				.rst_n	        (rst_n),
				.en				(en),
				.first_data		(first_data),
				.last_data		(last_data),
				.image_in		(image),
				.bias_in		(bias_in[i]),
				.weight_in		(weight_in[i]),
				.q_en			(acc_q_en[i]),
				.q              (acc_q[i])                
            );
        end
    endgenerate

endmodule

module conv_in4_acc #(
    parameter INPUT_NUM = 4,
    parameter SHIFT = 15
    )(   
    input clk,
    input rst_n,
    input en,
    input first_data,
    input last_data,
    input [`WD*INPUT_NUM-1:0] image_in,
    input [`WD_BIAS-1:0] bias_in,
    input [`WD*INPUT_NUM-1:0] weight_in,
    output [`WD-1:0] q,
    output  q_en
    );

    wire [0:INPUT_NUM-1][`WD-1:0]  image_i;
    wire [0:INPUT_NUM-1][`WD-1:0]  weight_i;
    wire [0:INPUT_NUM-1][`WD*2:0]  mac_q;
    wire [0:INPUT_NUM-1]            mac_q_en;
    wire [`WD*2+2:0]               acc_q;
    wire [`WD*2+1:0]               acc_q_00;
    wire [`WD*2+1:0]               acc_q_01;

    wire [`WD*2+1:0]               acc_q_10;



    assign image_i = image_in;
    assign weight_i = weight_in;
    assign q = acc_q[`WD*2+2:SHIFT];
    assign acc_q_00 = $signed(mac_q[0]) + $signed(mac_q[1]);
    assign acc_q_01 = $signed(mac_q[2]) + $signed(mac_q[3]);

    assign acc_q_10 = $signed(acc_q_00) + $signed(acc_q_01);

    assign acc_q = q_en ? $signed(acc_q_10) + $signed(bias_in) : 0;
    assign q_en = mac_q_en[0];

    genvar i;
    generate
        for (i=0; i < INPUT_NUM; i=i+1) begin :mac_in4
        mac u_mac(
            .clk        ( clk        ),
            .rst_n      ( rst_n      ),
            .en         ( en         ),
            .first_data ( first_data ),
            .last_data  ( last_data  ),
            .image_i    ( image_i[i]    ),
            .weight_i   ( weight_i[i]   ),
            .q_en       ( mac_q_en[i]   ),
            .q          ( mac_q[i]   )
        );
        end
    endgenerate

endmodule
