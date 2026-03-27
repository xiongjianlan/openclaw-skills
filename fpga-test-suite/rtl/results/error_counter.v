//============================================================================
// Module: error_counter
// Description: Error counting and classification
//============================================================================
module error_counter #(
    parameter NUM_CATEGORIES = 8,
    parameter CNT_WIDTH = 16
)(
    input  wire                    clk,
    input  wire                    rst_n,
    input  wire [NUM_CATEGORIES-1:0] error_in,
    input  wire                    clear,
    output reg  [CNT_WIDTH-1:0] total_errors,
    output reg  [CNT_WIDTH-1:0] error_cat_0,
    output reg  [CNT_WIDTH-1:0] error_cat_1,
    output reg  [CNT_WIDTH-1:0] error_cat_2,
    output reg  [CNT_WIDTH-1:0] error_cat_3,
    output reg  [CNT_WIDTH-1:0] error_cat_4,
    output reg  [CNT_WIDTH-1:0] error_cat_5,
    output reg  [CNT_WIDTH-1:0] error_cat_6,
    output reg  [CNT_WIDTH-1:0] error_cat_7
);

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            total_errors <= 0;
            error_cat_0 <= 0; error_cat_1 <= 0; error_cat_2 <= 0; error_cat_3 <= 0;
            error_cat_4 <= 0; error_cat_5 <= 0; error_cat_6 <= 0; error_cat_7 <= 0;
        end else if (clear) begin
            total_errors <= 0;
            error_cat_0 <= 0; error_cat_1 <= 0; error_cat_2 <= 0; error_cat_3 <= 0;
            error_cat_4 <= 0; error_cat_5 <= 0; error_cat_6 <= 0; error_cat_7 <= 0;
        end else begin
            if (error_in[0]) begin error_cat_0 <= error_cat_0 + 1'b1; total_errors <= total_errors + 1'b1; end
            if (error_in[1]) begin error_cat_1 <= error_cat_1 + 1'b1; total_errors <= total_errors + 1'b1; end
            if (error_in[2]) begin error_cat_2 <= error_cat_2 + 1'b1; total_errors <= total_errors + 1'b1; end
            if (error_in[3]) begin error_cat_3 <= error_cat_3 + 1'b1; total_errors <= total_errors + 1'b1; end
            if (error_in[4]) begin error_cat_4 <= error_cat_4 + 1'b1; total_errors <= total_errors + 1'b1; end
            if (error_in[5]) begin error_cat_5 <= error_cat_5 + 1'b1; total_errors <= total_errors + 1'b1; end
            if (error_in[6]) begin error_cat_6 <= error_cat_6 + 1'b1; total_errors <= total_errors + 1'b1; end
            if (error_in[7]) begin error_cat_7 <= error_cat_7 + 1'b1; total_errors <= total_errors + 1'b1; end
        end
    end

endmodule
