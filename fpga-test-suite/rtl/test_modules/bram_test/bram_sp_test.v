//============================================================================
// Module: bram_sp_test
// Description: Single-port BRAM test with March C- algorithm
//============================================================================
module bram_sp_test #(
    parameter ADDR_WIDTH = 10,
    parameter DATA_WIDTH = 32,
    parameter MEM_DEPTH  = 1024
)(
    input  wire                    clk,
    input  wire                    rst_n,
    input  wire                    test_start,
    output reg                     test_done,
    output reg                     test_pass,
    output reg  [15:0]             error_count
);

    // March C- states
    localparam IDLE         = 4'd0;
    localparam M0_UP_WR0    = 4'd1;   // Write 0 ascending
    localparam M1_UP_RD0    = 4'd2;   // Read 0, write 1 ascending
    localparam M2_UP_RD1    = 4'd3;   // Read 1, write 0 ascending
    localparam M3_DN_RD0    = 4'd4;   // Read 0, write 1 descending
    localparam M4_DN_RD1    = 4'd5;   // Read 1, write 0 descending
    localparam M5_DN_RD0    = 4'd6;   // Read 0 descending
    localparam VERIFY       = 4'd7;
    localparam DONE         = 4'd8;
    
    reg [3:0]   march_state;
    reg [ADDR_WIDTH-1:0] addr;
    reg [ADDR_WIDTH-1:0] addr_cnt;
    reg [DATA_WIDTH-1:0] wdata;
    reg [DATA_WIDTH-1:0] rdata;
    reg                    we;
    reg                    check;
    reg                    up_down; // 1=up, 0=down
    
    // Simple single-port RAM
    reg [DATA_WIDTH-1:0] mem [0:MEM_DEPTH-1];
    
    // Memory interface
    always @(posedge clk) begin
        if (we) begin
            mem[addr] <= wdata;
        end
        rdata <= mem[addr];
    end
    
    // March C- algorithm implementation
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            march_state <= IDLE;
            test_done <= 1'b0;
            test_pass <= 1'b0;
            error_count <= 16'd0;
            addr <= 0;
            addr_cnt <= 0;
            we <= 1'b0;
            check <= 1'b0;
            up_down <= 1'b1;
        end else begin
            case (march_state)
                IDLE: begin
                    test_done <= 1'b0;
                    if (test_start) march_state <= M0_UP_WR0;
                end
                M0_UP_WR0: begin
                    // Write 0 to all cells (ascending)
                    we <= 1'b1;
                    wdata <= {DATA_WIDTH{1'b0}};
                    addr <= addr_cnt;
                    if (addr_cnt < MEM_DEPTH - 1) begin
                        addr_cnt <= addr_cnt + 1'b1;
                    end else begin
                        addr_cnt <= 0;
                        march_state <= M1_UP_RD0;
                    end
                end
                M1_UP_RD0: begin
                    // Read 0, write 1 (ascending)
                    we <= 1'b1;
                    wdata <= {DATA_WIDTH{1'b1}};
                    addr <= addr_cnt;
                    check <= 1'b1;
                    if (check && rdata !== {DATA_WIDTH{1'b0}}) begin
                        error_count <= error_count + 1'b1;
                    end
                    if (addr_cnt < MEM_DEPTH - 1) begin
                        addr_cnt <= addr_cnt + 1'b1;
                    end else begin
                        addr_cnt <= 0;
                        march_state <= M2_UP_RD1;
                    end
                end
                M2_UP_RD1: begin
                    // Read 1, write 0 (ascending)
                    we <= 1'b1;
                    wdata <= {DATA_WIDTH{1'b0}};
                    addr <= addr_cnt;
                    check <= 1'b1;
                    if (check && rdata !== {DATA_WIDTH{1'b1}}) begin
                        error_count <= error_count + 1'b1;
                    end
                    if (addr_cnt < MEM_DEPTH - 1) begin
                        addr_cnt <= addr_cnt + 1'b1;
                    end else begin
                        addr_cnt <= MEM_DEPTH - 1;
                        march_state <= M3_DN_RD0;
                    end
                end
                M3_DN_RD0: begin
                    // Read 0, write 1 (descending)
                    we <= 1'b1;
                    wdata <= {DATA_WIDTH{1'b1}};
                    addr <= addr_cnt;
                    check <= 1'b1;
                    if (check && rdata !== {DATA_WIDTH{1'b0}}) begin
                        error_count <= error_count + 1'b1;
                    end
                    if (addr_cnt > 0) begin
                        addr_cnt <= addr_cnt - 1'b1;
                    end else begin
                        addr_cnt <= MEM_DEPTH - 1;
                        march_state <= M4_DN_RD1;
                    end
                end
                M4_DN_RD1: begin
                    // Read 1, write 0 (descending)
                    we <= 1'b1;
                    wdata <= {DATA_WIDTH{1'b0}};
                    addr <= addr_cnt;
                    check <= 1'b1;
                    if (check && rdata !== {DATA_WIDTH{1'b1}}) begin
                        error_count <= error_count + 1'b1;
                    end
                    if (addr_cnt > 0) begin
                        addr_cnt <= addr_cnt - 1'b1;
                    end else begin
                        addr_cnt <= MEM_DEPTH - 1;
                        march_state <= M5_DN_RD0;
                    end
                end
                M5_DN_RD0: begin
                    // Read 0 (descending)
                    we <= 1'b0;
                    addr <= addr_cnt;
                    check <= 1'b1;
                    if (check && rdata !== {DATA_WIDTH{1'b0}}) begin
                        error_count <= error_count + 1'b1;
                    end
                    if (addr_cnt > 0) begin
                        addr_cnt <= addr_cnt - 1'b1;
                    end else begin
                        march_state <= VERIFY;
                    end
                end
                VERIFY: begin
                    test_pass <= (error_count == 16'd0);
                    march_state <= DONE;
                end
                DONE: begin
                    test_done <= 1'b1;
                    march_state <= IDLE;
                end
            endcase
        end
    end

endmodule
