`include "global.v"

module relu #(
    parameter INPUT_NUM = 6
    )(
    input [`WD*INPUT_NUM-1:0] data_i,
    output [`WD*INPUT_NUM-1:0] q
    );

	wire [0:INPUT_NUM-1][`WD-1:0] d_in;
    wire [0:INPUT_NUM-1][`WD-1:0] temp;
    assign d_in = data_i;
    assign q = temp;

    genvar i;
    generate 
        for (i=0; i<INPUT_NUM; i=i+1) begin : relu_out
            assign temp[i] = (d_in[i][`WD-1]) ? 0 : d_in[i];
        end
    endgenerate

endmodule