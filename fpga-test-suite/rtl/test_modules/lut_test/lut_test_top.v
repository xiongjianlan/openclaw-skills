//============================================================================
// Module: lut_test_top
// Description: LUT test top-level wrapper
//============================================================================
module lut_test_top (
    input  wire        clk,
    input  wire        rst_n,
    input  wire        test_start,
    input  wire [1:0]  lut_size,
    output reg         test_done,
    output reg         test_pass,
    output reg  [15:0] error_count
);

    localparam SIZE_4 = 2'b00;
    localparam SIZE_6 = 2'b01;
    
    reg         lut4_start;
    reg         lut6_start;
    wire        lut4_done;
    wire        lut6_done;
    wire        lut4_pass;
    wire        lut6_pass;
    wire [15:0] lut4_errors;
    wire [15:0] lut6_errors;
    
    reg [2:0] state;
    localparam IDLE = 3'd0;
    localparam TEST4 = 3'd1;
    localparam WAIT4 = 3'd2;
    localparam TEST6 = 3'd3;
    localparam WAIT6 = 3'd4;
    localparam DONE = 3'd5;
    
    // Instantiate LUT test modules
    lut4_test lut4_inst (
        .clk(clk),
        .rst_n(rst_n),
        .test_start(lut4_start),
        .test_done(lut4_done),
        .test_pass(lut4_pass),
        .error_count(lut4_errors)
    );
    
    lut6_test lut6_inst (
        .clk(clk),
        .rst_n(rst_n),
        .test_start(lut6_start),
        .test_done(lut6_done),
        .test_pass(lut6_pass),
        .error_count(lut6_errors)
    );
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= IDLE;
            test_done <= 1'b0;
            test_pass <= 1'b0;
            error_count <= 16'd0;
            lut4_start <= 1'b0;
            lut6_start <= 1'b0;
        end else begin
            case (state)
                IDLE: begin
                    test_done <= 1'b0;
                    lut4_start <= 1'b0;
                    lut6_start <= 1'b0;
                    if (test_start) begin
                        if (lut_size == SIZE_4 || lut_size == 2'b10) begin
                            state <= TEST4;
                        end else if (lut_size == SIZE_6) begin
                            state <= TEST6;
                        end else begin
                            state <= TEST4;
                        end
                    end
                end
                
                TEST4: begin
                    lut4_start <= 1'b1;
                    state <= WAIT4;
                end
                
                WAIT4: begin
                    lut4_start <= 1'b0;
                    if (lut4_done) begin
                        if (lut_size == 2'b10) begin
                            state <= TEST6;
                        end else begin
                            test_pass <= lut4_pass;
                            error_count <= lut4_errors;
                            state <= DONE;
                        end
                    end
                end
                
                TEST6: begin
                    lut6_start <= 1'b1;
                    state <= WAIT6;
                end
                
                WAIT6: begin
                    lut6_start <= 1'b0;
                    if (lut6_done) begin
                        test_pass <= lut6_pass;
                        error_count <= lut6_errors;
                        state <= DONE;
                    end
                end
                
                DONE: begin
                    test_done <= 1'b1;
                    state <= IDLE;
                end
                
                default: state <= IDLE;
            endcase
        end
    end

endmodule
