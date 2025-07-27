/// Copyright by Syntacore LLC © 2016, 2017, 2021. See LICENSE for details
/// @file       <tang20k_scr1.sv>
/// @brief      Top-level entity with SCR1 for Tang Primer 20K board
///
`define SCR1_ARCH_CUSTOM
`include "scr1_arch_types.svh"
`include "scr1_arch_description.svh"
`include "scr1_ahb.svh"
`include "scr1_memif.svh"
`include "scr1_ipic.svh"

//User-defined board-specific parameters accessible as memory-mapped GPIO
parameter bit [31:0] FPGA_PRIMER20K_SOC_ID      = `SCR1_PTFM_SOC_ID;
parameter bit [31:0] FPGA_PRIMER20K_BLD_ID      = `SCR1_PTFM_BLD_ID;
parameter bit [31:0] FPGA_TANG20K_CORE_CLK_FREQ = `SCR1_PTFM_CORE_CLK_FREQ;
parameter SLAVE_DMEM_DEVISES_CNT                = `SLAVE_DMEM_DEVISES_CNT;
parameter SLAVE_IMEM_DEVISES_CNT                = `SLAVE_IMEM_DEVISES_CNT;
parameter ROM_SIZE                              = `ROM_SIZE;

module tang20k_scr1 
(   
    input  logic                        CLK,
    input  logic                        RESETn,
    output logic                        LED0,
    output logic                        LED1,
    output logic                        LED2,
    output logic                        LED3,
    output logic                        LED4,
    output logic                        LED5,
    output logic                        D_OUT_T12,
    // input  logic                        BTN0,
    // input  logic                        BTN1,
    // input  logic                        BTN2,
    // input  logic                        BTN3,
    // input  logic                        BTN4,

    `ifdef SCR1_DBG_EN
    // input  logic                        JTAG_SRST_N,
    input  logic                        JTAG_TRST_N,
    input  logic                        JTAG_TCK,
    input  logic                        JTAG_TMS,
    input  logic                        JTAG_TDI,
    output logic                        JTAG_TDO,
    `endif
    input  logic                        UART_RX,
    output logic                        UART_TX,

    output [13:0]                       ddr_addr,       //ROW_WIDTH=14
    output [2:0]                        ddr_bank,       //BANK_WIDTH=3
    output                              ddr_cs,
    output                              ddr_ras,
    output                              ddr_cas,
    output                              ddr_we,
    output                              ddr_ck,
    output                              ddr_ck_n,
    output                              ddr_cke,
    output                              ddr_odt,
    output                              ddr_reset_n,
    output                              ddr_dm,         //DM_WIDTH=2
    inout   [7:0]                       ddr_dq,         //DQ_WIDTH=16
    inout                               ddr_dqs,        //DQS_WIDTH=2
    inout                               ddr_dqs_n      //DQS_WIDTH=2
);



