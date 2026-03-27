//============================================================================
// Module: freq_meter
// Description: Frequency meter using reference clock
//============================================================================
module freq_meter #(
    parameter REF_CLK_FREQ = 100_000_000,
    parameter MEASURE_PERIOD = 100_000
)(
    input  wire        ref_clk,
    input  wire        rst_n,
    input  wire        meas_clk,
    output reg  [31:0] freq_out,
    output reg         freq_valid
);

    reg [31:0] ref_cnt;
    reg [31:0] meas_cnt;
    reg [31:0] meas_cnt_latched;
    reg        gate_open;
    
    always @(posedge ref_clk or negedge rst_n) begin
        if (!rst_n) begin
            ref_cnt <= 0;
            gate_open <= 0;
            freq_valid <= 0;
        end else if (ref_cnt < MEASURE_PERIOD) begin
            ref_cnt <= ref_cnt + 1;
            gate_open <= 1;
            freq_valid <= 0;
        end else begin
            ref_cnt <= 0;
            gate_open <= 0;
            freq_valid <= 1;
        end
    end
    
    always @(posedge meas_clk or negedge rst_n) begin
        if (!rst_n) begin
            meas_cnt <= 0;
        end else if (gate_open) begin
            meas_cnt <= meas_cnt + 1;
        end else begin
            meas_cnt_latched <= meas_cnt;
            meas_cnt <= 0;
        end
    end
    
    always @(posedge ref_clk or negedge rst_n) begin
        if (!rst_n) begin
            freq_out <= 0;
        end else if (freq_valid) begin
            freq_out <= (meas_cnt_latched * REF_CLK_FREQ) / MEASURE_PERIOD;
        end
    end

endmodule
