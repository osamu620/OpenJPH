# Hand-Written Assembly in OpenJPH

This document explains why hand-written NASM assembly is used in
specific parts of the encoder, and what rules govern its use.

## Background

The HTJ2K block encoder's MagSgn bit-packing loop (`proc_ms_encode`)
accounts for 31% of single-threaded lossless encode time on x86-64.
It accumulates variable-length codewords into a 64-bit register and
periodically drains completed bytes to an output buffer, inserting a
zero bit after every 0xFF byte (JPEG 2000 byte stuffing).

## Why the compiler falls short

The C++ compiler (GCC 14, Clang 18) generates correct but suboptimal
code for this loop due to three structural limitations:

### 1. Pointer aliasing forces dead stores

The inner loop reads codewords from stack arrays (`cwd[]`, `cwd_len[]`)
and writes through an `ms_struct*` pointer whose `buf` member points to
a separate output buffer.  The compiler cannot prove these memory
regions do not overlap, so it reloads and stores the accumulator state
(`tmp`, `used_bits`) on every loop iteration, even when no drain occurs.

Disassembly of the inner loop (GCC 14, `-O2 -mavx512f -mbmi2`):

```asm
; executed 16 times per proc_ms_encode call:
mov    %r14, 0x18(%r15)   ; store tmp       -- unnecessary
mov    %edx, 0x10(%r15)   ; store used_bits -- unnecessary
```

These 32 dead stores per call cannot be eliminated by `restrict`,
`__attribute__((noescape))`, or struct-member reordering because the
aliasing is through `msp->buf`, not the struct itself.

### 2. Register pressure in the drain loop

The SWAR 0xFF detection, `tzcnt`, variable-length shift, and
conditional 7-bit byte extraction require 6-7 scratch registers.
The compiler spills temporaries because it also reserves registers
for the outer loop state.

### 3. `memcpy` expansion

The compiler expands small `memcpy` calls (1-8 bytes) into a
general-purpose copy loop with alignment handling.  In assembly, a
single `mov [buf+pos], reg` suffices because the value is already in
a register and the buffer tolerates up to 7 bytes of harmless
overwrite.

## What the assembly does

A single NASM function (`ojph_ms_encode_batch`) replaces the scalar
inner loop of `proc_ms_encode`.  It:

- Loads the bit-accumulator state (`tmp`, `used_bits`, `last_was_ff`)
  into dedicated registers at entry
- Processes all 64 codewords from one `proc_ms_encode` invocation
  with zero memory traffic for the hot state
- Drains bytes inline using the same SWAR 0xFF detection algorithm
- Writes the state back to the struct once at exit

All SIMD code (AVX-512 codeword preparation, matrix rotation) remains
in C++.

## Scope and boundaries

- Assembly is used *only* for the scalar bit-packing and byte-stuffing
  loop, not for SIMD or algorithmic logic.
- The NASM function has a plain C-callable interface (`extern "C"`)
  with no SIMD register dependencies.
- Output is bitstream-identical to the C++ implementation, verified by
  byte-for-byte comparison.
- Platform: Linux/macOS x86-64 only (ELF/Mach-O).  MSVC builds
  continue using the C++ implementation.  A future MASM port can be
  added if needed.
- Requires BMI2 (`shlx`, `shrx`, `bzhi`) which is already a
  prerequisite for the AVX-512 encoder path.
