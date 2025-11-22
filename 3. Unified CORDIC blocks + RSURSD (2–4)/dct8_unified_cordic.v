// ============================================================================
// dct8_unified_cordic
//  - Final 8-point stage: "unified CORDIC-like" block
//  - Block-based: collects 8 inputs, then outputs 8 rotated values.
//  - Uses three fixed-angle 2D rotations (matrix multiply with cos/sin):
//        angle1 = -pi/16
//        angle2 =  pi/8
//        angle3 = 3pi/16
//
//  Mapping (you can tweak later to match the paper’s SFG exactly):
//    in[0] -> out[0]  (bypass; DC-like)
//    in[4] -> out[4]  (bypass; k=4-like)
//    (in[1], in[7]) rotated by angle1 -> out[1], out[7]
//    (in[2], in[6]) rotated by angle2 -> out[2], out[6]
//    (in[3], in[5]) rotated by angle3 -> out[3], out[5]
//
//  NOTE:
//    - This is *not* an iterative CORDIC-II; it uses precomputed cos/sin
//      in fixed-point (Q14). Structurally it matches a 3-angle rotation
//      block that you can later replace with a true CORDIC-II engine.
// ============================================================================

module dct8_unified_cordic #(
    parameter DATA_W = 16,   // incoming sample width
    parameter FRAC   = 14    // fractional bits for cos/sin
)(
    input  wire                     clk,
    input  wire                     rst_n,       // active-low sync reset

    input  wire                     in_valid,
    input  wire signed [DATA_W-1:0] in_sample,

    output reg                      out_valid,
    output reg  signed [DATA_W-1:0] out_sample
);

    // -----------------------------
    // Fixed-point cos/sin constants (Q14)
    // cos(theta)*2^FRAC, sin(theta)*2^FRAC
    // theta1 = -pi/16
    // theta2 =  pi/8
    // theta3 = 3pi/16
    // -----------------------------
    localparam signed [FRAC+1:0] C1 = 16'sd16069;   // cos(-pi/16)
    localparam signed [FRAC+1:0] S1 = -16'sd3196;   // sin(-pi/16)

    localparam signed [FRAC+1:0] C2 = 16'sd15137;   // cos(pi/8)
    localparam signed [FRAC+1:0] S2 = 16'sd6270;    // sin(pi/8)

    localparam signed [FRAC+1:0] C3 = 16'sd13623;   // cos(3pi/16)
    localparam signed [FRAC+1:0] S3 = 16'sd9102;    // sin(3pi/16)

    localparam integer MUL_W = DATA_W + FRAC + 2;

    // Block buffer
    reg  signed [DATA_W-1:0] x_reg [0:7];
    reg  signed [DATA_W-1:0] y_reg [0:7];

    // FSM
    localparam S_IDLE    = 2'd0;
    localparam S_COLLECT = 2'd1;
    localparam S_COMPUTE = 2'd2;
    localparam S_OUTPUT  = 2'd3;

    reg [1:0] state;
    reg [2:0] idx;

    integer i;

    // Pre-rotation wires (combinational) for three pairs
    wire signed [DATA_W-1:0] x1 = x_reg[1];
    wire signed [DATA_W-1:0] y1 = x_reg[7];
    wire signed [DATA_W-1:0] x2 = x_reg[2];
    wire signed [DATA_W-1:0] y2 = x_reg[6];
    wire signed [DATA_W-1:0] x3 = x_reg[3];
    wire signed [DATA_W-1:0] y3 = x_reg[5];

    // raw products
    wire signed [MUL_W-1:0] r1_x_raw = x1 * C1 - y1 * S1;
    wire signed [MUL_W-1:0] r1_y_raw = x1 * S1 + y1 * C1;

    wire signed [MUL_W-1:0] r2_x_raw = x2 * C2 - y2 * S2;
    wire signed [MUL_W-1:0] r2_y_raw = x2 * S2 + y2 * C2;

    wire signed [MUL_W-1:0] r3_x_raw = x3 * C3 - y3 * S3;
    wire signed [MUL_W-1:0] r3_y_raw = x3 * S3 + y3 * C3;

    // Truncated rotated results (Q(FRAC) -> integer)
    wire signed [DATA_W-1:0] r1_x = r1_x_raw >>> FRAC;
    wire signed [DATA_W-1:0] r1_y = r1_y_raw >>> FRAC;
    wire signed [DATA_W-1:0] r2_x = r2_x_raw >>> FRAC;
    wire signed [DATA_W-1:0] r2_y = r2_y_raw >>> FRAC;
    wire signed [DATA_W-1:0] r3_x = r3_x_raw >>> FRAC;
    wire signed [DATA_W-1:0] r3_y = r3_y_raw >>> FRAC;

    // ------------------------------------------------------------------------
    // Main FSM
    // ------------------------------------------------------------------------
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state     <= S_IDLE;
            idx       <= 3'd0;
            out_valid <= 1'b0;
            out_sample<= {DATA_W{1'b0}};
            for (i = 0; i < 8; i = i + 1) begin
                x_reg[i] <= {DATA_W{1'b0}};
                y_reg[i] <= {DATA_W{1'b0}};
            end
        end else begin
            case (state)
                // ------------------------------------------------------------
                S_IDLE: begin
                    out_valid <= 1'b0;
                    idx       <= 3'd0;
                    if (in_valid) begin
                        x_reg[0] <= in_sample;
                        idx      <= 3'd1;
                        state    <= S_COLLECT;
                    end
                end

                // ------------------------------------------------------------
                // Collect 8 samples from Stage-3
                // ------------------------------------------------------------
                S_COLLECT: begin
                    out_valid <= 1'b0;
                    if (in_valid) begin
                        x_reg[idx] <= in_sample;
                        if (idx == 3'd7) begin
                            idx   <= 3'd0;
                            state <= S_COMPUTE;
                        end else begin
                            idx <= idx + 3'd1;
                        end
                    end
                end

                // ------------------------------------------------------------
                // Compute rotated outputs in one cycle
                // ------------------------------------------------------------
                S_COMPUTE: begin
                    // Bypass 0 and 4 (you can add scaling here if desired)
                    y_reg[0] <= x_reg[0];
                    y_reg[4] <= x_reg[4];

                    // Rotated pairs
                    y_reg[1] <= r1_x;
                    y_reg[7] <= r1_y;

                    y_reg[2] <= r2_x;
                    y_reg[6] <= r2_y;

                    y_reg[3] <= r3_x;
                    y_reg[5] <= r3_y;

                    idx       <= 3'd0;
                    out_valid <= 1'b0;
                    state     <= S_OUTPUT;
                end

                // ------------------------------------------------------------
                // Stream the 8 outputs
                // ------------------------------------------------------------
                S_OUTPUT: begin
                    out_valid  <= 1'b1;
                    out_sample <= y_reg[idx];

                    if (idx == 3'd7) begin
                        idx   <= 3'd0;
                        state <= S_IDLE;
                    end else begin
                        idx <= idx + 3'd1;
                    end
                end

                default: begin
                    state <= S_IDLE;
                end
            endcase
        end
    end

endmodule
