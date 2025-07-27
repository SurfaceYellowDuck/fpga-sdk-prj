module ddr3_top(
    input                               clk,
    input                               rst_n,
    input                               we,
    input  [31:0]                       wr_data,
    input  [27:0]                       addr,
    input                               ddr_hsel,

    output logic [31:0]                 r_data,
    output logic                        ddr_rdy,
    // output         cmd_ready,
    output logic                        rst_out,

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
    output                              ddr_dqm,         //DM_WIDTH=1
    inout   [7:0]                       ddr_dq,         //DQ_WIDTH=8
    inout                               ddr_dqs,        //DQS_WIDTH=1
    inout                               ddr_dqs_n,      //DQS_WIDTH=1
    output logic                        ddr_calib_finished
);

always_comb begin
    if 
    ddr_calib_finished
end

logic        clk_mem;
logic        clk_ctrl;
logic        lock;
logic        clk_mem_out;
logic        ddr_rst;
logic        init_calib_complete;
logic [2:0]  cmd;
logic        cmd_en;
logic        wr_data_rdy;
logic        wr_data_en;
logic        wr_data_end;
logic [7:0]  wr_data_mask;
logic [63:0] rd_data;
logic        rd_data_valid;
logic        rd_data_end;
logic        cmd_ready;

logic from_clk_data_out_vld;
logic [67:0] from_clk_data_out;
logic from_clk_data_in_valid;


logic from_clk_mem_out_data_out_vld;

logic [67:0] data_from_clk;

logic [36:0] data_from_ddr_clk_mem_in;

logic [36:0] data_from_ddr_clk_mem_out;

// logic ddr_rdy;
// logic rd_data_vld;

// logic [59:0] wdout;

// logic [32:0] rdout;
// assign ddr_rdy = (rd_data_valid && rd_data_end && cmd_ready) && (wr_data_rdy && cmd_ready);
assign ddr_rdy = (data_from_ddr_clk_mem_out[3] && data_from_ddr_clk_mem_out[4] && data_from_ddr_clk_mem_out[1]) && (data_from_ddr_clk_mem_out[0] && data_from_ddr_clk_mem_out[1]);

assign r_data = data_from_ddr_clk_mem_out[36:5];


assign from_clk_data_in_valid = ddr_hsel && we;


assign data_from_clk = {wr_data, addr[27:0], cmd, cmd_en, wr_data_en, wr_data_end, from_clk_data_in_valid, rst_n};

assign data_from_ddr_clk_mem_in = {rd_data[31:0], rd_data_end, rd_data_valid, init_calib_complete, cmd_ready, wr_data_rdy};


Handshake_syn #(.WIDTH (68)) synch_from_clk (
    .sclk   (clk),
    .dclk   (clk_ctrl),
    .rst_n  (rst_n),
    .sready (from_clk_data_in_valid),
    .din    (data_from_clk),
    .dbusy  ('0),
    .sidle  (),
    .dvalid (from_clk_data_out_vld),
    .dout   (from_clk_data_out)
);

Handshake_syn #(.WIDTH (37)) synch_from_clk_mem_out (
    .sclk   (clk_mem_out),
    .dclk   (clk),
    .rst_n  (ddr_rst),
    .sready (rd_data_valid),
    .din    (data_from_ddr_clk_mem_in),
    .dbusy  ('0),
    .sidle  (),
    .dvalid (from_clk_mem_out_data_out_vld),
    .dout   (data_from_ddr_clk_mem_out)
);

always_comb begin
     if (ddr_hsel && we && cmd_ready)begin
        cmd = 3'b000;
        cmd_en = '1;
        wr_data_en = '1;
        wr_data_end = '1;
     end
     
     else if (ddr_hsel && ~we && cmd_ready)begin
        cmd = 3'b001;
        cmd_en = '1;
    end
    else
        cmd_en = '0;
        wr_data_en = '0;
        wr_data_end = '0;
end

Gowin_rPLL PLL
(
    .clkin (clk),
    .clkout (clk_mem),
    .clkoutd(clk_ctrl),
    .lock (lock),
    .reset (~rst_n)
);



DDR3_Memory_Interface_Top ddr3_mem(
        .clk(clk_ctrl), //input clk
        .memory_clk(clk_mem), //input memory_clk
        .pll_lock(lock), //input pll_lock
        .rst_n(from_clk_data_out[0]), //input rst_n

        .clk_out(clk_mem_out), //output clk_out
        .ddr_rst(ddr_rst), //output ddr_rst
        .init_calib_complete(init_calib_complete), //output init_calib_complete
        .cmd_ready(cmd_ready), //output cmd_ready
        
        .cmd(from_clk_data_out[8:6]), //input [2:0] cmd
        .cmd_en(from_clk_data_out[5]), //input cmd_en
        .addr(from_clk_data_out[35:9]), //input [27:0] addr
        
        .wr_data_rdy(wr_data_rdy), //output wr_data_rdy
        
        .wr_data({32'b0, from_clk_data_out[67:36]}), //input [63:0] wr_data
        .wr_data_en(from_clk_data_out[4]), //input wr_data_en
        .wr_data_end(from_clk_data_out[3]), //input wr_data_end
        .wr_data_mask(8'b00001111), //input [7:0] wr_data_mask
        .rd_data(rd_data), //output [63:0] rd_data

        .rd_data_valid(rd_data_valid), //output rd_data_valid
        .rd_data_end(rd_data_end), //output rd_data_end
        .sr_req(1'b0), //input sr_req
        .ref_req(1'b0), //input ref_req
        .sr_ack(), //output sr_ack
        .ref_ack(), //output ref_ack
        .burst(1'b1), //input burst

        .O_ddr_addr(ddr_addr), //output [13:0] O_ddr_addr
        .O_ddr_ba(ddr_bank), //output [2:0] O_ddr_ba
        .O_ddr_cs_n(ddr_cs), //output O_ddr_cs_n
        .O_ddr_ras_n(ddr_ras), //output O_ddr_ras_n
        .O_ddr_cas_n(ddr_cas), //output O_ddr_cas_n
        .O_ddr_we_n(ddr_we), //output O_ddr_we_n
        .O_ddr_clk(ddr_ck), //output O_ddr_clk
        .O_ddr_clk_n(ddr_ck_n), //output O_ddr_clk_n
        .O_ddr_cke(ddr_cke), //output O_ddr_cke
        .O_ddr_odt(ddr_odt), //output O_ddr_odt
        .O_ddr_reset_n(ddr_reset_n), //output O_ddr_reset_n
        .O_ddr_dqm(ddr_dqm), //output [0:0] O_ddr_dqm
        .IO_ddr_dq(ddr_dq), //inout [7:0] IO_ddr_dq
        .IO_ddr_dqs(ddr_dqs), //inout [0:0] IO_ddr_dqs
        .IO_ddr_dqs_n(ddr_dqs_n) //inout [0:0] IO_ddr_dqs_n
    );
endmodule
