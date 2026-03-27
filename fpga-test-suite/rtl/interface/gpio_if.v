//============================================================================
// Module: gpio_if
// Description: General Purpose IO interface
//============================================================================
module gpio_if #(
    parameter NUM_PINS = 32
)(
    input  wire                    clk,
    input  wire                    rst_n,
    input  wire [NUM_PINS-1:0]     gpio_in,
    output reg  [NUM_PINS-1:0]     gpio_out,
    output reg  [NUM_PINS-1:0]     gpio_oe,
    input  wire [NUM_PINS-1:0]     gpio_out_reg,
    input  wire [NUM_PINS-1:0]     gpio_oe_reg,
    output reg  [NUM_PINS-1:0]     gpio_in_reg,
    input  wire                    update_out,
    input  wire                    update_oe,
    input  wire                    capture_in
);

    reg [NUM_PINS-1:0] gpio_in_sync1;
    reg [NUM_PINS-1:0] gpio_in_sync2;
    
    // Input synchronization
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            gpio_in_sync1 <= {NUM_PINS{1'b0}};
            gpio_in_sync2 <= {NUM_PINS{1'b0}};
        end else begin
            gpio_in_sync1 <= gpio_in;
            gpio_in_sync2 <= gpio_in_sync1;
        end
    end
    
    // Output register
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            gpio_out <= {NUM_PINS{1'b0}};
        end else if (update_out) begin
            gpio_out <= gpio_out_reg;
        end
    end
    
    // Output enable register
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            gpio_oe <= {NUM_PINS{1'b0}};
        end else if (update_oe) begin
            gpio_oe <= gpio_oe_reg;
        end
    end
    
    // Input capture
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            gpio_in_reg <= {NUM_PINS{1'b0}};
        end else if (capture_in) begin
            gpio_in_reg <= gpio_in_sync2;
        end
    end

endmodule
