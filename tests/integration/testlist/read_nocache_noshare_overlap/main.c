// Copyright 2022 ETH Zurich and University of Bologna.
// Solderpad Hardware License, Version 0.51, see LICENSE for details.
// SPDX-License-Identifier: SHL-0.51

#include "read_nocache_noshare_overlap.h"
#include <stdint.h>

// synchronization variable: non-cached and shared
volatile uint64_t count __attribute__((section(".nocache_share_region")));

extern void exit(int);

void thread_entry(int cid, int nc)
{
// core 0 initializes the synchronization variable
if (cid == 0)
count = 0;
else
while(count != cid);

// actual test
read_nocache_noshare_overlap(cid, nc);
count++;

// cores wait here
while(cid)
{ asm volatile ("wfi"); }

// core 0 continues after all cores have finished
if (cid == 0) {
while (count != nc)
{ asm volatile ("nop"); }
}
}

int main()
{
return 0;
}
