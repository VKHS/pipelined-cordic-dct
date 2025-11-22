// ============================================================================
// butterfly_addsub
//  - Basic 2-input butterfly: sum and difference
//  - Combinational, no clock; use external regs if you want pipelining.
// ============================================================================

module butterfly_addsub #(
    parameter integer WIDTH = 16
)(
    input  wire signed [WIDTH-1:0] a,
    input  wire signed [WIDTH-1:0] b,
    output wire signed [WIDTH-1:0] sum,
    output wire signed [WIDTH-1:0] diff
);

    assign sum  = a + b;
    assign diff = a - b;

endmodule
