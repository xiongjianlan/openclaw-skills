//============================================================================
// Module: dsp_test_top
// Description: DSP test top-level wrapper
//============================================================================
module dsp_test_top (
    input  wire        clk,
    input  wire        rst_n,
    input  wire        test_start,
    input  wire [1:0]  dsp_test_sel,
    output reg         test_done,
    output reg         test_pass,
    output reg  [15:0] error_count
);

    localparam SEL_MULT = 2'b00;
    localparam SEL_MAC  = 2'b01;
    localparam SEL_ALL  = 2'b10;
    
    reg         mult_start;
    reg         mac_start;
    wire        mult_done;
    wire        mac_done;
    wire        mult_pass;
    wire        mac_pass;
    wire [15:0] mult_errors;
    wire [15:0] mac_errors;
    
    reg [2:0] state;
    localparam IDLE  = 3'd0;
    localparam MULT  = 3'd1;
    localparam WMULT = 3'd2;
    localparam MAC   = 3'd3;
    localparam WMAC  = 3'd4;
    localparam DONE  = 3'd5;
    
    // Instantiate DSP test modules
    dsp_mult_test mult_inst (
        .clk(clk),
        .rst_n(rst_n),
        .test_start(mult_start),
        .test_done(mult_done),
        .test_pass(mult_pass),
        .error_count(mult_errors)
    );
    
    dsp_mac_test mac_inst (
        .clk(clk),
        .rst_n(rst_n),
        .test_start(mac_start),
        .test_done(mac_done),
        .test_pass(mac_pass),
        .error_count(mac_errors)
    );
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= IDLE;
            test_done <= 1'b0;
            test_pass <= 1'b0;
            error_count <= 16'd0;
            mult_start <= 1'b0;
            mac_start <= 1'b0;
        end else begin
            case (state)
                IDLE: begin
                    test_done <= 1'b0;
                    mult_start <= 1'b0;
                    mac_start <= 1'b0;
                    if (test_start) begin
                        case (dsp_test_sel)
                            SEL_MULT: state <= MULT;
                            SEL_MAC:  state <= MAC;
                            default:  state <= MULT;
                        endcase
                    end
                end
                
                MULT: begin
                    mult_start <= 1'b1;
                    state <= WMULT;
                end
                
                WMULT: begin
                    mult_start <= 1'b0;
                    if (mult_done) begin
                        if (dsp_test_sel == SEL_ALL) begin
                            state <= MAC;
                        end else begin
                            test_pass <= mult_pass;
                            error_count <= mult_errors;
                            state <= DONE;
                        end
                    end
                end
                
                MAC: begin
                    mac_start <= 1'b1;
                    state <= WMAC;
                end
                
                WMAC: begin
                    mac_start <= 1'b0;
                    if (mac_done) begin
                        test_pass <= mac_pass;
                        error_count <= mac_errors;
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
