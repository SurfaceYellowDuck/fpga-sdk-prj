module ddr3_top(
    input          clk,
    input          rst_n,
    input          we,
    input  [31:0]  wr_data,
    input  [27:0]  addr,
    input          ddr_hsel,

    output [31:0]  r_data,
    output                          ddr_rdy,
    // output         cmd_ready,
    output logic         rst_out,

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
    inout                               ddr_dqs_n      //DQS_WIDTH=1
);

logic        clk_mem;
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

assign ddr_rdy  = (rd_data_valid && rd_data_end && cmd_ready) || (wr_data_rdy && cmd_ready);
assign r_data           = rd_data[63:32];
assign wr_data_mask     = {4'b1, 4'b0};

always_ff @(posedge clk) begin
    if(init_calib_complete)begin
        rst_out <= '1;
    end
    else
        rst_out <= '0;
end

always_ff @(posedge clk)begin
	 if (ddr_hsel && we && cmd_ready)begin
		cmd <= 3'b000;
        cmd_en <= '1;
        wr_data_en <= '1;
        wr_data_end <= '1;
	 end
     
     else if (ddr_hsel && ~we && cmd_ready)begin
        cmd <= 3'b001;
        cmd_en <= '1;
    end
    else
        cmd_en <= '0;
        wr_data_en <= '0;
        wr_data_end <= '0;
end

// always_comb begin
//     if (ddr_hsel && we && cmd_ready)begin
//         cmd = 3'b000;
//         cmd_en = '1;
//         wr_data_en = '1;
//         wr_data_end = '1;
//     end
//     else if (ddr_hsel && ~we && cmd_ready)begin
//         cmd = 3'b001;
//         // wr_data_en = '0;
//         // wr_data_end = '1;
//         cmd_en = '1;
//     end
//     else
        // cmd_en = '0;
        // wr_data_en = '0;
        // wr_data_end = '0;
// end

Gowin_rPLL PLL
(
    .clkin (clk),
    .clkout (clk_mem),
    .lock (lock),
    .reset (~rst_n)
);

DDR3_Memory_Interface_Top ddr3_mem(
		.clk(clk), //input clk
		.memory_clk(clk_mem), //input memory_clk
		.pll_lock(lock), //input pll_lock
		.rst_n(rst_n), //input rst_n
		.clk_out(clk_mem_out), //output clk_out
		.ddr_rst(ddr_rst), //output ddr_rst
		.init_calib_complete(init_calib_complete), //output init_calib_complete
		.cmd_ready(cmd_ready), //output cmd_ready
		.cmd(cmd), //input [2:0] cmd
		.cmd_en(cmd_en), //input cmd_en
		.addr(addr), //input [27:0] addr
		.wr_data_rdy(wr_data_rdy), //output wr_data_rdy
		.wr_data({wr_data, 32'b0}), //input [63:0] wr_data
		.wr_data_en(wr_data_en), //input wr_data_en
		.wr_data_end(wr_data_end), //input wr_data_end
		.wr_data_mask(wr_data_mask), //input [7:0] wr_data_mask
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