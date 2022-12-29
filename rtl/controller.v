module controller #(
    parameter INPUT_WIDTH = 32,
    parameter INPUT_HEIGHT = 32,
    parameter KERNEL_SIZEX = 5,
    parameter KERNEL_SIZEY = 5,
    parameter OUTPUT_BATCH = 1,     
    parameter STEP = 1,
    parameter W_AA_DATA = 8,
    parameter W_AA_WEIGHT = 8,
    parameter W_AA_BIAS = 7
    )(
    input clk,
    input rst_n,
    input go,
    output  first_data,
    output  last_data,
    output  [W_AA_BIAS-1:0] aa_bias,
    output  [W_AA_DATA-1:0] aa_data,
    output  [W_AA_WEIGHT-1:0] aa_weight,
    output  cena,
    output  ready
    );


    reg cnt_en;
    reg [3:0] ker_x;
    reg [3:0] ker_y;
    reg [4:0] col;
    reg [4:0] row;
    reg [W_AA_BIAS-1:0] batch;


    wire ker_x_max;
    wire ker_y_max;
    wire col_max;
    wire row_max;
    wire batch_max;
    wire cnt_end;


    assign ker_x_max = ker_x == KERNEL_SIZEX -1;
    assign ker_y_max = ker_y == KERNEL_SIZEY -1;
    assign col_max = col == INPUT_WIDTH - KERNEL_SIZEX;
    assign row_max = row == INPUT_HEIGHT - KERNEL_SIZEY;
    assign batch_max = batch == OUTPUT_BATCH -1;
    assign cnt_end = batch_max & row_max & col_max & ker_y_max & ker_x_max;


    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) 
            cnt_en <= 0;
        else if (go) 
            cnt_en <= 1;
        else if (cnt_end) 
            cnt_en <= 0;
    end
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            ker_x <= 4'b0;
        else if (cnt_en)
            ker_x <= ker_x_max? 0 :ker_x +1;
        else 
            ker_x <= 4'b0;
    end
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            ker_y <= 4'b0;
        else if (cnt_en) begin
            if (ker_x_max) 
                ker_y <= ker_y_max? 0 :ker_y +1;
        end
        else
            ker_y <= 4'b0;
    end
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            col <= 5'b0;
        else if (cnt_en) begin
            if (ker_y_max & ker_x_max) 
                col <= col_max? 0 :col +STEP;
        end
        else col <= 5'b0;
    end
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            row <= 5'b0;
        else if (cnt_en) begin
            if (col_max & ker_y_max & ker_x_max)
                row <= row_max? 0: row +STEP;
        end
        else row <= 5'b0;
    end
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            batch <= 0;
        else if (cnt_en) begin
            if (row_max & col_max & ker_y_max & ker_x_max)
                batch <= batch_max? 0 : batch +1;
        end
        else batch <= 0;
    end

    assign first_data = cnt_en && ker_x==0 && ker_y==0;
    assign last_data = ker_x_max && ker_y_max;
    assign aa_bias = batch;
    assign aa_data = row * INPUT_WIDTH + col + ker_y * INPUT_WIDTH + ker_x;
    assign aa_weight = batch * KERNEL_SIZEX * KERNEL_SIZEY + ker_y * KERNEL_SIZEX + ker_x;
    assign cena = !cnt_en;
    assign ready = cnt_end;


endmodule