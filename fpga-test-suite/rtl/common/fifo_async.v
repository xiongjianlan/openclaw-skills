//============================================================================
// Module: fifo_async
// Description: Asynchronous FIFO
//============================================================================
module fifo_async #(
    parameter DATA_WIDTH = 32,
    parameter DEPTH = 16
)(
    input  wire                  wr_clk,
    input  wire                  rd_clk,
    input  wire                  rst_n,
    input  wire [DATA_WIDTH-1:0] din,
    input  wire                  wr_en,
    output wire                  full,
    output wire [DATA_WIDTH-1:0] dout,
    input  wire                  rd_en,
    output wire                  empty
);

    localparam ADDR_WIDTH = $clog2(DEPTH);
    
    reg [DATA_WIDTH-1:0] mem [0:DEPTH-1];
    reg [ADDR_WIDTH:0]   wr_ptr, rd_ptr;
    reg [ADDR_WIDTH:0]   wr_ptr_gray, rd_ptr_gray;
    reg [ADDR_WIDTH:0]   wr_ptr_gray_sync1, wr_ptr_gray_sync2;
    reg [ADDR_WIDTH:0]   rd_ptr_gray_sync1, rd_ptr_gray_sync2;
    
    wire [ADDR_WIDTH:0] wr_ptr_next = wr_ptr + 1'b1;
    wire [ADDR_WIDTH:0] rd_ptr_next = rd_ptr + 1'b1;
    
    // Binary to Gray conversion
    function [ADDR_WIDTH:0] bin2gray;
        input [ADDR_WIDTH:0] bin;
        bin2gray = (bin >> 1) ^ bin;
    endfunction
    
    // Write logic
    always @(posedge wr_clk or negedge rst_n) begin
        if (!rst_n) begin
            wr_ptr <= 0;
            wr_ptr_gray <= 0;
        end else if (wr_en && !full) begin
            mem[wr_ptr[ADDR_WIDTH-1:0]] <= din;
            wr_ptr <= wr_ptr_next;
            wr_ptr_gray <= bin2gray(wr_ptr_next);
        end
    end
    
    // Read logic
    always @(posedge rd_clk or negedge rst_n) begin
        if (!rst_n) begin
            rd_ptr <= 0;
            rd_ptr_gray <= 0;
        end else if (rd_en && !empty) begin
            rd_ptr <= rd_ptr_next;
            rd_ptr_gray <= bin2gray(rd_ptr_next);
        end
    end
    
    // Clock domain crossing
    always @(posedge wr_clk) begin
        rd_ptr_gray_sync1 <= rd_ptr_gray;
        rd_ptr_gray_sync2 <= rd_ptr_gray_sync1;
    end
    
    always @(posedge rd_clk) begin
        wr_ptr_gray_sync1 <= wr_ptr_gray;
        wr_ptr_gray_sync2 <= wr_ptr_gray_sync1;
    end
    
    assign full = (wr_ptr_gray == {~rd_ptr_gray_sync2[ADDR_WIDTH:ADDR_WIDTH-1], rd_ptr_gray_sync2[ADDR_WIDTH-2:0]});
    assign empty = (rd_ptr_gray == wr_ptr_gray_sync2);
    assign dout = mem[rd_ptr[ADDR_WIDTH-1:0]];

endmodule
