`timescale 1ns/1ps
// ---------------------------------------------------------------------------
// 16‑point pipelined 1D DCT core (top level)
// Matches the 5‑stage structure in Fig. 9 of the paper:
//   Stage 1–3 : multi‑delay butterfly stages
//   Stage 4–5 : two unified CORDIC‑II blocks (COR.1..5 and COR.6..9)
// Streaming interface: 1 sample / cycle when in_valid = 1
// ---------------------------------------------------------------------------
module dct16_core #(
    parameter DATA_WIDTH = 12  // internal datapath width
)(
    input  wire                   clk,
    input  wire                   rst,         // synchronous, active‑high reset

    input  wire [DATA_WIDTH-1:0]  in_sample,   // input samples x(0..15) in order
    input  wire                   in_valid,    // assert for each valid input

    output wire [DATA_WIDTH-1:0]  out_sample,  // DCT outputs X(0..15) in order
    output wire                   out_valid    // pulses with each valid output
);

    // -----------------------------------------------------------------------
    // Stage‑1: first butterfly stage (multi‑delay feedback)
    // -----------------------------------------------------------------------
    wire [DATA_WIDTH-1:0] s1_sample;
    wire                  s1_valid;

    dct16_stage1_bfly #(
        .DATA_WIDTH (DATA_WIDTH)
    ) u_stage1 (
        .clk        (clk),
        .rst        (rst),
        .in_sample  (in_sample),
        .in_valid   (in_valid),
        .out_sample (s1_sample),
        .out_valid  (s1_valid)
    );

    // -----------------------------------------------------------------------
    // Stage‑2: second butterfly stage
    // -----------------------------------------------------------------------
    wire [DATA_WIDTH-1:0] s2_sample;
    wire                  s2_valid;

    dct16_stage2_bfly #(
        .DATA_WIDTH (DATA_WIDTH)
    ) u_stage2 (
        .clk        (clk),
        .rst        (rst),
        .in_sample  (s1_sample),
        .in_valid   (s1_valid),
        .out_sample (s2_sample),
        .out_valid  (s2_valid)
    );

    // -----------------------------------------------------------------------
    // Stage‑3: third butterfly stage
    // -----------------------------------------------------------------------
    wire [DATA_WIDTH-1:0] s3_sample;
    wire                  s3_valid;

    dct16_stage3_bfly #(
        .DATA_WIDTH (DATA_WIDTH)
    ) u_stage3 (
        .clk        (clk),
        .rst        (rst),
        .in_sample  (s2_sample),
        .in_valid   (s2_valid),
        .out_sample (s3_sample),
        .out_valid  (s3_valid)
    );

    // -----------------------------------------------------------------------
    // Stage‑4: first unified CORDIC‑II block
    // Groups COR.1..COR.5 from the SFG (Fig. 7) into a shared resource
    // (shown as the Stage‑4 block in Fig. 9).
    // -----------------------------------------------------------------------
    wire [DATA_WIDTH-1:0] s4_sample;
    wire                  s4_valid;

    dct16_unified_cordic4 #(
        .DATA_WIDTH (DATA_WIDTH)
    ) u_stage4 (
        .clk        (clk),
        .rst        (rst),
        .in_sample  (s3_sample),
        .in_valid   (s3_valid),
        .out_sample (s4_sample),
        .out_valid  (s4_valid)
    );

    // -----------------------------------------------------------------------
    // Stage‑5: second unified CORDIC‑II block
    // Groups COR.6..COR.9 from the SFG (Fig. 7) into a shared resource
    // (shown as the Stage‑5 block in Fig. 9).
    // -----------------------------------------------------------------------
    dct16_unified_cordic5 #(
        .DATA_WIDTH (DATA_WIDTH)
    ) u_stage5 (
        .clk        (clk),
        .rst        (rst),
        .in_sample  (s4_sample),
        .in_valid   (s4_valid),
        .out_sample (out_sample),
        .out_valid  (out_valid)
    );

    // Overall pipeline latency is ~89 cycles for the first output when
    // all stages are implemented as in the paper.

endmodule
