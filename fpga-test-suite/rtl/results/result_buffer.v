//============================================================================
// Module: result_buffer
// Description: Test result storage buffer (FIFO)
//============================================================================
module result_buffer #(
    parameter DATA_WIDTH = 32,
    parameter DEPTH = 64,
    parameter ADDR_WIDTH = 6
)(
    input  wire                    clk,
    input  wire                    rst_n,
    input  wire [DATA_WIDTH-1:0]   data_in,
    input  wire                    wr_en,
    output wire [DATA_WIDTH-1:0]   data_out,
    input  wire                    rd_en,
    output wire                    empty,
    output wire                    full,
    output reg  [ADDR_WIDTH:0]     count
);

    reg [DATA_WIDTH-1:0] mem [0:DEPTH-1];
    reg [ADDR_WIDTH-1:0] wr_ptr;
    reg [ADDR_WIDTH-1:0] rd_ptr;
    
    assign empty = (count == 0);
    assign full = (count == DEPTH);
    
    // Write operation
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            wr_ptr <= 0;
        end else if (wr_en && !full) begin
            mem[wr_ptr] <= data_in;
            wr_ptr <= wr_ptr + 1'b1;
        end
    end
    
    // Read operation
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            rd_ptr <= 0;
        end else if (rd_en && !empty) begin
            rd_ptr <= rd_ptr + 1'b1;
        end
    end
    
    // Count update
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            count <= 0;
        end else begin
            case ({wr_en && !full, rd_en && !empty})
                2'b10: count <= count + 1'b1;
                2'b01: count <= count - 1'b1;
                default: count <= count;
            endcase
        end
    end
    
    // Output data
    assign data_out = mem[rd_ptr];

endmodule
