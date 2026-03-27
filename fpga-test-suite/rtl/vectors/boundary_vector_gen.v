//============================================================================
// Module: boundary_vector_gen
// Description: Boundary value test vector generator
//============================================================================
module boundary_vector_gen (
    input  wire        clk,
    input  wire        rst_n,
    input  wire        next,
    input  wire [4:0]  width,
    output reg  [31:0] vector,
    output reg         valid,
    output reg         done
);

    // Boundary patterns
    localparam [2:0] PAT_ALL0    = 3'd0,
                     PAT_ALL1    = 3'd1, 
                     PAT_ONE1    = 3'd2,
                     PAT_ONE0    = 3'd3,
                     PAT_ALT     = 3'd4,
                     PAT_HALF    = 3'd5;
    
    reg [2:0] state;
    reg [4:0] bit_pos;
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= PAT_ALL0;
            bit_pos <= 0;
            done <= 0;
            valid <= 0;
        end else if (next) begin
            valid <= 1;
            case (state)
                PAT_ALL0: begin 
                    vector <= 0; 
                    state <= PAT_ALL1; 
                end
                PAT_ALL1: begin 
                    vector <= {32{1'b1}}; 
                    state <= PAT_ONE1; 
                end
                PAT_ONE1: begin 
                    vector <= (1 << bit_pos);
                    if (bit_pos < width-1) bit_pos <= bit_pos + 1;
                    else begin bit_pos <= 0; state <= PAT_ONE0; end
                end
                PAT_ONE0: begin
                    vector <= ~({32{1'b1}} ^ (1 << bit_pos));
                    if (bit_pos < width-1) bit_pos <= bit_pos + 1;
                    else begin bit_pos <= 0; state <= PAT_ALT; end
                end
                PAT_ALT:  begin 
                    vector <= 32'h55555555; 
                    state <= PAT_HALF; 
                end
                PAT_HALF: begin 
                    vector <= 32'hFF00FF00; 
                    state <= PAT_ALL0; 
                    done <= 1; 
                end
                default: state <= PAT_ALL0;
            endcase
        end else begin
            done <= 0;
        end
    end

endmodule
