module sram_ctrl #(
    parameter depth = 1024,
    parameter width = 96,
    parameter w_addr = 10
    )(
    input clk,
    input rst_n,
    input go,
    input write_en,
    input [width-1:0] write_q,
    input [w_addr-1:0] read_aa,
    input read_cen,
    output [width-1:0] read_out
    );

    reg [w_addr-1:0] write_aa;    

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)     write_aa <= 0;
        else begin 
            if (go)     write_aa <= 0;
            else if (write_en)	
                write_aa <= write_aa + 1;
        end
    end

    bhv_sram#(
        .WWORD ( width ),
        .WADDR ( w_addr ),
        .DEPTH ( depth )
    )conv1_sram(
        .clk   ( clk   ),
        .qa    ( read_out    ),
        .aa    ( read_aa    ),
        .cena  ( read_cen  ),
        .db    ( write_q    ),
        .ab    ( write_aa    ),
        .cenb  ( ~write_en  )
    );

endmodule