//============================================================================
// Module: lut4_test
// Description: 4-input LUT functional test
//============================================================================
module lut4_test (
    input  wire        clk,
    input  wire        rst_n,
    input  wire        test_start,
    output reg         test_done,
    output reg         test_pass,
    output reg  [15:0] error_count
);

    // Test state machine
    localparam IDLE    = 3'd0;
    localparam INIT    = 3'd1;
    localparam TEST    = 3'd2;
    localparam VERIFY  = 3'd3;
    localparam DONE    = 3'd4;
    
    reg [2:0]  state;
    reg [3:0]  test_pattern;
    reg [15:0] lut_config;
    reg        expected_out;
    wire       lut_out;
    
    // Instantiate LUT4 (using primitive)
    LUT4 #(
        .INIT(16'h0000)
    ) lut_inst (
        .O(lut_out),
        .I0(test_pattern[0]),
        .I1(test_pattern[1]),
        .I2(test_pattern[2]),
        .I3(test_pattern[3])
    );
    
    // State machine
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= IDLE;
            test_done <= 1'b0;
            test_pass <= 1'b0;
            error_count <= 16'd0;
            test_pattern <= 4'd0;
        end else begin
            case (state)
                IDLE: begin
                    test_done <= 1'b0;
                    if (test_start) state <= INIT;
                end
                INIT: begin
                    test_pattern <= 4'd0;
                    error_count <= 16'd0;
                    state <= TEST;
                end
                TEST: begin
                    // Generate expected output for AND function
                    expected_out = &test_pattern;
                    if (lut_out !== expected_out) begin
                        error_count <= error_count + 1'b1;
                    end
                    if (test_pattern == 4'b1111) begin
                        state <= VERIFY;
                    end else begin
                        test_pattern <= test_pattern + 1'b1;
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