logic              rd_data_rdy_ddr;
logic [31:0]       ddr_r_data;
logic              ddr_command_ready;
logic              ddr_rst_out;


    // ==  ==  ==  ==  ==  ==  ==  ==  ==  ==  ==  ==  ==  ==  ==  ==  ==  ==  ==  ==  ==  ==  ==  ==  ==  ==  ==  = 
    //  Signals / Variables declarations
    // ==  ==  ==  ==  ==  ==  ==  ==  ==  ==  ==  ==  ==  ==  ==  ==  ==  ==  ==  ==  ==  ==  ==  ==  ==  ==  ==  = 
    logic                               pwrup_rst_n;
    logic                               cpu_clk;
    logic                               extn_rst_in_n;
    logic                               extn_rst_n;
    logic [1:0]                         extn_rst_n_sync;
    logic                               hard_rst_n;
    logic [3:0]                         hard_rst_n_count;
    logic                               soc_rst_n;
    logic                               cpu_rst_n;
    `ifdef SCR1_DBG_EN
    logic                               sys_rst_n;

    
    logic                               dmem_ready;
    logic                               dmem_resp;
    logic                               dmem_hsel;
    `endif // SCR1_DBG_EN
    
    // --- SCR1 ---------------------------------------------
    logic [3:0]                         ahb_imem_hprot;
    logic [2:0]                         ahb_imem_hburst;
    logic [2:0]                         ahb_imem_hsize;
    logic [1:0]                         ahb_imem_htrans;
    logic [SCR1_AHB_WIDTH-1:0]          ahb_imem_haddr;
    logic                               ahb_imem_hready;
    logic [SCR1_AHB_WIDTH-1:0]          ahb_imem_hrdata;
    logic                               ahb_imem_hresp;
    //
    logic [3:0]                         ahb_dmem_hprot;
    logic [2:0]                         ahb_dmem_hburst;
    logic [2:0]                         ahb_dmem_hsize;
    logic [1:0]                         ahb_dmem_htrans;
    logic [SCR1_AHB_WIDTH-1:0]          ahb_dmem_haddr;
    logic                               ahb_dmem_hwrite;
    logic [SCR1_AHB_WIDTH-1:0]          ahb_dmem_hwdata;
    logic                               ahb_dmem_hready;
    logic [SCR1_AHB_WIDTH-1:0]          ahb_dmem_hrdata;
    logic                               ahb_dmem_hresp;
    `ifdef SCR1_IPIC_EN
    logic [31:0]                        scr1_irq;
    `else
    logic                               scr1_irq;
    `endif // SCR1_IPIC_EN
    
    wire  [`SLAVE_DMEM_DEVISES_CNT-1:0] hreadyout;
    wire  [`SLAVE_DMEM_DEVISES_CNT-1:0] resp;
    wire  [`SLAVE_DMEM_DEVISES_CNT-1:0] hsel_;

    wire  [`SLAVE_IMEM_DEVISES_CNT-1:0] ihreadyout;
    wire  [`SLAVE_IMEM_DEVISES_CNT-1:0] imem_hsel;

    logic [SCR1_AHB_WIDTH-1:0]          irdata_rom;
    logic [SCR1_AHB_WIDTH-1:0]          irdata_ddr;

    logic [SCR1_AHB_WIDTH-1:0]          hrdata_0;
    logic [SCR1_AHB_WIDTH-1:0]          hrdata_1;
    

    `ifdef SCR1_DBG_EN
    //logic                               jtag_srst_n;
    logic                               jtag_trst_n;
    logic                               jtag_tck;
    logic                               jtag_tms;
    logic                               jtag_tdi;
    logic                               jtag_tdo;
    logic                               jtag_tdo_en;
    `endif // SCR1_DBG_EN
    
    // --- UART ---------------------------------------------
    logic                               uart_rts_n; // <- UART
    logic                               uart_dtr_n; // <- UART
    logic                               uart_irq;
    logic                               uart_hready;
    logic                               uart_hresp;
    logic                               uart_hsel;
    
    // --- Heartbeat ----------------------------------------
    logic [31:0]                        rtc_counter;
    logic                               tick_2Hz;
    logic                               heartbeat;

    logic [31:0]                        core_frq = FPGA_TANG20K_CORE_CLK_FREQ;
    logic                               ahb_core_frq_sel;
    
    logic                               ddr_dmem_hsel;
    logic                               ddr_imem_hsel;

    
    // ==  ==  ==  ==  ==  ==  ==  ==  ==  ==  ==  ==  ==  ==  ==  ==  ==  ==  ==  ==  ==  ==  ==  ==  ==  ==  ==  = 
    //  Resets
    // ==  ==  ==  ==  ==  ==  ==  ==  ==  ==  ==  ==  ==  ==  ==  ==  ==  ==  ==  ==  ==  ==  ==  ==  ==  ==  ==  = 
    
