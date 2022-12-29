`include "global.v"

module mac(
    input clk,
    input rst_n,
    input en,
    input first_data,
    input last_data,
    input [`WD-1:0] image_i,
    input [`WD-1:0] weight_i,
    output q_en,
    output [2*`WD:0] q
);

    wire [2*`WD-1:0] mul;

    reg [2*`WD:0] mac_temp;
    reg last_data_d1;

    assign mul = $signed(image_i) * $signed(weight_i);
    assign q = last_data_d1 ? mac_temp : 0;
    assign q_en = last_data_d1;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) 
            mac_temp <= 0;
        else begin
            if (!en) mac_temp <= 0;
            else begin
                if (first_data) 
                    mac_temp <= mul;
                else mac_temp <= $signed(mac_temp) + $signed(mul);
            end
        end
    end
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) last_data_d1 <= 0;
        else  last_data_d1 <= last_data;
    end

endmodule