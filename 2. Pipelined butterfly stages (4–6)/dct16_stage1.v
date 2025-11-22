// ============================================================================
// dct16_stage1
//  - Collects 16 input samples x(0..15)
//  - Computes first-level symmetric butterflies:
//        for i = 0..7:
//          y[i]      = x[i] + x[15-i]
//          y[15 - i] = x[i] - x[15-i]
//  - Outputs y(0..15) one per clock (block-based)
// ============================================================================

module dct16_stage1 #(
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

    localparam integer N = 16;

    // State machine
    localparam S_FILL    = 2'd0;
    localparam S_COMPUTE = 2'd1;
    localparam S_OUTPUT  = 2'd2;

    reg [1:0] state;

    reg [3:0] in_count;   // 0..15
    reg [3:0] out_count;  // 0..15

    // Internal storage
    reg signed [DATA_IN_WIDTH-1:0]  x [0:N-1];
    reg signed [DATA_OUT_WIDTH-1:0] y [0:N-1];

    integer i;

    // ------------------------------------------------------------------------
    // Main sequential logic
    // ------------------------------------------------------------------------
    always @(posedge clk) begin
        if (!rst_n) begin
            state      <= S_FILL;
            in_count   <= 4'd0;
            out_count  <= 4'd0;
            out_valid  <= 1'b0;
            out_sample <= {DATA_OUT_WIDTH{1'b0}};
            for (i = 0; i < N; i = i + 1) begin
                x[i] <= {DATA_IN_WIDTH{1'b0}};
                y[i] <= {DATA_OUT_WIDTH{1'b0}};
            end
        end else begin
            // Default
            out_valid <= 1'b0;

            case (state)
                // ------------------------------------------------------------
                // Collect 16 inputs
                // ------------------------------------------------------------
                S_FILL: begin
                    if (in_valid) begin
                        x[in_count] <= in_sample;

                        if (in_count == N-1) begin
                            in_count <= 4'd0;
                            state    <= S_COMPUTE;
                        end else begin
                            in_count <= in_count + 4'd1;
                        end
                    end
                end

                // ------------------------------------------------------------
                // Compute butterflies: y[i], y[15-i] from x[]
                // ------------------------------------------------------------
                S_COMPUTE: begin
                    for (i = 0; i < 8; i = i + 1) begin
                        y[i]        <= $signed(x[i])        + $signed(x[15-i]);
                        y[15 - i]   <= $signed(x[i])        - $signed(x[15-i]);
                    end

                    out_count <= 4'd0;
                    state     <= S_OUTPUT;
                end

                // ------------------------------------------------------------
                // Output y[0..15], one per clock
                // ------------------------------------------------------------
                S_OUTPUT: begin
                    out_valid  <= 1'b1;
                    out_sample <= y[out_count];

                    if (out_count == N-1) begin
                        out_count <= 4'd0;
                        state     <= S_FILL;
                    end else begin
                        out_count <= out_count + 4'd1;
                    end
                end

                default: begin
                    state <= S_FILL;
                end
            endcase
        end
    end

endmodule