// always_comb begin
//     if()
// end
// assign LED0 = ddr_rst_out;
assign LED3 = RESETn;



    assign extn_rst_in_n = RESETn;
    assign cpu_clk       = CLK;
    assign pwrup_rst_n   = RESETn;
    
    always_ff @(posedge cpu_clk, negedge pwrup_rst_n)
    begin
        if (~pwrup_rst_n) begin
            extn_rst_n_sync <= '0;
            end else begin
            extn_rst_n_sync[0] <= extn_rst_in_n;
            extn_rst_n_sync[1] <= extn_rst_n_sync[0];
        end
    end
    assign extn_rst_n = extn_rst_n_sync[1];
    
    always_ff @(posedge cpu_clk, negedge pwrup_rst_n)
    begin
        if (~pwrup_rst_n) begin
            hard_rst_n       <= 1'b0;
            hard_rst_n_count <= '0;
            end 
        else begin
            if (hard_rst_n) begin
                // hard_rst_n == 1 - de-asserted
                hard_rst_n       <= extn_rst_n;
                hard_rst_n_count <= '0;
            end 
            else begin
                // hard_rst_n == 0 - asserted
                if (extn_rst_n) begin
                    if (hard_rst_n_count == '1) begin
                        // If extn_rst_n = 1 at least 16 clocks,
                        // de-assert hard_rst_n
                        hard_rst_n <= 1'b1;
                        end else begin
                        hard_rst_n_count <= hard_rst_n_count + 1'b1;
                    end
                end 
                else begin
                    // If extn_rst_n is asserted within 16-cycles window -> start
                    // counting from the beginning
                    hard_rst_n_count <= '0;
                end
            end
        end
    end
    
    `ifdef SCR1_DBG_EN
    assign soc_rst_n = sys_rst_n;
    assign cpu_rst_n = sys_rst_n;
    `else
    assign soc_rst_n = hard_rst_n;
    assign cpu_rst_n = hard_rst_n;
    `endif // SCR1_DBG_EN
    
    // ==  ==  ==  ==  ==  ==  ==  ==  ==  ==  ==  ==  ==  ==  ==  ==  ==  ==  ==  ==  ==  ==  ==  ==  ==  ==  ==  = 
    //  Heartbeat
    // ==  ==  ==  ==  ==  ==  ==  ==  ==  ==  ==  ==  ==  ==  ==  ==  ==  ==  ==  ==  ==  ==  ==  ==  ==  ==  ==  = 
    always_ff @(posedge cpu_clk, negedge hard_rst_n)
    begin
        if (~hard_rst_n) begin
            rtc_counter <= '0;
            tick_2Hz    <= 1'b0;
        end
        else begin
            if (rtc_counter == '0) begin
                rtc_counter <= (FPGA_TANG20K_CORE_CLK_FREQ/2);
                tick_2Hz    <= 1'b1;
            end
            else begin
                rtc_counter <= rtc_counter - 1'b1;
                tick_2Hz    <= 1'b0;
            end
        end
    end
    
    always_ff @(posedge cpu_clk, negedge hard_rst_n)
    begin
        if (~hard_rst_n) begin
            heartbeat <= 1'b0;
        end
        else begin
            if (tick_2Hz) begin
                heartbeat <= ~heartbeat;
            end
        end
    end
    // ==  ==  ==  ==  ==  ==  ==  ==  ==  ==  ==  ==  ==  ==  ==  ==  ==  ==  ==  ==  ==  ==  ==  ==  ==  ==  ==  = 
    //  SCR1 Core's Processor Cluster
    // ==  ==  ==  ==  ==  ==  ==  ==  ==  ==  ==  ==  ==  ==  ==  ==  ==  ==  ==  ==  ==  ==  ==  ==  ==  ==  ==  = 
    scr1_top_ahb
    i_scr1 (
    // Common
    .pwrup_rst_n                (pwrup_rst_n),
    .rst_n                      (hard_rst_n),
    .cpu_rst_n                  (cpu_rst_n),
    .test_mode                  (1'b0),
    .test_rst_n                 (1'b1),
    .clk                        (cpu_clk),
    .rtc_clk                    (1'b0),
    `ifdef SCR1_DBG_EN
    .sys_rst_n_o                (sys_rst_n),
    .sys_rdc_qlfy_o             (),
    `endif // SCR1_DBG_EN
    
    // Fuses
    .fuse_mhartid               ('0),
    `ifdef SCR1_DBG_EN
    .fuse_idcode                (`SCR1_TAP_IDCODE),
    `endif // SCR1_DBG_EN
    
    // IRQ
    `ifdef SCR1_IPIC_EN
    .irq_lines                  (scr1_irq),
    `else
    .ext_irq                    (scr1_irq),
    `endif//SCR1_IPIC_EN
    .soft_irq                   ('0),
    
    // Instruction Memory Interface
    .imem_hprot                 (ahb_imem_hprot),
    .imem_hburst                (ahb_imem_hburst),
    .imem_hsize                 (ahb_imem_hsize),
    .imem_htrans                (ahb_imem_htrans),
    .imem_hmastlock             (),
    .imem_haddr                 (ahb_imem_haddr),
    .imem_hready                (ahb_imem_hready),
    .imem_hrdata                (ahb_imem_hrdata),
    .imem_hresp                 (ahb_imem_hresp),
    // Data Memory Interface
    .dmem_hprot                 (ahb_dmem_hprot),
    .dmem_hburst                (ahb_dmem_hburst),
    .dmem_hsize                 (ahb_dmem_hsize),
    .dmem_htrans                (ahb_dmem_htrans),
    .dmem_hmastlock             (),
    .dmem_haddr                 (ahb_dmem_haddr),
    .dmem_hwrite                (ahb_dmem_hwrite),
    .dmem_hwdata                (ahb_dmem_hwdata),
    .dmem_hready                (ahb_dmem_hready),
    .dmem_hrdata                (ahb_dmem_hrdata),
    .dmem_hresp                 (ahb_dmem_hresp),

    `ifdef SCR1_DBG_EN
    .trst_n                     (jtag_trst_n),
    .tck                        (jtag_tck),
    .tms                        (jtag_tms),
    .tdi                        (jtag_tdi),
    .tdo                        (jtag_tdo),
    .tdo_en                     (jtag_tdo_en)
    `endif
    );
    
    `ifdef SCR1_IPIC_EN
    assign scr1_irq = {31'd0, uart_irq};
    `else
    assign scr1_irq = uart_irq;
    `endif // SCR1_IPIC_EN
    
    `ifdef SCR1_DBG_EN
    assign jtag_trst_n = JTAG_TRST_N;
    assign jtag_tck = JTAG_TCK;
    assign jtag_tms = JTAG_TMS;
    assign jtag_tdi = JTAG_TDI;

    assign JTAG_TDO = (jtag_tdo_en == 1'b1) ? jtag_tdo : 1'bZ;;

    // assign LED2 = 0;
  
    `endif

    // assign LED0             = ~hard_rst_n;
    assign LED5             =  heartbeat;
    assign D_OUT_T12        =  ~heartbeat;
    // assign LED3             =  1'b1;
    assign LED4             =  1'b0;
    
    
    assign ddr_dmem_hsel         = ahb_dmem_haddr[31:28] == 4'b1000;
    assign ddr_imem_hsel         = ahb_imem_haddr[31:28] == 4'b1000;


    assign ahb_core_frq_sel = ahb_dmem_haddr[31:16] == 16'b1111_1111_0000_0000; //frq register
    assign uart_hsel        = ahb_dmem_haddr[31:16] == 16'b1111_1111_0000_0001;  //uart
    assign dmem_hsel        = ahb_dmem_haddr[31:16] == 16'b1111_1111_1111_1111;   //rom
    
    assign r_imem_hsel        = ahb_imem_haddr[31:16] == 16'b1111_1111_1111_1111;
    
    assign hsel_            = {ddr_dmem_hsel, ahb_core_frq_sel, dmem_hsel, uart_hsel};
    assign imem_hsel        = {ddr_imem_hsel, r_imem_hsel};
    // assign

logic           ddr_ready;
logic [31:0]    ddr_haddr;
logic [1:0]     ddr_htrans;
logic           ddr_hwrite;
logic [2:0]     ddr_hsize;
logic [31:0]    ddr_data;
logic           ddr_ready_out;
logic [3:0]     ddr_master_out;
logic           ddr_hsel;
logic [31:0]    ddr_imem_rdata;
logic [31:0]    ddr_dmem_rdata;
logic           ddr_imem_ready;
logic           ddr_dmem_ready;



logic irom_ready;
logic irom_resp;

assign ihreadyout      = {ddr_imem_ready , rom_ready};
assign ihresp          = {1'b0, 1'b0};
assign hreadyout       = {ddr_dmem_ready, 1'b1, dmem_ready, uart_hready};
assign resp            = {1'b0, 1'b0, dmem_resp, uart_hresp};
    
    // logic [31:0] arb_instr_out;

ddr3_top ddr3(
        .clk        (cpu_clk),
        .rst_n      (RESETn),
        .we         (ddr_hwrite),
        .wr_data    (ddr_data),
        .addr       ({ddr_haddr[27:0]}),
        .ddr_hsel   (ddr_hsel),

        .r_data      (ddr_r_data),
        .ddr_rdy     (rd_data_rdy_ddr),
        .rst_out     (ddr_rst_out),
        
        .ddr_addr    (ddr_addr),
        .ddr_bank    (ddr_bank),
        .ddr_cs      (ddr_cs),
        .ddr_ras     (ddr_ras),
        .ddr_cas     (ddr_cas),
        .ddr_we      (ddr_we),
        .ddr_ck      (ddr_ck),
        .ddr_ck_n    (ddr_ck_n),
        .ddr_cke     (ddr_cke),
        .ddr_odt     (ddr_odt),
        .ddr_reset_n (ddr_reset_n),
        .ddr_dqm      (ddr_dm),
        .ddr_dq      (ddr_dq),
        .ddr_dqs     (ddr_dqs),
        .ddr_dqs_n   (ddr_dqs_n),
        .ddr_calib_finished(LED2)
);

    ahb_lite_uart16550
    i_uart(
    .HCLK       (cpu_clk),
    .HRESETn    (soc_rst_n),
    .HADDR      (ahb_dmem_haddr),
    .HBURST     (ahb_dmem_hburst),
    .HMASTLOCK  (1'b1),
    .HPROT      (ahb_dmem_hprot),
    .HSEL       (uart_hsel),
    .HSIZE      (ahb_dmem_hsize),
    .HTRANS     (ahb_dmem_htrans),
    .HWDATA     (ahb_dmem_hwdata),
    .HWRITE     (ahb_dmem_hwrite),
    .HREADY_IN  ('1),
    .HRDATA     (hrdata_0),
    .HREADY     (uart_hready),
    .HRESP      (uart_hresp),
    .SI_Endian  (1'b1),
    
    .UART_SRX   (UART_RX),
    .UART_STX   (UART_TX),
    .UART_RTS   (uart_rts_n),
    .UART_CTS   (uart_rts_n),
    .UART_DTR   (uart_dtr_n),
    .UART_DSR   (uart_dtr_n),
    .UART_RI    ('1),
    .UART_DCD   ('1),
    
    .UART_INT   (uart_irq)
    );
    
    rom_mem
    soc_rom_mem(
    .clk            (cpu_clk),
    .rst_n          (soc_rst_n),
    .dmem_hsel      (dmem_hsel),
    .dmem_hready_in ('1),
    
    .imem_addr      (ahb_imem_haddr[$clog2(ROM_SIZE)+1:2]),
    .imem_trans     (ahb_imem_htrans),
    .imem_hsel      (r_imem_hsel),
    
    .imem_ready     (rom_ready),
    .imem_resp      (),
    .imem_data      (irdata_rom),
    
    .dmem_addr      (ahb_dmem_haddr[$clog2(ROM_SIZE)+1:2]),
    .dmem_trans     (ahb_dmem_htrans),
    
    .dmem_ready     (dmem_ready),
    .dmem_resp      (dmem_resp),
    .dmem_data      (hrdata_1)
    );
    
// by idea arbiter have to keep addr untill it get responce from device
Gowin_AHB_Arbiter_Top ahb_arbiter(
		.HCLK           (cpu_clk), //input HCLK
		.HRESETn        (soc_rst_n), //input HRESETn

		.MHSELS0        (ddr_dmem_hsel), //input MHSELS0
		.MHADDRS0       (ahb_dmem_haddr), //input [31:0] MHADDRS0
		.MHTRANSS0      (ahb_dmem_htrans), //input [1:0] MHTRANSS0
		.MHWRITES0      (ahb_dmem_hwrite), //input MHWRITES0
		.MHSIZES0       (ahb_dmem_hsize), //input [2:0] MHSIZES0
		.MHBURSTS0      (ahb_dmem_hburst), //input [2:0] MHBURSTS0
		.MHPROTS0       (ahb_dmem_hprot), //input [3:0] MHPROTS0
		.MHMASTERS0     (4'b0001), //input [3:0] MHMASTERS0
		.MHWDATAS0      (ahb_dmem_hwdata), //input [31:0] MHWDATAS0
		.MHMASTLOCKS0   (), //input MHMASTLOCKS0
		.MHREADYS0      (1'b1), //input MHREADYS0
		.MHRDATAS0      (ddr_dmem_rdata), //output [31:0] MHRDATAS0
		.MHREADYOUTS0   (ddr_dmem_ready), //output MHREADYOUTS0
		.MHRESPS0       (), //output [1:0] MHRESPS0

		.MHSELS1        (ddr_imem_hsel), //input MHSELS1
		.MHADDRS1       (ahb_imem_haddr), //input [31:0] MHADDRS1
		.MHTRANSS1      (ahb_imem_htrans), //input [1:0] MHTRANSS1
		.MHWRITES1      (1'b0), //input MHWRITES1
		.MHSIZES1       (ahb_imem_hsize), //input [2:0] MHSIZES1
		.MHBURSTS1      (ahb_imem_hburst), //input [2:0] MHBURSTS1
		.MHPROTS1       (ahb_imem_hprot), //input [3:0] MHPROTS1
		.MHMASTERS1     (4'b0010), //input [3:0] MHMASTERS1
		.MHWDATAS1      (), //input [31:0] MHWDATAS1
		.MHMASTLOCKS1   (), //input MHMASTLOCKS1
		.MHREADYS1      (1'b1), //input MHREADYS1
		.MHRDATAS1      (ddr_imem_rdata), //output [31:0] MHRDATAS1
		.MHREADYOUTS1   (ddr_imem_ready), //output MHREADYOUTS1
		.MHRESPS1       (), //output [1:0] MHRESPS1

		.SHRDATAM0      (ddr_r_data), //input [31:0] SHRDATAM0
		.SHREADYOUTM0   (rd_data_rdy_ddr), //input SHREADYOUTM0
		.SHRESPM0       (1'b0), //input [1:0] SHRESPM0
		.SHSELM0        (ddr_hsel), //output SHSELM0
		.SHADDRM0       (ddr_haddr), //output [31:0] SHADDRM0
		.SHTRANSM0      (ddr_htrans), //output [1:0] SHTRANSM0
		.SHWRITEM0      (ddr_hwrite), //output SHWRITEM0
		.SHSIZEM0       (), //output [2:0] SHSIZEM0
		.SHBURSTM0      (), //output [2:0] SHBURSTM0
		.SHPROTM0       (), //output [3:0] SHPROTM0
		.SHMASTERM0     (ddr_master_out), //output [3:0] SHMASTERM0
		.SHWDATAM0      (ddr_data), //output [31:0] SHWDATAM0
		.SHMASTLOCKM0   (), //output SHMASTLOCKM0
		.SHREADYMUXM0   (ddr_ready_out) //output SHREADYMUXM0
);

//mux need only for reading operations
ahb_slave_mux
    soc_ahb_slave_mux(
    .clk        (cpu_clk),
    .rst_n      (soc_rst_n),
    .htrans     (ahb_dmem_htrans),
    .ihtrans    (ahb_imem_htrans),
    
    .dhsel_s    (hsel_),
    .ihsel_s    (imem_hsel),
    // data
    .rdata_0    (hrdata_0),
    .rdata_1    (hrdata_1),
    .rdata_2    (core_frq),
    .rdata_3    (ddr_dmem_rdata),
    // instruction data
    .irdata_rom (irdata_rom),
    .irdata_ddr (ddr_imem_rdata),

    
    .resp       (resp),
    .iresp      (ihresp),

    .readyout   (hreadyout),
    .ireadyout  (ihreadyout),
    
    .hrdata     (ahb_dmem_hrdata),
    .hresp      (ahb_dmem_hresp),
    .hready     (ahb_dmem_hready),

    .ihrdata     (ahb_imem_hrdata),
    .ihresp      (ahb_imem_hresp),
    .ihready     (ahb_imem_hready)
);
    endmodule: tang20k_scr1
