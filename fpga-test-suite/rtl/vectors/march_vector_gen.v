//============================================================================
// Module: march_vector_gen
// Description: March algorithm test vector generator
//============================================================================
module march_vector_gen #(
    parameter DATA_WIDTH = 32
)(
    input  wire                    clk,
    input  wire                    rst_n,
    input  wire                    start,
    input  wire [2:0]              march_element,
    output reg  [DATA_WIDTH-1:0]   wdata,
    output reg                     we,
    output reg                     re,
    output wire [DATA_WIDTH-1:0]   expected_rdata,
    output reg                     done
);

    // March element definitions
    localparam M0_UP_WR0  = 3'd0;  // Write 0, address ascending
    localparam M1_UP_RD0  = 3'd1;  // Read 0, write 1, ascending
    localparam M2_UP_RD1  = 3'd2;  // Read 1, write 0, ascending
    localparam M3_DN_RD0  = 3'd3;  // Read 0, write 1, descending
    localparam M4_DN_RD1  = 3'd4;  // Read 1, write 0, descending
    localparam M5_DN_RD0  = 3'd5;  // Read 0, descending
    
    localparam IDLE  = 2'd0;
    localparam READ  = 2'd1;
    localparam WRITE = 2'd2;
    localparam NEXT  = 2'd3;
    
    reg [1:0] state;
    reg       up_down;  // 1=ascending, 0=descending
    reg [DATA_WIDTH-1:0] expected_data;
    
    assign expected_rdata = expected_data;
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= IDLE;
            wdata <= {DATA_WIDTH{1'b0}};
            we <= 1'b0;
            re <= 1'b0;
            done <= 1'b0;
            expected_data <= {DATA_WIDTH{1'b0}};
            up_down <= 1'b1;
        end else begin
            case (state)
                IDLE: begin
                    done <= 1'b0;
                    we <= 1'b0;
                    re <= 1'b0;
                    if (start) begin
                        case (march_element)
                            M0_UP_WR0: begin up_down <= 1'b1; state <= WRITE; wdata <= {DATA_WIDTH{1'b0}}; end
                            M1_UP_RD0: begin up_down <= 1'b1; state <= READ; expected_data <= {DATA_WIDTH{1'b0}}; end
                            M2_UP_RD1: begin up_down <= 1'b1; state <= READ; expected_data <= {DATA_WIDTH{1'b1}}; end
                            M3_DN_RD0: begin up_down <= 1'b0; state <= READ; expected_data <= {DATA_WIDTH{1'b0}}; end
                            M4_DN_RD1: begin up_down <= 1'b0; state <= READ; expected_data <= {DATA_WIDTH{1'b1}}; end
                            M5_DN_RD0: begin up_down <= 1'b0; state <= READ; expected_data <= {DATA_WIDTH{1'b0}}; end
                            default: state <= IDLE;
                        endcase
                    end
                end
                
                READ: begin
                    re <= 1'b1;
                    we <= 1'b0;
                    state <= WRITE;
                    // Determine next write data
                    case (march_element)
                        M1_UP_RD0: wdata <= {DATA_WIDTH{1'b1}};
                        M2_UP_RD1: wdata <= {DATA_WIDTH{1'b0}};
                        M3_DN_RD0: wdata <= {DATA_WIDTH{1'b1}};
                        M4_DN_RD1: wdata <= {DATA_WIDTH{1'b0}};
                        default:   wdata <= {DATA_WIDTH{1'b0}};
                    endcase
                end
                
                WRITE: begin
                    re <= 1'b0;
                    we <= 1'b1;
                    state <= NEXT;
                end
                
                NEXT: begin
                    re <= 1'b0;
                    we <= 1'b0;
                    done <= 1'b1;
                    state <= IDLE;
                end
                
                default: state <= IDLE;
            endcase
        end
    end

endmodule
