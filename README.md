# Pipelined CORDIC-based 8/16‑point DCT (Verilog)

This repository contains my Verilog implementation of a low‑power,
pipelined 1D DCT processor (8‑point and 16‑point) using a
shared‑resource CORDIC‑style rotation block and multi‑delay
butterfly stages.

The design is inspired by the architecture in:

> A. V. Khalili Sadaghiani, B. Forouzandeh,  
> “Novel low‑power pipelined DCT processor for real‑time IoT applications”,  
> Journal of Real‑Time Image Processing, 2023. :contentReference[oaicite:0]{index=0}

The goal is a DCT engine suitable for resource‑constrained
FPGA / IoT image and video compression.

---

## Folder overview

The repository is currently organised into four main folders:

1. **`1. Top-level modules (2)`**  
   Top‑level 1D DCT cores (interfaces to the outside world).  
   Typical files:
   - `dct8_core.v` – 8‑point DCT core (1D)
   - `dct16_core.v` – 16‑point DCT core (1D)

2. **`2. Pipelined butterfly stages (4–6)`**  
   Internal pipeline stages with multi‑delay butterflies and safe
   scaling. These correspond to stages 1–3 in the paper’s figures:
   - 8‑point: three stages of add/sub + scaling before the final rotation
   - 16‑point: three stages of add/sub + scaling before the final rotations

3. **`3. Unified CORDIC blocks + RSURSD (2–4)`**  
   Final rotation stages. Here the CORDIC‑like blocks implement
   several DCT rotation angles and handle radius‑scale‑up (RSU)
   and radius‑scale‑down (RSD) using shift‑add logic, similar to
   the unified CORDIC‑II stages shown in the paper. :contentReference[oaicite:1]{index=1}  

4. **`4. Utility  shared modules (3–4)`**  
   Reusable helper modules used by all stages, e.g.:
   - basic butterfly add/sub blocks
   - generic delay lines
   - simple stage controllers
   - safe‑scaling units (÷2, 0.1011₂, etc.)

---

## How to use the cores

### 8‑point DCT core

The 8‑point top‑level module is intended to look like:

```verilog
module dct8_core #(
    parameter DATA_WIDTH = 12
)(
    input  wire                   clk,
    input  wire                   rst,        // synchronous reset
    input  wire [DATA_WIDTH-1:0]  in_sample,  // x(0..7) in order
    input  wire                   in_valid,

    output wire [DATA_WIDTH-1:0]  out_sample, // X(0..7) in order
    output wire                   out_valid
);
