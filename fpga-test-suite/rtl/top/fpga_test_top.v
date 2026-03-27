//============================================================================
// Module: fpga_test_top
// Description: FPGA Test Suite Top Level Module
//============================================================================
module fpga_test_top #(
    parameter CLK_FREQ = 100_000_000,
    parameter UART_BAUD = 115200
)(
    input  wire        clk,
    input  wire        rst_n,
    
    // UART Interface
    input  wire        uart_rx,
    output wire        uart_tx,
    
    // JTAG Interface
    input  wire        tck,
    input  wire        tms,
    input  wire        tdi,
    output wire        tdo,
    
    // GPIO
    input  wire [15:0] gpio_in,
    output wire [15:0] gpio_out,
    output wire [15:0] gpio_oe,
    
    // Status
    output reg         test_active,
    output reg         test_complete,
    output reg         all_pass,
    output reg  [7:0]  test_status
);

    // Internal signals
    wire [7:0]  uart_rx_data;
    wire        uart_rx_valid;
    reg  [7:0]  uart_tx_data;
    reg         uart_tx_valid;
    wire        uart_tx_ready;
    
    wire [2:0]  test_type;
    wire [4:0]  test_param;
    wire        test_en;
    wire        continuous_mode;
    
    reg  [2:0]  current_test;
    reg         seq_start;
    wire        seq_done;
    wire [7:0]  seq_result;
    
    wire        lut_done, lut_pass;
    wire [15:0] lut_errors;
    wire        ff_done, ff_pass;
    wire [15:0] ff_errors;
    wire        bram_done, bram_pass;
    wire [15:0] bram_errors;
    wire        dsp_done, dsp_pass;
    wire [15:0] dsp_errors;
    wire        io_done, io_pass;
    wire [15:0] io_errors;
    
    // Controller
    test_controller ctrl_inst (
        .clk(clk),
        .rst_n(rst_n),
        .cmd_in(uart_rx_data),
        .cmd_valid(uart_rx_valid),
        .test_state(test_status[3:0]),
        .test_start(seq_start),
        .test_done(seq_done),
        .error_flag(~all_pass),
        .test_type(current_test)
    );
    
    // Command decoder
    cmd_decoder cmd_dec_inst (
        .clk(clk),
        .rst_n(rst_n),
        .cmd_in(uart_rx_data),
        .cmd_valid(uart_rx_valid),
        .test_type(test_type),
        .test_param(test_param),
        .test_en(test_en),
        .continuous_mode(continuous_mode),
        .interrupt_en()
    );
    
    // Test sequencer
    test_sequencer seq_inst (
        .clk(clk),
        .rst_n(rst_n),
        .seq_start(seq_start),
        .seq_mask(8'h1F),
        .continuous(continuous_mode),
        .current_test(current_test),
        .test_start(),
        .test_done(seq_done),
        .test_pass(all_pass),
        .seq_done(test_complete),
        .seq_result(seq_result)
    );
    
    // UART interface
    uart_if #(
        .CLK_FREQ(CLK_FREQ),
        .BAUD_RATE(UART_BAUD)
    ) uart_inst (
        .clk(clk),
        .rst_n(rst_n),
        .rx(uart_rx),
        .tx(uart_tx),
        .rx_data(uart_rx_data),
        .rx_valid(uart_rx_valid),
        .tx_data(uart_tx_data),
        .tx_valid(uart_tx_valid),
        .tx_ready(uart_tx_ready)
    );
    
    // LUT test
    lut_test_top lut_inst (
        .clk(clk),
        .rst_n(rst_n),
        .test_start(current_test == 3'd0),
        .lut_size(test_param[1:0]),
        .test_done(lut_done),
        .test_pass(lut_pass),
        .error_count(lut_errors)
    );
    
    // FF test
    ff_test_top ff_inst (
        .clk(clk),
        .rst_n(rst_n),
        .test_start(current_test == 3'd1),
        .test_done(ff_done),
        .test_pass(ff_pass),
        .error_count(ff_errors)
    );
    
    // BRAM test
    bram_test_top bram_inst (
        .clk(clk),
        .rst_n(rst_n),
        .test_start(current_test == 3'd2),
        .bram_test_sel(test_param[1:0]),
        .test_done(bram_done),
        .test_pass(bram_pass),
        .error_count(bram_errors)
    );
    
    // DSP test
    dsp_test_top dsp_inst (
        .clk(clk),
        .rst_n(rst_n),
        .test_start(current_test == 3'd3),
        .dsp_test_sel(test_param[1:0]),
        .test_done(dsp_done),
        .test_pass(dsp_pass),
        .error_count(dsp_errors)
    );
    
    // IO test
    io_test_top io_inst (
        .clk(clk),
        .rst_n(rst_n),
        .test_start(current_test == 3'd4),
        .io_channel(test_param[3:0]),
        .io_in(gpio_in[7:0]),
        .io_out(gpio_out[7:0]),
        .test_done(io_done),
        .test_pass(io_pass),
        .error_count(io_errors)
    );
    
    // Status aggregation
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            test_active <= 1'b0;
            all_pass <= 1'b1;
        end else begin
            test_active <= seq_start || !seq_done;
            all_pass <= lut_pass && ff_pass && bram_pass && dsp_pass && io_pass;
        end
    end
    
    assign gpio_oe = 16'h00FF;

endmodule
