//============================================================================
// Module: jtag_if
// Description: JTAG TAP interface
//============================================================================
module jtag_if (
    input  wire        tck,
    input  wire        trst_n,
    input  wire        tms,
    input  wire        tdi,
    output reg         tdo,
    output reg         tdo_en,
    output reg  [7:0]  ir_out,
    output reg         ir_update,
    input  wire [31:0] dr_in,
    output reg  [31:0] dr_out,
    output reg         dr_update,
    output reg         dr_capture,
    output reg         dr_shift
);

    // TAP states
    localparam TEST_LOGIC_RESET = 4'd0;
    localparam RUN_TEST_IDLE    = 4'd1;
    localparam SELECT_DR_SCAN   = 4'd2;
    localparam CAPTURE_DR       = 4'd3;
    localparam SHIFT_DR         = 4'd4;
    localparam EXIT1_DR         = 4'd5;
    localparam PAUSE_DR         = 4'd6;
    localparam EXIT2_DR         = 4'd7;
    localparam UPDATE_DR        = 4'd8;
    localparam SELECT_IR_SCAN   = 4'd9;
    localparam CAPTURE_IR       = 4'd10;
    localparam SHIFT_IR         = 4'd11;
    localparam EXIT1_IR         = 4'd12;
    localparam PAUSE_IR         = 4'd13;
    localparam EXIT2_IR         = 4'd14;
    localparam UPDATE_IR        = 4'd15;
    
    reg [3:0] state;
    reg [7:0] ir_reg;
    reg [31:0] dr_reg;
    reg [4:0] bit_cnt;
    
    // TAP state machine
    always @(posedge tck or negedge trst_n) begin
        if (!trst_n) begin
            state <= TEST_LOGIC_RESET;
        end else begin
            case (state)
                TEST_LOGIC_RESET: state <= tms ? TEST_LOGIC_RESET : RUN_TEST_IDLE;
                RUN_TEST_IDLE:    state <= tms ? SELECT_DR_SCAN : RUN_TEST_IDLE;
                SELECT_DR_SCAN:   state <= tms ? SELECT_IR_SCAN : CAPTURE_DR;
                CAPTURE_DR:       state <= tms ? EXIT1_DR : SHIFT_DR;
                SHIFT_DR:         state <= tms ? EXIT1_DR : SHIFT_DR;
                EXIT1_DR:         state <= tms ? UPDATE_DR : PAUSE_DR;
                PAUSE_DR:         state <= tms ? EXIT2_DR : PAUSE_DR;
                EXIT2_DR:         state <= tms ? UPDATE_DR : SHIFT_DR;
                UPDATE_DR:        state <= tms ? SELECT_DR_SCAN : RUN_TEST_IDLE;
                SELECT_IR_SCAN:   state <= tms ? TEST_LOGIC_RESET : CAPTURE_IR;
                CAPTURE_IR:       state <= tms ? EXIT1_IR : SHIFT_IR;
                SHIFT_IR:         state <= tms ? EXIT1_IR : SHIFT_IR;
                EXIT1_IR:         state <= tms ? UPDATE_IR : PAUSE_IR;
                PAUSE_IR:         state <= tms ? EXIT2_IR : PAUSE_IR;
                EXIT2_IR:         state <= tms ? UPDATE_IR : SHIFT_IR;
                UPDATE_IR:        state <= tms ? SELECT_DR_SCAN : RUN_TEST_IDLE;
                default:          state <= TEST_LOGIC_RESET;
            endcase
        end
    end
    
    // DR operations
    always @(posedge tck or negedge trst_n) begin
        if (!trst_n) begin
            dr_reg <= 32'd0;
            dr_out <= 32'd0;
            bit_cnt <= 5'd0;
        end else begin
            case (state)
                CAPTURE_DR: begin
                    dr_reg <= dr_in;
                    bit_cnt <= 5'd0;
                end
                SHIFT_DR: begin
                    dr_reg <= {tdi, dr_reg[31:1]};
                    bit_cnt <= bit_cnt + 1'b1;
                end
                UPDATE_DR: begin
                    dr_out <= dr_reg;
                end
            endcase
        end
    end
    
    // IR operations
    always @(posedge tck or negedge trst_n) begin
        if (!trst_n) begin
            ir_reg <= 8'b00000001;  // IDCODE
        end else begin
            case (state)
                CAPTURE_IR: begin
                    ir_reg <= 8'h01;
                end
                SHIFT_IR: begin
                    ir_reg <= {tdi, ir_reg[7:1]};
                end
                UPDATE_IR: begin
                    ir_out <= ir_reg;
                end
            endcase
        end
    end
    
    // Output control
    always @(*) begin
        tdo_en = (state == SHIFT_DR) || (state == SHIFT_IR);
        if (state == SHIFT_DR)
            tdo = dr_reg[0];
        else if (state == SHIFT_IR)
            tdo = ir_reg[0];
        else
            tdo = 1'b0;
    end
    
    // Control signals
    always @(posedge tck or negedge trst_n) begin
        if (!trst_n) begin
            ir_update <= 1'b0;
            dr_update <= 1'b0;
            dr_capture <= 1'b0;
            dr_shift <= 1'b0;
        end else begin
            ir_update <= (state == UPDATE_IR);
            dr_update <= (state == UPDATE_DR);
            dr_capture <= (state == CAPTURE_DR);
            dr_shift <= (state == SHIFT_DR);
        end
    end

endmodule
