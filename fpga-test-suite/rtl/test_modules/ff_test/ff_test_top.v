//============================================================================
// Module: ff_test_top
// Description: Flip-flop test top-level with setup/hold test
//============================================================================
module ff_test_top (
    input  wire        clk,
    input  wire        rst_n,
    input  wire        test_start,
    output reg         test_done,
    output reg         test_pass,
    output reg  [15:0] error_count
);

    localparam IDLE    = 3'd0;
    localparam INIT    = 3'd1;
    localparam TEST    = 3'd2;
    localparam VERIFY  = 3'd3;
    localparam DONE    = 3'd4;
    
    reg [2:0]  state;
    reg [7:0]  test_count;
    reg        test_data;
    reg        ff_output;
    wire       ff_input;
    
    // DFF instance
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            ff_output <= 1'b0;
        end else begin
            ff_output <= ff_input;
        end
    end
    
    assign ff_input = test_data;
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= IDLE;
            test_done <= 1'b0;
            test_pass <= 1'b0;
            error_count <= 16'd0;
            test_count <= 8'd0;
            test_data <= 1'b0;
        end else begin
            case (state)
                IDLE: begin
                    test_done <= 1'b0;
                    if (test_start) state <= INIT;
                end
                INIT: begin
                    test_count <= 8'd0;
                    error_count <= 16'd0;
                    test_data <= 1'b0;
                    state <= TEST;
                end
                TEST: begin
                    // Toggle test pattern
                    test_data <= ~test_data;
                    
                    // Check output
                    if (test_count > 0 && ff_output !== test_data) begin
                        error_count <= error_count + 1'b1;
                    end
                    
                    if (test_count >= 8'd255) begin
                        state <= VERIFY;
                    end else begin
                        test_count <= test_count + 1'b1;
                    end
                end
                VERIFY: begin
                    test_pass <= (error_count == 16'd0);
                    state <= DONE;
                end
                DONE: begin
                    test_done <= 1'b1;
                    state <= IDLE;
                end
            endcase
        end
    end

endmodule
