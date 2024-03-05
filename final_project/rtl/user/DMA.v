module DMA #(
    parameter pADDR_WIDTH = 12,
    parameter pDATA_WIDTH = 32
)
(
	// system signals
	input wire 						clk,
	input wire 						rst_n,
	
    // input config for telling where and how many to fetch
	// these signals are from fir.v
    input wire                      dma_valid,
    input wire                      dma_en,
    input wire [(pDATA_WIDTH-1):0]  r_start_addr, // 0x38000200
    input wire [(pDATA_WIDTH-1):0]  w_start_addr, // 0x38000404
    input wire [(pDATA_WIDTH-1):0]  read_len,
	
    // 1 for write to user_bram, 0 for read from user_bram
    // input wire                      dma_write_en, 
	
	// DMA status
	output reg 						dma_busy, //指示DMA模塊是否處於忙狀態。

    // Memory -> DMA buffer
    output reg                      sm_tready, 
    input  wire                     sm_tvalid, 
    input  wire [(pDATA_WIDTH-1):0] sm_tdata, 
    input  wire                     sm_tlast, 

    // DMA buffer -> output interface 
    output reg                      ss_tlast,
    output reg  [(pDATA_WIDTH-1):0] ss_tdata,
    output reg                      ss_tvalid,
    input  wire                     ss_tready,
	
	// user_bram interface
	output reg  [(pDATA_WIDTH-1):0] A0,
	output reg  [(pDATA_WIDTH-1):0] Di0,
	output reg  [3:0] 			   	WE0,
	input  wire [(pDATA_WIDTH-1):0] Do0 // read data from user_bram and pass to fir

);

reg [6:0] ans_cnt;
reg [3:0] cal_cnt; // for 12T fir calculation
reg [3:0] delay_cnt; // user_bram 10T delay
reg [6:0] read_cnt; // count to read_data_len
reg [6:0] write_cnt;
reg [6:0] buf_cnt;
reg [31:0] read_buffer [0:63];
reg [31:0] write_buffer [0:63];
reg [31:0] addr;

//The read_flag and write_flag signals are used to identify whether the current operation is read or write
reg read_flag;
reg write_flag;

always@(posedge clk, negedge rst_n) begin
    if(!rst_n) begin
        delay_cnt <= 0;
    end else begin
        if(dma_valid) begin
            if(delay_cnt < 9)   delay_cnt <= delay_cnt + 1;
            else                delay_cnt <= delay_cnt;
        end
        else begin
            delay_cnt <= 0;
        end
    end
end

always@(posedge clk, negedge rst_n) begin
    if(!rst_n) begin
        read_cnt <= 0;
    end else begin
        if(dma_valid) begin
            if(read_cnt < read_len) read_cnt <= read_cnt + 1;
            else                    read_cnt <= read_cnt;
        end
        else begin
            read_cnt <= 0;
        end
    end
end

always@(posedge clk, negedge rst_n) begin
    if(!rst_n) begin
        buf_cnt <= 0;
    end else begin
        if(dma_valid) begin
            if(buf_cnt < read_len && read_cnt >= 11)buf_cnt <= buf_cnt + 1;
            else                                    buf_cnt <= buf_cnt;
        end
        else begin
            buf_cnt <= 0;
        end
    end
end

always@(posedge clk, negedge rst_n) begin
    if(!rst_n) begin
        read_flag <= 0;
        write_flag <= 0;
    end
    else begin
        if(dma_valid) begin
            // read_flag
            if(buf_cnt < read_len - 1)  read_flag <= 1;
            else                        read_flag <= 0;

            // write flag
            if(sm_tlast)                    write_flag <= 1;
            //"write_cnt < read_len" can determine that read end or not, and we start write 
            else if(write_cnt < read_len -1)write_flag <= write_flag;  
            else                            write_flag <= 0;
        end
    end
end

genvar i;
generate
    for(i=0; i<64; i=i+1) begin :READ_BUFFER
        always@(posedge clk, negedge rst_n) begin
            if(!rst_n) begin
                read_buffer[i] <= 0;
            end else begin
                if(i == buf_cnt && read_flag) begin
                    read_buffer[i] <= Do0;
                end
            end
        end
    end
endgenerate

always@(*) begin
    if(write_flag == 0) addr = (r_start_addr - 32'h38000000 + (read_cnt << 2)) >> 2;
    else                addr = (w_start_addr - 32'h38000000 + (write_cnt << 2)) >> 2;
end

always@(posedge clk, negedge rst_n) begin
    if(!rst_n) begin
        cal_cnt <= 13;
    end else begin
        if(dma_valid && delay_cnt == 9) begin
            if(cal_cnt < 13)        cal_cnt <= cal_cnt + 1;
            else if(cal_cnt == 13)  cal_cnt <= 1;
        end
        else begin
            cal_cnt <= 13;
        end
    end
end

always@(posedge clk, negedge rst_n) begin
    if(!rst_n) begin
        ans_cnt <= 0;
    end else begin
        if(dma_valid) begin
            if(cal_cnt == 2)        ans_cnt <= ans_cnt + 1;
            else                    ans_cnt <= ans_cnt;
        end
        else begin
            ans_cnt <= 0;
        end
    end
end

// ss part, DMA use AXI-Stream to receive and send data
always@(posedge clk, negedge rst_n) begin
    if(!rst_n) begin
        ss_tlast <= 0;
        ss_tvalid <= 0;
        ss_tdata <= 0;
    end else begin
        if(dma_valid) begin
            if(delay_cnt == 9) begin
                ss_tvalid <= (cal_cnt == 13 || cal_cnt == 1);
                ss_tlast <= (cal_cnt == 13 || cal_cnt == 1);
                ss_tdata <= read_buffer[ans_cnt];
            end
        end
    end
end

// sm part, DMA use AXI-Stream to receive and send data
always@(posedge clk, negedge rst_n) begin
    if(!rst_n) begin
        sm_tready <= 0;
    end else begin
        sm_tready <= (dma_busy) ? 1 : 0;
    end
end

genvar j;
generate
    for(j=0; j<64; j=j+1) begin :WRITE_BUFFER
        always@(posedge clk, negedge rst_n) begin
            if(!rst_n) begin
                write_buffer[j] <= 0;
            end else begin
                if(j == ans_cnt - 1 && (sm_tready && sm_tvalid)) begin
                    write_buffer[j] <= sm_tdata;
                end
            end
        end
    end
endgenerate

always@(posedge clk, negedge rst_n) begin
    if(!rst_n)  write_cnt <= 0;
    else begin
        if(dma_valid) begin
            if(write_flag) begin
                //"write_cnt < read_len" can determine that read end or not, and we start write 
                if(write_cnt < read_len)    write_cnt <= write_cnt + 1;
                else                        write_cnt <= write_cnt;
            end
        end
        else begin
            write_cnt <= 0;
        end
    end
end

// user bram interface
always@(*) begin
    A0 = 0;
    Di0 = 0;
    WE0 = 0;
    if(dma_valid) begin
        A0 = addr;
        Di0 = (write_flag) ? write_buffer[write_cnt] : 0;
        WE0 = {4{write_flag}};
    end
end

always@(posedge clk, negedge rst_n) begin
	if(!rst_n)	dma_busy <= 0;
	else begin
        if(dma_en)                      dma_busy <= 1;
        else if(write_cnt == read_len)  dma_busy <= 0;
        else                            dma_busy <= dma_busy;
	end
end

endmodule
