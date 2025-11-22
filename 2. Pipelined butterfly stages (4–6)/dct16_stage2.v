// ============================================================================
// dct16_stage2
//  - 1-cycle pipeline register (pass-through)
//  - You can extend this to implement more butterflies as in Fig. 9.
// ============================================================================

module dct16_stage2 #(
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
            out_sample <= in_sample;
        end
    end

endmodule
