//============================================================================
// Module: clk_gen
// Description: Clock generation and distribution
//============================================================================
module clk_gen (
    input  wire        clk_in,
    input  wire        rst_n,
    input  wire [7:0]  clk_div,
    output reg         clk_out,
    output wire        clk_locked
);

    reg [7:0] clk_cnt;
    reg       clk_div2;
    
    // Clock divider
    always @(posedge clk_in or negedge rst_n) begin
        if (!rst_n) begin
            clk_cnt <= 8'd0;
            clk_out <= 1'b0;
        end else if (clk_cnt >= clk_div) begin
            clk_cnt <= 8'd0;
            clk_out <= ~clk_out;
        end else begin
            clk_cnt <= clk_cnt + 1'b1;
        end
    end
    
    assign clk_locked = (clk_cnt == 8'd0);

endmodule
