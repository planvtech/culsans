// Copyright 2022 ETH Zurich and University of Bologna.
// Solderpad Hardware License, Version 0.51, see LICENSE for details.
// SPDX-License-Identifier: SHL-0.51

`include "ace/assign.svh"
module culsans_tb
    import ariane_pkg::*;
    import snoop_test::*;
    import ace_test::*;
    import tb_ace_ccu_pkg::*;
    import tb_std_cache_subsystem_pkg::*;
#()();

    `define WAIT_CYC(CLK, N) \
        repeat(N) @(posedge(CLK));


    `define WAIT_SIG(CLK,SIG)    \
        do begin                 \
            @(posedge(CLK));     \
        end while(SIG == 1'b0);

    parameter  int unsigned AxiIdWidth       = culsans_pkg::IdWidth;
    parameter  int unsigned AxiAddrWidth     = culsans_pkg::AddrWidth;
    parameter  int unsigned AxiDataWidth     = culsans_pkg::DataWidth;
    localparam int unsigned AxiUserWidth     = culsans_pkg::UserWidth;
    localparam ariane_cfg_t ArianeCfg        = culsans_pkg::ArianeSocCfg;

    localparam time         CLK_PERIOD         = 10ns;
    localparam int unsigned RTC_CLOCK_PERIOD   = 30.517us;
    localparam int unsigned DCACHE_PORTS       = 3;
    localparam int unsigned NB_CORES           = culsans_pkg::NB_CORES;
    localparam int unsigned NUM_WORDS          = 4**10;
    localparam bit          STALL_RANDOM_DELAY = `ifdef TB_AXI_RAND_DELAY  `TB_AXI_RAND_DELAY  `else 1'b1  `endif;
    localparam int unsigned FIXED_AXI_DELAY    = `ifdef TB_AXI_FIXED_DELAY `TB_AXI_FIXED_DELAY `else 0     `endif;
    localparam bit          HAS_LLC            = `ifdef TB_HAS_LLC         `TB_HAS_LLC         `else  1'b1 `endif;
    localparam int unsigned DCACHE_INDEX_DIST = std_cache_pkg::DCACHE_NUM_WORDS * DCACHE_LINE_WIDTH / 8; // Distance between two addresses mapping to the same index

    // The length of cached, shared region is derived from other constants
    localparam int CachedSharedRegionLength =  ArianeCfg.SharedRegionAddrBase[0] + ArianeCfg.SharedRegionLength[0] - ArianeCfg.CachedRegionAddrBase[0];
    initial assert (CachedSharedRegionLength > 0) else $error ("Got negative CachedSharedRegionLength");

    // TB signals
    dcache_req_i_t [NB_CORES][DCACHE_PORTS] dcache_req_ports_i;
    dcache_req_o_t [NB_CORES][DCACHE_PORTS] dcache_req_ports_o;
    logic                                   clk;
    logic                                   rst_n;
    logic                                   rtc;
    logic [31:0]                            exit_val;

    // TB interfaces
    amo_intf                amo_if           [NB_CORES]               (clk);
    dcache_intf             dcache_if        [NB_CORES][DCACHE_PORTS] (clk);
    icache_intf             icache_if        [NB_CORES]               (clk);
    dcache_sram_if          dc_sram_if       [NB_CORES]               (clk);
    dcache_gnt_if           gnt_if           [NB_CORES]               (clk);
    dcache_mgmt_intf        mgmt_if          [NB_CORES]               (clk);

    // verification conponents
    dcache_driver           dcache_drv       [NB_CORES][DCACHE_PORTS];
    dcache_monitor          dcache_mon       [NB_CORES][DCACHE_PORTS];
    dcache_mgmt_driver      dcache_mgmt_drv  [NB_CORES];
    dcache_mgmt_monitor     dcache_mgmt_mon  [NB_CORES];

    icache_driver           icache_drv       [NB_CORES];

    amo_driver              amo_drv          [NB_CORES];
    amo_monitor             amo_mon          [NB_CORES];

    mailbox #(dcache_req)   dcache_req_mbox      [NB_CORES][DCACHE_PORTS];
    mailbox #(dcache_resp)  dcache_resp_mbox     [NB_CORES][DCACHE_PORTS];
    mailbox #(dcache_req)   dcache_req_mbox_fwd  [NB_CORES];
    mailbox #(dcache_resp)  dcache_resp_mbox_fwd [NB_CORES];

    mailbox #(amo_req)      amo_req_mbox      [NB_CORES];
    mailbox #(amo_resp)     amo_resp_mbox     [NB_CORES];
    mailbox #(amo_req)      amo_req_mbox_fwd  [NB_CORES];
    mailbox #(amo_resp)     amo_resp_mbox_fwd [NB_CORES];

    mailbox #(dcache_mgmt_trans) mgmt_mbox   [NB_CORES];

    sram_intf #(
        .NUM_WORDS        (NUM_WORDS),
        .DATA_WIDTH       (AxiDataWidth),
        .DCACHE_SET_ASSOC (DCACHE_SET_ASSOC)
    ) sram_if [NB_CORES] ();

    std_cache_scoreboard #(
        .AXI_ADDR_WIDTH ( AxiAddrWidth ),
        .AXI_DATA_WIDTH ( AxiDataWidth ),
        .AXI_ID_WIDTH   ( AxiIdWidth   ),
        .AXI_USER_WIDTH ( AxiUserWidth )
    ) cache_scbd [NB_CORES];

    std_dcache_checker #(
        .NB_CORES        ( NB_CORES     ),
        .SRAM_DATA_WIDTH ( AxiDataWidth ),
        .SRAM_NUM_WORDS  ( NUM_WORDS    )
    ) dcache_chk;

    // ACE mailboxes
    mailbox aw_mbx [NB_CORES];
    mailbox w_mbx  [NB_CORES];
    mailbox b_mbx  [NB_CORES];
    mailbox ar_mbx [NB_CORES];
    mailbox r_mbx  [NB_CORES];

    // Snoop mailboxes
    mailbox ac_mbx [NB_CORES];
    mailbox cd_mbx [NB_CORES];
    mailbox cr_mbx [NB_CORES];

    //--------------------------------------------------------------------------
    // Clock & reset generation
    //--------------------------------------------------------------------------

    initial begin
        clk   = 1'b0;
        rst_n = 1'b0;

        repeat(8)
            #(CLK_PERIOD/2) clk = ~clk;

        rst_n = 1'b1;

        forever begin
            #(CLK_PERIOD/2) clk = ~clk;
        end

    end


    initial begin
        forever begin
            rtc = 1'b0;
            forever begin
                #(RTC_CLOCK_PERIOD/2) rtc = ~rtc;
            end
        end
    end

    //--------------------------------------------------------------------------
    // DUT
    //--------------------------------------------------------------------------
    culsans_top #(
        .InclSimDTM       (1'b0),
        .NUM_WORDS        (NUM_WORDS), // 4Kwords
        .StallRandomInput (STALL_RANDOM_DELAY),
        .StallRandomOutput(STALL_RANDOM_DELAY),
        .HasLLC           (HAS_LLC),
        .FixedDelayInput  (FIXED_AXI_DELAY),
        .FixedDelayOutput (FIXED_AXI_DELAY),
        .BootAddress      (culsans_pkg::DRAMBase + 64'h10_0000)
    ) i_culsans (
        .clk_i  ( clk      ),
        .rtc_i  ( rtc      ),
        .rst_ni ( rst_n    ),
        .exit_o ( exit_val )
    );

    //--------------------------------------------------------------------------
    // AXI/ACE bus interfaces
    //--------------------------------------------------------------------------

    AXI_BUS #(
        .AXI_ADDR_WIDTH ( AxiAddrWidth               ),
        .AXI_DATA_WIDTH ( AxiDataWidth               ),
        .AXI_ID_WIDTH   ( culsans_pkg::IdWidthToXbar ),
        .AXI_USER_WIDTH ( AxiUserWidth               )
    ) axi_bus [0:0] ();

    AXI_BUS_DV #(
        .AXI_ADDR_WIDTH ( AxiAddrWidth               ),
        .AXI_DATA_WIDTH ( AxiDataWidth               ),
        .AXI_ID_WIDTH   ( culsans_pkg::IdWidthToXbar ),
        .AXI_USER_WIDTH ( AxiUserWidth               )
    ) axi_bus_dv [0:0] (clk);


    ACE_BUS #(
        .AXI_ADDR_WIDTH ( AxiAddrWidth ),
        .AXI_DATA_WIDTH ( AxiDataWidth ),
        .AXI_ID_WIDTH   ( AxiIdWidth   ),
        .AXI_USER_WIDTH ( AxiUserWidth )
    ) ace_bus [NB_CORES-1:0] ();

    ACE_BUS_DV #(
        .AXI_ADDR_WIDTH ( AxiAddrWidth ),
        .AXI_DATA_WIDTH ( AxiDataWidth ),
        .AXI_ID_WIDTH   ( AxiIdWidth   ),
        .AXI_USER_WIDTH ( AxiUserWidth )
    ) ace_bus_dv [NB_CORES-1:0] (clk);


    SNOOP_BUS #(
        .SNOOP_ADDR_WIDTH ( AxiAddrWidth ),
        .SNOOP_DATA_WIDTH ( AxiDataWidth )
    ) snoop_bus [NB_CORES-1:0] ();

    SNOOP_BUS_DV #(
        .SNOOP_ADDR_WIDTH ( AxiAddrWidth ),
        .SNOOP_DATA_WIDTH ( AxiDataWidth )
    ) snoop_bus_dv [NB_CORES-1:0] (clk);


    // connect internal signals to interfaces, connect interfaces to dv interfaces
    `AXI_ASSIGN_MONITOR (axi_bus[0], i_culsans.to_xbar[0])
    `AXI_ASSIGN_MONITOR (axi_bus_dv[0], axi_bus[0])

    for (genvar core_idx=0; core_idx<NB_CORES; core_idx++) begin
        `ACE_ASSIGN_FROM_REQ    (ace_bus   [core_idx], i_culsans.gen_ariane[core_idx].i_ariane.i_cva6.WB.i_cache_subsystem.axi_req_o)
        `ACE_ASSIGN_FROM_RESP   (ace_bus   [core_idx], i_culsans.gen_ariane[core_idx].i_ariane.i_cva6.WB.i_cache_subsystem.axi_resp_i)
        `ACE_ASSIGN_MONITOR   (ace_bus_dv   [core_idx], ace_bus   [core_idx])

        `SNOOP_ASSIGN_FROM_REQ  (snoop_bus [core_idx], i_culsans.gen_ariane[core_idx].i_ariane.i_cva6.WB.i_cache_subsystem.axi_resp_i)
        `SNOOP_ASSIGN_FROM_RESP (snoop_bus [core_idx], i_culsans.gen_ariane[core_idx].i_ariane.i_cva6.WB.i_cache_subsystem.axi_req_o)
        `SNOOP_ASSIGN_MONITOR (snoop_bus_dv [core_idx], snoop_bus [core_idx])
    end

    // AXI/ACE monitors
    ace_monitor #(
        .IW ( AxiIdWidth   ),
        .AW ( AxiAddrWidth ),
        .DW ( AxiDataWidth ),
        .UW ( AxiUserWidth )
    ) ace_mon [NB_CORES-1:0] ;

    snoop_monitor #(
        .AW ( AxiAddrWidth ),
        .DW ( AxiDataWidth )
    ) snoop_mon [NB_CORES-1:0];

    // CCU monitor & scoreboard
    ace_ccu_monitor #(
        .AxiAddrWidth      ( AxiAddrWidth               ),
        .AxiDataWidth      ( AxiDataWidth               ),
        .AxiIdWidthMasters ( AxiIdWidth                 ),
        .AxiIdWidthSlaves  ( culsans_pkg::IdWidthToXbar ),
        .AxiUserWidth      ( AxiUserWidth               ),
        .NoMasters         ( NB_CORES      ),
        .NoSlaves          ( 1                          ),
        .TimeTest          ( 0                          )
    ) ccu_mon;


    //--------------------------------------------------------------------------
    // Create environment
    //--------------------------------------------------------------------------

    bit enable_ccu_mon=1;
    bit ccu_mon_end_check=0;

    initial begin : CCU_MON
        ccu_mon = new(ace_bus_dv, axi_bus_dv, snoop_bus_dv);
        void'($value$plusargs("ENABLE_CCU_MON=%b", enable_ccu_mon));
    end

    final begin : CCU_CHECK
        if (ccu_mon_end_check) begin
            $display("--------------------------------------------------------------------------");
            $display("CCU scoreboard results");
            $display("--------------------------------------------------------------------------");
            ccu_mon.print_result();
            $display("--------------------------------------------------------------------------");
        end
    end

    for (genvar core_idx=0; core_idx<NB_CORES; core_idx++) begin : CORE

        initial begin : ACE_MON
            aw_mbx [core_idx] = new();
            w_mbx  [core_idx] = new();
            b_mbx  [core_idx] = new();
            ar_mbx [core_idx] = new();
            r_mbx  [core_idx] = new();

            ace_mon[core_idx] = new(ace_bus_dv[core_idx]);

            ace_mon[core_idx].aw_mbx = aw_mbx [core_idx];
            ace_mon[core_idx].w_mbx  = w_mbx  [core_idx];
            ace_mon[core_idx].b_mbx  = b_mbx  [core_idx];
            ace_mon[core_idx].ar_mbx = ar_mbx [core_idx];
            ace_mon[core_idx].r_mbx  = r_mbx  [core_idx];
        end

        initial begin : SNOOP_MON
            ac_mbx [core_idx] = new();
            cd_mbx [core_idx] = new();
            cr_mbx [core_idx] = new();

            snoop_mon[core_idx] = new(snoop_bus_dv[core_idx]);

            snoop_mon[core_idx].ac_mbx = ac_mbx[core_idx];
            snoop_mon[core_idx].cd_mbx = cd_mbx[core_idx];
            snoop_mon[core_idx].cr_mbx = cr_mbx[core_idx];
        end

        // assign SRAM IF
        `ifdef USE_XILINX_SRAM
            assign dc_sram_if[core_idx].vld_sram_xilinx  = i_culsans.gen_ariane[core_idx].i_ariane.i_cva6.WB.i_cache_subsystem.i_nbdcache.valid_dirty_sram.i_tc_sram.gen_1_ports.i_xpm_memory_spram.xpm_memory_base_inst.mem;
        `else
            assign dc_sram_if[core_idx].vld_sram  = i_culsans.gen_ariane[core_idx].i_ariane.i_cva6.WB.i_cache_subsystem.i_nbdcache.valid_dirty_sram.i_tc_sram.sram;
        `endif


        assign dc_sram_if[core_idx].vld_req   = i_culsans.gen_ariane[core_idx].i_ariane.i_cva6.WB.i_cache_subsystem.i_nbdcache.valid_dirty_sram.req_i;
        assign dc_sram_if[core_idx].vld_we    = i_culsans.gen_ariane[core_idx].i_ariane.i_cva6.WB.i_cache_subsystem.i_nbdcache.valid_dirty_sram.we_i;
        assign dc_sram_if[core_idx].vld_index = i_culsans.gen_ariane[core_idx].i_ariane.i_cva6.WB.i_cache_subsystem.i_nbdcache.valid_dirty_sram.addr_i;
        for (genvar i = 0; i<DCACHE_SET_ASSOC; i++) begin : sram_block
            `ifdef USE_XILINX_SRAM
                assign dc_sram_if[core_idx].tag_sram_xilinx[i]  = i_culsans.gen_ariane[core_idx].i_ariane.i_cva6.WB.i_cache_subsystem.i_nbdcache.sram_block[i].tag_sram.i_tc_sram.gen_1_ports.i_xpm_memory_spram.xpm_memory_base_inst.mem;
                assign dc_sram_if[core_idx].data_sram_xilinx[i] = i_culsans.gen_ariane[core_idx].i_ariane.i_cva6.WB.i_cache_subsystem.i_nbdcache.sram_block[i].data_sram.i_tc_sram.gen_1_ports.i_xpm_memory_spram.xpm_memory_base_inst.mem;
            `else
                assign dc_sram_if[core_idx].tag_sram[i]  = i_culsans.gen_ariane[core_idx].i_ariane.i_cva6.WB.i_cache_subsystem.i_nbdcache.sram_block[i].tag_sram.i_tc_sram.sram;
                assign dc_sram_if[core_idx].data_sram[i] = i_culsans.gen_ariane[core_idx].i_ariane.i_cva6.WB.i_cache_subsystem.i_nbdcache.sram_block[i].data_sram.i_tc_sram.sram;
            `endif
        end

        // assign Grant IF
        assign gnt_if[core_idx].gnt[0] = i_culsans.gen_ariane[core_idx].i_ariane.i_cva6.WB.i_cache_subsystem.i_nbdcache.gnt[0] &&
            i_culsans.gen_ariane[core_idx].i_ariane.i_cva6.WB.i_cache_subsystem.i_nbdcache.we[0];

        assign gnt_if[core_idx].gnt[1] = i_culsans.gen_ariane[core_idx].i_ariane.i_cva6.WB.i_cache_subsystem.i_nbdcache.gnt[1] &&
            !(|i_culsans.gen_ariane[core_idx].i_ariane.i_cva6.WB.i_cache_subsystem.i_nbdcache.updating_cache);

        assign gnt_if[core_idx].gnt[2] = i_culsans.gen_ariane[core_idx].i_ariane.i_cva6.WB.i_cache_subsystem.i_nbdcache.gnt[2] &&
            i_culsans.gen_ariane[core_idx].i_ariane.i_cva6.WB.i_cache_subsystem.i_nbdcache.we[2];

        assign gnt_if[core_idx].gnt[3] = i_culsans.gen_ariane[core_idx].i_ariane.i_cva6.WB.i_cache_subsystem.i_nbdcache.gnt[3] &&
            i_culsans.gen_ariane[core_idx].i_ariane.i_cva6.WB.i_cache_subsystem.i_nbdcache.we[3];

        assign gnt_if[core_idx].gnt[4] = i_culsans.gen_ariane[core_idx].i_ariane.i_cva6.WB.i_cache_subsystem.i_nbdcache.gnt[4] &&
            i_culsans.gen_ariane[core_idx].i_ariane.i_cva6.WB.i_cache_subsystem.i_nbdcache.we[4];

        for (genvar p=0; p<5; p++) begin
            assign gnt_if[core_idx].req[p] = |i_culsans.gen_ariane[core_idx].i_ariane.i_cva6.WB.i_cache_subsystem.i_nbdcache.req[p];
        end

        assign gnt_if[core_idx].rd_gnt = i_culsans.gen_ariane[core_idx].i_ariane.i_cva6.WB.i_cache_subsystem.i_nbdcache.gnt;

        assign gnt_if[core_idx].snoop_wr_gnt = i_culsans.gen_ariane[core_idx].i_ariane.i_cva6.WB.i_cache_subsystem.i_nbdcache.gnt[1] &&
            i_culsans.gen_ariane[core_idx].i_ariane.i_cva6.WB.i_cache_subsystem.i_nbdcache.we[1];


        assign gnt_if[core_idx].bypass_gnt[0] = i_culsans.gen_ariane[core_idx].i_ariane.i_cva6.WB.i_cache_subsystem.i_nbdcache.bypass_gnt[0];
        assign gnt_if[core_idx].bypass_gnt[1] = i_culsans.gen_ariane[core_idx].i_ariane.i_cva6.WB.i_cache_subsystem.i_nbdcache.bypass_gnt[1];
        assign gnt_if[core_idx].bypass_gnt[2] = i_culsans.gen_ariane[core_idx].i_ariane.i_cva6.WB.i_cache_subsystem.i_nbdcache.bypass_gnt[2];

        assign gnt_if[core_idx].miss_gnt[0] = i_culsans.gen_ariane[core_idx].i_ariane.i_cva6.WB.i_cache_subsystem.i_nbdcache.miss_gnt[0];
        assign gnt_if[core_idx].miss_gnt[1] = i_culsans.gen_ariane[core_idx].i_ariane.i_cva6.WB.i_cache_subsystem.i_nbdcache.miss_gnt[1];
        assign gnt_if[core_idx].miss_gnt[2] = i_culsans.gen_ariane[core_idx].i_ariane.i_cva6.WB.i_cache_subsystem.i_nbdcache.miss_gnt[2];

        // priority encoding of wr_gnt.
        assign gnt_if[core_idx].wr_gnt[0] = (i_culsans.gen_ariane[core_idx].i_ariane.i_cva6.WB.i_cache_subsystem.i_nbdcache.i_miss_handler.state_q == 0) && // IDLE
                                            (i_culsans.gen_ariane[core_idx].i_ariane.i_cva6.WB.i_cache_subsystem.i_nbdcache.master_ports[1].i_cache_ctrl.miss_req_o.valid &&
                                             !i_culsans.gen_ariane[core_idx].i_ariane.i_cva6.WB.i_cache_subsystem.i_nbdcache.master_ports[1].i_cache_ctrl.miss_req_o.bypass);

        assign gnt_if[core_idx].wr_gnt[1] = (i_culsans.gen_ariane[core_idx].i_ariane.i_cva6.WB.i_cache_subsystem.i_nbdcache.i_miss_handler.state_q == 0) && // IDLE
                                            (i_culsans.gen_ariane[core_idx].i_ariane.i_cva6.WB.i_cache_subsystem.i_nbdcache.master_ports[2].i_cache_ctrl.miss_req_o.valid &&
                                             !i_culsans.gen_ariane[core_idx].i_ariane.i_cva6.WB.i_cache_subsystem.i_nbdcache.master_ports[2].i_cache_ctrl.miss_req_o.bypass) &&
                                            !(i_culsans.gen_ariane[core_idx].i_ariane.i_cva6.WB.i_cache_subsystem.i_nbdcache.master_ports[1].i_cache_ctrl.miss_req_o.valid &&
                                             !i_culsans.gen_ariane[core_idx].i_ariane.i_cva6.WB.i_cache_subsystem.i_nbdcache.master_ports[1].i_cache_ctrl.miss_req_o.bypass);

        assign gnt_if[core_idx].wr_gnt[2] = (i_culsans.gen_ariane[core_idx].i_ariane.i_cva6.WB.i_cache_subsystem.i_nbdcache.i_miss_handler.state_q == 0) && // IDLE
                                            (i_culsans.gen_ariane[core_idx].i_ariane.i_cva6.WB.i_cache_subsystem.i_nbdcache.master_ports[3].i_cache_ctrl.miss_req_o.valid &&
                                             !i_culsans.gen_ariane[core_idx].i_ariane.i_cva6.WB.i_cache_subsystem.i_nbdcache.master_ports[3].i_cache_ctrl.miss_req_o.bypass) &&
                                            !(i_culsans.gen_ariane[core_idx].i_ariane.i_cva6.WB.i_cache_subsystem.i_nbdcache.master_ports[2].i_cache_ctrl.miss_req_o.valid &&
                                             !i_culsans.gen_ariane[core_idx].i_ariane.i_cva6.WB.i_cache_subsystem.i_nbdcache.master_ports[2].i_cache_ctrl.miss_req_o.bypass) &&
                                            !(i_culsans.gen_ariane[core_idx].i_ariane.i_cva6.WB.i_cache_subsystem.i_nbdcache.master_ports[1].i_cache_ctrl.miss_req_o.valid &&
                                             !i_culsans.gen_ariane[core_idx].i_ariane.i_cva6.WB.i_cache_subsystem.i_nbdcache.master_ports[1].i_cache_ctrl.miss_req_o.bypass);

        assign gnt_if[core_idx].mshr_match[0] = i_culsans.gen_ariane[core_idx].i_ariane.i_cva6.WB.i_cache_subsystem.i_nbdcache.mshr_addr_matches[0];
        assign gnt_if[core_idx].mshr_match[1] = i_culsans.gen_ariane[core_idx].i_ariane.i_cva6.WB.i_cache_subsystem.i_nbdcache.mshr_addr_matches[1];
        assign gnt_if[core_idx].mshr_match[2] = i_culsans.gen_ariane[core_idx].i_ariane.i_cva6.WB.i_cache_subsystem.i_nbdcache.mshr_index_matches[2];

        assign gnt_if[core_idx].way    = i_culsans.gen_ariane[core_idx].i_ariane.i_cva6.WB.i_cache_subsystem.i_nbdcache.req_ram;
        assign gnt_if[core_idx].be_vld = i_culsans.gen_ariane[core_idx].i_ariane.i_cva6.WB.i_cache_subsystem.i_nbdcache.be_valid_dirty_ram;

        // assign management IF
        assign i_culsans.gen_ariane[core_idx].i_ariane.i_cva6.dcache_en_csr_nbdcache  = mgmt_if[core_idx].dcache_enable;
        assign i_culsans.gen_ariane[core_idx].i_ariane.i_cva6.dcache_flush_ctrl_cache = mgmt_if[core_idx].dcache_flush;
        assign mgmt_if[core_idx].dcache_flushing  = i_culsans.gen_ariane[core_idx].i_ariane.i_cva6.WB.i_cache_subsystem.i_nbdcache.flushing;
        assign mgmt_if[core_idx].dcache_flush_ack = i_culsans.gen_ariane[core_idx].i_ariane.i_cva6.dcache_flush_ack_cache_ctrl;
        assign mgmt_if[core_idx].dcache_miss      = i_culsans.gen_ariane[core_idx].i_ariane.i_cva6.dcache_miss_cache_perf;
        assign mgmt_if[core_idx].wbuffer_empty    = i_culsans.gen_ariane[core_idx].i_ariane.i_cva6.dcache_commit_wbuffer_empty;

        initial begin : DCACHE_MGMT_DRV
            dcache_mgmt_drv[core_idx] = new(mgmt_if[core_idx], $sformatf("%s[%0d]","dcache_mgmt_driver",core_idx));
        end
        initial begin : DCACHE_MGMT_MON
            mgmt_mbox[core_idx] = new();
            dcache_mgmt_mon[core_idx] = new(mgmt_if[core_idx], $sformatf("%s[%0d]","dcache_mgmt_monitor",core_idx));
            dcache_mgmt_mon[core_idx].mbox = mgmt_mbox[core_idx];
        end


        initial begin : ICACHE_DRV
            icache_drv[core_idx] = new(icache_if[core_idx], ArianeCfg, $sformatf("%s[%0d]","icache_driver",core_idx));

        end

        assign i_culsans.gen_ariane[core_idx].i_ariane.i_cva6.icache_dreq_if_cache = icache_if[core_idx].req;
        assign icache_if[core_idx].resp = i_culsans.gen_ariane[core_idx].i_ariane.i_cva6.icache_dreq_cache_if;


        for (genvar port=0; port<=2; port++) begin : PORT
            // assign dcache request/response to dcache_if
            assign i_culsans.gen_ariane[core_idx].i_ariane.i_cva6.dcache_req_ports_ex_cache[port] = dcache_if[core_idx][port].req;
            assign dcache_if[core_idx][port].resp   = i_culsans.gen_ariane[core_idx].i_ariane.i_cva6.dcache_req_ports_cache_ex[port];
            assign dcache_if[core_idx][port].wr_gnt = i_culsans.gen_ariane[core_idx].i_ariane.i_cva6.WB.i_cache_subsystem.i_nbdcache.gnt[port+2] &&
                                                      //i_culsans.gen_ariane[core_idx].i_ariane.i_cva6.WB.i_cache_subsystem.i_nbdcache.start_ack[port+2] &&
                                                      (i_culsans.gen_ariane[core_idx].i_ariane.i_cva6.WB.i_cache_subsystem.i_nbdcache.master_ports[port+1].i_cache_ctrl.state_q == 0); // IDLE


            initial begin : DCACHE_MON
                dcache_req_mbox  [core_idx][port] = new();
                dcache_resp_mbox [core_idx][port] = new();

                dcache_mon[core_idx][port] = new(dcache_if[core_idx][port], port, $sformatf("%s[%0d][%0d]","dcache_monitor",core_idx, port));

                dcache_mon[core_idx][port].req_mbox  = dcache_req_mbox[core_idx][port];
                dcache_mon[core_idx][port].resp_mbox = dcache_resp_mbox[core_idx][port];
            end

            initial begin : DCACHE_DRV
                dcache_drv[core_idx][port] = new(dcache_if[core_idx][port], ArianeCfg, $sformatf("%s[%0d][%0d]","dcache_driver",core_idx, port));
            end

            // force different AXI IDs for testbench purposes
            initial begin : FORCE_AXI_ID
                automatic logic axi_id_per_port = 0;
                logic enable_axi_id_per_port;
                if ($value$plusargs("ENABLE_AXI_ID_PER_PORT=%d", enable_axi_id_per_port)) begin
                    axi_id_per_port = enable_axi_id_per_port;
                end

                if (axi_id_per_port) begin
                    force i_culsans.gen_ariane[core_idx].i_ariane.i_cva6.WB.i_cache_subsystem.i_nbdcache.i_miss_handler.req_fsm_miss_id =
                        4'hC + i_culsans.gen_ariane[core_idx].i_ariane.i_cva6.WB.i_cache_subsystem.i_nbdcache.i_miss_handler.mshr_q.id;
                    // disable assertions checking AXI IDs
                    $assertoff(0,i_culsans.gen_ariane[core_idx].i_ariane.i_cva6.WB.i_cache_subsystem.a_axi_data_awid);
                    $assertoff(0,i_culsans.gen_ariane[core_idx].i_ariane.i_cva6.WB.i_cache_subsystem.a_axi_data_arid);
                    #0;
                    cache_scbd[core_idx].axi_id_per_port = 1;
                end
            end


            //------------------------------------------------------------------
            // check that the read responds match the read requests
            //------------------------------------------------------------------
            int cnt = 0;
            logic check_neg = 1;
            logic check_pos = 1;
            always @ (posedge clk) begin
                if (dcache_if[core_idx][port].req.data_req && !dcache_if[core_idx][port].req.data_we && dcache_if[core_idx][port].resp.data_gnt) begin
                    cnt++;
                end
                if (dcache_if[core_idx][port].resp.data_rvalid) begin
                    cnt--;
                end

                a_rd_resp_neg : assert (!check_neg || cnt >= 0) else begin
                   $error("too many read responds in core %0d, dcache port %0d", core_idx, port);
                    check_neg = 0;
                end

                a_rd_resp_pos : assert (!check_pos || cnt <= 2) else begin
                   $error("too many outstanding read requests in core %0d, dcache port %0d", core_idx, port);
                    check_pos = 0;
                end
            end
            final a_req_resp_match : assert (cnt == 0) else $error("read requests and responds dont match in core %0d, dcache port %0d", core_idx, port);

        end

        // assign AMO IF
        assign i_culsans.gen_ariane[core_idx].i_ariane.i_cva6.amo_req = amo_if[core_idx].req;
        assign amo_if[core_idx].resp = i_culsans.gen_ariane[core_idx].i_ariane.i_cva6.amo_resp;
        assign amo_if[core_idx].gnt  = (i_culsans.gen_ariane[core_idx].i_ariane.i_cva6.WB.i_cache_subsystem.i_nbdcache.i_miss_handler.state_q == 0) && // IDLE
                                       (i_culsans.gen_ariane[core_idx].i_ariane.i_cva6.WB.i_cache_subsystem.i_nbdcache.i_miss_handler.busy_i  == 0);
        initial begin : AMO_MON
            amo_req_mbox  [core_idx] = new();
            amo_resp_mbox [core_idx] = new();

            amo_mon[core_idx] = new(amo_if[core_idx], $sformatf("%s[%0d]","amo_monitor",core_idx));

            amo_mon[core_idx].req_mbox  = amo_req_mbox[core_idx];
            amo_mon[core_idx].resp_mbox = amo_resp_mbox[core_idx];
        end

        initial begin : AMO_DRV
            amo_drv[core_idx] = new(amo_if[core_idx], ArianeCfg, $sformatf("%s[%0d]","amo_driver",core_idx));
        end

        initial begin : CACHE_SCBD
            cache_scbd[core_idx] = new(dc_sram_if[core_idx], gnt_if[core_idx], ArianeCfg, $sformatf("%s[%0d]","dcache_scoreboard",core_idx));
            amo_req_mbox_fwd      [core_idx] = new();
            amo_resp_mbox_fwd     [core_idx] = new();
            dcache_req_mbox_fwd   [core_idx] = new();
            dcache_resp_mbox_fwd  [core_idx] = new();

            for (int port=0; port<=2; port++) begin : PORT
                cache_scbd[core_idx].dcache_req_mbox[port]  = dcache_req_mbox  [core_idx][port];
                cache_scbd[core_idx].dcache_resp_mbox[port] = dcache_resp_mbox [core_idx][port];
            end
            cache_scbd[core_idx].dcache_req_mbox_fwd   = dcache_req_mbox_fwd   [core_idx];
            cache_scbd[core_idx].dcache_resp_mbox_fwd  = dcache_resp_mbox_fwd  [core_idx];

            cache_scbd[core_idx].amo_req_mbox      = amo_req_mbox      [core_idx];
            cache_scbd[core_idx].amo_resp_mbox     = amo_resp_mbox     [core_idx];
            cache_scbd[core_idx].amo_req_mbox_fwd  = amo_req_mbox_fwd  [core_idx];
            cache_scbd[core_idx].amo_resp_mbox_fwd = amo_resp_mbox_fwd [core_idx];

            cache_scbd[core_idx].aw_mbx_pre_filt   = aw_mbx            [core_idx];
            cache_scbd[core_idx].w_mbx_pre_filt    = w_mbx             [core_idx];
            cache_scbd[core_idx].b_mbx_pre_filt    = b_mbx             [core_idx];
            cache_scbd[core_idx].ar_mbx_pre_filt   = ar_mbx            [core_idx];
            cache_scbd[core_idx].r_mbx_pre_filt    = r_mbx             [core_idx];

            cache_scbd[core_idx].ac_mbx            = ac_mbx            [core_idx];
            cache_scbd[core_idx].cd_mbx            = cd_mbx            [core_idx];
            cache_scbd[core_idx].cr_mbx            = cr_mbx            [core_idx];

            cache_scbd[core_idx].mgmt_mbox         = mgmt_mbox         [core_idx];
        end

        // assign SRAM IF
        for (genvar w=0; w<DCACHE_SET_ASSOC; w++) begin
            `ifdef USE_XILINX_SRAM
                assign sram_if[core_idx].data[w][0] = i_culsans.i_sram.i_tc_sram.gen_1_ports.i_xpm_memory_spram.xpm_memory_base_inst.mem[sram_if[core_idx].addr[w]];
                assign sram_if[core_idx].data[w][1] = i_culsans.i_sram.i_tc_sram.gen_1_ports.i_xpm_memory_spram.xpm_memory_base_inst.mem[sram_if[core_idx].addr[w]+1];
            `else
                assign sram_if[core_idx].data[w][0] = i_culsans.i_sram.i_tc_sram.sram[sram_if[core_idx].addr[w]];
                assign sram_if[core_idx].data[w][1] = i_culsans.i_sram.i_tc_sram.sram[sram_if[core_idx].addr[w]+1];
            `endif
        end

    end


    bit enable_mem_check=1;
    initial begin
        dcache_chk = new(sram_if, dc_sram_if, ArianeCfg, "dcache_checker");
        void'($value$plusargs("ENABLE_MEM_CHECK=%b", enable_mem_check));
        dcache_chk.enable_mem_check = enable_mem_check;

        for (int core_idx=0; core_idx<NB_CORES; core_idx++) begin : CORE
            dcache_chk.amo_req_mbox[core_idx]  = amo_req_mbox_fwd  [core_idx];
            dcache_chk.amo_resp_mbox[core_idx] = amo_resp_mbox_fwd [core_idx];

            dcache_chk.dcache_req_mbox[core_idx]  = dcache_req_mbox_fwd  [core_idx];
            dcache_chk.dcache_resp_mbox[core_idx] = dcache_resp_mbox_fwd [core_idx];
        end
    end

    task automatic start_amo_monitor;
        fork
            dcache_chk.check_amo_lock();
        join_none
    endtask

    // start all monitors
    task automatic start_monitors;
        fork
            for (int c=0; c<NB_CORES; c++) begin : CORE
                fork
                    automatic int core_idx = c;
                    begin
                        for (int p=0; p<=2; p++) begin : PORT
                            fork
                                automatic int port = p;
                                begin
                                    dcache_mon[core_idx][port].monitor();
                                end
                            join_none
                        end
                    end
                    ace_mon[core_idx].monitor();
                    snoop_mon[core_idx].monitor();
                    amo_mon[core_idx].monitor();
                    dcache_mgmt_mon[core_idx].monitor();
                    cache_scbd[core_idx].run();
                join_none
            end
            if (enable_ccu_mon) begin
                ccu_mon_end_check = 1;
                ccu_mon.run();
            end
            dcache_chk.monitor();
        join_none
    endtask



    //--------------------------------------------------------------------------
    // Tests
    //--------------------------------------------------------------------------

    task automatic test_header (string testname, string description="");
        $display("--------------------------------------------------------------------------");
        $display("Running test %s", testname);
        $display("%s", description);
        $display("--------------------------------------------------------------------------");
    endtask

    int timeout = 500000; // default
    int wait_time = 0;
    int test_id = -1;
    int rep_cnt;
    // select one core randomly for tests that need one core that behaves differently
    int cid = $urandom_range(NB_CORES-1);
    // select one more core for tests that need two specific cores
    int cid2 = (cid + (NB_CORES/2)) % NB_CORES;

    initial begin : TESTS
        logic [63:0] addr, base_addr;
        logic [63:0] data, base_data;
        static logic enable_icache_random_gen = 0;

        automatic string testname="";
        if (!$value$plusargs("TESTNAME=%s", testname)) begin
            $error("No TESTNAME plusarg given");
        end

        void'($value$plusargs("ENABLE_ICACHE_RANDOM_GEN=%b", enable_icache_random_gen));

        // The tests assume that the address regions are arranged in increaisng address order:
        // - non-cached, non-shared
        // - shared, non-cached
        // - cached, shared
        // - cached, non-shared
        a_shared_gt_nonshared: assert (ArianeCfg.SharedRegionAddrBase[0] >= 64'(culsans_pkg::DRAMBase)) else
            $error("Non-cached, shared region must be after non-cached, non-shared region");
        a_cached_gt_shared: assert (ArianeCfg.CachedRegionAddrBase[0] >= ArianeCfg.SharedRegionAddrBase[0]) else
            $error("Cached, shared region must be after non-cached, shared region");

        fork

            begin

                `WAIT_SIG(clk, rst_n)
                start_monitors();
                `WAIT_CYC(clk, 300)
                `WAIT_CYC(clk, 1500) // wait some more for LLC initialization

                if (enable_icache_random_gen) begin
                    for (int c=0; c < NB_CORES; c++) begin
                        icache_drv[c].start_random_req();
                    end
                end

                case (testname)

                    // - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
                    "read_miss" : begin
                        test_header(testname, "8 consecutive read misses in the same cache set");

                        addr = ArianeCfg.CachedRegionAddrBase[0];

                        // write to address 0-7 and then some more
                        for (int i=0; i<16; i++) begin
                            dcache_drv[cid][2].wr(.addr(addr + (i << DCACHE_INDEX_WIDTH)), .data(i));
                        end


                        // read miss x 8 - fill cache 0
                        for (int i=0; i<8; i++) begin
                            dcache_drv[cid][1].rd(.addr(addr + (i << DCACHE_INDEX_WIDTH)));
                        end

                        `WAIT_CYC(clk, 100)
                    end

                    // - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
                    "write_collision" : begin
                        test_header(testname, "Part 1 : Write conflicts to single address");

                        addr = ArianeCfg.CachedRegionAddrBase[0];

                        // make sure data 0 is in cache
                        for (int c=0; c < NB_CORES; c++) begin
                            dcache_drv[c][0].rd(.addr(addr));
                            `WAIT_CYC(clk, 100)
                        end

                        // simultaneous writes to same address
                        fork begin // this is needed to make sure the "wait fork" below doesn't affect forks outside this scope
                            for (int i=0; i<100; i++) begin
                                for (int c=0; c < NB_CORES; c++) begin
                                    fork
                                        automatic int cc = c;
                                        begin
                                            if (cc == cid) begin
                                                dcache_drv[cc][2].wr(.addr(addr), .data(64'hBEEFCAFE0000 + i), .rand_size_be(1));
                                                `WAIT_CYC(clk, 10)
                                                dcache_drv[cc][2].wr(.addr(addr), .data(64'hBEEFCAFE0100 + i), .rand_size_be(1));
                                            end else begin
                                                dcache_drv[cc][2].wr(.addr(addr), .data(64'hBAADF00D0000 + i), .rand_size_be(1));
                                                `WAIT_CYC(clk, ((i+cc)%19))
                                                dcache_drv[cc][2].wr(.addr(addr), .data(64'hDEADABBA0000 + i), .rand_size_be(1));
                                            end
                                        end
                                    join_none
                                end
                                wait fork;
                            end
                        end join

                        `WAIT_CYC(clk, 100)

                        test_header(testname, "Part 2 : Write conflicts to addresses in the same cache set");

                        // simultaneous writes to same set
                        fork begin // this is needed to make sure the "wait fork" below doesn't affect forks outside this scope
                            for (int i=0; i<100; i++) begin
                                for (int c=0; c < NB_CORES; c++) begin
                                    fork
                                        automatic int cc = c;
                                        begin
                                            if (cc == cid) begin
                                                dcache_drv[cc][2].wr(.addr(addr + ((i%8) << DCACHE_INDEX_WIDTH) + 8*$urandom_range(1)), .data(64'hBEEFCAFE0000 + i), .rand_size_be(1));
                                                `WAIT_CYC(clk, 10)
                                                dcache_drv[cc][2].wr(.addr(addr + ((i%8) << DCACHE_INDEX_WIDTH) + 8*$urandom_range(1)), .data(64'hBEEFCAFE0100 + i), .rand_size_be(1));
                                                `WAIT_CYC(clk, 10)
                                            end else begin
                                                dcache_drv[cc][2].wr(.addr(addr + ((i%8) << DCACHE_INDEX_WIDTH) + 8*$urandom_range(1)), .data(64'hBAADF00D0000 + i), .rand_size_be(1));
                                                `WAIT_CYC(clk, (i+cc)%19)
                                                dcache_drv[cc][2].wr(.addr(addr + ((i%8) << DCACHE_INDEX_WIDTH) + 8*$urandom_range(1)), .data(64'hDEADABBA0000 + i), .rand_size_be(1));
                                                `WAIT_CYC(clk, 10)
                                            end
                                        end
                                    join_none
                                end
                                wait fork;
                            end
                        end join

                    end

                    // - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
                    "read_collision" : begin
                        test_header(testname, "Trigger colliding_read in cache controllers");

                        addr = ArianeCfg.CachedRegionAddrBase[0] + $urandom_range(256) * 16;
                        rep_cnt = 400 / NB_CORES;
                        wait_time = 2000;
                        timeout = 1000000;

                        for (int core_idx=0; core_idx<NB_CORES; core_idx++) begin : CORE
                            cache_scbd[core_idx].set_cache_msg_timeout(wait_time);
                        end


                        for (int i=0; i < rep_cnt; i++) begin
                            test_id = i;
                            // make sure data is shared in all caches
                            for (int c=0; c < NB_CORES; c++) begin
                                dcache_drv[c][1].rd(.do_wait(1), .addr(addr));
                            end

                            // overwrite data in all but one cache by reading in other data to the same cache entry
                            for (int c=0; c < NB_CORES; c++) begin
                                logic [63:0] laddr;
                                if (c != cid) begin
                                    for (int i=1; i<16; i++) begin
                                        laddr = addr + (i << DCACHE_INDEX_WIDTH);
                                        dcache_drv[c][1].rd(.do_wait(1), .addr(laddr));
                                    end
                                end
                            end

                            fork begin // this fork is needed to make sure the "wait fork" below doesn't affect forks outside this scope
                                for (int c=0; c < NB_CORES; c++) begin
                                    fork
                                        automatic int         cc     = c;
                                        // target one 32 bit word inside the 128 bit cacheline
                                        automatic int         offset = $urandom_range(3);
                                        // be is either 00001111 or 11110000 depending on offset
                                        automatic logic [7:0] be     = 8'b00001111 << 4 * (offset % 2);
                                        begin
                                            `WAIT_CYC(clk, $urandom_range(10))
                                            // write in one core while the others read
                                            if (cc == cid) begin
                                                fork
                                                    begin
                                                        // write the target cacheline
                                                        `WAIT_CYC(clk, 5)
                                                        dcache_drv[cc][2].wr(.addr(addr + (offset*4)), .rand_data(1), .size(2'b10), .be(be));
                                                    end
                                                    begin
                                                        // read some other cacheline - compete withe the write above
                                                        `WAIT_CYC(clk, $urandom_range(10))
                                                        dcache_drv[cc][1].rd(.addr(addr + $urandom_range(2,1024) * 8));
                                                    end
                                                join
                                            end else begin
                                                // read the target cacheline
                                                `WAIT_CYC(clk, 5)
                                                dcache_drv[cc][1].rd(.do_wait(1), .addr(addr + (offset*4)), .size(2'b10), .be(be));
                                            end
                                        end
                                    join_none
                                end
                                wait fork;
                            end join
                        end

                        $display("***\n*** Test finished, waiting %0d cycles to catch possible timeouts\n***",wait_time);
                        `WAIT_CYC(clk, wait_time)

                    end


                    // - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
                    "read_write_collision" : begin
                        test_header(testname, "Part 1 : Write + read conflicts to single address");

                        addr = ArianeCfg.CachedRegionAddrBase[0];
                        rep_cnt = 400 / NB_CORES;

                        // make sure data 0 is in cache
                        for (int c=0; c < NB_CORES; c++) begin
                            dcache_drv[c][0].rd(.addr(addr));
                            `WAIT_CYC(clk, 100)
                        end

                        // simultaneous writes and read to same address
                        fork begin // this is needed to make sure the "wait fork" below doesn't affect forks outside this scope
                            for (int i=0; i<rep_cnt; i++) begin
                                for (int c=0; c < NB_CORES; c++) begin
                                    fork
                                        automatic int cc = c;
                                        begin
                                            `WAIT_CYC(clk, $urandom_range(5))
                                            if ($urandom_range(1)) begin
                                                dcache_drv[cc][0].rd(.addr(addr), .rand_size_be(1), .rand_kill(10));
                                            end else begin
                                                dcache_drv[cc][2].wr(.addr(addr), .data(64'hBAADF00D0000 + i), .rand_size_be(1));
                                            end
                                        end
                                    join_none
                                end
                                wait fork;
                            end
                        end join

                        `WAIT_CYC(clk, 100)

                        test_header(testname, "Part 2 : Write + read conflicts to addresses in the same cache set");
                        rep_cnt = 2000 / NB_CORES;

                        // read x 8 - fill cache set 0 in CPU 0
                        for (int c=0; c < NB_CORES; c++) begin
                            for (int i=0; i<8; i++) begin
                                dcache_drv[c][1].rd(.addr(addr + (i << DCACHE_INDEX_WIDTH)), .rand_size_be(1));
                            end
                        end

                        // simultaneous writes and reads to same set
                        fork begin // this is needed to make sure the "wait fork" below doesn't affect forks outside this scope
                            for (int i=0; i<rep_cnt; i++) begin
                                for (int c=0; c < NB_CORES; c++) begin
                                    fork
                                        automatic int cc = c;
                                        automatic int sel = $urandom_range(3);
                                        begin
                                            `WAIT_CYC(clk, $urandom_range(10))
                                            case (sel)
                                                0 : begin // Wr Wr
                                                    dcache_drv[cc][2].wr(.addr(addr + ((i%8) << DCACHE_INDEX_WIDTH)),     .data(64'hBEEFCAFE0000 + i), .rand_size_be(1));
                                                    `WAIT_CYC(clk, $urandom_range(20))
                                                    dcache_drv[cc][2].wr(.addr(addr + ((i%8) << DCACHE_INDEX_WIDTH) + 8), .data(64'hBEEFCAFE0100 + i), .rand_size_be(1));
                                                end
                                                1 : begin // Wr Rd
                                                    dcache_drv[cc][2].wr(             .addr(addr + ((i%8) << DCACHE_INDEX_WIDTH)), .data(64'hBEEFCAFE0000 + i), .rand_size_be(1));
                                                    `WAIT_CYC(clk, $urandom_range(20))
                                                    dcache_drv[cc][0].rd(.do_wait(1), .addr(addr + ((i%8) << DCACHE_INDEX_WIDTH) + 8), .rand_size_be(1), .rand_kill(5));
                                                end

                                                2 : begin // Rd Wr
                                                    dcache_drv[cc][0].rd(.do_wait(1), .addr(addr + ((i%8) << DCACHE_INDEX_WIDTH)), .rand_size_be(1), .rand_kill(5));
                                                    `WAIT_CYC(clk, $urandom_range(20))
                                                    dcache_drv[cc][2].wr(             .addr(addr + ((i%8) << DCACHE_INDEX_WIDTH) + 8), .data(64'hBEEFCAFE0100 + i), .rand_size_be(1));
                                                end

                                                3 : begin // Rd Rd
                                                    dcache_drv[cc][0].rd(             .addr(addr+ ((i%8) << DCACHE_INDEX_WIDTH)), .rand_size_be(1), .rand_kill(5));
                                                    `WAIT_CYC(clk, $urandom_range(20))
                                                    dcache_drv[cc][0].rd(.do_wait(1), .addr(addr+ ((i%8) << DCACHE_INDEX_WIDTH) + 8), .rand_size_be(1), .rand_kill(5));
                                                end
                                            endcase
                                        end
                                    join_none
                                end
                                wait fork;
                            end
                        end join

                        `WAIT_CYC(clk, 100)

                    end


                    // - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
                    "cacheline_rw_collision" : begin
                        test_header(testname, "Read cacheline while it is being updated");

                        addr = ArianeCfg.CachedRegionAddrBase[0];

                        fork begin // this is needed to make sure the "wait fork" below doesn't affect forks outside this scope
                            repeat (100) begin
                                addr = addr + 32;
                                // write data in one core
                                dcache_drv[cid][2].wr(.addr(addr),    .data(64'hBEEFCAFE0000));
                                dcache_drv[cid][2].wr(.addr(addr+8),  .data(64'hBEEFCAFE8888));
                                dcache_drv[cid][2].wr(.addr(addr+16), .data(64'hDEADABBA0000));
                                `WAIT_CYC(clk, 100)
                                for (int c=0; c < NB_CORES; c++) begin
                                    fork
                                        automatic int cc = c;
                                        begin
                                            if (cc != cid) begin
                                                // read data in other cores
                                                dcache_drv[cc][1].rd(.do_wait(1), .addr(addr));
                                                dcache_drv[cc][1].rd(.do_wait(1), .addr(addr+8));
                                                dcache_drv[cc][1].rd(.do_wait(1), .addr(addr+16));
                                                // data is now shared in this core
                                                `WAIT_CYC(clk, $urandom_range(10))
                                                fork
                                                    begin
                                                        // write to one part of cacheline (causing cache update)
                                                        `WAIT_CYC(clk, $urandom_range(5))
                                                        dcache_drv[cc][2].wr(.addr(addr+8), .rand_data(1));
                                                    end
                                                    begin
                                                        // at the same time, read other cache line
                                                        `WAIT_CYC(clk, $urandom_range(10))
                                                        dcache_drv[cc][1].rd(.addr(addr));
                                                        `WAIT_CYC(clk, $urandom_range(10))
                                                        dcache_drv[cc][1].rd(.do_wait(1), .addr(addr+16), .check_result(1), .exp_result(64'hDEADABBA0000));
                                                    end
                                                join
                                            end
                                        end
                                    join_none
                                end
                                wait fork;
                                `WAIT_CYC(clk, 100)
                            end
                        end join
                    end




                    // - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
                    "flush_collision" : begin
                        test_header(testname, "Flush the cache while other core is accessing its contents");


                        // core 0 mgmt will have to wait for flush, increase timeout
                        if (STALL_RANDOM_DELAY) begin
                            wait_time = 100000; // flushing takes long time
                            timeout  += 200000;
                        end else begin
                            wait_time = 10000;
                        end

                        cache_scbd[cid].set_mgmt_trans_timeout (wait_time);

                        // other snooped cores will have to wait for flush, increase timeout
                        for (int core_idx=0; core_idx<NB_CORES; core_idx++) begin : CORE
                            cache_scbd[core_idx].set_snoop_msg_timeout(wait_time);
                            cache_scbd[core_idx].set_cache_msg_timeout(wait_time);
                        end

                        addr = ArianeCfg.CachedRegionAddrBase[0];

                        // fill up cache
                        for (int i=0; i<2048; i++) begin
                            dcache_drv[cid][2].wr(.addr(addr + i*8),  .data(64'hBEEFCAFE0000 + i));
                        end

                        fork begin // this is needed to make sure the "wait fork" below doesn't affect forks outside this scope
                            for (int c=0; c < NB_CORES; c++) begin
                                fork
                                    automatic int cc = c;
                                    automatic int port;
                                    automatic logic [63:0] laddr;
                                    begin
                                        if (cc == cid) begin
                                            // flush
                                            dcache_mgmt_drv[cc].flush();
                                        end else begin
                                            for (int i=2047;  i>=0; i--) begin
                                                dcache_drv[cc][1].rd(.do_wait(1), .addr(addr + i*8), .check_result(1), .exp_result(64'hBEEFCAFE0000 + i));
                                            end
                                        end
                                    end
                                join_none
                            end
                            wait fork;
                        end join

                        $display("***\n*** Test finished, waiting %0d cycles to catch possible timeouts\n***",wait_time);
                        `WAIT_CYC(clk, wait_time)

                    end


                    // - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
                    "evict_collision" : begin
                        test_header(testname, "Collision between eviction in one core and access in others");

                        base_addr = ArianeCfg.CachedRegionAddrBase[0];
                        rep_cnt   = 200;
                        wait_time = 5000;
                        timeout  += 200000;


                        for (int core_idx=0; core_idx<NB_CORES; core_idx++) begin : CORE
                            cache_scbd[core_idx].set_cache_msg_timeout(wait_time);
                        end

                        fork begin // this is needed to make sure the "wait fork" below doesn't affect forks outside this scope
                            for (int r=0; r<rep_cnt; r++) begin
                                // fill up cache set
                                for (int i=0; i<8; i++) begin
                                    automatic logic [63:0] laddr = base_addr + (i << DCACHE_INDEX_WIDTH);
                                    dcache_drv[cid][2].wr(.addr(laddr), .data(i + cid*1024));
                                end

                                `WAIT_CYC(clk, 100)

                                // cause collision
                                for (int c=0; c < NB_CORES; c++) begin
                                    fork
                                        automatic int cc = c;
                                        automatic int port;
                                        automatic logic [63:0] laddr;
                                        begin
                                            if (cc == cid) begin
                                                // cause evictions in one core
                                                for (int i=8; i<16; i++) begin
                                                    laddr = base_addr + (i << DCACHE_INDEX_WIDTH);
                                                    port = $urandom_range(2);
                                                    // add none or a few cycles between requests
                                                    `WAIT_CYC(clk, $urandom_range(4,0));
                                                    // evictions are caused by read or write
                                                    case (port)
                                                        0, 1 : dcache_drv[cc][port].rd(.do_wait(1), .addr(laddr), .rand_size_be(1));
                                                        2    : dcache_drv[cc][port].wr(.addr(laddr), .data(i + cc*1024), .rand_size_be(1));
                                                    endcase
                                                end
                                            end else begin
                                                // access the evicted addresses in other cores
                                                for (int i=0; i<8; i++) begin
                                                    automatic int offset;
                                                    offset  = (i + cc) % 8;
                                                    laddr = base_addr + (offset << DCACHE_INDEX_WIDTH);
                                                    port  = $urandom_range(3);
                                                    // add none or a few cycles between requests
                                                    `WAIT_CYC(clk, $urandom_range(4,0));
                                                    // create conflict with read, write, or AMO
                                                    case (port)
                                                        0, 1 : dcache_drv[cc][port].rd(.do_wait(1), .addr(laddr), .rand_size_be(1));
                                                        2    : dcache_drv[cc][port].wr(.addr(laddr), .data(i + cc*1024), .rand_size_be(1));
                                                        3    : amo_drv[cc].req(.addr(laddr), .rand_op(1), .data(i + cc*1024));
                                                    endcase
                                                end
                                            end
                                        end
                                    join_none
                                end
                                wait fork;
                            end
                        end join

                        $display("***\n*** Test finished, waiting %0d cycles to catch possible timeouts\n***",wait_time);
                        `WAIT_CYC(clk, wait_time)
                    end

                    // - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
                    "raw_spin_lock" : begin
                        logic [63:0] lock_addr0, lock_addr1;
                        test_header(testname, "emulate the Linux raw_spin_lock/unlock functions");
                        start_amo_monitor();

                        lock_addr0 = ArianeCfg.CachedRegionAddrBase[0] + $urandom_range(100) * 8; // 64 bit
                        lock_addr1 = lock_addr0 + $urandom_range(1,100) * 8 + 4; // 32 bit

                        wait_time = 10000;
                        timeout  += 500000; // long test
                        rep_cnt   = 1000;

                        for (int c=0; c < NB_CORES; c++) begin
                            cache_scbd[c].set_amo_msg_timeout(wait_time);
                        end

                        // initialize locks to 0
                        dcache_drv[cid][2].wr(.addr(lock_addr0), .data(0));
                        dcache_drv[cid][2].wr(.addr(lock_addr1), .data(0));

                        fork begin // this is needed to make sure the "wait fork" below doesn't affect forks outside this scope
                            for (int c=0; c < NB_CORES; c++) begin
                                fork
                                    automatic int          cc     = c;
                                    automatic logic [63:0] locked;
                                    automatic int          wait_cyc;
                                    automatic logic [63:0] laddr;
                                    automatic int          sel;
                                    automatic logic  [1:0] size;
                                    automatic logic  [7:0] be;
                                    begin
                                        for (int i=0; i<rep_cnt; i++) begin
                                            wait_cyc = $urandom_range(10);
                                            // try to get one of two locks
                                            // selec which lock to try to aquire
                                            sel = $urandom_range(1);
                                            case (sel)
                                                0 : begin
                                                    laddr = lock_addr0;
                                                    size  = 2'b11;
                                                    be    = 8'hFF;
                                                end
                                                default : begin
                                                    laddr = lock_addr1;
                                                    size  = 2'b10;
                                                    be    = 8'hF0;
                                                end
                                            endcase

                                            $display("%t ns : Core %0d Waiting %0d cycles before trying to get lock (check_amo_lock)",$time ,cc,wait_cyc);
                                            `WAIT_CYC(clk, wait_cyc);

                                            // lock
                                            locked = 1;
                                            while (locked != 0) begin
                                                // read lock
                                                while (locked != 0) begin
                                                    dcache_drv[cc][1].rd_resp(.addr(laddr), .size(size), .be(be), .do_wait(1), .rand_kill(25), .result(locked));
                                                    `WAIT_CYC(clk, $urandom_range(10))
                                                end
                                                $display("%t ns : Core %0d saw free lock, trying to aquire it (check_amo_lock)",$time ,cc);

                                                // try to swap in 1
                                                amo_drv[cc].req_resp(.addr(laddr), .size(size), .op(AMO_SWAP), .data(1), .result(locked));
                                                `WAIT_CYC(clk, $urandom_range(10))
                                            end

                                            // waste time
                                            wait_cyc = $urandom_range(100);
                                            $display("%t ns : Core %0d Waiting %0d cycles before releasing lock (check_amo_lock)",$time , cc,wait_cyc);
                                            `WAIT_CYC(clk, wait_cyc);

                                            // unlock
                                            dcache_drv[cc][2].wr(.addr(laddr), .size(size), .be(be), .data(0));
                                        end
                                    end
                                join_none
                            end
                            wait fork;
                        end join

                        $display("***\n*** Test finished, waiting %0d cycles to catch possible timeouts\n***",wait_time);
                        `WAIT_CYC(clk, wait_time)

                    end


                    // - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
                    "raw_spin_lock_wait" : begin
                        logic [63:0] lock_addr0, lock_addr1;
                        test_header(testname, "emulate the Linux raw_spin_lock/unlock functions");
                        start_amo_monitor();

                        lock_addr0 = ArianeCfg.CachedRegionAddrBase[0] + $urandom_range(100) * 8; // 64 bit
                        lock_addr1 = lock_addr0 + $urandom_range(1,100) * 8 + 4; // 32 bit

                        wait_time = 10000;
                        timeout  += 500000;
                        rep_cnt   = 1000;

                        for (int c=0; c < NB_CORES; c++) begin
                            cache_scbd[c].set_amo_msg_timeout(wait_time);
                        end

                        // initialize locks to 0
                        dcache_drv[cid][2].wr(.addr(lock_addr0), .data(0));
                        dcache_drv[cid][2].wr(.addr(lock_addr1), .data(0));


                        fork begin // this is needed to make sure the "wait fork" below doesn't affect forks outside this scope
                            for (int i=0; i<rep_cnt; i++) begin
                                $display("%t ns %s: Iteration %0d", $time, testname, i);
                                for (int c=0; c < NB_CORES; c++) begin
                                    fork
                                        automatic int          cc     = c;
                                        automatic logic [63:0] locked;
                                        automatic int          wait_cyc;
                                        automatic logic [63:0] laddr;
                                        automatic int          sel;
                                        automatic logic  [1:0] size;
                                        automatic logic  [7:0] be;
                                        begin
                                            wait_cyc = $urandom_range(10);
                                            // try to get one of two locks
                                            // selec which lock to try to aquire
                                            sel = $urandom_range(1);
                                            case (sel)
                                                0 : begin
                                                    laddr = lock_addr0;
                                                    size  = 2'b11;
                                                    be    = 8'hFF;
                                                end
                                                default : begin
                                                    laddr = lock_addr1;
                                                    size  = 2'b10;
                                                    be    = 8'hF0;
                                                end
                                            endcase

                                            $display("%t ns %s: Core %0d Waiting %0d cycles before trying to get lock %0d", $time, testname, cc, wait_cyc, sel);
                                            `WAIT_CYC(clk, wait_cyc);

                                            // lock
                                            locked = 1;
                                            while (locked != 0) begin
                                                // read lock
                                                while (locked != 0) begin
                                                    dcache_drv[cc][1].rd_resp(.addr(laddr), .size(size), .be(be), .do_wait(1), .rand_kill(25), .result(locked));
                                                    `WAIT_CYC(clk, $urandom_range(10))
                                                end
                                                $display("%t ns %s: Core %0d saw free lock %0d, trying to aquire it", $time, testname, cc, sel);

                                                // try to swap in 1
                                                amo_drv[cc].req_resp(.addr(laddr), .size(size), .op(AMO_SWAP), .data(1), .result(locked));
                                                `WAIT_CYC(clk, $urandom_range(10))
                                            end

                                            // waste time
                                            wait_cyc = $urandom_range(100);
                                            $display("%t ns %s: Core %0d Waiting %0d cycles before releasing lock %0d", $time, testname, cc, wait_cyc, sel);
                                            `WAIT_CYC(clk, wait_cyc);

                                            // unlock
                                            $display("%t ns %s: Core %0d releasing lock %0d", $time, testname, cc, sel);
                                            dcache_drv[cc][2].wr(.addr(laddr), .size(size), .be(be), .data(0));

                                            // read the lock again (to make sure write has finished)
                                            dcache_drv[cc][1].rd(.addr(laddr), .size(size), .be(be), .do_wait(1));
                                        end
                                    join_none
                                end
                                wait fork;
                            end
                        end join

                        $display("***\n*** Test finished, waiting %0d cycles to catch possible timeouts\n***",wait_time);
                        `WAIT_CYC(clk, wait_time)

                    end





                    // - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
                    "amo_read_write" : begin
                        test_header(testname, "AMO reads and writes to single address");
                        addr = ArianeCfg.CachedRegionAddrBase[0];

                        wait_time = 10000;

                        for (int c=0; c < NB_CORES; c++) begin
                            cache_scbd[c].set_amo_msg_timeout(wait_time);
                        end


                        // simultaneous writes to same address
                        fork begin // this is needed to make sure the "wait fork" below doesn't affect forks outside this scope
                            for (int i=0; i<100; i++) begin
                                for (int c=0; c < NB_CORES; c++) begin
                                    fork
                                        automatic int cc = c;
                                        begin
                                            if (cc == cid) begin
                                                amo_drv[cc].req(.addr(addr), .op(AMO_LR), .rand_data(1));
                                                `WAIT_CYC(clk, 5)
                                                amo_drv[cc].req(.addr(addr), .op(AMO_SC), .rand_data(1));
                                            end else begin
                                                amo_drv[cc].req(.addr(addr), .op(AMO_LR), .rand_data(1));
                                                `WAIT_CYC(clk, ((i%20)+cc))
                                                amo_drv[cc].req(.addr(addr), .op(AMO_SC), .rand_data(1));
                                            end
                                        end
                                    join_none
                                end
                                wait fork;
                            end
                        end join

                        $display("***\n*** Test finished, waiting %0d cycles to catch possible timeouts\n***",wait_time);
                        `WAIT_CYC(clk, wait_time)

                    end


                    // - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
                    "amo_alu" : begin
                        logic [63:0] data_op;   // operand to apply
                        logic [63:0] data_res;  // expaected result in memory
                        logic [63:0] next_addr; // address to next entry

                        test_header(testname, "AMO ALU operations");

                        rep_cnt = 500;

                        // 32 bit
                        for (int i=0; i<rep_cnt; i++) begin
                            logic [7:0] be, next_be;
                            int         shift;
                            amo_t       op;
                            logic       word_op;
                            int         size;
                            int         addr_step;

                            word_op = $urandom_range(1); // operate on word or double

                            if (word_op) begin
                                addr      = ArianeCfg.CachedRegionAddrBase[0] + $urandom_range(1024) * 4; // addr aligned with data size 32
                                next_addr = addr + 4;

                                // only use unsigned, avoid too large numbers to avoid overflow
                                data    = $urandom() >> 2;
                                data_op = $urandom() >> 2;

                                size = 2;
                                if (addr % 8 == 4) begin
                                    shift   = 32;
                                    be      = 8'hf0;
                                    next_be = 8'h0f;
                                end else begin
                                    shift   = 0;
                                    be      = 8'h0f;
                                    next_be = 8'hf0;
                                end
                            end else begin
                                addr      = ArianeCfg.CachedRegionAddrBase[0] + $urandom_range(1024) * 8;  // addr aligned with data size 64
                                next_addr = addr + 8;

                                // only use unsigned, avoid too large numbers to avoid overflow
                                data    = {$urandom(), $urandom()} >> 2;
                                data_op = {$urandom(), $urandom()} >> 2;

                                size    = 3;
                                shift   = 0;
                                be      = 8'hff;
                                next_be = 8'hff;
                            end

                            op = amo_t'($urandom_range(AMO_MINU, AMO_SWAP)); // only select supported ALU operations
                            case (op)
                                AMO_SWAP          : data_res = data_op;
                                AMO_ADD           : data_res = data + data_op;
                                AMO_AND           : data_res = data & data_op;
                                AMO_OR            : data_res = data | data_op;
                                AMO_XOR           : data_res = data ^ data_op;
                                AMO_MAX, AMO_MAXU : data_res = data > data_op ? data : data_op;
                                AMO_MIN, AMO_MINU : data_res = data < data_op ? data : data_op;
                            endcase

                            // core X writes data
                            $display("%t ns : [Test %s (%0d) step 1] Core %0d writing 0x%16h to addr 0x%16h",$time , testname, i, cid, (data << shift), addr);
                            dcache_drv[cid][2].wr(.addr(addr), .data(data << shift), .size(size), .be(be));

                            // core X possibly writes data to neighboring address
                            if ($urandom_range(1)) begin
                                $display("%t ns : [Test %s (%0d) step 2] Core %0d writing random data to addr 0x%16h",$time , testname, i, cid, next_addr);
                                dcache_drv[cid][2].wr(.addr(next_addr), .rand_data(1), .size(size), .be(next_be));
                            end
                            // core Y possibly writes data to neighboring address
                            if ($urandom_range(1)) begin
                                $display("%t ns : [Test %s (%0d) step 3] Core %0d writing random data to addr 0x%16h",$time , testname, i, cid2, next_addr);
                                dcache_drv[cid2][2].wr(.addr(next_addr), .rand_data(1), .size(size), .be(next_be));
                            end

                            // core X possibly reads data
                            if ($urandom_range(1)) begin
                                $display("%t ns : [Test %s (%0d) step 4] Core %0d reading data from addr 0x%16h",$time , testname, i, cid, addr);
                                // only check results if it was written by core X (cid)
                                dcache_drv[cid][0].rd(.do_wait(1), .size(size), .be(be), .addr(addr),  .check_result(1), .exp_result(data << shift));
                            end

                            // core X sends AMO request
                            $display("%t ns : [Test %s (%0d) step 5] Core %0d sending AMO request %s with operand 0x%16h to addr 0x%16h",$time , testname, i, cid, op.name(), data_op, addr);
                            amo_drv[cid].req(.addr(addr), .op(op), .data(data_op), .size(size), .check_result(1), .exp_result(data));

                            // core X possibly writes data to neighboring address
                            if ($urandom_range(1)) begin
                                $display("%t ns : [Test %s (%0d) step 6] Core %0d writing random data to addr 0x%16h",$time , testname, i, cid, next_addr);
                                dcache_drv[cid][2].wr(.addr(next_addr), .rand_data(1), .size(size), .be(next_be));
                            end

                            // core Y possibly writes data to neighboring address
                            if ($urandom_range(1)) begin
                                $display("%t ns : [Test %s (%0d) step 7] Core %0d writing random data to addr 0x%16h",$time , testname, i, cid2, next_addr);
                                dcache_drv[cid2][2].wr(.addr(next_addr), .rand_data(1), .size(size), .be(next_be));
                            end

                            // core Y possibly reads data
                            if ($urandom_range(1)) begin
                                $display("%t ns : [Test %s (%0d) step 8] Core %0d reading data from addr 0x%16h",$time , testname, i, cid2, addr);
                                dcache_drv[cid2][0].rd(.do_wait(1), .size(size), .be(be), .addr(addr),  .check_result(1), .exp_result(data_res << shift));
                            end

                            // core X reads data
                            $display("%t ns : [Test %s (%0d) step 9] Core %0d reading data from addr 0x%16h",$time , testname, i, cid, addr);
                            dcache_drv[cid][0].rd(.do_wait(1), .size(size), .be(be), .addr(addr),  .check_result(1), .exp_result(data_res << shift));

                        end

                        $display("***\n*** Test finished, waiting %0d cycles to catch possible timeouts\n***",wait_time);
                        `WAIT_CYC(clk, wait_time)

                    end



                    // - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
                    "amo_cacheline_collision" : begin
                        logic [63:0] addr_hi;
                        test_header(testname, "AMO LR/SC targeting address in upper part of cache line, while other core accesses the lower part of cache line.\nTriggers JIRA issue PROJ-272");

                        rep_cnt = 10;

                        for (int i=0; i<rep_cnt; i++) begin
                            test_id = i;

                            addr    = ArianeCfg.CachedRegionAddrBase[0] + $urandom_range(1024) * 16; // addr aligned with cache line
                            addr_hi = addr + 8;                                                      // addr_hi targets upper part of cache line

                            // write known data to addr_hi
                            data = 64'h00000000CAFEBABE + (i * 64'h0000000100000000);
                            dcache_drv[cid][2].wr(.addr(addr_hi),  .data(data));

                            // Reserve the target, expect data
                            amo_drv[cid].req(.addr(addr_hi), .size(3), .op(AMO_LR), .rand_data(1), .check_result(1), .exp_result(data));
                            `WAIT_CYC(clk, 100)

                            // other core writes to other part of cache line
                            dcache_drv[cid2][2].wr(.addr(addr), .rand_data(1));
                            `WAIT_CYC(clk, 100)

                            // store-conditional to the target, expect failure
                            amo_drv[cid].req(.addr(addr_hi), .size(3), .op(AMO_SC), .data(data+2), .check_result(1),. exp_result(1));
                            `WAIT_CYC(clk, 100)
                        end

                    end


                    // - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
                    "amo_lr_sc_upper" : begin
                        test_header(testname, "AMO collision with 8 byte offset, triggers JIRA issue PROJ-270");

                        addr = ArianeCfg.CachedRegionAddrBase[0] + 8;

                        rep_cnt = 10;

                        for (int i=0; i<rep_cnt; i++) begin
                            // write known data to target address
                            data = 64'h00000000DEADBEEF;
                            dcache_drv[cid][2].wr(.addr(addr),  .data(data));

                            // Reserve the target, expect data
                            amo_drv[cid].req(.addr(addr), .size(3), .op(AMO_LR), .rand_data(1), .check_result(1), .exp_result(data));
                            `WAIT_CYC(clk, 1000)

                            // other core writes to target address
                            dcache_drv[cid2][2].wr(.addr(addr),  .rand_data(1));
                            `WAIT_CYC(clk, 1000)

                            // store-conditional to the target, expect failure
                            amo_drv[cid].req(.addr(addr),  .size(3), .op(AMO_SC), .data(data+2), .check_result(1),. exp_result(1));
                            `WAIT_CYC(clk, 1000)
                        end

                    end


                    // - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
                    "amo_lr_sc_adjacent" : begin
                        test_header(testname, "Verify that a write to a cacheline next to a reserved address doesn't invalidate the reservation.");

                        rep_cnt = 10;

                        for (int i=0; i<rep_cnt; i++) begin
                            int offset;
                            addr = ArianeCfg.CachedRegionAddrBase[0] + $urandom_range(32,1) * 16;

                            // write known data to target address
                            data = 64'h00000000CAFEBABE + (i * 64'h0000000100000000);
                            dcache_drv[cid][2].wr(.addr(addr),  .data(data));
                            `WAIT_CYC(clk, 100)

                            // Reserve the target, expect data
                            amo_drv[cid].req(.addr(addr), .size(3), .op(AMO_LR), .rand_data(1), .check_result(1), .exp_result(data));
                            `WAIT_CYC(clk, 100)

                            offset = $urandom_range(1) ? 16 : -16;

                            // Other core writes to the cacheline next to target
                            dcache_drv[cid2][2].wr(.addr(addr+offset), .rand_data(1));
                            `WAIT_CYC(clk, 100)

                            // read other addresses mapped to the same cache set, forcing evacuation
                            for (int i=0; i<16; i++) begin
                                dcache_drv[cid2][1].rd(.addr(addr+offset + (i << DCACHE_INDEX_WIDTH)));
                            end

                            // store-conditional to the target, expect success
                            amo_drv[cid].req(.addr(addr), .size(3), .op(AMO_SC), .data(data+1), .check_result(1),. exp_result(0));
                            `WAIT_CYC(clk, 100)

                            // read the value in target, expect value from previous store-conditional
                            dcache_drv[cid][0].rd(.do_wait(1), .addr(addr),  .check_result(1), .exp_result(data+1));
                            `WAIT_CYC(clk, 100)
                        end
                    end


                    // - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
                    "amo_lr_sc_single" : begin
                        test_header(testname, "Verify that a write to a reserved address from the core that reserved it doesn't invalidate the reservation.\nThis bug triggers JIRA issue PROJ-274");

                        rep_cnt = 10;

                        for (int i=0; i<rep_cnt; i++) begin
                            addr = ArianeCfg.CachedRegionAddrBase[0] + $urandom_range(32) * 16;

                            // write known data to target address
                            data = 64'h00000000CAFEBABE + (i * 64'h0000000100000000);
                            dcache_drv[cid][2].wr(.addr(addr),  .data(data));
                            `WAIT_CYC(clk, 100)

                            // Reserve the target, expect data
                            amo_drv[cid].req(.addr(addr), .size(3), .op(AMO_LR), .rand_data(1), .check_result(1), .exp_result(data));
                            `WAIT_CYC(clk, 100)

                            // Regular write to the target
                            dcache_drv[cid][2].wr(.addr(addr),  .data(data+1));
                            `WAIT_CYC(clk, 100)

                            // read the value in target, expect value from previous store
                            dcache_drv[cid][0].rd(.do_wait(1), .addr(addr),  .check_result(1), .exp_result(data+1));
                            `WAIT_CYC(clk, 100)

                            // store-conditional to the target, expect success
                            amo_drv[cid].req(.addr(addr), .size(3), .op(AMO_SC), .data(data+2), .check_result(1),. exp_result(0));
                            `WAIT_CYC(clk, 100)

                            // read the value in target, expect value from previous store-conditional
                            dcache_drv[cid][0].rd(.do_wait(1), .addr(addr),  .check_result(1), .exp_result(data+2));
                            `WAIT_CYC(clk, 100)
                        end
                    end

                    // - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
                    "amo_lr_sc_delay" : begin
                        test_header(testname, "Verify AMO LR/SC handling with delay on AXI, triggers JIRA issue PROJ-271");

                        a_axi_delay : assert (STALL_RANDOM_DELAY == 1 || FIXED_AXI_DELAY > 5) else
                            $error("Test %s requires AXI delay to trigger bug", testname);

                        addr = ArianeCfg.CachedRegionAddrBase[0];
                        rep_cnt = 10;

                        for (int i=0; i<rep_cnt; i++) begin
                            // write known data to target address
                            data = 64'h00000000CAFEBABE + (i * 64'h0000000100000000);
                            dcache_drv[cid][2].wr(.addr(addr),  .data(data));
                            `WAIT_CYC(clk, 100)

                            // Reserve the target, expect data
                            amo_drv[cid].req(.addr(addr), .size(3), .op(AMO_LR), .rand_data(1), .check_result(1), .exp_result(data));
                            `WAIT_CYC(clk, 100)

                            // store-conditional to the target, expect success
                            amo_drv[cid].req(.addr(addr), .size(3), .op(AMO_SC), .data(data+1), .check_result(1),. exp_result(0));
                            `WAIT_CYC(clk, 100)

                            // store-conditional again to the target, expect failure
                            amo_drv[cid].req(.addr(addr),  .size(3), .op(AMO_SC), .data(data+2), .check_result(1),. exp_result(1));
                            `WAIT_CYC(clk, 100)

                            // read the value in target, expect value from first store
                            dcache_drv[cid][0].rd(.do_wait(1), .addr(addr),  .check_result(1), .exp_result(data+1));
                            `WAIT_CYC(clk, 100)
                        end
                    end


                    // - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
                    "amo_lr_sc" : begin
                        test_header(testname, "AMO Load-Reserved / Store-Conditional test");

                        rep_cnt = 10;

                        for (int i=0; i<rep_cnt; i++) begin

                            addr = ArianeCfg.CachedRegionAddrBase[0] + $urandom_range(1024) * 8; // AMO address must be aligned with memory

                            ////////////////////////////////////////////////////////
                            // Single core, 32 Byte AMO
                            ////////////////////////////////////////////////////////
                            test_id=i*100;

                            // write known data to target address
                            data = 64'h0000CAFEBABE0000;
                            dcache_drv[cid][2].wr(.addr(addr),  .data(data));
                            `WAIT_CYC(clk, 100)

                            // Reserve the target, expect data
                            amo_drv[cid].req(.addr(addr+4), .size(2), .op(AMO_LR), .rand_data(1), .check_result(1), .exp_result(data[63:32]));
                            `WAIT_CYC(clk, 100)

                            // store-conditional to the target, expect success
                            amo_drv[cid].req(.addr(addr+4), .size(2), .op(AMO_SC), .data(data+1), .check_result(1),. exp_result(0));
                            `WAIT_CYC(clk, 100)

                            // store-conditional again to the target, expect failure
                            amo_drv[cid].req(.addr(addr+4),  .size(2), .op(AMO_SC), .data(data+2), .check_result(1),. exp_result(1));
                            `WAIT_CYC(clk, 100)

                            // read the value in target, expect value from first store
                            dcache_drv[cid][0].rd(.do_wait(1), .addr(addr),  .check_result(1), .exp_result({(data[31:0]+1), data[31:0]}));
                            `WAIT_CYC(clk, 100)


                            ////////////////////////////////////////////////////////
                            // Single core, 64 Byte AMO
                            ////////////////////////////////////////////////////////
                            test_id++;

                            // write known data to target address
                            data = 64'h00000000CAFEBABE + test_id;
                            dcache_drv[cid][2].wr(.addr(addr),  .data(data));
                            `WAIT_CYC(clk, 100)

                            // Reserve the target, expect data
                            amo_drv[cid].req(.addr(addr), .size(3), .op(AMO_LR), .rand_data(1), .check_result(1), .exp_result(data));
                            `WAIT_CYC(clk, 100)

                            // store-conditional to the target, expect success
                            amo_drv[cid].req(.addr(addr), .size(3), .op(AMO_SC), .data(data+1), .check_result(1),. exp_result(0));
                            `WAIT_CYC(clk, 100)

                            // store-conditional again to the target, expect failure
                            amo_drv[cid].req(.addr(addr),  .size(3), .op(AMO_SC), .data(data+2), .check_result(1),. exp_result(1));
                            `WAIT_CYC(clk, 100)

                            // read the value in target, expect value from first store
                            dcache_drv[cid][0].rd(.do_wait(1), .addr(addr),  .check_result(1), .exp_result(data+1));
                            `WAIT_CYC(clk, 100)


                            ////////////////////////////////////////////////////////
                            // Two cores, reservation fails due to write from other core
                            ////////////////////////////////////////////////////////
                            test_id++;

                            // core 0 writes known data to target address
                            data = 64'h0001CAFEBABE0000 + test_id;
                            dcache_drv[cid][2].wr(.addr(addr), .data(data));
                            `WAIT_CYC(clk, 100)

                            // Core 1 reserves the target, expect data
                            amo_drv[cid2].req(.addr(addr), .op(AMO_LR), .rand_data(1), .check_result(1), .exp_result(data));
                            `WAIT_CYC(clk, 100)

                            // core 0 writes new data to target address
                            dcache_drv[cid][2].wr(.addr(addr), .data(data+1));
                            `WAIT_CYC(clk, 100)

                            // core 1 store-conditional to the target, expect failure
                            amo_drv[cid2].req(.addr(addr), .op(AMO_SC), .data(data+3), .check_result(1),. exp_result(1));
                            `WAIT_CYC(clk, 100)

                            // read the value in target, expect value from regular write
                            dcache_drv[cid2][0].rd(.do_wait(1), .addr(addr),  .check_result(1), .exp_result(data+1));
                            `WAIT_CYC(clk, 100)


                            ////////////////////////////////////////////////////////
                            test_id++;

                            // core 0 writes known data to target address
                            data = 64'h0002CAFEBABE0000 + test_id;
                            dcache_drv[cid][2].wr(.addr(addr), .data(data));
                            `WAIT_CYC(clk, 100)

                            // Core 1 reserves the target, expect data
                            amo_drv[cid2].req(.addr(addr), .op(AMO_LR), .rand_data(1), .check_result(1), .exp_result(data));
                            `WAIT_CYC(clk, 100)


//                            // core 1 writes new data to target address
//                            // results in clearing the reservation => a subsequent store conditional would not succeed
//                            dcache_drv[cid2][2].wr(.addr(addr), .data(data+1));
//                            `WAIT_CYC(clk, 100)
//
//                            // core 0 reads the value in target, expect value from regular write
//                            dcache_drv[cid][0].rd(.do_wait(1), .addr(addr),  .check_result(1), .exp_result(data+1));
//                            `WAIT_CYC(clk, 100)


                            // core 1 store-conditional to the target, expect success
                            amo_drv[cid2].req(.addr(addr), .op(AMO_SC), .data(data+2), .check_result(1),. exp_result(0));
                            `WAIT_CYC(clk, 100)

                            // core 0 read the value in target, expect value from conditional store
                            dcache_drv[cid][0].rd(.do_wait(1), .addr(addr),  .check_result(1), .exp_result(data+2));
                            `WAIT_CYC(clk, 100)

                            // core 1 store-conditional to the target, expect failure
                            amo_drv[cid2].req(.addr(addr), .op(AMO_SC), .data(data+3), .check_result(1),. exp_result(1));
                            `WAIT_CYC(clk, 100)

                            // core 0 read the value in target, expect value from successful conditional store
                            dcache_drv[cid][0].rd(.do_wait(1), .addr(addr),  .check_result(1), .exp_result(data+2));
                            `WAIT_CYC(clk, 100)

                        end

                        `WAIT_CYC(clk, 10000) // make sure we see timeouts

                        `WAIT_CYC(clk, 100)
                    end


                    // - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
                    "amo_read_write_collision" : begin
                        test_header(testname, "AMO write and read while other cores are active");

                        base_addr = ArianeCfg.CachedRegionAddrBase[0];
                        rep_cnt   = 1000;
                        wait_time = 10000;

                        for (int c=0; c < NB_CORES; c++) begin
                            // other cores may have to wait for AMO
                            if (c != cid) begin
                                cache_scbd[c].set_cache_msg_timeout(wait_time);
                            end
                        end

                        fork begin // this is needed to make sure the "wait fork" below doesn't affect forks outside this scope
                            for (int c=0; c < NB_CORES; c++) begin
                                fork
                                    automatic int cc = c;
                                    automatic int port;
                                    automatic int offset;
                                    begin
                                        if (cc == cid) begin
                                            `WAIT_CYC(clk, rep_cnt*10)
                                            amo_drv[cc].req(.addr(base_addr), .op(AMO_SC));
                                            `WAIT_CYC(clk, 5)
                                            amo_drv[cc].req(.addr(base_addr), .op(AMO_LR));
                                        end else begin
                                            for (int i=0; i<rep_cnt; i++) begin
                                                port   = $urandom_range(2);
                                                offset = $urandom_range(1024);
                                                if (port == 2) begin
                                                    dcache_drv[cc][2].wr(.addr(base_addr + offset), .data(64'hBEEFCAFE00000000 + offset), .rand_size_be(1));
                                                end else begin
                                                    dcache_drv[cc][port].rd(.do_wait(1), .addr(base_addr + offset), .rand_size_be(1));
                                                end
                                            end
                                        end
                                        $display("%t ns %s: test sequence ended for core %0d", $time, testname, cc);
                                    end
                                join_none
                            end
                            wait fork;
                        end join

                        $display("***\n*** Test finished, waiting %0d cycles to catch possible timeouts\n***",wait_time);
                        `WAIT_CYC(clk, wait_time)

                    end


                    // - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
                    "amo_read_cached" : begin
                        // This test is targeted towards triggering bug PROJ-153: "AMO read of cached data returns wrong data"
                        test_header(testname, "AMO requests data cached in other core");

                        base_addr = ArianeCfg.CachedRegionAddrBase[0];

                        // write data to cache in core 1
                        dcache_drv[cid2][2].wr(.addr(base_addr),     .data(64'hCAFEBABE_00000000));
                        dcache_drv[cid2][2].wr(.addr(base_addr + 8), .data(64'hBAADF00D_11111111));

                        // amo read
                        amo_drv[cid].req(.addr(base_addr),     .op(AMO_LR), .check_result(1), .exp_result(64'hCAFEBABE_00000000));
                        amo_drv[cid].req(.addr(base_addr + 8), .op(AMO_LR), .check_result(1), .exp_result(64'hBAADF00D_11111111));

                        `WAIT_CYC(clk, 100)
                    end


                    // - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
                    "amo_snoop_single_collision" : begin
                        // This test is targeted towards triggering bug PROJ-150: "AMO request skips cache flush if snoop_cache_ctrl is busy"
                        test_header(testname, "Single AMO request while receiving snoop");

                        addr = ArianeCfg.CachedRegionAddrBase[0];
                        fork
                            begin
                                // make sure there is something dirty in the cache of core 0
                                dcache_drv[cid][2].wr(.addr(addr));
                                // allow snoop from core 1 to propagate
                                `WAIT_CYC(clk, 15)
                                // AMO request, should cause flush and writeback of data in cache
                                amo_drv[cid].req(.addr(addr), .rand_op(1));
                                // another request outside cacheable regions will trigger the AW beat and detect the mismatch
                                dcache_drv[cid][2].wr(.addr(ArianeCfg.SharedRegionAddrBase[0]));
                            end
                            begin
                                // read cache in core 1 to trigger a snoop transaction towards other cores
                                dcache_drv[cid2][0].rd(.addr(addr+1));
                            end
                        join

                        `WAIT_CYC(clk, 100)
                    end


                    // - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
                    "amo_upper_cache_line" : begin
                        logic [63:0] data8, data16;
                        // This test is targeted towards triggering a bug in PROJ-151 that caused writeback of "next" cache line
                        test_header(testname, "Single AMO request towards upper part of cache line");

                        addr = ArianeCfg.CachedRegionAddrBase[0];

                        // write known value to address 16 in core 0
                        data16 = 64'h00000000_CAFEBABE;
                        dcache_drv[cid][2].wr(.addr(addr + 16), .data(data16));

                        `WAIT_CYC(clk, 1000)

                        // write something to address 8 in core 1
                        data8 = 64'h1111BAAD_F00D0000;
                        dcache_drv[cid2][2].wr(.addr(addr + 8), .data(data8));

                        `WAIT_CYC(clk, 1000)

                        // AMO request to increment data8, should cause flush and writeback of data16 in cache
                        amo_drv[cid].req(.addr(addr + 8), .op(AMO_ADD), .data(17), .check_result(1), .exp_result(data8));
                        data8 = data8 + 17;

                        `WAIT_CYC(clk, 100)

                        // check expected values
                        dcache_drv[cid][1].rd(.do_wait(1), .addr(addr + 16), .check_result(1), .exp_result(data16));

                        `WAIT_CYC(clk, 100)

                        dcache_drv[cid][1].rd(.do_wait(1), .addr(addr + 8),  .check_result(1), .exp_result(data8));

                        `WAIT_CYC(clk, 100)
                    end


                    // - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
                    "amo_snoop_collision" : begin
                        test_header(testname, "AMO request flushing the cache while other core is accessing its contents");

                        wait_time = 50000;

                        // core 1 will have to wait for flush, increase timeout
                        cache_scbd[1].set_cache_msg_timeout(wait_time);

                        // core 0 will have to wait for flush, increase timeout
                        cache_scbd[0].set_amo_msg_timeout(wait_time);


                        // other snooped cores will have to wait for flush, increase timeout
                        for (int core_idx=0; core_idx<NB_CORES; core_idx++) begin : CORE
                            if (core_idx != 1) begin
                                cache_scbd[core_idx].set_snoop_msg_timeout(wait_time);
                            end
                        end

                        addr = ArianeCfg.CachedRegionAddrBase[0];

                        // fill up cache
                        for (int i=0; i<2048; i++) begin
                            dcache_drv[cid][2].wr(.addr(addr + i*8),  .data(64'hBEEFCAFE0000 + i));
                        end

                        fork
                            begin
                                // AMO request, should cause flush and writeback of data in cache
                                amo_drv[cid].req(.addr(addr), .rand_op(1));
                            end
                            begin
                                for (int i=2047;  i>=1; i--) begin // don't verify address (addr + 0), it may have been modified by AMO
                                    dcache_drv[cid2][1].rd(.do_wait(1), .addr(addr + i*8), .check_result(1), .exp_result(64'hBEEFCAFE0000 + i));
                                end
                            end
                        join

                        $display("***\n*** Test finished, waiting %0d cycles to catch possible timeouts\n***",wait_time);
                        `WAIT_CYC(clk, wait_time)

                    end


                    // - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
                    "random_cached", "random_shared", "random_non-shared" : begin

                        case (testname)
                            "random_cached" : begin
                                test_header(testname, "Writes and reads to random cacheable, shareable addresses, excluding AMO requests");
                                base_addr = ArianeCfg.CachedRegionAddrBase[0];
                            end
                            "random_shared" : begin
                                test_header(testname, "Writes and reads to random non-cacheable, shareable addresses, excluding AMO requests");
                                base_addr = ArianeCfg.SharedRegionAddrBase[0];
                            end
                            "random_non-shared" : begin
                                test_header(testname, "Writes and reads to random non-cacheable, non-shareable addresses, excluding AMO requests");
                                base_addr = culsans_pkg::DRAMBase;
                            end
                        endcase

                        rep_cnt   = 1000;
                        // LLC and random AXI delay cause longer tests
                        wait_time = 10000;
                        if (HAS_LLC && STALL_RANDOM_DELAY) begin
                            timeout   += 500000;
                            wait_time = 20000;
                            for (int core_idx=0; core_idx<NB_CORES; core_idx++) begin : CORE
                                cache_scbd[core_idx].set_cache_msg_timeout(20000);
                            end
                        end

                        fork begin // this is needed to make sure the "wait fork" below doesn't affect forks outside this scope
                            for (int c=0; c < NB_CORES; c++) begin
                                fork
                                    automatic int cc = c;
                                    begin
                                        for (int i=0; i<rep_cnt; i++) begin
                                            automatic int offset [3];
                                            automatic int word_size, byte_cnt;
                                            automatic logic [7:0] be;
                                            word_size = $urandom_range(3);
                                            byte_cnt = 2**word_size;

                                            case (word_size)
                                                0 : be = 8'b00000001;
                                                1 : be = 8'b00000011;
                                                2 : be = 8'b00001111;
                                                3 : be = 8'b11111111;
                                            endcase

                                            for (int p=0; p<3; p++) begin
                                                automatic bit hit;
                                                // Randomize address, make sure write address is different from read addresses.
                                                // This emulates to some extent how the core schedules requests.
                                                hit = $urandom_range(1); // increase the chance of address being inside a narrow range to get more hits
                                                do begin
                                                    case (testname)
                                                        "random_cached"     : offset[p] = hit ? $urandom_range(64) + $urandom_range(1) * DCACHE_INDEX_DIST : (cc == cid) ? $urandom_range(ArianeCfg.CachedRegionLength[0]) : $urandom_range(CachedSharedRegionLength); // only one core should enter the cached, non-shared region
                                                        "random_shared"     : offset[p] = hit ? $urandom_range(64) + $urandom_range(1) * DCACHE_INDEX_DIST : $urandom_range(ArianeCfg.CachedRegionAddrBase[0] - base_addr); // don't enter the cached region
                                                        "random_non-shared" : offset[p] = hit ? $urandom_range(64) + $urandom_range(1) * DCACHE_INDEX_DIST : $urandom_range(ArianeCfg.SharedRegionAddrBase[0] - base_addr); // don't enter the shared region
                                                    endcase

                                                    offset[p] = (offset[p] / byte_cnt) * byte_cnt;

                                                end while ((p == 2) && ((offset[2] == offset[1]) ||
                                                                        (offset[2] == offset[0])));
                                            end

                                            for (int p=0; p<3; p++) begin
                                                fork
                                                    automatic int port = p;
                                                    automatic logic [7:0] be_shift;
                                                    begin
                                                        be_shift = be << (offset[port] % 8);
                                                        // add none or a few cycles between requests
                                                        `WAIT_CYC(clk, $urandom_range(4,0));
                                                        // submit a request on each port with a probability
                                                        if ($urandom_range(100) > 50) begin
                                                            if (port == 2) begin
                                                                dcache_drv[cc][2].wr(.addr(base_addr + offset[port]), .rand_data(1), .size(word_size), .be(be_shift));
                                                            end else begin
                                                                dcache_drv[cc][port].rd(.do_wait(1), .addr(base_addr + offset[port]), .size(word_size), .be(be_shift));
                                                            end
                                                        end
                                                    end
                                                join_none
                                            end
                                            wait fork;
                                        end
                                    end
                                join_none
                            end
                            wait fork;
                        end join

                        $display("***\n*** Test finished, waiting %0d cycles to catch possible timeouts\n***",wait_time);
                        `WAIT_CYC(clk, wait_time)

                    end


                    // - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
                    "random_cached_amo", "random_shared_amo", "random_non-shared_amo" : begin
                        case (testname)
                            "random_cached_amo" : begin
                                test_header(testname, "Writes and reads to random cacheable, shareable addresses, including AMO requests");
                                base_addr = ArianeCfg.CachedRegionAddrBase[0];
                            end
                            "random_shared_amo" : begin
                                test_header(testname, "Writes and reads to random non-cacheable, shareable addresses, including AMO requests");
                                base_addr = ArianeCfg.SharedRegionAddrBase[0];
                            end
                            "random_non-shared_amo" : begin
                                test_header(testname, "Writes and reads to random non-cacheable, non-shareable addresses, including AMO requests");
                                base_addr = culsans_pkg::DRAMBase;
                            end
                        endcase

                        rep_cnt   = 1000;
                        wait_time = 10000;

                        // LLC and random AXI delay cause longer tests
                        if (HAS_LLC && STALL_RANDOM_DELAY) begin
                            timeout   += 300000;
                            wait_time = 20000;
                            for (int c=0; c < NB_CORES; c++) begin
                                cache_scbd[c].set_amo_msg_timeout(wait_time);
                            end
                        end

                        for (int c=0; c < NB_CORES; c++) begin
                            // any core may have to wait for AMO/flush, increase timeouts
                            cache_scbd[c].set_cache_msg_timeout(wait_time);
                            cache_scbd[c].set_snoop_msg_timeout(wait_time);
                        end

                        fork begin // this is needed to make sure the "wait fork" below doesn't affect forks outside this scope
                            for (int c=0; c < NB_CORES; c++) begin
                                fork
                                    automatic int cc = c;
                                    begin
                                        for (int i=0; i<rep_cnt; i++) begin
                                            automatic int offset [4];
                                            automatic int word_size, byte_cnt;
                                            automatic logic [7:0] be;
                                            word_size = $urandom_range(3);
                                            byte_cnt = 2**word_size;

                                            case (word_size)
                                                0 : be = 8'b00000001;
                                                1 : be = 8'b00000011;
                                                2 : be = 8'b00001111;
                                                3 : be = 8'b11111111;
                                            endcase


                                            for (int p=0; p<4; p++) begin
                                                automatic bit hit;
                                                // Randomize address, make sure write address is different from read addresses.
                                                // This emulates to some extent how the core schedules requests.
                                                hit = $urandom_range(1); // increase the chance of address being inside a narrow range to get more hits
                                                do begin
                                                    case (testname)
                                                        "random_cached_amo"     : offset[p] = hit ? $urandom_range(64) + $urandom_range(1) * DCACHE_INDEX_DIST : (cc == cid) ? $urandom_range(ArianeCfg.CachedRegionLength[0]) : $urandom_range(CachedSharedRegionLength); // only one core should enter the cached, non-shared region
                                                        "random_shared_amo"     : offset[p] = hit ? $urandom_range(64) + $urandom_range(1) * DCACHE_INDEX_DIST : $urandom_range(ArianeCfg.CachedRegionAddrBase[0] - base_addr); // don't enter the cached region
                                                        "random_non-shared_amo" : offset[p] = hit ? $urandom_range(64) + $urandom_range(1) * DCACHE_INDEX_DIST : $urandom_range(ArianeCfg.SharedRegionAddrBase[0] - base_addr); // don't enter the shared region
                                                    endcase

                                                    offset[p] = (offset[p] / byte_cnt) * byte_cnt;

                                                end while ((p == 2) && ((offset[2] == offset[1]) ||
                                                                        (offset[2] == offset[0])));
                                            end

                                            // submit requests and possibly an AMO
                                            for (int p=0; p<4; p++) begin
                                                fork
                                                    automatic int port = p;
                                                    begin
                                                        // add none or a few cycles between requests
                                                        `WAIT_CYC(clk, $urandom_range(4,0));

                                                        if (port < 3) begin
                                                            // submit a request on each port with a probability
                                                            automatic logic [7:0] be_shift;
                                                            be_shift = be << (offset[port] % 8);
                                                            if ($urandom_range(100) > 50) begin
                                                                if (port == 2) begin
                                                                    dcache_drv[cc][2].wr(.addr(base_addr + offset[port]), .rand_data(1), .size(word_size), .be(be_shift));
                                                                end else begin
                                                                    dcache_drv[cc][port].rd(.do_wait(1), .addr(base_addr + offset[port]), .size(word_size), .be(be_shift));
                                                                end
                                                            end
                                                        end else begin
                                                            // port 3 is AMO
                                                            if ($urandom_range(100) > 80) begin
                                                                automatic int amo_offset;
                                                                automatic int amo_word_size, amo_byte_cnt;

                                                                amo_word_size = $urandom_range(2,3);
                                                                amo_byte_cnt = 2**amo_word_size;
                                                                amo_offset = (offset[port] / amo_byte_cnt) * amo_byte_cnt; // AMOs are always aligned with word width

                                                                amo_drv[cc].req(.addr(base_addr+amo_offset), .rand_op(1),. rand_data(1), .size(amo_word_size));
                                                            end
                                                        end
                                                    end
                                                join_none
                                            end
                                            wait fork;
                                        end
                                    end
                                join_none
                            end
                            wait fork;
                        end join

                        $display("***\n*** Test finished, waiting %0d cycles to catch possible timeouts\n***",wait_time);
                        `WAIT_CYC(clk, wait_time)

                    end


                    // - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
                    "random_cached_flush" : begin
                        test_header(testname, "Writes and reads to random cacheable addresses mixed with occasional flush");

                        base_addr = ArianeCfg.CachedRegionAddrBase[0];

                        rep_cnt   = 1000;
                        wait_time = 20000;

                        // random AXI delay cause longer tests
                        if (STALL_RANDOM_DELAY) begin
                            timeout  += 300000;
                            wait_time = 50000;
                            for (int c=0; c < NB_CORES; c++) begin
                                cache_scbd[c].set_cache_msg_timeout(wait_time);
                                cache_scbd[c].set_snoop_msg_timeout(wait_time);
                            end
                        end

                        fork begin // this is needed to make sure the "wait fork" below doesn't affect forks outside this scope
                            for (int c=0; c < NB_CORES; c++) begin
                                fork
                                    automatic int cc = c;
                                    automatic int port;
                                    automatic int offset;
                                    automatic bit hit;

                                    begin
                                        for (int i=0; i<rep_cnt; i++) begin
                                            if ($urandom_range(99) < 99) begin
                                                port   = $urandom_range(2);
                                                hit    = $urandom_range(1);
                                                offset = hit ? $urandom_range(8) + $urandom_range(1) * DCACHE_INDEX_DIST : (cc == cid) ? $urandom_range(ArianeCfg.CachedRegionLength[0]) : $urandom_range(CachedSharedRegionLength); // only one core should enter the cached, non-shared region

                                                if (port == 2) begin
                                                    dcache_drv[cc][2].wr(.addr(base_addr + offset), .data(64'hBEEFCAFE00000000 + offset), .rand_size_be(1));
                                                end else begin
                                                    dcache_drv[cc][port].rd(.do_wait(1), .addr(base_addr + offset), .rand_size_be(1));
                                                end
                                            end else begin
                                                dcache_mgmt_drv[cc].flush();
                                            end
                                        end
                                    end

                                join_none
                            end
                            wait fork;
                        end join

                        $display("***\n*** Test finished, waiting %0d cycles to catch possible timeouts\n***",wait_time);
                        `WAIT_CYC(clk, wait_time)

                    end


                    // - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
                    "random_cached_shared", "random_cached_non-shared", "random_shared_non-shared", "random_all"  : begin

                        case (testname)
                            "random_cached_shared"     : test_header(testname, "Writes and reads to random addresses:\n  cacheable\n  shareable, non-cacheable");
                            "random_cached_non-shared" : test_header(testname, "Writes and reads to random addresses:\n  cacheable\n  non-shareable, non-cacheable");
                            "random_shared_non-shared" : test_header(testname, "Writes and reads to random addresses:\n  shareable, non-cacheable\n  non-shareable, non-cacheable");
                            "random_all"               : test_header(testname, "Writes and reads to random addresses in all address areas");
                        endcase

                        rep_cnt   = 1000;
                        wait_time = 1000;

                        // LLC and random AXI delay cause longer tests
                        if (HAS_LLC && STALL_RANDOM_DELAY) begin
                            timeout  += 300000;
                            wait_time = 10000;
                            for (int c=0; c < NB_CORES; c++) begin
                                cache_scbd[c].set_cache_msg_timeout(wait_time);
                            end
                        end

                        fork begin // this is needed to make sure the "wait fork" below doesn't affect forks outside this scope
                            for (int c=0; c < NB_CORES; c++) begin
                                fork
                                    automatic int cc = c;
                                    begin
                                        for (int i=0; i<rep_cnt; i++) begin
                                            automatic logic [3:0][63:0] baddr;
                                            automatic int               offset [4];
                                            automatic int               word_size, byte_cnt;
                                            automatic logic       [7:0] be;
                                            word_size = $urandom_range(3);
                                            byte_cnt = 2**word_size;

                                            case (word_size)
                                                0 : be = 8'b00000001;
                                                1 : be = 8'b00000011;
                                                2 : be = 8'b00001111;
                                                3 : be = 8'b11111111;
                                            endcase


                                            for (int p=0; p<4; p++) begin
                                                automatic bit hit;
                                                automatic int addr_region;
                                                // Randomize address, make sure write address is different from read addresses.
                                                // This emulates to some extent how the core schedules requests.
                                                hit = $urandom_range(1); // increase the chance of address being inside a narrow range to get more hits
                                                do begin
                                                    case (testname)
                                                        "random_cached_shared"     : addr_region = $urandom_range(1);     // [0, 1]
                                                        "random_cached_non-shared" : addr_region = $urandom_range(1) * 2; // [0, 2]
                                                        "random_shared_non-shared" : addr_region = $urandom_range(2,1);   // [1, 2]
                                                        "random_all"               : addr_region = $urandom_range(2);     // [0, 1, 2]
                                                    endcase

                                                    case (addr_region)
                                                        0 : begin // "cached" : cached, shared + cached, non-shared
                                                            baddr[p]  = ArianeCfg.CachedRegionAddrBase[0];
                                                            offset[p] = hit ? $urandom_range(64) + $urandom_range(1) * DCACHE_INDEX_DIST : (cc == cid) ? $urandom_range(ArianeCfg.CachedRegionLength[0]) : $urandom_range(CachedSharedRegionLength); // only one core should enter the cached, non-shared region
                                                        end
                                                        1 : begin // "shared" : non-cached, shared
                                                            baddr[p]  = ArianeCfg.SharedRegionAddrBase[0];
                                                            offset[p] = hit ? $urandom_range(64) + $urandom_range(1) * DCACHE_INDEX_DIST : $urandom_range(ArianeCfg.CachedRegionAddrBase[0] - baddr[p]); // don't enter the cached region
                                                        end
                                                        2 : begin // "non-shared" : non-cached, non-shared
                                                            baddr[p]  = culsans_pkg::DRAMBase;
                                                            offset[p] = hit ? $urandom_range(64) + $urandom_range(1) * DCACHE_INDEX_DIST : $urandom_range(ArianeCfg.SharedRegionAddrBase[0] - baddr[p]); // don't enter the shared region
                                                        end
                                                    endcase

                                                    offset[p] = (offset[p] / byte_cnt) * byte_cnt;

                                                end while ((p == 2) && ((offset[2] == offset[1]) ||
                                                                        (offset[2] == offset[0])));
                                            end

                                            for (int p=0; p<4; p++) begin
                                                fork
                                                    automatic int port = p;
                                                    begin
                                                        // add none or a few cycles between requests
                                                        `WAIT_CYC(clk, $urandom_range(4,0));



                                                        if (port < 3) begin
                                                            automatic logic [7:0] be_shift;
                                                            be_shift = be << (offset[port] % 8);

                                                            // submit a request on each port with a probability
                                                            if ($urandom_range(100) > 50) begin
                                                                if (port == 2) begin
                                                                    dcache_drv[cc][2].wr(.addr(baddr[port] + offset[port]), .rand_data(1), .size(word_size), .be(be_shift));
                                                                end else begin
                                                                    dcache_drv[cc][port].rd(.do_wait(1), .addr(baddr[port] + offset[port]), .size(word_size), .be(be_shift));
                                                                end
                                                            end
                                                        end else begin
                                                            // port 3 is AMO
                                                            if ($urandom_range(100) > 80) begin
                                                                automatic int amo_offset;
                                                                automatic int amo_word_size, amo_byte_cnt;

                                                                amo_word_size = $urandom_range(2,3);
                                                                amo_byte_cnt = 2**amo_word_size;
                                                                amo_offset = (offset[port] / amo_byte_cnt) * amo_byte_cnt; // AMOs are always aligned with word width

                                                                amo_drv[cc].req(.addr(baddr[port]+amo_offset), .rand_op(1),. rand_data(1), .size(amo_word_size));
                                                            end
                                                        end
                                                    end
                                                join_none
                                            end
                                            wait fork;
                                        end
                                    end
                                join_none
                            end
                            wait fork;
                        end join

                        $display("***\n*** Test finished, waiting %0d cycles to catch possible timeouts\n***",wait_time);
                        `WAIT_CYC(clk, wait_time)

                    end


                    // - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
                    "snoop_non-cached_collision" : begin
                        test_header(testname, "CLEAN_INVALID from core 1 colliding with bypass read in core 0.\nTrigger issue described in JIRA issue PROJ-149");
                        addr = ArianeCfg.CachedRegionAddrBase[0];

                        // make cache entry is dirty in cache 0
                        dcache_drv[cid][2].wr(.addr(addr));
                        // make cache entry shared in cache 1
                        dcache_drv[cid2][0].rd(.addr(addr));
                        `WAIT_CYC(clk, 100)

                        fork
                            begin
                                // core 0 : read from shared region
                                `WAIT_CYC(clk, 3)
                                dcache_drv[cid][0].rd(.addr(ArianeCfg.SharedRegionAddrBase[0]));
                            end
                            begin
                                // core 1 : write to dirty cache entry, causing CLEAN_INVALID
                                dcache_drv[cid2][2].wr(.addr(addr));
                            end
                        join

                        `WAIT_CYC(clk, 10000) // make sure timeout gets triggered
                    end


                    //******************************************************************************
                    //*** NOTE: this test currently fails at it hits bug described in PROJ-147
                    //******************************************************************************
                    // - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
                    "read_two_writes_back_to_back" : begin
                        test_header(testname, "Single read followed by two writes back to back\nTrigger issue described in JIRA issue PROJ-147");

                        addr = ArianeCfg.CachedRegionAddrBase[0];

                        // make sure data[0] is in cache
                        dcache_drv[cid][0].rd(.addr(addr));
                        `WAIT_CYC(clk, 100)

                        // read followed by 2 writes (here with 1 cc inbetween, could be back-to-back too)
                        dcache_drv[cid][0].rd(.addr(addr));
                        dcache_drv[cid][0].wr(.addr(addr), .data(32'hBBBBBBBB));
                        `WAIT_CYC(clk, 1)
                        dcache_drv[cid][0].wr(.addr(addr), .data(32'hCCCCCCCC));
                        `WAIT_CYC(clk, 1)
                        // read 0 again to visualize in waveforms that the value 0xCCCCCCCC is not stored
                        dcache_drv[cid][0].rd(.addr(addr));

                        `WAIT_CYC(clk, 100)
                    end


                    // - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
                    default : $error("Unknown test name %s",testname);

                endcase


                //--------------------------------------------------------------
                // end of tests
                //--------------------------------------------------------------
                for (int c=0; c < NB_CORES; c++) begin
                    icache_drv[c].stop_random_req();
                end

                `WAIT_CYC(clk, 100)

                $display("Test done");
                $display("--------------------------------------------------------------------------------------------------------");
                for (int c=0; c < NB_CORES; c++) begin
                    for (int p=0; p<3; p++) begin
                        dcache_mon[c][p].print_stats();
                    end
                end
                $display("--------------------------------------------------------------------------------------------------------");


                $finish();

            end

            //------------------------------------------------------------------
            // Timeout
            //------------------------------------------------------------------
            begin
                while (timeout > 0) begin
                    timeout--;
                    `WAIT_CYC(clk, 1)
                end
                $error("Timeout");
                $finish();
            end

        join_any
        disable fork;

    end

endmodule
