// ============================================================================
// rsd_generic
//  - Radius Scale-Down (RSD) / Safe-scaling block using shift-add
//  - out = sum_k ( in >>> SHIFT_k ) for enabled shifts
//
// Example: for Safe-Scaling 2 with 0.1011_2 ~= 0.6875:
//      0.1011_2 = 1/2 + 1/8 + 1/16
//      => SHIFT0=1, SHIFT1=3, SHIFT2=4, all USE=1
// ============================================================================

module rsd_generic #(
    parameter DATA_W = 16,
    parameter integer SHIFT0 = 1,
    parameter integer SHIFT1 = 3,
    parameter integer SHIFT2 = 4,
    parameter USE_SHIFT0 = 1,
    parameter USE_SHIFT1 = 1,
    parameter USE_SHIFT2 = 1
)(
    input  wire                     clk,
    input  wire                     rst_n,

    input  wire                     in_valid,
    input  wire signed [DATA_W-1:0] in_sample,

    output reg                      out_valid,
    output reg  signed [DATA_W-1:0] out_sample
);

    reg signed [DATA_W+1:0] acc; // small growth for intermediate

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            out_valid  <= 1'b0;
            out_sample <= {DATA_W{1'b0}};
            acc        <= {(DATA_W+2){1'b0}};
        end else begin
            if (in_valid) begin
                acc = { {(2){in_sample[DATA_W-1]}}, in_sample }; // sign-extend

                if (USE_SHIFT0)
                    acc = acc + (in_sample >>> SHIFT0);
                if (USE_SHIFT1)
                    acc = acc + (in_sample >>> SHIFT1);
                if (USE_SHIFT2)
                    acc = acc + (in_sample >>> SHIFT2);

                out_sample <= acc[DATA_W-1:0];
                out_valid  <= 1'b1;
            end else begin
                out_valid  <= 1'b0;
            end
        end
    end

endmodule
