// ============================================================================
// delay_line
//  - Generic shift-register delay with valid propagation
//  - DEPTH >= 1: out is delayed DEPTH clock cycles w.r.t in.
// ============================================================================

module delay_line #(
    parameter integer WIDTH = 16,
    parameter integer DEPTH = 1   // minimum 1
)(
    input  wire                   clk,
    input  wire                   rst_n,      // active-low sync reset

    input  wire                   in_valid,
    input  wire signed [WIDTH-1:0] in_data,

    output reg                    out_valid,
    output reg signed [WIDTH-1:0] out_data
);

    // Shift registers for data and valid
    reg signed [WIDTH-1:0] data_reg [0:DEPTH-1];
    reg                    valid_reg[0:DEPTH-1];

    integer i;

    always @(posedge clk) begin
        if (!rst_n) begin
            out_valid <= 1'b0;
            out_data  <= {WIDTH{1'b0}};
            for (i = 0; i < DEPTH; i = i + 1) begin
                data_reg[i]  <= {WIDTH{1'b0}};
                valid_reg[i] <= 1'b0;
            end
        end else begin
            // Stage 0 gets new input
            data_reg[0]  <= in_data;
            valid_reg[0] <= in_valid;

            // Propagate through the delay line
            for (i = 1; i < DEPTH; i = i + 1) begin
                data_reg[i]  <= data_reg[i-1];
                valid_reg[i] <= valid_reg[i-1];
            end

            out_data  <= data_reg[DEPTH-1];
            out_valid <= valid_reg[DEPTH-1];
        end
    end

endmodule
