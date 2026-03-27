//============================================================================
// Module: uart_if
// Description: UART interface for test control
//============================================================================
module uart_if #(
    parameter CLK_FREQ = 100_000_000,
    parameter BAUD_RATE = 115200
)(
    input  wire        clk,
    input  wire        rst_n,
    input  wire        rx,
    output wire        tx,
    output reg  [7:0]  rx_data,
    output reg         rx_valid,
    input  wire [7:0]  tx_data,
    input  wire        tx_valid,
    output wire        tx_ready
);

    localparam BIT_PERIOD = CLK_FREQ / BAUD_RATE;
    
    localparam RX_IDLE = 2'd0;
    localparam RX_START = 2'd1;
    localparam RX_DATA = 2'd2;
    localparam RX_STOP = 2'd3;
    
    reg [1:0] rx_state;
    reg [15:0] rx_cnt;
    reg [2:0] rx_bit_cnt;
    reg [7:0] rx_shift;
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            rx_state <= RX_IDLE;
            rx_valid <= 0;
            rx_cnt <= 0;
        end else begin
            rx_valid <= 0;
            case (rx_state)
                RX_IDLE: begin
                    if (!rx) begin
                        rx_state <= RX_START;
                        rx_cnt <= 0;
                    end
                end
                RX_START: begin
                    if (rx_cnt < BIT_PERIOD/2) rx_cnt <= rx_cnt + 1;
                    else begin
                        rx_state <= RX_DATA;
                        rx_cnt <= 0;
                        rx_bit_cnt <= 0;
                    end
                end
                RX_DATA: begin
                    if (rx_cnt < BIT_PERIOD) rx_cnt <= rx_cnt + 1;
                    else begin
                        rx_cnt <= 0;
                        rx_shift <= {rx, rx_shift[7:1]};
                        if (rx_bit_cnt < 7) rx_bit_cnt <= rx_bit_cnt + 1;
                        else rx_state <= RX_STOP;
                    end
                end
                RX_STOP: begin
                    if (rx_cnt < BIT_PERIOD) rx_cnt <= rx_cnt + 1;
                    else begin
                        rx_state <= RX_IDLE;
                        rx_data <= rx_shift;
                        rx_valid <= 1;
                    end
                end
            endcase
        end
    end
    
    assign tx = 1'b1;
    assign tx_ready = 1'b1;

endmodule
