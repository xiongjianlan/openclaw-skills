//============================================================================
// Module: bist_controller
// Description: Built-In Self-Test Controller
//============================================================================
module bist_controller #(
    parameter NUM_TESTS = 8
)(
    input  wire                    clk,
    input  wire                    rst_n,
    input  wire                    bist_start,
    input  wire                    bist_mode,
    output reg                     bist_done,
    output reg                     bist_pass,
    output reg  [NUM_TESTS-1:0]    test_results,
    output reg  [15:0]             total_errors,
    
    // Test control outputs
    output reg  [2:0]              test_select,
    output reg                     test_start,
    input  wire                    test_done,
    input  wire                    test_pass,
    input  wire [15:0]             test_error_count
);

    localparam IDLE    = 3'd0;
    localparam INIT    = 3'd1;
    localparam RUN     = 3'd2;
    localparam WAIT    = 3'd3;
    localparam NEXT    = 3'd4;
    localparam VERIFY  = 3'd5;
    localparam DONE    = 3'd6;
    
    reg [2:0] state;
    reg [2:0] test_index;
    reg [15:0] error_accum;
    
    // Test sequence: LUT, FF, BRAM, DSP, IO
    localparam TEST_LUT  = 3'd0;
    localparam TEST_FF   = 3'd1;
    localparam TEST_BRAM = 3'd2;
    localparam TEST_DSP  = 3'd3;
    localparam TEST_IO   = 3'd4;
    localparam TEST_MAX  = 3'd5;
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= IDLE;
            bist_done <= 1'b0;
            bist_pass <= 1'b0;
            test_results <= {NUM_TESTS{1'b0}};
            total_errors <= 16'd0;
            test_select <= 3'd0;
            test_start <= 1'b0;
            test_index <= 3'd0;
            error_accum <= 16'd0;
        end else begin
            case (state)
                IDLE: begin
                    bist_done <= 1'b0;
                    test_start <= 1'b0;
                    if (bist_start) begin
                        state <= INIT;
                        test_index <= 3'd0;
                        error_accum <= 16'd0;
                        test_results <= {NUM_TESTS{1'b0}};
                    end
                end
                
                INIT: begin
                    if (test_index < TEST_MAX) begin
                        test_select <= test_index;
                        state <= RUN;
                    end else begin
                        state <= VERIFY;
                    end
                end
                
                RUN: begin
                    test_start <= 1'b1;
                    state <= WAIT;
                end
                
                WAIT: begin
                    test_start <= 1'b0;
                    if (test_done) begin
                        test_results[test_index] <= test_pass;
                        error_accum <= error_accum + test_error_count;
                        state <= NEXT;
                    end
                end
                
                NEXT: begin
                    test_index <= test_index + 1'b1;
                    state <= INIT;
                end
                
                VERIFY: begin
                    total_errors <= error_accum;
                    bist_pass <= (&test_results[TEST_MAX-1:0]) && (error_accum == 16'd0);
                    state <= DONE;
                end
                
                DONE: begin
                    bist_done <= 1'b1;
                    state <= IDLE;
                end
                
                default: state <= IDLE;
            endcase
        end
    end

endmodule
