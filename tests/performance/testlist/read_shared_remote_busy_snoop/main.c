// Copyright 2022 ETH Zurich and University of Bologna.
// Solderpad Hardware License, Version 0.51, see LICENSE for details.
// SPDX-License-Identifier: SHL-0.51

#include "read_shared_remote_busy_snoop.h"
#include <stdint.h>

void thread_entry(int cid, int nc)
{
  // actual test
  read_shared_remote_busy_snoop(cid, nc);
}

int main()
{
  return 0;
}
