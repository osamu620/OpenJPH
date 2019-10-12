/****************************************************************************/
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
/****************************************************************************/
// This file is part of the OpenJPH software implementation.
// File: ojph_colour_avx.cpp
// Author: Aous Naman
// Date: 11 October 2019
/****************************************************************************/

#include <cmath>

#include "ojph_defs.h"
#include "ojph_arch.h"
#include "ojph_colour.h"
#include "ojph_colour_local.h"

#ifdef OJPH_COMPILER_MSVC
#include <intrin.h>
#else
#include <x86intrin.h>
#endif

namespace ojph {
  namespace local {

    //////////////////////////////////////////////////////////////////////////
    void avx_cnvrt_si32_to_float_shftd(const si32 *sp, float *dp, float mul,
                                       int width)
    {
      __m256 shift = _mm256_set1_ps(0.5f);
      __m256 m = _mm256_set1_ps(mul);
      for (int i = (width + 7) >> 3; i > 0; --i, sp+=8, dp+=8)
      {
        __m256i t = _mm256_load_si256((__m256i*)sp);
        __m256 s = _mm256_cvtepi32_ps(t);
        s = _mm256_mul_ps(s, m);
        s = _mm256_sub_ps(s, shift);
        _mm256_store_ps(dp, s);
      }
    }

    //////////////////////////////////////////////////////////////////////////
    void avx_cnvrt_si32_to_float(const si32 *sp, float *dp, float mul,
                                 int width)
    {
      __m256 m = _mm256_set1_ps(mul);
      for (int i = (width + 7) >> 3; i > 0; --i, sp+=8, dp+=8)
      {
        __m256i t = _mm256_load_si256((__m256i*)sp);
        __m256 s = _mm256_cvtepi32_ps(t);
        s = _mm256_mul_ps(s, m);
        _mm256_store_ps(dp, s);
      }
    }

    //////////////////////////////////////////////////////////////////////////
    void avx_cnvrt_float_to_si32_shftd(const float *sp, si32 *dp, float mul,
                                       int width)
    {
      __m256 shift = _mm256_set1_ps(0.5f);
      __m256 m = _mm256_set1_ps(mul);
      for (int i = (width + 7) >> 3; i > 0; --i, sp+=8, dp+=8)
      {
        __m256 t = _mm256_load_ps(sp);
        __m256 s = _mm256_add_ps(t, shift);
        s = _mm256_mul_ps(s, m);
        s = _mm256_round_ps(s, _MM_FROUND_TO_NEAREST_INT | _MM_FROUND_NO_EXC);
        _mm256_store_si256((__m256i*)dp, _mm256_cvtps_epi32(s));
      }
    }

    //////////////////////////////////////////////////////////////////////////
    void avx_cnvrt_float_to_si32(const float *sp, si32 *dp, float mul,
                                 int width)
    {
      __m256 m = _mm256_set1_ps(mul);
      for (int i = (width + 7) >> 3; i > 0; --i, sp+=8, dp+=8)
      {
        __m256 t = _mm256_load_ps(sp);
        __m256 s = _mm256_mul_ps(t, m);
        s = _mm256_round_ps(s, _MM_FROUND_TO_NEAREST_INT | _MM_FROUND_NO_EXC);
        _mm256_store_si256((__m256i*)dp, _mm256_cvtps_epi32(s));
      }
    }

    //////////////////////////////////////////////////////////////////////////
    void avx_ict_forward(const float *r, const float *g, const float *b,
                         float *y, float *cb, float *cr, int repeat)
    {
      __m256 alpha_rf = _mm256_set1_ps(CT_CNST::ALPHA_RF);
      __m256 alpha_gf = _mm256_set1_ps(CT_CNST::ALPHA_GF);
      __m256 alpha_bf = _mm256_set1_ps(CT_CNST::ALPHA_BF);
      __m256 beta_cbf = _mm256_set1_ps(CT_CNST::BETA_CbF);
      __m256 beta_crf = _mm256_set1_ps(CT_CNST::BETA_CrF);
      for (int i = (repeat + 7) >> 3; i > 0; --i)
      {
        __m256 mr = _mm256_load_ps(r);
        __m256 mb = _mm256_load_ps(b);
        __m256 my = _mm256_mul_ps(alpha_rf, mr);
        my = _mm256_add_ps(my, _mm256_mul_ps(alpha_gf, _mm256_load_ps(g)));
        my = _mm256_add_ps(my, _mm256_mul_ps(alpha_bf, mb));
        _mm256_store_ps(y, my);
        _mm256_store_ps(cb, _mm256_mul_ps(beta_cbf, _mm256_sub_ps(mb, my)));
        _mm256_store_ps(cr, _mm256_mul_ps(beta_crf, _mm256_sub_ps(mr, my)));

        r += 8; g += 8; b += 8;
        y += 8; cb += 8; cr += 8;
      }
    }

    //////////////////////////////////////////////////////////////////////////
    void avx_ict_backward(const float *y, const float *cb, const float *cr,
                          float *r, float *g, float *b, int repeat)
    {
      __m256 gamma_cr2g = _mm256_set1_ps(CT_CNST::GAMMA_CR2G);
      __m256 gamma_cb2g = _mm256_set1_ps(CT_CNST::GAMMA_CB2G);
      __m256 gamma_cr2r = _mm256_set1_ps(CT_CNST::GAMMA_CR2R);
      __m256 gamma_cb2b = _mm256_set1_ps(CT_CNST::GAMMA_CB2B);
      for (int i = (repeat + 7) >> 3; i > 0; --i)
      {
        __m256 my = _mm256_load_ps(y);
        __m256 mcr = _mm256_load_ps(cr);
        __m256 mcb = _mm256_load_ps(cb);
        __m256 mg = _mm256_sub_ps(my, _mm256_mul_ps(gamma_cr2g, mcr));
        _mm256_store_ps(g, _mm256_sub_ps(mg, _mm256_mul_ps(gamma_cb2g, mcb)));
        _mm256_store_ps(r, _mm256_add_ps(my, _mm256_mul_ps(gamma_cr2r, mcr)));
        _mm256_store_ps(b, _mm256_add_ps(my, _mm256_mul_ps(gamma_cb2b, mcb)));

        y += 8; cb += 8; cr += 8;
        r += 8; g += 8; b += 8;
      }
    }

  }
}
