// ============================================================================
// dct16_stage3
//  - Another 1-cycle pipeline stage
//  - Includes simple "safe scaling" by 1/2 as an example.
// ============================================================================

module dct16_stage3 #(
    parameter DATA_WIDTH = 16
)(
    input  wire                        clk,
    input  wire                        rst_n,       // active-low sync reset

    input  wire                        in_valid,
    input  wire signed [DATA_WIDTH-1:0] in_sample,

    output reg                         out_valid,
    output reg signed [DATA_WIDTH-1:0] out_sample
);

    always @(posedge clk) begin
        if (!rst_n) begin
            out_valid  <= 1'b0;
            out_sample <= {DATA_WIDTH{1'b0}};
        end else begin
            out_valid  <= in_valid;
            out_sample <= in_sample >>> 1; // divide-by-2
        end
    end

endmodule
