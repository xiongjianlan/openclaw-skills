//============================================================================
// Module: cmd_decoder
// Description: Command decoder for test instructions
//============================================================================
module cmd_decoder (
    input  wire        clk,
    input  wire        rst_n,
    input  wire [7:0]  cmd_in,
    input  wire        cmd_valid,
    output reg  [2:0]  test_type,
    output reg  [4:0]  test_param,
    output reg         test_en,
    output reg         continuous_mode,
    output reg         interrupt_en
);

    // Command format: [7:5] type, [4:0] param
    // Test types
    localparam TYPE_LUT  = 3'b000;
    localparam TYPE_FF   = 3'b001;
    localparam TYPE_BRAM = 3'b010;
    localparam TYPE_DSP  = 3'b011;
    localparam TYPE_IO   = 3'b100;
    localparam TYPE_SYS  = 3'b111;
    
    // Special commands
    localparam CMD_STOP  = 8'hFF;
    localparam CMD_CONT  = 8'hFE;
    localparam CMD_INT_ON = 8'hFD;
    localparam CMD_INT_OFF = 8'hFC;
    
    reg [7:0] cmd_reg;
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            test_type <= 3'b000;
            test_param <= 5'b00000;
            test_en <= 1'b0;
            continuous_mode <= 1'b0;
            interrupt_en <= 1'b0;
            cmd_reg <= 8'd0;
        end else begin
            test_en <= 1'b0; // Default pulse
            
            if (cmd_valid) begin
                cmd_reg <= cmd_in;
                
                case (cmd_in)
                    CMD_STOP: begin
                        continuous_mode <= 1'b0;
                    end
                    CMD_CONT: begin
                        continuous_mode <= 1'b1;
                    end
                    CMD_INT_ON: begin
                        interrupt_en <= 1'b1;
                    end
                    CMD_INT_OFF: begin
                        interrupt_en <= 1'b0;
                    end
                    default: begin
                        test_type <= cmd_in[7:5];
                        test_param <= cmd_in[4:0];
                        test_en <= 1'b1;
                    end
                endcase
            end
        end
    end

endmodule
