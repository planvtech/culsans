// Copyright 2022 ETH Zurich and University of Bologna.
// Solderpad Hardware License, Version 0.51, see LICENSE for details.
// SPDX-License-Identifier: SHL-0.51

#include "read_modify_cache.h"
#include "../../sw/include/nb_cores.h"
#include <stdint.h>

extern void exit(int);

#define uint128_t __uint128_t
#define NUM_CACHELINES 256*6
uint128_t data[NB_CORES*NUM_CACHELINES] __attribute__((section(".cache_share_region")));

int read_modify_cache(int cid, int nc)
{
  // initialize the cachelines
  for (int i = 0; i < NUM_CACHELINES; i++) {
    data[cid*NUM_CACHELINES+i] = cid*NUM_CACHELINES+i+1;
    if (data[cid*NUM_CACHELINES+i] != cid*NUM_CACHELINES+i+1)
      exit(cid*NUM_CACHELINES+i+1);
  }

  // modify the cacheline
  for (int i = 0; i < NUM_CACHELINES; i++) {
    data[cid*NUM_CACHELINES+i] *= 10;
    if (data[cid*NUM_CACHELINES+i] != 10*(cid*NUM_CACHELINES+i+1))
      exit(10*(cid*NUM_CACHELINES+i+1));
  }

  return 0;
}
