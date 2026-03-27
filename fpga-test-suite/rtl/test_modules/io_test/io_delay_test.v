//============================================================================
// Module: io_delay_test
// Description: IO delay and timing test
//============================================================================
module io_delay_test (
    input  wire        clk,
    input  wire        rst_n,
    input  wire        test_start,
    input  wire        io_in,
    output reg         io_out,
    output reg         test_done,
    output reg         test_pass,
    output reg  [15:0] error_count,
    output reg  [7:0]  delay_value
);

    localparam IDLE    = 3'd0;
    localparam INIT    = 3'd1;
    localparam TEST    = 3'd2;
    localparam VERIFY  = 3'd3;
    localparam DONE    = 3'd4;
    
    reg [2:0]  state;
    reg [7:0]  test_count;
    reg        io_in_d1, io_in_d2;
    reg [15:0] transition_count;
    reg [15:0] glitch_count;
    
    // Input synchronization
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            io_in_d1 <= 1'b0;
            io_in_d2 <= 1'b0;
        end else begin
            io_in_d1 <= io_in;
            io_in_d2 <= io_in_d1;
        end
    end
    
    // Output toggle for delay measurement
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            io_out <= 1'b0;
        end else if (state == TEST) begin
            io_out <= ~io_out;
        end
    end
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= IDLE;
            test_done <= 1'b0;
            test_pass <= 1'b0;
            error_count <= 16'd0;
            test_count <= 8'd0;
            transition_count <= 16'd0;
            glitch_count <= 16'd0;
            delay_value <= 8'd0;
        end else begin
            case (state)
                IDLE: begin
                    test_done <= 1'b0;
                    if (test_start) state <= INIT;
                end
                INIT: begin
                    test_count <= 8'd0;
                    error_count <= 16'd0;
                    transition_count <= 16'd0;
                    glitch_count <= 16'd0;
                    state <= TEST;
                end
                TEST: begin
                    // Count transitions
                    if (io_in_d1 != io_in_d2) begin
                        transition_count <= transition_count + 1'b1;
                    end
                    
                    // Detect glitches (unexpected transitions)
                    if (test_count > 8'd2 && io_in_d1 != io_out) begin
                        glitch_count <= glitch_count + 1'b1;
                    end
                    
                    // Estimate delay based on toggle frequency
                    if (test_count == 8'd100) begin
                        delay_value <= transition_count[7:0];
                    end
                    
                    if (test_count >= 8'd255) begin
                        state <= VERIFY;
                    end else begin
                        test_count <= test_count + 1'b1;
                    end
                end
                VERIFY: begin
                    // Pass if transitions detected and no glitches
                    test_pass <= (transition_count > 16'd10) && (glitch_count < 16'd5);
                    error_count <= glitch_count;
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
