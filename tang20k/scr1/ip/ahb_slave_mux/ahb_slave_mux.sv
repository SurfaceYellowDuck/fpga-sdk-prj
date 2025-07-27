`include "scr1_arch_custom.svh"
module ahb_slave_mux 
(
                input                                clk,
                input                                rst_n,
                
                input        [SLAVE_DMEM_DEVISES_CNT-1:0] dhsel_s,
                input        [SLAVE_IMEM_DEVISES_CNT-1:0] ihsel_s,
                
                input        [1:0]                   htrans,
                input        [1:0]                   ihtrans,

                input        [31:0]                  rdata_0,
                input        [31:0]                  rdata_1,
                input        [31:0]                  rdata_2,
                input        [31:0]                  rdata_3,

                input        [31:0]                  irdata_rom,
                input        [31:0]                  irdata_ddr,
                
                input        [SLAVE_DMEM_DEVISES_CNT-1:0] resp,
                input        [SLAVE_IMEM_DEVISES_CNT-1:0] iresp,
                
                input        [SLAVE_DMEM_DEVISES_CNT-1:0] readyout,
                input        [SLAVE_IMEM_DEVISES_CNT-1:0] ireadyout,

                output logic [31:0]                  hrdata,
                output logic                         hresp,
                output logic                         hready,

                output logic [31:0]                  ihrdata,
                output logic                         ihresp,
                output logic                         ihready
);
logic [SLAVE_DMEM_DEVISES_CNT-1:0] dlocal_hsel;
logic [SLAVE_IMEM_DEVISES_CNT-1:0] ilocal_hsel;

always_ff @(posedge clk)begin
    if (~rst_n)begin
        dlocal_hsel <= 4'b0;
    end
    else if (dlocal_hsel[3] && ~readyout[3])begin
        dlocal_hsel[3] <= '1;
    end
    else if (htrans != 2'b0 && dhsel_s != 4'b0) begin
        dlocal_hsel <= dhsel_s;
    end      
end

always_comb begin
    if (dlocal_hsel[0] == 1) begin
        hresp  = resp[0];
        hrdata = rdata_0;
        hready = readyout[0];
    end
    else if (dlocal_hsel[1] == 1) begin
        hready = readyout[1];
        hrdata = rdata_1;
        hresp  = resp[1];
    end
    else if (dlocal_hsel[2] == 1) begin
        hready = readyout[2];
        hrdata = rdata_2;
        hresp  = resp[2];
    end

    else if(dlocal_hsel[3] == 1) begin
        hready = readyout[3];
        hrdata = rdata_3;
        hresp  = resp[3];
    end

    else begin
        hready = 1'b1;
        hrdata = 32'b0;
        hresp  = 1'b0;
    end
    end

always_ff @(posedge clk)begin
    if (~rst_n)begin
        ilocal_hsel <= 4'b0;
    end
    else if (ilocal_hsel[1] && ~ireadyout[1])begin
        ilocal_hsel[1] <= '1;
    end
    else if (ihtrans != 2'b0 && ihsel_s != 2'b0) begin
        ilocal_hsel <= ihsel_s;
    end      
end

always_comb begin
    if (ilocal_hsel[0] == 1) begin
        ihresp  = iresp[0];
        ihrdata = irdata_rom;
        ihready = ireadyout[0];
    end
    else if (ilocal_hsel[1] == 1) begin
        ihready = ireadyout[1];
        ihrdata = irdata_ddr;
        ihresp  = iresp[1];
    end
    else begin
        ihready = 1'b1;
        ihrdata = 32'b0;
        ihresp  = 1'b0;
    end
end
endmodule: ahb_slave_mux
