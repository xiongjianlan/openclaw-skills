//============================================================================
// Module: signature_analyzer
// Description: Multiple Input Signature Register (MISR) for signature analysis
//============================================================================
module signature_analyzer #(
    parameter WIDTH = 32
)(
    input  wire              clk,
    input  wire              rst_n,
    input  wire              en,
    input  wire              clear,
    input  wire [WIDTH-1:0]  data_in,
    output reg  [WIDTH-1:0]  signature,
    output reg               valid
);

    // MISR polynomial: x^32 + x^26 + x^23 + x^22 + x^16 + x^12 + x^11 + x^10 + x^8 + x^7 + x^5 + x^4 + x^2 + x + 1
    wire feedback;
    assign feedback = signature[31] ^ data_in[0];
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            signature <= {WIDTH{1'b0}};
            valid <= 1'b0;
        end else if (clear) begin
            signature <= {WIDTH{1'b0}};
            valid <= 1'b0;
        end else if (en) begin
            // LFSR with data input
            signature[0] <= feedback;
            signature[1] <= signature[0] ^ data_in[1];
            signature[2] <= signature[1] ^ signature[31] ^ data_in[2];
            signature[3] <= signature[2];
            signature[4] <= signature[3] ^ signature[31] ^ data_in[4];
            signature[5] <= signature[4] ^ signature[31] ^ data_in[5];
            signature[6] <= signature[5];
            signature[7] <= signature[6] ^ signature[31] ^ data_in[7];
            signature[8] <= signature[7] ^ signature[31] ^ data_in[8];
            signature[9] <= signature[8];
            signature[10] <= signature[9] ^ signature[31] ^ data_in[10];
            signature[11] <= signature[10] ^ signature[31] ^ data_in[11];
            signature[12] <= signature[11] ^ signature[31] ^ data_in[12];
            signature[13] <= signature[12];
            signature[14] <= signature[13];
            signature[15] <= signature[14];
            signature[16] <= signature[15] ^ signature[31] ^ data_in[16];
            signature[17] <= signature[16];
            signature[18] <= signature[17];
            signature[19] <= signature[18];
            signature[20] <= signature[19];
            signature[21] <= signature[20];
            signature[22] <= signature[21] ^ signature[31] ^ data_in[22];
            signature[23] <= signature[22] ^ signature[31] ^ data_in[23];
            signature[24] <= signature[23];
            signature[25] <= signature[24];
            signature[26] <= signature[25] ^ signature[31] ^ data_in[26];
            signature[27] <= signature[26];
            signature[28] <= signature[27];
            signature[29] <= signature[28];
            signature[30] <= signature[29];
            signature[31] <= signature[30];
            valid <= 1'b1;
        end
    end

endmodule
