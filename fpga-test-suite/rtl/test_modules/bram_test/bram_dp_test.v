//============================================================================
// Module: bram_dp_test
// Description: Dual-port BRAM test
//============================================================================
module bram_dp_test #(
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

    localparam IDLE      = 3'd0;
    localparam WR_PORT_A = 3'd1;
    localparam WR_PORT_B = 3'd2;
    localparam RD_VERIFY = 3'd3;
    localparam CONFLICT  = 3'd4;
    localparam DONE      = 3'd5;
    
    reg [2:0]   state;
    reg [ADDR_WIDTH-1:0] addr_a, addr_b;
    reg [DATA_WIDTH-1:0] wdata_a, wdata_b;
    reg [DATA_WIDTH-1:0] rdata_a, rdata_b;
    reg                    we_a, we_b;
    reg [15:0]  test_addr;
    
    // Dual-port RAM
    reg [DATA_WIDTH-1:0] mem [0:MEM_DEPTH-1];
    
    // Port A
    always @(posedge clk) begin
        if (we_a) begin
            mem[addr_a] <= wdata_a;
        end
        rdata_a <= mem[addr_a];
    end
    
    // Port B
    always @(posedge clk) begin
        if (we_b) begin
            mem[addr_b] <= wdata_b;
        end
        rdata_b <= mem[addr_b];
    end
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= IDLE;
            test_done <= 1'b0;
            test_pass <= 1'b0;
            error_count <= 16'd0;
            addr_a <= 0;
            addr_b <= 0;
            wdata_a <= 0;
            wdata_b <= 0;
            we_a <= 1'b0;
            we_b <= 1'b0;
            test_addr <= 16'd0;
        end else begin
            case (state)
                IDLE: begin
                    test_done <= 1'b0;
                    if (test_start) begin
                        state <= WR_PORT_A;
                        test_addr <= 16'd0;
                        error_count <= 16'd0;
                    end
                end
                
                WR_PORT_A: begin
                    // Write through port A
                    we_a <= 1'b1;
                    addr_a <= test_addr[ADDR_WIDTH-1:0];
                    wdata_a <= {DATA_WIDTH{test_addr[0]}};
                    
                    if (test_addr < MEM_DEPTH - 1) begin
                        test_addr <= test_addr + 1'b1;
                    end else begin
                        test_addr <= 16'd0;
                        state <= WR_PORT_B;
                    end
                end
                
                WR_PORT_B: begin
                    // Write complementary pattern through port B
                    we_a <= 1'b0;
                    we_b <= 1'b1;
                    addr_b <= test_addr[ADDR_WIDTH-1:0];
                    wdata_b <= {DATA_WIDTH{~test_addr[0]}};
                    
                    if (test_addr < MEM_DEPTH - 1) begin
                        test_addr <= test_addr + 1'b1;
                    end else begin
                        test_addr <= 16'd0;
                        state <= RD_VERIFY;
                    end
                end
                
                RD_VERIFY: begin
                    we_b <= 1'b0;
                    addr_a <= test_addr[ADDR_WIDTH-1:0];
                    addr_b <= test_addr[ADDR_WIDTH-1:0];
                    
                    // Check data (should be port B's write)
                    if (test_addr > 0) begin
                        if (rdata_a !== {DATA_WIDTH{~test_addr[0]}}) begin
                            error_count <= error_count + 1'b1;
                        end
                    end
                    
                    if (test_addr < MEM_DEPTH - 1) begin
                        test_addr <= test_addr + 1'b1;
                    end else begin
                        state <= DONE;
                    end
                end
                
                DONE: begin
                    test_pass <= (error_count == 16'd0);
                    test_done <= 1'b1;
                    state <= IDLE;
                end
                
                default: state <= IDLE;
            endcase
        end
    end

endmodule
