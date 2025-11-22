// ============================================================================
// dct8_stage2
//  - Simple 1-cycle pipeline register
//  - Passes data and valid onward
//  - In the paper this corresponds to one of the early butterfly stages;
//    here it's just a clean timing / pipeline stage you can extend.
// ============================================================================

module dct8_stage2 #(
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
