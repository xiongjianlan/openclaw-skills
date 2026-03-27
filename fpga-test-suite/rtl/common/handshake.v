//============================================================================
// Module: handshake
// Description: Asynchronous handshake interface for clock domain crossing
//============================================================================
module handshake (
    input  wire        clk_src,
    input  wire        clk_dst,
    input  wire        rst_n,
    input  wire        req_src,
    output reg         ack_src,
    output reg         req_dst,
    input  wire        ack_dst,
    input  wire [31:0] data_src,
    output reg  [31:0] data_dst
);

    reg         req_src_ff1, req_src_ff2;
    reg         ack_dst_ff1, ack_dst_ff2;
    reg [31:0]  data_src_reg;
    reg         req_pulse;
    
    // Source domain: register data and generate request pulse
    always @(posedge clk_src or negedge rst_n) begin
        if (!rst_n) begin
            data_src_reg <= 32'd0;
            req_pulse <= 1'b0;
        end else if (req_src && !req_pulse) begin
            data_src_reg <= data_src;
            req_pulse <= 1'b1;
        end else if (ack_src) begin
            req_pulse <= 1'b0;
        end
    end
    
    // Synchronize request to destination domain
    always @(posedge clk_dst or negedge rst_n) begin
        if (!rst_n) begin
            req_src_ff1 <= 1'b0;
            req_src_ff2 <= 1'b0;
        end else begin
            req_src_ff1 <= req_pulse;
            req_src_ff2 <= req_src_ff1;
        end
    end
    
    // Destination domain: generate request output
    always @(posedge clk_dst or negedge rst_n) begin
        if (!rst_n) begin
            req_dst <= 1'b0;
            data_dst <= 32'd0;
        end else begin
            req_dst <= req_src_ff2;
            if (req_src_ff2 && !req_dst) begin
                data_dst <= data_src_reg;
            end
        end
    end
    
    // Synchronize acknowledge back to source domain
    always @(posedge clk_src or negedge rst_n) begin
        if (!rst_n) begin
            ack_dst_ff1 <= 1'b0;
            ack_dst_ff2 <= 1'b0;
            ack_src <= 1'b0;
        end else begin
            ack_dst_ff1 <= ack_dst;
            ack_dst_ff2 <= ack_dst_ff1;
            ack_src <= ack_dst_ff2;
        end
    end

endmodule
