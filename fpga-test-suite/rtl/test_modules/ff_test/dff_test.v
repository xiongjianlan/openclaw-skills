//============================================================================
// Module: dff_test
// Description: D Flip-Flop functional test
//============================================================================
module dff_test (
    input  wire        clk,
    input  wire        rst_n,
    input  wire        test_start,
    output reg         test_done,
    output reg         test_pass,
    output reg  [15:0] error_count
);

    // Test states
    localparam IDLE     = 3'd0;
    localparam INIT     = 3'd1;
    localparam TEST_0   = 3'd2;
    localparam TEST_1   = 3'd3;
    localparam TEST_RST = 3'd4;
    localparam VERIFY   = 3'd5;
    localparam DONE     = 3'd6;
    
    reg [2:0]  state;
    reg        test_d;
    wire       test_q;
    reg        test_arst;
    
    // Instantiate DFF with async reset
    FDCE #(
        .INIT(1'b0)
    ) dff_inst (
        .Q(test_q),
        .C(clk),
        .CE(1'b1),
        .CLR(test_arst),
        .D(test_d)
    );
    
    // Test sequence
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= IDLE;
            test_done <= 1'b0;
            test_pass <= 1'b0;
            error_count <= 16'd0;
            test_d <= 1'b0;
            test_arst <= 1'b0;
        end else begin
            case (state)
                IDLE: begin
                    test_done <= 1'b0;
                    test_arst <= 1'b0;
                    if (test_start) state <= INIT;
                end
                INIT: begin
                    error_count <= 16'd0;
                    state <= TEST_0;
                end
                TEST_0: begin
                    test_d <= 1'b0;
                    if (test_q !== 1'b0) error_count <= error_count + 1'b1;
                    state <= TEST_1;
                end
                TEST_1: begin
                    test_d <= 1'b1;
                    if (test_q !== 1'b1) error_count <= error_count + 1'b1;
                    state <= TEST_RST;
                end
                TEST_RST: begin
                    test_arst <= 1'b1;
                    if (test_q !== 1'b0) error_count <= error_count + 1'b1;
                    test_arst <= 1'b0;
                    state <= VERIFY;
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
