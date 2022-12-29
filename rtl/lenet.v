`include "global.v"

//jisy
//TODO 1.12
//difine the width of wire  -ok
//$signed()                 -ok
//correct the wave          -ok
//change the global in tb   -ok
//rename sram_ctrl          -ok
//solve the problem:  (ver-318) signed to unsigned assignment occurs.

module lenet(
    input clk,
    input rst_n,
    input go,
    input   [`WD-1:0] conv1_image,
    output  [9:0] aa_image,
    output  cena_image,
    output  [3:0] digit,
    output  ready
    );

    wire conv1_ready;
    wire pool1_ready;
    wire conv_fc1_ready;
    wire conv1_go;
    wire pool1_go;
    wire conv_fc1_go;

    wire [6:0] conv1_aa_bias;
    wire [9:0] conv1_aa_weight;
    wire [4*`WD_BIAS-1:0] conv1_bias;
    wire [4*`WD-1:0] conv1_weight;
    wire [4*`WD-1:0] conv1_q;
    wire [9:0] pool1_aa_data;
    wire [4*`WD-1:0] pool1_input;
    wire [4*`WD-1:0] pool1_q;
    wire [4*`WD-1:0] relu1_q;

    wire [7:0] conv_fc1_aa_data;
    wire [4*`WD-1:0] conv_fc1_input;
    wire [11:0] conv_fc1_aa_weight;
    wire [4*`WD-1:0] conv_fc1_weight;
    wire [6:0] conv_fc1_aa_bias;
    wire [`WD_BIAS-1:0] conv_fc1_bias;
    wire [`WD-1:0] conv_fc1_q;



    assign conv1_go = go;
    assign pool1_go = conv1_ready;
    assign conv_fc1_go = pool1_ready;


    controller#(
        .INPUT_WIDTH  ( 32 ),
        .INPUT_HEIGHT ( 32 ),
        .KERNEL_SIZEX ( 5 ),
        .KERNEL_SIZEY ( 5 ),
        .OUTPUT_BATCH ( 1 ),
        .STEP         ( 1 ),
        .W_AA_DATA    ( 10 ),
        .W_AA_WEIGHT  ( 10 ),
        .W_AA_BIAS    ( 7 )
    )u_conv1_ctrl(
        .clk          ( clk          ),
        .rst_n        ( rst_n        ),
        .go           ( conv1_go     ),
        .first_data   ( conv1_aa_first_data   ),
        .last_data    ( conv1_aa_last_data    ),
        .aa_bias      ( conv1_aa_bias      ),
        .aa_data      ( aa_image           ),
        .aa_weight    ( conv1_aa_weight    ),
        .cena         ( cena_image         ),
        .ready        ( conv1_ready        )
    );

    bias_conv1_rom u_bias_conv1_rom(
        .clk   ( clk   ),
        .rst_n ( rst_n ),
        .aa    ( conv1_aa_bias    ),
        .cena  ( cena_image  ),
        .qa    ( conv1_bias    )
    );

    wieght_conv1_rom u_wieght_conv1_rom(
        .clk   ( clk   ),
        .rst_n ( rst_n ),
        .aa    ( conv1_aa_weight    ),
        .cena  ( cena_image  ),
        .qa    ( conv1_weight    )
    );

    conv_in1#(
        .INPUT_NUM  ( 1 ),
        .OUTPUT_NUM ( 4 ),
        .SHIFT      ( `SHIFT )
    )u_conv1(
        .clk        ( clk        ),
        .rst_n      ( rst_n      ),
        .aa_en         ( ~cena_image         ),
        .aa_first_data ( conv1_aa_first_data ),
        .aa_last_data  ( conv1_aa_last_data  ),
        .image      ( conv1_image      ),
        .bias       ( conv1_bias       ),
        .weight     ( conv1_weight     ),
        .q          ( conv1_q          ),
        .q_en       ( conv1_q_en       )
    );



    sram_ctrl#(
        .depth         ( 1024 ),
        .width         ( 4*`WD ),
        .w_addr        ( 10 )
    )u_conv1_sram_ctrl(
        .clk            ( clk           ),
        .rst_n          ( rst_n         ),
        .go             ( conv1_go      ),
        .write_en       ( conv1_q_en    ),
        .write_q        ( conv1_q       ),
        .read_aa        ( pool1_aa_data ),
        .read_cen       ( pool1_cen     ),
        .read_out       ( pool1_input   )
    );

    controller#(
        .INPUT_WIDTH  ( 28 ),
        .INPUT_HEIGHT ( 28 ),
        .KERNEL_SIZEX ( 4 ),
        .KERNEL_SIZEY ( 4 ),
        .OUTPUT_BATCH ( 1 ),
        .STEP         ( 4 ),
        .W_AA_DATA    ( 10 ),//TODO -ok
        .W_AA_WEIGHT  ( 3 ),//TODO -ok 
        .W_AA_BIAS    ( 7 )//TODO -ok
    )u_pool1_ctrl(
        .clk          ( clk          ),
        .rst_n        ( rst_n        ),
        .go           ( pool1_go     ),
        .first_data   ( pool1_aa_first_data ),
        .last_data    ( pool1_aa_last_data  ),
        .aa_bias      (),
        .aa_data      ( pool1_aa_data       ),
        .aa_weight    (),
        .cena         ( pool1_cen           ),
        .ready        ( pool1_ready         )
    );

    max_pool#(
        .INPUT_NUM  ( 4 )
    )u_max_pool1(
        .clk            ( clk        ),
        .rst_n          ( rst_n      ),
        .aa_en          ( ~pool1_cen            ),
        .aa_first_data  ( pool1_aa_first_data   ),
        .aa_last_data   ( pool1_aa_last_data    ),
        .data_i         ( pool1_input           ),
        .q_en           ( pool1_q_en           ),
        .q              ( pool1_q              )
    );

    relu#(
        .INPUT_NUM ( 4 )
    )u_relu1(
        .data_i ( pool1_q       ),
        .q      ( relu1_q       )
    );

    sram_ctrl#(
        .depth         ( 256 ),
        .width         ( 4*`WD ),
        .w_addr        ( 8 )
    )u_relu1_sram_ctrl(
        .clk            ( clk           ),
        .rst_n          ( rst_n         ),
        .go             ( pool1_go      ),
        .write_en       ( pool1_q_en    ),
        .write_q        ( relu1_q       ),
        .read_aa        ( conv_fc1_aa_data ),
        .read_cen       ( conv_fc1_cen     ),
        .read_out       ( conv_fc1_input   )
    );


	wieght_fc1_rom u_wieght_fc1_rom(
		.clk			(clk),
		.rst_n			(rst_n),
		.aa				(conv_fc1_aa_weight),
		.cena			(conv_fc1_cen),
		.qa				(conv_fc1_weight)
		);

	bias_fc1_rom u_bias_fc1_rom(
		.clk			(clk),
		.rst_n			(rst_n),
		.aa				(conv_fc1_aa_bias),
		.cena			(conv_fc1_cen),
		.qa				(conv_fc1_bias)
		);

    controller#(
        .INPUT_WIDTH  ( 7 ),
        .INPUT_HEIGHT ( 7 ),
        .KERNEL_SIZEX ( 7 ),
        .KERNEL_SIZEY ( 7 ),
        .OUTPUT_BATCH ( 10 ),
        .STEP         ( 1 ),
        .W_AA_DATA    ( 8 ),
        .W_AA_WEIGHT  ( 12 ),
        .W_AA_BIAS    ( 7 )
    )u_conv_fc1_ctrl(
        .clk          ( clk          ),
        .rst_n        ( rst_n        ),
        .go           ( conv_fc1_go     ),
        .first_data   ( conv_fc1_aa_first_data   ),
        .last_data    ( conv_fc1_aa_last_data    ),
        .aa_bias      ( conv_fc1_aa_bias      ),
        .aa_data      ( conv_fc1_aa_data           ),
        .aa_weight    ( conv_fc1_aa_weight    ),
        .cena         ( conv_fc1_cen         ),
        .ready        ( conv_fc1_ready        )
    );

    conv_in4#(
        .INPUT_NUM     ( 4 ),
        .OUTPUT_NUM    ( 1 ),
        .SHIFT         ( `SHIFT )
    )u_conv_fc1(
        .clk           ( clk           ),
        .rst_n         ( rst_n         ),
        .aa_en         ( ~conv_fc1_cen         ),
        .aa_first_data ( conv_fc1_aa_first_data ),
        .aa_last_data  ( conv_fc1_aa_last_data  ),
        .image         ( conv_fc1_input         ),
        .bias          ( conv_fc1_bias          ),
        .weight        ( conv_fc1_weight        ),
        .q             ( conv_fc1_q             ),
        .q_en          ( conv_fc1_q_en          )
    );


    digit_produce u_digit_produce(
        .clk            ( clk            ),
        .rst_n          ( rst_n          ),
        .conv_fc3_go    ( conv_fc1_go    ),
        .conv_fc3_q     ( conv_fc1_q     ),
        .conv_fc3_q_en  ( conv_fc1_q_en  ),
        .digit          ( digit          ),
        .ready          ( ready          )
    );


endmodule
