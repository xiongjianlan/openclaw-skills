//============================================================================
// Module: dsp_mac_test
// Description: DSP MAC (Multiply-Accumulate) test
//============================================================================
module dsp_mac_test (
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
    
    reg [2:0]   state;
    reg [7:0]   test_count;
    reg [15:0]  a_reg, b_reg;
    reg [31:0]  acc_reg;
    reg         acc_en;
    wire [31:0] mac_out;
    wire [31:0] expected_mac;
    
    // MAC operation: acc = acc + (a * b)
    assign mac_out = acc_en ? (acc_reg + (a_reg * b_reg)) : (a_reg * b_reg);
    assign expected_mac = acc_reg + (a_reg * b_reg);
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= IDLE;
            test_done <= 1'b0;
            test_pass <= 1'b0;
            error_count <= 16'd0;
            test_count <= 8'd0;
            a_reg <= 16'd0;
            b_reg <= 16'd0;
            acc_reg <= 32'd0;
            acc_en <= 1'b0;
        end else begin
            case (state)
                IDLE: begin
                    test_done <= 1'b0;
                    acc_en <= 1'b0;
                    if (test_start) state <= INIT;
                end
                INIT: begin
                    test_count <= 8'd0;
                    error_count <= 16'd0;
                    a_reg <= 16'h0001;
                    b_reg <= 16'h0001;
                    acc_reg <= 32'd0;
                    acc_en <= 1'b1;
                    state <= TEST;
                end
                TEST: begin
                    // Check MAC result
                    if (mac_out !== expected_mac) begin
                        error_count <= error_count + 1'b1;
                    end
                    
                    // Update accumulator
                    acc_reg <= mac_out;
                    
                    // Generate next test pattern
                    a_reg <= {a_reg[14:0], a_reg[15]} ^ 16'hACE1;
                    b_reg <= {b_reg[14:0], b_reg[15]} ^ 16'h1235;
                    
                    if (test_count >= 8'd127) begin
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
