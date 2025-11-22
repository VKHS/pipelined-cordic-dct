// ============================================================================
// rsu_generic
//  - Radius Scale-Up (RSU) block using shift-add
//  - out = sum_k ( in <<< SHIFT_k ) for enabled shifts
//
// Example: for approximate radius factor 10:
//      10 = 2^1 + 2^3   => SHIFT0=1, SHIFT1=3, SHIFT2=0, USE2=0
// ============================================================================

module rsu_generic #(
    parameter DATA_W = 16,
    // up to three shift terms
    parameter integer SHIFT0 = 1,
    parameter integer SHIFT1 = 3,
    parameter integer SHIFT2 = 0,
    parameter USE_SHIFT0 = 1,
    parameter USE_SHIFT1 = 1,
    parameter USE_SHIFT2 = 0
)(
    input  wire                     clk,
    input  wire                     rst_n,

    input  wire                     in_valid,
    input  wire signed [DATA_W-1:0] in_sample,

    output reg                      out_valid,
    output reg  signed [DATA_W-1:0] out_sample
);

    reg signed [DATA_W+4:0] acc; // a few extra bits for growth

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            out_valid  <= 1'b0;
            out_sample <= {DATA_W{1'b0}};
            acc        <= {(DATA_W+5){1'b0}};
        end else begin
            if (in_valid) begin
                // accumulate shifted versions
                acc = { {(5){in_sample[DATA_W-1]}}, in_sample }; // sign-extend

                if (USE_SHIFT0)
                    acc = acc + (in_sample <<< SHIFT0);
                if (USE_SHIFT1)
                    acc = acc + (in_sample <<< SHIFT1);
                if (USE_SHIFT2)
                    acc = acc + (in_sample <<< SHIFT2);

                // simple truncation back to DATA_W
                out_sample <= acc[DATA_W-1:0];
                out_valid  <= 1'b1;
            end else begin
                out_valid  <= 1'b0;
            end
        end
    end

endmodule
