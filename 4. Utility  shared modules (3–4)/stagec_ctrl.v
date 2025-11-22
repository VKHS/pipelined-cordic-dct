// ============================================================================
// stage_ctrl
//  - Generic controller for block-based streaming stages.
//  - For each asserted in_valid, increments an index (0..BLOCK_SIZE-1)
//    and generates block_start / block_end pulses.
// ============================================================================

module stage_ctrl #(
    parameter integer BLOCK_SIZE = 8
)(
    input  wire clk,
    input  wire rst_n,        // active-low sync reset

    input  wire in_valid,

    output reg  [$clog2(BLOCK_SIZE)-1:0] idx,
    output reg                           block_start,
    output reg                           block_end
);

    // Internal counter for samples in current block
    reg [$clog2(BLOCK_SIZE)-1:0] cnt;

    always @(posedge clk) begin
        if (!rst_n) begin
            cnt         <= {($clog2(BLOCK_SIZE)){1'b0}};
            idx         <= {($clog2(BLOCK_SIZE)){1'b0}};
            block_start <= 1'b0;
            block_end   <= 1'b0;
        end else begin
            block_start <= 1'b0;
            block_end   <= 1'b0;

            if (in_valid) begin
                idx <= cnt;

                // Generate start/end pulses
                if (cnt == {($clog2(BLOCK_SIZE)){1'b0}})
                    block_start <= 1'b1;

                if (cnt == BLOCK_SIZE - 1) begin
                    block_end <= 1'b1;
                    cnt       <= {($clog2(BLOCK_SIZE)){1'b0}};
                end else begin
                    cnt <= cnt + 1'b1;
                end
            end
        end
    end

endmodule
