//============================================================================
// Module: power_probe
// Description: Power monitoring probe (simulation model)
//============================================================================
module power_probe (
    input  wire        clk,
    input  wire        rst_n,
    input  wire        enable,
    input  wire [7:0]  activity_level,
    output reg  [15:0] power_estimate,
    output reg         power_valid
);

    reg [15:0] base_power;
    reg [15:0] dynamic_power;
    reg [7:0]  sample_cnt;
    
    localparam SAMPLE_PERIOD = 100;
    
    // Base power consumption (static)
    localparam STATIC_POWER = 16'd50;  // 50 mW
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            base_power <= STATIC_POWER;
            dynamic_power <= 16'd0;
            power_estimate <= 16'd0;
            power_valid <= 1'b0;
            sample_cnt <= 8'd0;
        end else begin
            power_valid <= 1'b0;
            
            if (enable) begin
                // Calculate dynamic power based on activity
                dynamic_power <= activity_level * 8'd10;
                
                if (sample_cnt < SAMPLE_PERIOD) begin
                    sample_cnt <= sample_cnt + 1'b1;
                end else begin
                    sample_cnt <= 8'd0;
                    // Total power = static + dynamic
                    power_estimate <= base_power + dynamic_power;
                    power_valid <= 1'b1;
                end
            end else begin
                power_estimate <= 16'd0;
            end
        end
    end

endmodule
