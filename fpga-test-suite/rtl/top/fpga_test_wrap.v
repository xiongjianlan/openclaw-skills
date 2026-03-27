//============================================================================
// Module: fpga_test_wrap
// Description: FPGA Test Suite Wrapper with board-specific pins
//============================================================================
module fpga_test_wrap (
    input  wire        sys_clk,
    input  wire        sys_rst_n,
    
    // USB-UART
    input  wire        uart_rx,
    output wire        uart_tx,
    
    // JTAG (if available)
    input  wire        tck,
    input  wire        tms,
    input  wire        tdi,
    output wire        tdo,
    
    // User GPIO
    inout  wire [15:0] user_gpio,
    
    // LEDs
    output reg  [7:0]  leds,
    
    // Test points
    output wire        test_active,
    output wire        test_pass,
    output wire        test_fail
);

    wire [15:0] gpio_out;
    wire [15:0] gpio_oe;
    wire [15:0] gpio_in;
    wire        test_complete;
    wire        all_pass;
    wire [7:0]  test_status;
    
    // Tri-state buffer for GPIO
    genvar i;
    generate
        for (i = 0; i < 16; i = i + 1) begin: gpio_tri
            assign user_gpio[i] = gpio_oe[i] ? gpio_out[i] : 1'bz;
            assign gpio_in[i] = user_gpio[i];
        end
    endgenerate
    
    // LED status
    always @(posedge sys_clk or negedge sys_rst_n) begin
        if (!sys_rst_n) begin
            leds <= 8'h00;
        end else begin
            leds[0] <= test_active;
            leds[1] <= test_complete;
            leds[2] <= all_pass;
            leds[7:3] <= test_status[4:0];
        end
    end
    
    // Test point outputs
    assign test_active = leds[0];
    assign test_pass = leds[2];
    assign test_fail = ~leds[2] & test_complete;
    
    // Main test module
    fpga_test_top #(
        .CLK_FREQ(100_000_000),
        .UART_BAUD(115200)
    ) test_top_inst (
        .clk(sys_clk),
        .rst_n(sys_rst_n),
        .uart_rx(uart_rx),
        .uart_tx(uart_tx),
        .tck(tck),
        .tms(tms),
        .tdi(tdi),
        .tdo(tdo),
        .gpio_in(gpio_in),
        .gpio_out(gpio_out),
        .gpio_oe(gpio_oe),
        .test_active(test_active),
        .test_complete(test_complete),
        .all_pass(all_pass),
        .test_status(test_status)
    );

endmodule
