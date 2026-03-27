//============================================================================
// Module: bram_test_top
// Description: BRAM test top-level wrapper
//============================================================================
module bram_test_top (
    input  wire        clk,
    input  wire        rst_n,
    input  wire        test_start,
    input  wire [1:0]  bram_test_sel,
    output reg         test_done,
    output reg         test_pass,
    output reg  [15:0] error_count
);

    localparam SEL_SP  = 2'b00;  // Single port
    localparam SEL_DP  = 2'b01;  // Dual port
    localparam SEL_ALL = 2'b10;  // Both
    
    reg         sp_start;
    reg         dp_start;
    wire        sp_done;
    wire        dp_done;
    wire        sp_pass;
    wire        dp_pass;
    wire [15:0] sp_errors;
    wire [15:0] dp_errors;
    
    reg [2:0] state;
    localparam IDLE = 3'd0;
    localparam SP   = 3'd1;
    localparam WSP  = 3'd2;
    localparam DP   = 3'd3;
    localparam WDP  = 3'd4;
    localparam DONE = 3'd5;
    
    // Instantiate BRAM test modules
    bram_sp_test #(
        .ADDR_WIDTH(10),
        .DATA_WIDTH(32),
        .MEM_DEPTH(1024)
    ) sp_inst (
        .clk(clk),
        .rst_n(rst_n),
        .test_start(sp_start),
        .test_done(sp_done),
        .test_pass(sp_pass),
        .error_count(sp_errors)
    );
    
    bram_dp_test #(
        .ADDR_WIDTH(10),
        .DATA_WIDTH(32),
        .MEM_DEPTH(1024)
    ) dp_inst (
        .clk(clk),
        .rst_n(rst_n),
        .test_start(dp_start),
        .test_done(dp_done),
        .test_pass(dp_pass),
        .error_count(dp_errors)
    );
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= IDLE;
            test_done <= 1'b0;
            test_pass <= 1'b0;
            error_count <= 16'd0;
            sp_start <= 1'b0;
            dp_start <= 1'b0;
        end else begin
            case (state)
                IDLE: begin
                    test_done <= 1'b0;
                    sp_start <= 1'b0;
                    dp_start <= 1'b0;
                    if (test_start) begin
                        case (bram_test_sel)
                            SEL_SP:  state <= SP;
                            SEL_DP:  state <= DP;
                            default: state <= SP;
                        endcase
                    end
                end
                
                SP: begin
                    sp_start <= 1'b1;
                    state <= WSP;
                end
                
                WSP: begin
                    sp_start <= 1'b0;
                    if (sp_done) begin
                        if (bram_test_sel == SEL_ALL) begin
                            state <= DP;
                        end else begin
                            test_pass <= sp_pass;
                            error_count <= sp_errors;
                            state <= DONE;
                        end
                    end
                end
                
                DP: begin
                    dp_start <= 1'b1;
                    state <= WDP;
                end
                
                WDP: begin
                    dp_start <= 1'b0;
                    if (dp_done) begin
                        test_pass <= dp_pass;
                        error_count <= dp_errors;
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
