//============================================================================
// Module: misr_checker
// Description: MISR signature checker for BIST
//============================================================================
module misr_checker #(
    parameter DATA_WIDTH = 32,
    parameter EXPECTED_SIG = 32'hA5A5A5A5
)(
    input  wire                    clk,
    input  wire                    rst_n,
    input  wire                    start,
    input  wire                    data_valid,
    input  wire [DATA_WIDTH-1:0]   data_in,
    output reg                     check_done,
    output reg                     check_pass,
    output reg  [DATA_WIDTH-1:0]   actual_signature
);

    localparam IDLE  = 2'd0;
    localparam RUN   = 2'd1;
    localparam CHECK = 2'd2;
    localparam DONE  = 2'd3;
    
    reg [1:0] state;
    reg [15:0] sample_cnt;
    reg [15:0] max_samples;
    
    wire [DATA_WIDTH-1:0] misr_out;
    wire misr_valid;
    
    // MISR instance
    signature_analyzer #(
        .WIDTH(DATA_WIDTH)
    ) misr_inst (
        .clk(clk),
        .rst_n(rst_n),
        .en(data_valid),
        .clear(start),
        .data_in(data_in),
        .signature(misr_out),
        .valid(misr_valid)
    );
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= IDLE;
            check_done <= 1'b0;
            check_pass <= 1'b0;
            actual_signature <= {DATA_WIDTH{1'b0}};
            sample_cnt <= 16'd0;
            max_samples <= 16'd1000;
        end else begin
            case (state)
                IDLE: begin
                    check_done <= 1'b0;
                    if (start) begin
                        state <= RUN;
                        sample_cnt <= 16'd0;
                    end
                end
                
                RUN: begin
                    if (data_valid) begin
                        sample_cnt <= sample_cnt + 1'b1;
                    end
                    if (sample_cnt >= max_samples) begin
                        state <= CHECK;
                    end
                end
                
                CHECK: begin
                    actual_signature <= misr_out;
                    check_pass <= (misr_out == EXPECTED_SIG);
                    state <= DONE;
                end
                
                DONE: begin
                    check_done <= 1'b1;
                    state <= IDLE;
                end
                
                default: state <= IDLE;
            endcase
        end
    end

endmodule
