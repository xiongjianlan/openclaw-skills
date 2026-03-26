//============================================================================
// Module: rst_sync
// Description: Asynchronous reset synchronizer
//============================================================================
module rst_sync (
    input  wire clk,
    input  wire rst_n_async,
    output reg  rst_n_sync
);

    reg rst_d1, rst_d2;
    
    always @(posedge clk or negedge rst_n_async) begin
        if (!rst_n_async) begin
            rst_d1 <= 1'b0;
            rst_d2 <= 1'b0;
            rst_n_sync <= 1'b0;
        end else begin
            rst_d1 <= 1'b1;
            rst_d2 <= rst_d1;
            rst_n_sync <= rst_d2;
        end
    end

endmodule
