// ============================================================================
// dct8_stage1
//  - Collects 8 input samples x(0..7)
//  - Computes first butterfly pre-additions:
//        y0 = x0 + x7
//        y1 = x1 + x6
//        y2 = x2 + x5
//        y3 = x3 + x4
//        y4 = x3 - x4
//        y5 = x2 - x5
//        y6 = x1 - x6
//        y7 = x0 - x7
//  - Outputs y(0..7) one per clock (block-based, not per-sample streaming)
// ============================================================================

module dct8_stage1 #(
    parameter DATA_IN_WIDTH  = 12,
    parameter DATA_OUT_WIDTH = 16
)(
    input  wire                           clk,
    input  wire                           rst_n,       // active-low sync reset

    input  wire                           in_valid,
    input  wire signed [DATA_IN_WIDTH-1:0]  in_sample,

    output reg                            out_valid,
    output reg signed [DATA_OUT_WIDTH-1:0] out_sample
);

    localparam integer N = 8;

    // State machine
    localparam S_FILL    = 2'd0;
    localparam S_COMPUTE = 2'd1;
    localparam S_OUTPUT  = 2'd2;

    reg [1:0] state;

    reg [2:0] in_count;   // 0..7 for input
    reg [2:0] out_count;  // 0..7 for output

    // Internal storage for one block of 8 samples
    reg signed [DATA_IN_WIDTH-1:0]  x [0:N-1];
    reg signed [DATA_OUT_WIDTH-1:0] y [0:N-1];

    integer i;

    // ------------------------------------------------------------------------
    // Main sequential logic
    // ------------------------------------------------------------------------
    always @(posedge clk) begin
        if (!rst_n) begin
            state      <= S_FILL;
            in_count   <= 3'd0;
            out_count  <= 3'd0;
            out_valid  <= 1'b0;
            out_sample <= {DATA_OUT_WIDTH{1'b0}};
            // Optional: clear arrays (not strictly required for synthesis)
            for (i = 0; i < N; i = i + 1) begin
                x[i] <= {DATA_IN_WIDTH{1'b0}};
                y[i] <= {DATA_OUT_WIDTH{1'b0}};
            end
        end else begin
            // Default
            out_valid <= 1'b0;

            case (state)
                // ------------------------------------------------------------
                // Collect 8 input samples
                // ------------------------------------------------------------
                S_FILL: begin
                    if (in_valid) begin
                        x[in_count] <= in_sample;

                        if (in_count == N-1) begin
                            in_count <= 3'd0;
                            state    <= S_COMPUTE;
                        end else begin
                            in_count <= in_count + 3'd1;
                        end
                    end
                end

                // ------------------------------------------------------------
                // Compute butterfly results y[0..7] from stored x[0..7]
                // (one clock; no I/O in this state)
                // ------------------------------------------------------------
                S_COMPUTE: begin
                    // Sums
                    y[0] <= $signed(x[0]) + $signed(x[7]);
                    y[1] <= $signed(x[1]) + $signed(x[6]);
                    y[2] <= $signed(x[2]) + $signed(x[5]);
                    y[3] <= $signed(x[3]) + $signed(x[4]);

                    // Differences
                    y[4] <= $signed(x[3]) - $signed(x[4]);
                    y[5] <= $signed(x[2]) - $signed(x[5]);
                    y[6] <= $signed(x[1]) - $signed(x[6]);
                    y[7] <= $signed(x[0]) - $signed(x[7]);

                    out_count <= 3'd0;
                    state     <= S_OUTPUT;
                end

                // ------------------------------------------------------------
                // Output y[0..7], one per clock
                // ------------------------------------------------------------
                S_OUTPUT: begin
                    out_valid  <= 1'b1;
                    out_sample <= y[out_count];

                    if (out_count == N-1) begin
                        out_count <= 3'd0;
                        state     <= S_FILL;
                    end else begin
                        out_count <= out_count + 3'd1;
                    end
                end

                default: begin
                    state <= S_FILL;
                end
            endcase
        end
    end

endmodule
