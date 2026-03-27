//============================================================================
// Module: delay_line
// Description: Programmable delay line for timing measurement
//============================================================================
module delay_line #(
    parameter MAX_DELAY = 32,
    parameter DELAY_WIDTH = 5
)(
    input  wire                    clk,
    input  wire                    rst_n,
    input  wire                    sig_in,
    input  wire [DELAY_WIDTH-1:0]  delay_sel,
    output wire                    sig_out,
    output reg  [DELAY_WIDTH-1:0]  measured_delay
);

    reg [MAX_DELAY-1:0] delay_chain;
    reg                 sig_in_d1;
    reg                 sig_in_d2;
    reg [DELAY_WIDTH-1:0] delay_cnt;
    reg                   measuring;
    
    // Delay chain
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            delay_chain <= {MAX_DELAY{1'b0}};
        end else begin
            delay_chain <= {delay_chain[MAX_DELAY-2:0], sig_in};
        end
    end
    
    // Multiplexer for delay selection
    assign sig_out = delay_chain[delay_sel];
    
    // Delay measurement logic
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            sig_in_d1 <= 1'b0;
            sig_in_d2 <= 1'b0;
            delay_cnt <= 0;
            measuring <= 1'b0;
            measured_delay <= 0;
        end else begin
            sig_in_d1 <= sig_in;
            sig_in_d2 <= sig_in_d1;
            
            // Detect rising edge
            if (sig_in_d1 && !sig_in_d2) begin
                measuring <= 1'b1;
                delay_cnt <= 0;
            end else if (measuring) begin
                if (delay_cnt < MAX_DELAY - 1) begin
                    delay_cnt <= delay_cnt + 1'b1;
                    // Check when signal appears in chain
                    if (delay_chain[delay_cnt] && measured_delay == 0) begin
                        measured_delay <= delay_cnt;
                    end
                end else begin
                    measuring <= 1'b0;
                end
            end
        end
    end

endmodule
