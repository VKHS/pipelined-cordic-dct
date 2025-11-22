`timescale 1ns/1ps
// ---------------------------------------------------------------------------
// 8‑point pipelined 1D DCT core (top level)
// Matches the 4‑stage structure in Fig. 5 of the paper:
//   Stage 1–3 : multi‑delay butterfly + safe‑scaling
//   Stage 4   : unified CORDIC‑II rotation block (COR.1..COR.3 + RSU/RSD)
// Streaming interface: 1 sample / cycle when in_valid = 1
// ---------------------------------------------------------------------------
module dct8_core #(
    parameter DATA_WIDTH = 12  // internal datapath width (you can tune this)
)(
    input  wire                   clk,
    input  wire                   rst,        // synchronous, active‑high reset

    input  wire [DATA_WIDTH-1:0]  in_sample,  // input samples x(0..7) in order
    input  wire                   in_valid,   // assert for each valid input

    output wire [DATA_WIDTH-1:0]  out_sample, // DCT outputs X(0..7) in order
    output wire                   out_valid   // pulses with each valid output
);

    // -----------------------------------------------------------------------
    // Stage‑1: multi‑delay feedback butterfly (double‑line feedback)
    // -----------------------------------------------------------------------
    wire [DATA_WIDTH-1:0] s1_sample;
    wire                  s1_valid;

    dct8_stage1_bfly #(
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
    // Stage‑2: multi‑delay feedback butterfly (three‑delay feedback)
    // -----------------------------------------------------------------------
    wire [DATA_WIDTH-1:0] s2_sample;
    wire                  s2_valid;

    dct8_stage2_bfly #(
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
    // Stage‑3: butterfly + Safe Scaling (per‑stage / √2 scaling logic)
    // -----------------------------------------------------------------------
    wire [DATA_WIDTH-1:0] s3_sample;
    wire                  s3_valid;

    dct8_stage3_bfly_scaling #(
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
    // Stage‑4: unified CORDIC‑II block (COR.1, COR.2, COR.3)
    // Handles angles −π/16, π/8, 3π/16 and RSU/RSD units (Fig. 6)
    // This stage also includes the bypass delay lines for k=0,4 outputs.
    // -----------------------------------------------------------------------
    dct8_unified_cordic #(
        .DATA_WIDTH (DATA_WIDTH)
    ) u_stage4 (
        .clk        (clk),
        .rst        (rst),
        .in_sample  (s3_sample),
        .in_valid   (s3_valid),
        .out_sample (out_sample),
        .out_valid  (out_valid)
    );

    // Overall pipeline latency is ~51 cycles for the first output when
    // all stages are implemented as in the paper.

endmodule
