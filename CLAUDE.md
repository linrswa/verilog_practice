# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Purpose

Verilog learning project for career transition prep, focused on building up to I2C master/slave implementation. Uses Icarus Verilog for simulation and Surfer (VSCode extension) for waveform viewing.

## Build & Simulate Commands

Compile and run a module with its testbench (example for FF):
```bash
iverilog -o out/ff FF/ff.v FF/ff_tb.v
vvp out/ff
```

This produces a `.vcd` file for waveform inspection in Surfer.

General pattern:
```bash
iverilog -o <output> <module>.v <testbench>.v
vvp <output>
# Open the generated .vcd file in Surfer to view waveforms
```

## Project Structure

Each topic lives in its own directory with design files and testbenches:
- `FF/` — Flip-flop fundamentals (DFF with async reset)
- `FSM/` — Finite state machines (vending machine example, Mealy-style with combinational outputs)
- `I2C/` — I2C master/slave implementation (in progress, see `I2C/plan.md` for 5-day roadmap)

## Conventions

- Testbench files are named `*_tb.v` and placed alongside their design files
- Compiled outputs go in `out/` subdirectories
- VCD dump files are generated in the module's directory
- Timescale: `` `timescale 1ns/1ps ``
- Comments and documentation are in Traditional Chinese (繁體中文)

## Teaching Context

This repo is used in a mentor/student context. Claude should:
- Act as a tutor: ask probing questions about design decisions after implementations
- Arrange small quizzes (Q&A or hands-on) when knowledge gaps are detected
- Occasionally take an interviewer perspective for practice questions
- The I2C plan (`I2C/plan.md`) includes interview prep topics — reference these when relevant
