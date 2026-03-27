//============================================================================
// Module: lfsr_generator
// Description: 32-bit LFSR pseudo-random sequence generator
//============================================================================
module lfsr_generator (
    input  wire        clk,
    input  wire        rst_n,
    input  wire        en,
    output reg  [31:0] data_out,
    output wire        valid
);

    // 32-bit LFSR: x^32 + x^22 + x^2 + x^1 + 1
    wire feedback;
    assign feedback = data_out[31] ^ data_out[21] ^ data_out[1] ^ data_out[0];
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_out <= 32'h1;  // Non-zero seed
        end else if (en) begin
            data_out <= {data_out[30:0], feedback};
        end
    end
    
    assign valid = en;

endmodule
