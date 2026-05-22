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
// File: ojph_encode_timing_local.h
//***************************************************************************/

#ifndef OJPH_ENCODE_TIMING_LOCAL_H
#define OJPH_ENCODE_TIMING_LOCAL_H

#include "ojph_defs.h"

namespace ojph {
  namespace local {

#if defined(OJPH_ENABLE_ENCODE_TIMINGS)

    ui64 encode_timing_now_ns();
    void encode_timing_add_tile_push_ns(ui64 ns);
    void encode_timing_add_resolution_push_ns(ui64 ns);
    void encode_timing_add_codeblock_encode_ns(ui64 ns);
    void encode_timing_add_flush_ns(ui64 ns);
    void encode_timing_inc_input_line_count();
    void encode_timing_inc_codeblock_count();
    void encode_timing_report_and_reset();

    class scoped_encode_timer
    {
    public:
      typedef void (*accumulator_fun)(ui64);

      explicit scoped_encode_timer(accumulator_fun fn)
      : fn(fn), start(encode_timing_now_ns()) {}

      ~scoped_encode_timer()
      {
        fn(encode_timing_now_ns() - start);
      }

    private:
      accumulator_fun fn;
      ui64 start;
    };

#else

    static inline ui64 encode_timing_now_ns() { return 0; }
    static inline void encode_timing_add_tile_push_ns(ui64) {}
    static inline void encode_timing_add_resolution_push_ns(ui64) {}
    static inline void encode_timing_add_codeblock_encode_ns(ui64) {}
    static inline void encode_timing_add_flush_ns(ui64) {}
    static inline void encode_timing_inc_input_line_count() {}
    static inline void encode_timing_inc_codeblock_count() {}
    static inline void encode_timing_report_and_reset() {}

    class scoped_encode_timer
    {
    public:
      explicit scoped_encode_timer(void (*)(ui64)) {}
    };

#endif

  }
}

#endif // !OJPH_ENCODE_TIMING_LOCAL_H
