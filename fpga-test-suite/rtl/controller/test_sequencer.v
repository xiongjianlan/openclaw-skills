//============================================================================
// Module: test_sequencer
// Description: Test sequence generator and scheduler
//============================================================================
module test_sequencer (
    input  wire        clk,
    input  wire        rst_n,
    input  wire        seq_start,
    input  wire [7:0]  seq_mask,
    input  wire        continuous,
    output reg  [2:0]  current_test,
    output reg         test_start,
    input  wire        test_done,
    input  wire        test_pass,
    output reg         seq_done,
    output reg  [7:0]  seq_result
);

    localparam IDLE     = 3'd0;
    localparam INIT     = 3'd1;
    localparam RUN      = 3'd2;
    localparam WAIT     = 3'd3;
    localparam NEXT     = 3'd4;
    localparam DONE     = 3'd5;
    
    localparam TEST_LUT  = 3'd0;
    localparam TEST_FF   = 3'd1;
    localparam TEST_BRAM = 3'd2;
    localparam TEST_DSP  = 3'd3;
    localparam TEST_IO   = 3'd4;
    localparam TEST_MAX  = 3'd5;
    
    reg [2:0] state;
    reg [2:0] test_index;
    reg [7:0] result_reg;
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= IDLE;
            current_test <= 3'd0;
            test_start <= 1'b0;
            seq_done <= 1'b0;
            seq_result <= 8'd0;
            test_index <= 3'd0;
            result_reg <= 8'd0;
        end else begin
            case (state)
                IDLE: begin
                    seq_done <= 1'b0;
                    test_start <= 1'b0;
                    if (seq_start) begin
                        state <= INIT;
                        test_index <= 3'd0;
                        result_reg <= 8'd0;
                    end
                end
                
                INIT: begin
                    // Find next enabled test
                    if (test_index < TEST_MAX) begin
                        if (seq_mask[test_index]) begin
                            current_test <= test_index;
                            state <= RUN;
                        end else begin
                            test_index <= test_index + 1'b1;
                        end
                    end else begin
                        state <= DONE;
                    end
                end
                
                RUN: begin
                    test_start <= 1'b1;
                    state <= WAIT;
                end
                
                WAIT: begin
                    test_start <= 1'b0;
                    if (test_done) begin
                        result_reg[test_index] <= test_pass;
                        state <= NEXT;
                    end
                end
                
                NEXT: begin
                    test_index <= test_index + 1'b1;
                    state <= INIT;
                end
                
                DONE: begin
                    seq_result <= result_reg;
                    seq_done <= 1'b1;
                    if (continuous) begin
                        state <= INIT;
                        test_index <= 3'd0;
                    end else begin
                        state <= IDLE;
                    end
                end
                
                default: state <= IDLE;
            endcase
        end
    end

endmodule
