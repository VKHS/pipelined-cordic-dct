// ============================================================================
// safe_scale_unit
//  - Per-sample safe scaling block used between stages
//  - mode = 2'b00 : divide by 2   (arithmetic right shift by 1)
//  - mode = 2'b01 : multiply by 0.1011_2 ~= 0.6875
//                   (x/2 + x/8 + x/16) - used for √2-paths in the paper
//  - others       : pass-through
// ============================================================================

module safe_scale_unit #(
    parameter integer WIDTH = 16
)(
    input  wire                         clk,
    input  wire                         rst_n,      // active-low sync reset

    input  wire                         in_valid,
    input  wire [1:0]                   mode,
    input  wire signed [WIDTH-1:0]      in_sample,

    output reg                          out_valid,
    output reg  signed [WIDTH-1:0]      out_sample
);

    reg signed [WIDTH-1:0] scaled;

    always @* begin
        case (mode)
            2'b00: begin
                // divide by 2
                scaled = in_sample >>> 1;
            end

            2'b01: begin
                // 0.1011_2 = 1/2 + 1/8 + 1/16
                // (x >> 1) + (x >> 3) + (x >> 4)
                scaled = (in_sample >>> 1)
                       + (in_sample >>> 3)
                       + (in_sample >>> 4);
            end

            default: begin
                // pass-through
                scaled = in_sample;
            end
        endcase
    end

    always @(posedge clk) begin
        if (!rst_n) begin
            out_valid  <= 1'b0;
            out_sample <= {WIDTH{1'b0}};
        end else begin
            out_valid  <= in_valid;
            out_sample <= scaled;
        end
    end

endmodule
