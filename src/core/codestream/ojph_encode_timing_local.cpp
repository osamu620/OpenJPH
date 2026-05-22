//***************************************************************************/
// This software is released under the 2-Clause BSD license, included
// below.
//
// Copyright (c) 2019, Aous Naman
// Copyright (c) 2019, Kakadu Software Pty Ltd, Australia
// Copyright (c) 2019, The University of New South Wales, Australia
//
// Redistribution and use in source and binary forms, with or without
// modification, are permitted provided that the following conditions are
// met:
//
// 1. Redistributions of source code must retain the above copyright
// notice, this list of conditions and the following disclaimer.
//
// 2. Redistributions in binary form must reproduce the above copyright
// notice, this list of conditions and the following disclaimer in the
// documentation and/or other materials provided with the distribution.
//
// THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS
// IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED
// TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A
// PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
// HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
// SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED
// TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
// PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF
// LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING
// NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
// SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
//***************************************************************************/
// This file is part of the OpenJPH software implementation.
// File: ojph_encode_timing_local.cpp
//***************************************************************************/

#include "ojph_encode_timing_local.h"

#if defined(OJPH_ENABLE_ENCODE_TIMINGS)

#include <chrono>
#include <cstdio>

namespace ojph {
  namespace local {

    namespace
    {
      struct encode_timing_state
      {
        ui64 tile_push_ns;
        ui64 resolution_push_ns;
        ui64 codeblock_encode_ns;
        ui64 flush_ns;
        ui64 input_line_count;
        ui64 codeblock_count;
      };

      encode_timing_state g_encode_timing_state = {0, 0, 0, 0, 0, 0};
    }

    ui64 encode_timing_now_ns()
    {
      auto now = std::chrono::steady_clock::now().time_since_epoch();
      return (ui64) std::chrono::duration_cast<std::chrono::nanoseconds>(now)
        .count();
    }

    void encode_timing_add_tile_push_ns(ui64 ns)
    {
      g_encode_timing_state.tile_push_ns += ns;
    }

    void encode_timing_add_resolution_push_ns(ui64 ns)
    {
      g_encode_timing_state.resolution_push_ns += ns;
    }

    void encode_timing_add_codeblock_encode_ns(ui64 ns)
    {
      g_encode_timing_state.codeblock_encode_ns += ns;
    }

    void encode_timing_add_flush_ns(ui64 ns)
    {
      g_encode_timing_state.flush_ns += ns;
    }

    void encode_timing_inc_input_line_count()
    {
      ++g_encode_timing_state.input_line_count;
    }

    void encode_timing_inc_codeblock_count()
    {
      ++g_encode_timing_state.codeblock_count;
    }

    void encode_timing_report_and_reset()
    {
      const ui64 total_ns = g_encode_timing_state.tile_push_ns
                          + g_encode_timing_state.flush_ns;
      if (total_ns == 0)
        return;

      const double ns_to_ms = 1.0e-6;
      const double total_ms = (double)total_ns * ns_to_ms;
      const double tile_ms =
        (double)g_encode_timing_state.tile_push_ns * ns_to_ms;
      const double res_ms =
        (double)g_encode_timing_state.resolution_push_ns * ns_to_ms;
      const double cb_ms =
        (double)g_encode_timing_state.codeblock_encode_ns * ns_to_ms;
      const double flush_ms = (double)g_encode_timing_state.flush_ns * ns_to_ms;
      const double tile_pct = 100.0 * (double)g_encode_timing_state.tile_push_ns
                            / (double)total_ns;
      const double cb_pct = 100.0
                          * (double)g_encode_timing_state.codeblock_encode_ns
                          / (double)total_ns;
      const double flush_pct = 100.0 * (double)g_encode_timing_state.flush_ns
                             / (double)total_ns;

      std::fprintf(stderr,
        "OpenJPH encode timing [ms]: total=%.3f tile_push=%.3f "
        "resolution_push=%.3f codeblock_encode=%.3f flush=%.3f\n",
        total_ms, tile_ms, res_ms, cb_ms, flush_ms);
      std::fprintf(stderr,
        "OpenJPH encode timing [share%%]: tile_push=%.2f "
        "codeblock_encode=%.2f flush=%.2f | input_lines=%llu "
        "codeblocks=%llu\n",
        tile_pct, cb_pct, flush_pct,
        (unsigned long long)g_encode_timing_state.input_line_count,
        (unsigned long long)g_encode_timing_state.codeblock_count);

      g_encode_timing_state = {0, 0, 0, 0, 0, 0};
    }

  }
}

#endif
