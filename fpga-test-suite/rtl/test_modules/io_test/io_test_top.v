//============================================================================
// Module: io_test_top
// Description: IO test top-level wrapper
//============================================================================
module io_test_top (
    input  wire        clk,
    input  wire        rst_n,
    input  wire        test_start,
    input  wire [3:0]  io_channel,
    input  wire [7:0]  io_in,
    output reg  [7:0]  io_out,
    output reg         test_done,
    output reg         test_pass,
    output reg  [15:0] error_count
);

    localparam IDLE  = 3'd0;
    localparam DELAY = 3'd1;
    localparam WDLY  = 3'd2;
    localparam DONE  = 3'd3;
    
    reg [2:0] state;
    reg       delay_start;
    wire      delay_done;
    wire      delay_pass;
    wire [15:0] delay_errors;
    wire [7:0]  delay_val;
    
    reg [7:0] io_out_reg;
    
    // IO loopback test pattern
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            io_out_reg <= 8'h55;  // Pattern: 01010101
        end else if (state == DELAY) begin
            io_out_reg <= ~io_out_reg;
        end
    end
    
    assign io_out = io_out_reg;
    
    // Instantiate delay test for selected channel
    io_delay_test delay_inst (
        .clk(clk),
        .rst_n(rst_n),
        .test_start(delay_start),
        .io_in(io_in[io_channel[2:0]]),
        .io_out(io_out_reg[io_channel[2:0]]),
        .test_done(delay_done),
        .test_pass(delay_pass),
        .error_count(delay_errors),
        .delay_value(delay_val)
    );
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= IDLE;
            test_done <= 1'b0;
            test_pass <= 1'b0;
            error_count <= 16'd0;
            delay_start <= 1'b0;
        end else begin
            case (state)
                IDLE: begin
                    test_done <= 1'b0;
                    delay_start <= 1'b0;
                    if (test_start) begin
                        state <= DELAY;
                    end
                end
                
                DELAY: begin
                    delay_start <= 1'b1;
                    state <= WDLY;
                end
                
                WDLY: begin
                    delay_start <= 1'b0;
                    if (delay_done) begin
                        test_pass <= delay_pass;
                        error_count <= delay_errors;
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
