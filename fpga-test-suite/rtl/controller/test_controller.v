//============================================================================
// Module: test_controller
// Description: Main test control state machine
//============================================================================
module test_controller (
    input  wire        clk,
    input  wire        rst_n,
    input  wire [7:0]  cmd_in,
    input  wire        cmd_valid,
    output reg  [3:0]  test_state,
    output reg         test_start,
    output reg         test_done,
    output reg         error_flag,
    output reg  [2:0]  test_type
);

    // Test state definitions
    localparam STATE_IDLE   = 4'd0;
    localparam STATE_DECODE = 4'd1;
    localparam STATE_INIT   = 4'd2;
    localparam STATE_RUN    = 4'd3;
    localparam STATE_WAIT   = 4'd4;
    localparam STATE_CHECK  = 4'd5;
    localparam STATE_REPORT = 4'd6;
    localparam STATE_ERROR  = 4'd7;
    localparam STATE_DONE   = 4'd8;
    
    // Command types
    localparam CMD_LUT  = 3'b000;
    localparam CMD_FF   = 3'b001;
    localparam CMD_BRAM = 3'b010;
    localparam CMD_DSP  = 3'b011;
    localparam CMD_IO   = 3'b100;
    localparam CMD_SYS  = 3'b111;
    
    reg [7:0] cmd_reg;
    reg [3:0] next_state;
    
    // State machine - sequential logic
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            test_state <= STATE_IDLE;
        end else begin
            test_state <= next_state;
        end
    end
    
    // State machine - combinational logic
    always @(*) begin
        next_state = test_state;
        case (test_state)
            STATE_IDLE:   if (cmd_valid) next_state = STATE_DECODE;
            STATE_DECODE: next_state = STATE_INIT;
            STATE_INIT:   next_state = STATE_RUN;
            STATE_RUN:    next_state = STATE_WAIT;
            STATE_WAIT:   if (test_done) next_state = STATE_CHECK;
            STATE_CHECK:  if (error_flag) next_state = STATE_ERROR;
                         else next_state = STATE_REPORT;
            STATE_REPORT: next_state = STATE_DONE;
            STATE_ERROR:  next_state = STATE_REPORT;
            STATE_DONE:   next_state = STATE_IDLE;
            default:      next_state = STATE_IDLE;
        endcase
    end
    
    // Output logic
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            test_start <= 1'b0;
            test_done  <= 1'b0;
            error_flag <= 1'b0;
            test_type  <= 3'b000;
            cmd_reg    <= 8'd0;
        end else begin
            case (test_state)
                STATE_IDLE: begin
                    test_start <= 1'b0;
                    test_done  <= 1'b0;
                    if (cmd_valid) cmd_reg <= cmd_in;
                end
                STATE_DECODE: begin
                    test_type <= cmd_reg[7:5];
                end
                STATE_INIT: begin
                    test_start <= 1'b1;
                end
                STATE_RUN: begin
                    test_start <= 1'b0;
                end
                STATE_CHECK: begin
                    error_flag <= 1'b0; // Will be set by test modules
                end
                STATE_DONE: begin
                    test_done <= 1'b1;
                end
            endcase
        end
    end

endmodule
