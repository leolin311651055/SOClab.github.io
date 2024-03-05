module WB_to_User_Bram #(
    parameter BITS = 32,
    parameter DELAYS=10
)(
    // Wishbone Slave ports (WB MI A)
    input wb_clk_i,
    input wb_rst_i,
    input wbs_stb_i,
    input wbs_cyc_i,
    input wbs_we_i,
    input [3:0] wbs_sel_i,
    input [31:0] wbs_dat_i,
    input [31:0] wbs_adr_i,
    output wbs_ack_o,
    output [31:0] wbs_dat_o,
	
	// to DMA signals
    // input config for telling where and how many to fetch
    input wire dma_en,
    input wire [(BITS-1):0]  r_start_addr,
    input wire [(BITS-1):0]  w_start_addr,
    input wire [(BITS-1):0]  read_len,
    // 1 for write to user_bram, 0 for read from user_bram
    // input wire                      dma_write_en, 
	// DMA status
	output wire 					dma_busy,
    // Memory -> DMA buffer
    output wire                     sm_tready, 
    input  wire                     sm_tvalid, 
    input  wire [(BITS-1):0] sm_tdata, 
    input  wire                     sm_tlast, 
    // DMA buffer -> output interface 
    output wire                     ss_tlast,
    output wire [(BITS-1):0]        ss_tdata,
    output wire                     ss_tvalid,
    input  wire                     ss_tready
);
    wire clk;
    wire rst;

    reg [3:0] counter;
    reg valid;
    reg  [31:0] wbs_dat_o;
    reg ack;
	
	// wishbone to user_bram
    wire [3:0]  wb_write_en;
    wire [31:0] wb_address;
    wire [31:0] wb_data_in;
    wire [31:0] wb_data_out;
    wire to_user_bram;
	
	// dma to user_bram
    wire [3:0]  dma_write_en;
    wire [31:0] dma_address;
    wire [31:0] dma_data_in;
    wire [31:0] dma_data_out;
	
	// user_bram_priority arbitrator
	reg wb_or_dma; // 1 for dma, 0 for wb
    wire [3:0]  write_en;
    wire [31:0] address;
    wire [31:0] data_in;
    wire [31:0] data_out;
	
    /*If wb_or_dma is 1, it means that the DMA operation is currently being performed; if it is 0, 
    it means that the Wishbone operation is currently being performed.*/
	always@(posedge clk or negedge rst) begin 
		if(rst) wb_or_dma <= 0;
		else begin
			if(((wbs_cyc_i == 0) || (wbs_stb_i == 0)) && dma_busy == 1) begin
				wb_or_dma <= 1;
			end
			else if(dma_busy == 0) begin
				wb_or_dma <= 0;
			end
			else begin
				wb_or_dma <= wb_or_dma;
			end
		end
	end
	
    assign clk          = wb_clk_i;
    assign rst          = wb_rst_i;
    assign to_user_bram = (wbs_cyc_i && wbs_stb_i && wbs_adr_i[31:24] == 8'h38);
    assign wb_write_en  = to_user_bram ? {4{wbs_we_i}} & wbs_sel_i : 4'b0000;
    assign wb_address   = to_user_bram ? (wbs_adr_i - 32'h38000000) >> 2 : 32'h0;
    assign wb_data_in   = to_user_bram ? wbs_dat_i : 32'h0;
    assign wbs_ack_o    = ack;

    always @(posedge clk or posedge rst) begin
        if(rst) begin
            counter <= 0;
        end
        else begin
            if(wbs_ack_o)           counter <= 0;
            else if(to_user_bram)   counter <= counter + 1;
            else                    counter <= 0;
        end
    end

    always @(posedge clk or posedge rst) begin
        if(rst) begin
            ack <= 0;
        end
        else begin
            if(!wb_or_dma) begin
                if(counter == DELAYS - 1)   ack <= 1;
                else                        ack <= 0;
            end
            else ack <= 0;
        end
    end

    always @(posedge clk or posedge rst) begin
        if(rst) begin
            wbs_dat_o <= 0;
        end
        else begin
            if(counter == DELAYS - 1)   wbs_dat_o <= wb_data_out;
            else                        wbs_dat_o <= 0;
        end
    end
	
	DMA dma_u(
		// system signals
		.clk(clk),
		.rst_n(!rst),
		
		// DMA config
        .dma_valid(wb_or_dma),
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
		
		// dma to user_bram interfece
        .WE0(dma_write_en),
        .Di0(dma_data_in),
        .Do0(dma_data_out),
        .A0(dma_address)
	);

    reg [31:0] dma_data_out_10T [0:(DELAYS-1)];
    integer i;
    always@(posedge clk, posedge rst) begin
        if(rst) begin
            for(i=0; i<DELAYS; i=i+1) begin
                dma_data_out_10T[i] <= 0;
            end
        end else begin
            dma_data_out_10T[DELAYS-1] <= (wb_or_dma == 1) ? data_out : 0;
            for(i=0; i<(DELAYS-1); i=i+1) begin
                dma_data_out_10T[i] <= dma_data_out_10T[i+1];
            end
        end
    end
	
	assign write_en = (wb_or_dma == 1) ? dma_write_en : wb_write_en;
	assign data_in 	= (wb_or_dma == 1) ? dma_data_in : wb_data_in;
	assign address 	= (wb_or_dma == 1) ? dma_address : wb_address;
    assign wb_data_out = (wb_or_dma == 0) ? data_out : 0;
    // assign dma_data_out = (wb_or_dma == 1) ? data_out : 0;
    assign dma_data_out = dma_data_out_10T[0];
	
    bram user_bram (
        .CLK(clk),
        .WE0(write_en),
        .EN0(1'b1),
        .Di0(data_in),
        .Do0(data_out),
        .A0(address)
    );

endmodule
