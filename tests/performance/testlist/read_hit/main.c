// Copyright 2022 ETH Zurich and University of Bologna.
// Solderpad Hardware License, Version 0.51, see LICENSE for details.
// SPDX-License-Identifier: SHL-0.51

#include "read_hit.h"
#include <stdint.h>

extern void exit(int);

void thread_entry(int cid, int nc)
{
  // core 0 initializes the synchronization variable
  if (cid == 0)
    // actual test
    read_hit(cid, nc);

  // cores wait here
  while(cid)
    { asm volatile ("wfi"); }
}

int main()
{
  return 0;
}
