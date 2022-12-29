`include "global.v"

module digit_produce(
    input clk,
    input rst_n,
    input conv_fc3_go,
    input [`WD-1:0] conv_fc3_q,
    input conv_fc3_q_en,
    output [3:0] digit,
    output ready
);

    reg [`WD-1:0] max_temp;//1_13
    reg [3:0] digit_temp;
    reg [3:0] temp_idx;
    reg ready_temp;

    wire temp_gt_max;

    assign ready = ready_temp;    
    assign temp_gt_max = $signed(conv_fc3_q) > $signed(max_temp);
    assign digit = digit_temp;


    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) 
            max_temp <= 0;
        else begin
            if (conv_fc3_go)
                max_temp <= 1 << (`WD-1);
            else begin if (conv_fc3_q_en)
                if (temp_gt_max)
                    max_temp <= conv_fc3_q;
            end
        end
    end

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) 
            temp_idx <= 0;
        else if (conv_fc3_go) 
            temp_idx <= 0;
        else if (conv_fc3_q_en)
            temp_idx <= temp_idx + 1;
    end

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) digit_temp <= 0;
        else if (conv_fc3_go) digit_temp <=0;
        else if (conv_fc3_q_en && temp_gt_max) digit_temp <= temp_idx;
    end

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) ready_temp <= 0;
        else if (conv_fc3_q_en && temp_idx==9) 
            ready_temp <= 1;
        else ready_temp <= 0;
    end

endmodule