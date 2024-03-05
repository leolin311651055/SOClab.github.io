// SPDX-FileCopyrightText: 2020 Efabless Corporation
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
// SPDX-License-Identifier: Apache-2.0

//`include "/home/ubuntu/final/Answer/Ans1/rtl/user/bram11.v"

`default_nettype wire
/*
 *-------------------------------------------------------------
 *
 * user_project_wrapper
 *
 * This wrapper enumerates all of the pins available to the
 * user for the user project.
 *
 * An example user project is provided in this wrapper.  The
 * example should be removed and replaced with the actual
 * user project.
 *
 *-------------------------------------------------------------
 */

module user_project_wrapper #( //conbined in caravel.v
    parameter BITS = 32
) (
`ifdef USE_POWER_PINS
    inout vdda1,	// User area 1 3.3V supply
    inout vdda2,	// User area 2 3.3V supply
    inout vssa1,	// User area 1 analog ground
    inout vssa2,	// User area 2 analog ground
    inout vccd1,	// User area 1 1.8V supply
    inout vccd2,	// User area 2 1.8v supply
    inout vssd1,	// User area 1 digital ground
    inout vssd2,	// User area 2 digital ground
`endif

    // Wishbone Slave ports (WB MI A)
    input wb_clk_i,
    input wb_rst_i,
    input wbs_stb_i,
    input wbs_cyc_i,
    input wbs_we_i,
    input [3:0] wbs_sel_i,
    input [31:0] wbs_dat_i,
    input [31:0] wbs_adr_i,
    output reg wbs_ack_o,
    output reg [31:0] wbs_dat_o,

    // Logic Analyzer Signals
    input  [127:0] la_data_in,
    output [127:0] la_data_out,
    input  [127:0] la_oenb,

    // IOs
    input  [`MPRJ_IO_PADS-1:0] io_in,
    output [`MPRJ_IO_PADS-1:0] io_out,
    output [`MPRJ_IO_PADS-1:0] io_oeb,

    // Analog (direct connection to GPIO pad---use with caution)
    // Note that analog I/O is not available on the 7 lowest-numbered
    // GPIO pads, and so the analog_io indexing is offset from the
    // GPIO indexing by 7 (also upper 2 GPIOs do not have analog_io).
    inout [`MPRJ_IO_PADS-10:0] analog_io,

    // Independent clock (on independent integer divider)
    input   user_clock2,

    // User maskable interrupt signals
    output [2:0] user_irq
);

parameter pDATA_WIDTH = 32;
parameter pADDR_WIDTH = 12;
// WB responding signals
wire        wbs_ack_o_fir;
wire [31:0] wbs_dat_o_fir;

wire [3:0]               tap_WE;
wire                     tap_EN;
wire [(pDATA_WIDTH-1):0] tap_Di;
wire [(pADDR_WIDTH-1):0] tap_A;
wire [(pDATA_WIDTH-1):0] tap_Do;

// bram for data RAM
wire [3:0]               data_WE;
wire                     data_EN;
wire [(pDATA_WIDTH-1):0] data_Di;
wire [(pADDR_WIDTH-1):0] data_A;
wire [(pDATA_WIDTH-1):0] data_Do;

// AXI LITE
wire awready;
wire wready;
wire awvalid;
wire [11:0] awaddr;
wire wvalid;
wire [31:0] wdata;

wire arready;
wire rready;
wire arvalid;
wire [11:0] araddr;
wire rvalid;
wire [31:0] rdata;

// DMA config
wire dma_en;
wire [31:0] r_start_addr;
wire [31:0] w_start_addr;
wire [31:0] read_len;
// wire dma_write_en;
wire dma_busy;

// AXI stream
wire ss_tvalid; 
wire [31:0] ss_tdata; 
wire ss_tlast; 
wire ss_tready; 

wire sm_tready; 
wire sm_tvalid; 
wire [31:0] sm_tdata; 
wire sm_tlast;
wire wbs_ack_o_user, wbs_ack_o_uart;
wire [31:0] wbs_dat_o_user, wbs_dat_o_uart;

always@(*) begin
	wbs_dat_o	= 0;
	wbs_ack_o	= 0;
	if(wbs_cyc_i && wbs_stb_i) begin
		if(wbs_adr_i[31:24] == 'h38) begin
			wbs_dat_o = wbs_dat_o_user;
			wbs_ack_o = wbs_ack_o_user;
		end
		else if(wbs_adr_i[31:24] == 'h30) begin
			wbs_dat_o = wbs_dat_o_uart;
			wbs_ack_o = wbs_ack_o_uart;
		end
		else if(wbs_adr_i[31:24] == 'h31) begin
			wbs_dat_o = wbs_dat_o_fir;
			wbs_ack_o = wbs_ack_o_fir;
		end
	end
end

/*--------------------------------------*/
/* User project is instantiated  here   */
/*--------------------------------------*/
WB_to_User_Bram wb_to_userbram_u (
        .wb_clk_i(wb_clk_i),
        .wb_rst_i(wb_rst_i),
        .wbs_stb_i(wbs_stb_i),
        .wbs_cyc_i(wbs_cyc_i),
        .wbs_we_i(wbs_we_i),
        .wbs_sel_i(wbs_sel_i),
        .wbs_dat_i(wbs_dat_i),
        .wbs_adr_i(wbs_adr_i),
        .wbs_ack_o(wbs_ack_o_user),
        .wbs_dat_o(wbs_dat_o_user),
        
        // DMA signals
        .dma_en(dma_en),
        .r_start_addr(r_start_addr),
        .w_start_addr(w_start_addr),
        .read_len(read_len),
        // .dma_write_en(dma_write_en),
        .dma_busy(dma_busy),
        
        .sm_tready(sm_tready), 
        .sm_tvalid(sm_tvalid), 
        .sm_tdata(sm_tdata), 
        .sm_tlast(sm_tlast), 
        
        .ss_tlast(ss_tlast),
        .ss_tdata(ss_tdata),
        .ss_tvalid(ss_tvalid),
        .ss_tready(ss_tready)
);

WBToAXI wbtoaxi_u (
    // WB
    .wb_clk_i(wb_clk_i),
    .wb_rst_i(wb_rst_i),
    .wbs_stb_i(wbs_stb_i),
    .wbs_cyc_i(wbs_cyc_i),
    .wbs_we_i(wbs_we_i),
    .wbs_sel_i(wbs_sel_i),
    .wbs_dat_i(wbs_dat_i),
    .wbs_adr_i(wbs_adr_i),
    .wbs_ack_o(wbs_ack_o_fir),
    .wbs_dat_o(wbs_dat_o_fir),

    // AXI LITE
    .awready(awready),
    .wready(wready),
    .awvalid(awvalid),
    .awaddr(awaddr),
    .wvalid(wvalid),
    .wdata(wdata),

    .arready(arready),
    .rready(rready),
    .arvalid(arvalid),
    .araddr(araddr),
    .rvalid(rvalid),
    .rdata(rdata)
);

fir fir_1(
    // AXI LITE
    .awready(awready),
    .wready(wready),
    .awvalid(awvalid),
    .awaddr(awaddr),
    .wvalid(wvalid),
    .wdata(wdata),

    .arready(arready),
    .rready(rready),
    .arvalid(arvalid),
    .araddr(araddr),
    .rvalid(rvalid),
    .rdata(rdata),
    
    // DMA config
    .dma_en(dma_en),
    .r_start_addr(r_start_addr),
    .w_start_addr(w_start_addr),
    .read_len(read_len),
    // .dma_write_en(dma_write_en),
    .dma_busy(dma_busy),
    
    // AXI stream
    .ss_tvalid(ss_tvalid), 
    .ss_tdata(ss_tdata), 
    .ss_tlast(ss_tlast), 
    .ss_tready(ss_tready), 

    .sm_tready(sm_tready), 
    .sm_tvalid(sm_tvalid), 
    .sm_tdata(sm_tdata), 
    .sm_tlast(sm_tlast), 

    // bram for tap RAM
    .tap_WE(tap_WE),
    .tap_EN(tap_EN),
    .tap_Di(tap_Di),
    .tap_A(tap_A),
    .tap_Do(tap_Do),

    // bram for data RAM
    .data_WE(data_WE),
    .data_EN(data_EN),
    .data_Di(data_Di),
    .data_A(data_A),
    .data_Do(data_Do),

    .axis_clk(wb_clk_i),
    .axis_rst_n(!wb_rst_i)
);
	

bram11 data_ram (
    .CLK(wb_clk_i),
    .WE(data_WE[0]),
    .EN(data_EN),
    .A(data_A),
    .Di(data_Di),
    .Do(data_Do)
);

bram11 tap_ram (
    .CLK(wb_clk_i),
    .WE(tap_WE[0]),
    .EN(tap_EN),
    .A(tap_A),
    .Di(tap_Di),
    .Do(tap_Do)
);

/*uart uart (
`ifdef USE_POWER_PINS
	.vccd1(vccd1),	// User area 1 1.8V power
	.vssd1(vssd1),	// User area 1 digital ground
`endif
    .wb_clk_i(wb_clk_i),
    .wb_rst_i(wb_rst_i),

    // MGMT SoC Wishbone Slave

    .wbs_stb_i(wbs_stb_i),
    .wbs_cyc_i(wbs_cyc_i),
    .wbs_we_i(wbs_we_i),
    .wbs_sel_i(wbs_sel_i),
    .wbs_dat_i(wbs_dat_i),
    .wbs_adr_i(wbs_adr_i),
    .wbs_ack_o(wbs_ack_o_uart),
    .wbs_dat_o(wbs_dat_o_uart),

    // IO ports
    .io_in  (io_in      ),
    .io_out (io_out     ),
    .io_oeb (io_oeb     ),

    // irq
    .user_irq (user_irq)
);*/

endmodule	// user_project_wrapper

`default_nettype wire
