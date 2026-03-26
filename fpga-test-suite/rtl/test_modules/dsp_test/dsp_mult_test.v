//============================================================================
// Module: dsp_mult_test
// Description: DSP multiplier functional test
//============================================================================
module dsp_mult_test #(
    parameter WIDTH_A = 18,
    parameter WIDTH_B = 25
)(
    input  wire                    clk,
    input  wire                    rst_n,
    input  wire                    test_start,
    output reg                     test_done,
    output reg                     test_pass,
    output reg  [15:0]             error_count
);

    // Test states
    localparam IDLE     = 3'd0;
    localparam INIT     = 3'd1;
    localparam TEST     = 3'd2;
    localparam VERIFY   = 3'd3;
    localparam DONE     = 3'd4;
    
    reg [2:0]  state;
    reg [WIDTH_A-1:0] op_a;
    reg [WIDTH_B-1:0] op_b;
    reg [WIDTH_A+WIDTH_B-1:0] expected_prod;
    wire [WIDTH_A+WIDTH_B-1:0] product;
    
    // Simple multiplier (behavioral model)
    assign product = op_a * op_b;
    
    // Test sequence
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= IDLE;
            test_done <= 1'b0;
            test_pass <= 1'b0;
            error_count <= 16'd0;
            op_a <= 0;
            op_b <= 0;
        end else begin
            case (state)
                IDLE: begin
                    test_done <= 1'b0;
                    if (test_start) state <= INIT;
                end
                INIT: begin
                    error_count <= 16'd0;
                    op_a <= 0;
                    op_b <= 0;
                    state <= TEST;
                end
                TEST: begin
                    // Test cases
                    case (op_a[3:0])
                        4'd0: begin op_a <= {{(WIDTH_A-1){1'b0}}, 1'b1}; op_b <= {{(WIDTH_B-1){1'b0}}, 1'b1}; end
                        4'd1: begin op_a <= {WIDTH_A{1'b1}}; op_b <= {{(WIDTH_B-1){1'b0}}, 1'b1}; end
                        4'd2: begin op_a <= {{(WIDTH_A-1){1'b0}}, 1'b1}; op_b <= {WIDTH_B{1'b1}}; end
                        4'd3: begin op_a <= {WIDTH_A{1'b1}}; op_b <= {WIDTH_B{1'b1}}; end
                        4'd4: begin op_a <= {WIDTH_A/2{2'b10}}; op_b <= {WIDTH_B/2{2'b01}}; end
                        4'd5: begin op_a <= 0; op_b <= 0; state <= VERIFY; end
                        default: begin op_a <= 0; op_b <= 0; end
                    endcase
                    
                    expected_prod <= op_a * op_b;
                    if (product !== expected_prod && op_a != 0) begin
                        error_count <= error_count + 1'b1;
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
