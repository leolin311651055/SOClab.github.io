`include "FIR_kernel.v"
`timescale 1ns / 100ps
module fir 
#(  parameter pADDR_WIDTH = 12,
    parameter pDATA_WIDTH = 32,
    parameter Tape_Num    = 11,
    parameter IDLE        =  0,
    parameter WAIT        =  0,
    parameter TRAN          =  1,
    parameter Received_Address = 1 ,
    parameter WORK        =  2
)
(
    output  wire                     awready,
    output  wire                     wready,
    input   wire                     awvalid,
    input   wire [(pADDR_WIDTH-1):0] awaddr,
    input   wire                     wvalid,
    input   wire [(pDATA_WIDTH-1):0] wdata,
    output  wire                     arready,
    input   wire                     rready,
    input   wire                     arvalid,
    input   wire [(pADDR_WIDTH-1):0] araddr,
    output  wire                     rvalid,
    output  wire [(pDATA_WIDTH-1):0] rdata,    
    input   wire                     ss_tvalid, 
    input   wire [(pDATA_WIDTH-1):0] ss_tdata, 
    input   wire                     ss_tlast, 
    output  wire                     ss_tready, 
    input   wire                     sm_tready, 
    output  wire                     sm_tvalid, 
    output  wire [(pDATA_WIDTH-1):0] sm_tdata, 
    output  wire                     sm_tlast, 
    
    // bram for tap RAM
    output  wire [3:0]               tap_WE,
    output  wire                     tap_EN,
    output  wire [(pDATA_WIDTH-1):0] tap_Di,
    output  wire [(pADDR_WIDTH-1):0] tap_A,
    input   wire [(pDATA_WIDTH-1):0] tap_Do,
    output  reg  [(pDATA_WIDTH-1):0] tap_Do_out,

    // bram for data RAM
    output  wire [3:0]               data_WE,
    output  wire                     data_EN,
    output  wire [(pDATA_WIDTH-1):0] data_Di,
    output  wire [(pADDR_WIDTH-1):0] data_A,
    input   wire [(pDATA_WIDTH-1):0] data_Do,
    output  reg  [(pDATA_WIDTH-1):0] data_Do_out,

    input   wire                     axis_clk,
    input   wire                     axis_rst_n
);

    
    
    //def parameter

    //change to use the code in the always function
    reg                         awready_temp;
    reg                         wready_temp;
    reg                         arready_temp;
    reg                         rvalid_temp;
    reg [(pDATA_WIDTH-1):0]     rdata_temp;
    reg                         ss_tready_temp;

    reg                         sm_tvalid_temp;
    reg                         sm_tlast_temp;
    reg [(pDATA_WIDTH-1):0]     sm_tdata_temp;
    wire[31:0]                  Y ;
    reg [31:0]                  Y_temp ;

    reg [3:0]                   tap_WE_temp;
    reg                         tap_EN_temp;
    reg[(pDATA_WIDTH-1):0]      tap_Di_temp; 
    reg[(pADDR_WIDTH-1):0]      tap_A_temp;

    reg[3:0]                    data_WE_temp;
    reg                         data_EN_temp;
    reg [(pDATA_WIDTH-1):0]     data_Di_temp;
    reg [(pADDR_WIDTH-1):0]     data_A_temp;


    assign      awready = awready_temp;
    assign      wready = wready_temp;
    assign      arready = arready_temp;
    assign      rvalid = rvalid_temp;
    assign      rdata[(pDATA_WIDTH-1):0] = rdata_temp[(pDATA_WIDTH-1):0];
    assign      ss_tready = ss_tready_temp;
    assign      sm_tvalid = sm_tvalid_temp;
    assign      sm_tlast = sm_tlast_temp;
    assign      sm_tdata = sm_tdata_temp;

    assign      tap_WE[3:0] = tap_WE_temp;
    assign      tap_EN = tap_EN_temp;
    assign      tap_Di[(pDATA_WIDTH-1):0] = tap_Di_temp[(pDATA_WIDTH-1):0];
    assign      tap_A[(pADDR_WIDTH-1):0] = tap_A_temp[(pADDR_WIDTH-1):0];

    assign      data_WE[3:0] = data_WE_temp;
    assign      data_EN = data_EN_temp;
    assign      data_Di[(pDATA_WIDTH-1):0] = data_Di_temp[(pDATA_WIDTH-1):0];
    assign      data_A[(pADDR_WIDTH-1):0] = data_A_temp[(pADDR_WIDTH-1):0];
    //change to use the code in the always function








    // Parameters Defined//
    reg                 AP_START , AP_IDLE , AP_DONE;
    reg [1:0]           Read_Address;
    reg [3:0]           tap_count , data_count ;

    reg [2:0]           FIR_STATE ; 
    reg [2:0]           FIR_Next_STATE ;

    reg                 Write_and_WriteAddress_STATE ;
    reg [2:0]           Write_and_WriteAddress_Next_STATE ;

    reg                 Read_and_ReadAddress_STATE ;
    reg [2:0]           Read_and_ReadAddress_Next_STATE ;

    reg [1:0]           Write_Address;
    reg [31:0]          data_length ;
    reg [1:0]           Write_or_Read_Tap ;
    reg [3:0]           count_t; 
    reg [31:0]          count_d;
    reg [1:0]           Last;
    // Parameters Defined//





    //Solve Tap_Do
    always @(posedge tap_EN_temp) begin
        if (~axis_rst_n) begin
            count_t= 0;
        end 
        else if ((count_t < 11)&(axis_rst_n)) begin
            tap_Do_out <= 1'b0;
            count_t <= count_t + 1'b1;
        end 
        else if((count_t==11)&(axis_rst_n)) begin
            count_t <= count_t + 1'b1;
        end
    end

    always @(*) begin
        if (~axis_rst_n) begin
            tap_Do_out=0;
        end 
        else if ((count_t > 11)&(axis_rst_n))begin
            tap_Do_out <= tap_Do;
        end
    end
    //Solve Tap_Do



    //Solve Data_Do

    always @(*) begin
        if (~axis_rst_n) begin
            count_d = 0;
        end 
    end

    always @(negedge data_WE_temp[0]) begin
        count_d <= count_d + 1'b1;
    end


    always @(negedge data_WE_temp[0]) begin
        if(~axis_rst_n)begin
            data_Do_out=0; 
        end
        else if ((count_d < 12)&&(axis_rst_n)) begin
            #10;
            data_Do_out <= data_Do;
            if (count_d == 1) begin
            end
            else if (count_d == 2) begin
            end
            else if (count_d == 3) begin
                #10;
                data_Do_out <= data_Do;
            end
            else if (count_d == 4) begin
                #10;
                data_Do_out <= data_Do;
                #10;
                data_Do_out <= data_Do;
            end
            else if (count_d == 5) begin
                #10;
                data_Do_out <= data_Do;
                #10;
                data_Do_out <= data_Do;
                #10;
                data_Do_out <= data_Do;
            end
            else if (count_d == 6) begin
                #10;
                data_Do_out <= data_Do;
                #10;
                data_Do_out <= data_Do;
                #10;
                data_Do_out <= data_Do;
                #10;
                data_Do_out <= data_Do;
            end
            else if (count_d == 7) begin
                #10;
                data_Do_out <= data_Do;
                #10;
                data_Do_out <= data_Do;
                #10;
                data_Do_out <= data_Do;
                #10;
                data_Do_out <= data_Do;
                #10;
                data_Do_out <= data_Do;
            end
            else if (count_d == 8) begin
                #10;
                data_Do_out <= data_Do;
                #10;
                data_Do_out <= data_Do;
                #10;
                data_Do_out <= data_Do;
                #10;
                data_Do_out <= data_Do;
                #10;
                data_Do_out <= data_Do;
                #10;
                data_Do_out <= data_Do;
            end
            else if (count_d == 9) begin
                #10;
                data_Do_out <= data_Do;
                #10;
                data_Do_out <= data_Do;
                #10;
                data_Do_out <= data_Do;
                #10;
                data_Do_out <= data_Do;
                #10;
                data_Do_out <= data_Do;
                #10;
                data_Do_out <= data_Do;
                #10;
                data_Do_out <= data_Do;
            end
            else if (count_d == 10) begin
                #10;
                data_Do_out <= data_Do;
                #10;
                data_Do_out <= data_Do;
                #10;
                data_Do_out <= data_Do;
                #10;
                data_Do_out <= data_Do;
                #10;
                data_Do_out <= data_Do;
                #10;
                data_Do_out <= data_Do;
                #10;
                data_Do_out <= data_Do;
                #10;
                data_Do_out <= data_Do;
            end
            else if (count_d == 11) begin
                #10;
                data_Do_out <= data_Do;
                #10;
                data_Do_out <= data_Do;
                #10;
                data_Do_out <= data_Do;
                #10;
                data_Do_out <= data_Do;
                #10;
                data_Do_out <= data_Do;
                #10;
                data_Do_out <= data_Do;
                #10;
                data_Do_out <= data_Do;
                #10;
                data_Do_out <= data_Do;
                #10;
                data_Do_out <= data_Do;
            end
            data_Do_out <= 1'b0;
        end 
    end

    always @(*) begin
        if(~axis_rst_n)begin
            data_Do_out=0; 
        end
        else if((data_Do==0 & count_d<12)&(axis_rst_n))begin
            data_Do_out<=0;
        end
    end

    always @(*) begin
        if(~axis_rst_n)begin
            data_Do_out=0; 
        end
        else if ((count_d > 11)&(axis_rst_n))begin
            #10;
            data_Do_out <= data_Do;
        end
    end
    //Solve Data_Do




    // AP_IDLE assignment //
    always @(posedge axis_clk or negedge axis_rst_n) begin
        if (~axis_rst_n) begin
            AP_IDLE <= 1'b1 ;
        end 
        else begin
            if (AP_START) begin
                AP_IDLE <= 1'b0 ;
            end else if (FIR_STATE==IDLE) begin
                AP_IDLE <= 1'b1 ;
            end else begin
                AP_IDLE <= AP_IDLE ;
            end
        end
    end
   // AP_IDLE assignment //



    // RAM pointer //
    always @(posedge axis_clk or negedge axis_rst_n) begin
        if (~axis_rst_n)begin
            tap_count <= 0 ;
            data_count <= 0 ;
        end else begin
            if (tap_EN_temp) begin
                if (tap_count==4'b1010) begin
                    tap_count <= 4'b0000;
                end else begin
                    tap_count <= tap_count + 1'b1 ;
                end
            end
            

            if (data_EN_temp) begin
                if (tap_count == 4'd10) begin
                    data_count <= data_count ; 
                    data_EN_temp <= 1'b1 ;         // Latch ? 
                end else if (data_count == 4'b1010) begin
                    data_count <= 4'b0000;
                    data_EN_temp <= 1'b0 ; 
                end else begin
                    data_count <= data_count + 1'b1 ;
                    data_EN_temp <= 1'b0 ; 
                end
            end
        end
    end

    always @(*) begin
        tap_A_temp = tap_count << 2 ;
        data_A_temp = data_count << 2 ;
    end
    // RAM pointer //
    



    // FIR Working or Nonworking //
    always @(posedge axis_clk or negedge axis_rst_n) begin
        if (~axis_rst_n) begin
            FIR_STATE <= IDLE ;
        end else begin
            FIR_STATE <= FIR_Next_STATE ;
        end
    end

    always @(*) begin
        case (FIR_STATE)
            IDLE: begin
                FIR_Next_STATE = (AP_START)? (WORK):(IDLE);
            end 
            WORK : begin
                FIR_Next_STATE = (AP_DONE & rready & rvalid_temp &arvalid)? (IDLE):(WORK);
            end
            default: begin 
                FIR_Next_STATE = IDLE ;
            end
        endcase
    end
    // FIR Working or Nonworking //



    // AXI Stream Control Write and Write Address //
    always @(posedge axis_clk or negedge axis_rst_n) begin
        if (~axis_rst_n) begin
            Write_and_WriteAddress_STATE <= WAIT ;
        end else begin
            Write_and_WriteAddress_STATE <= Write_and_WriteAddress_Next_STATE ;
        end
    end

    always @(*) begin
        if (FIR_STATE==IDLE) begin
            case (Write_and_WriteAddress_STATE)
                WAIT : begin
                    Write_and_WriteAddress_Next_STATE = (awvalid) ? (Received_Address) : (WAIT);
                    awready_temp = 1'b1 ;
                    wready_temp  = 1'b0 ;
                end
                Received_Address : begin
                    Write_and_WriteAddress_Next_STATE = (wvalid) ? (WAIT) : (Received_Address);
                    awready_temp = 1'b0 ;
                    wready_temp  = 1'b1 ;
                end  
                default: begin
                    Write_and_WriteAddress_Next_STATE = WAIT ;
                    awready_temp = 1'b1 ;
                    wready_temp  = 1'b0 ;
                end
            endcase
        end else begin
            Write_and_WriteAddress_Next_STATE = WAIT ;
        end
    end
    // AXI Stream Control Write and Write Address //



    // AXI Stream Control Read and Read Address //
    always @(posedge axis_clk or negedge axis_rst_n) begin
        if (~axis_rst_n) begin
            Read_and_ReadAddress_STATE <= WAIT ;
        end else begin
            Read_and_ReadAddress_STATE <= Read_and_ReadAddress_Next_STATE ;
        end
    end

    always @(*) begin
        case (Read_and_ReadAddress_STATE)
            WAIT :  begin
                Read_and_ReadAddress_Next_STATE = (arvalid) ? (TRAN) : (WAIT) ;
                arready_temp = 1'b1;
                rvalid_temp = 1'b0;
            end
            TRAN :  begin
                Read_and_ReadAddress_Next_STATE = (rready) ? (WAIT) : (TRAN) ;
                arready_temp = 1'b0;
                rvalid_temp = 1'b1;
                case (Read_Address)
                    2'd0 : rdata_temp = {{29{1'b0}},AP_IDLE,AP_DONE,AP_START};
                    2'd1 : rdata_temp = data_length ;
                    2'd2 : rdata_temp = tap_Do_out ;
                    2'd3 : rdata_temp = {{29{1'b0}},AP_IDLE,AP_DONE,AP_START}; // dont care
                    default: rdata_temp = {{29{1'b0}},AP_IDLE,AP_DONE,AP_START};
                endcase
            end
            default: begin
                Read_and_ReadAddress_Next_STATE = WAIT ;
                arready_temp = 1'b1;
                rvalid_temp = 1'b0;
            end
        endcase
    end
    // AXI Stream Control Read and Read Address //



    // Assignment of Write Address //
    always @(posedge axis_clk or negedge axis_rst_n) begin
        if (!axis_rst_n ) begin
            Write_Address <= 2'd3; // fail
        end else begin
            if (awvalid & awready_temp) begin
                if (awaddr == 12'h00) begin // AP_START
                    Write_Address <= 2'd0 ;
                end
                else if (awaddr > 12'h0F && awaddr < 12'h15) begin
                    Write_Address <= 2'd1;
                end 
                else if (awaddr > 12'h1F && awaddr < 12'h100) begin
                    Write_Address <= 2'd2;
                end else begin
                    Write_Address <= 2'd3;
                end
            end
        end
    end
    // Assignment of Write Address //



    // Assignment of Read Address //
    always @(posedge axis_clk or negedge axis_rst_n) begin
        if (!axis_rst_n ) begin
            Read_Address <= 2'd3; // fail
        end else begin
            if (arvalid & arready_temp) begin
                if (awaddr == 12'h00) begin
                    Read_Address <= 2'd0 ;
                end
                else if (awaddr > 12'h0F && awaddr < 12'h15) begin
                    Read_Address <= 2'd1;
                end 
                else if (awaddr > 12'h1F && awaddr < 12'h100) begin
                    Read_Address <= 2'd2;
                end else begin
                    Read_Address <= 2'd3;
                end
            end
        end
    end
    // Assignment of Read Address //



    // Store(Write) Data //
    always @(posedge axis_clk or negedge axis_rst_n) begin
        if(~axis_rst_n) begin
            data_length <= 32'd0 ;
        end
    end

    always @(*) begin
        if(~axis_rst_n) begin
            AP_START <= 0;
        end
        else if ((FIR_STATE == IDLE)&&(axis_rst_n)) begin
            if (wready_temp && wvalid) begin
                case (Write_Address)
                    2'd0 : begin 
                        if(wdata[0]==1'd1 && rvalid_temp==1) begin
                            #10;
                            AP_START = 1 ;
                            $display("----- FIR kernel starts -----");
                        end 
                        else if(wdata[0]==1'd1 && rvalid_temp!=1) begin
                            AP_START = 1 ;
                            $display("----- FIR kernel starts -----");
                        end
                        else begin
                            AP_START = 0 ;
                        end
                    end
                    2'd1 : begin 
                        data_length = wdata ;
                    end
                    2'd2 : begin 
                        tap_Di_temp = wdata ;
                    end
                endcase
            end 
        end else begin 
            AP_START = (AP_START&ss_tvalid&ss_tready_temp)? (0):(AP_START) ;
        end
    end
    // Store(Write) Data //



    // Control Tap //
    always @(*) begin
        if (Write_or_Read_Tap[1]) begin  
            tap_EN_temp = 1'b1;
            tap_WE_temp = 4'b1111 ;
        end 
        else if (Write_or_Read_Tap[0]) begin     
            tap_EN_temp = 1'b1;
            tap_WE_temp = 4'd0;
        end else begin
            tap_EN_temp = 1'b0;
            tap_WE_temp = 4'd0;
        end
    end
    // Control Tap //



    // Control whrite or Read //
    always @(*) begin
        if (FIR_STATE==IDLE) begin
            if (Write_Address == 2'd2 & Read_Address == 2'd2) begin
                Write_or_Read_Tap = (wvalid & wready_temp) ? (2'b10) : ((rvalid_temp & rready) ? (2'b01) : (2'b00));
            end else if (Write_Address == 2'd2) begin
                Write_or_Read_Tap = (wvalid & wready_temp) ? (2'b10) : (2'b00) ;
            end 
            else if (Read_Address == 2'd2) begin
                Write_or_Read_Tap = (rvalid_temp & rready) ? (2'b01) : (2'b00) ;
            end
            else begin
                Write_or_Read_Tap = 2'b00;
            end
        end else if (FIR_STATE==WORK) begin 
            Write_or_Read_Tap = 2'b01 ;
        end else begin 
            Write_or_Read_Tap = 2'b00;
        end
    end
    // Control whrite or Read //



    // AXI-Stream Input Data//
    reg Resetn_fir ;
    wire Done_fir ;
    always @(posedge axis_clk or negedge axis_rst_n) begin
        if (~axis_rst_n) begin
            data_WE_temp <= 4'd0;
            data_EN_temp <= 1'b0 ;
            ss_tready_temp <= 1'b0 ;
            Resetn_fir <= 1'b0 ; 
        end else begin
            // ss_tready_temp
            if (AP_START) begin
                data_WE_temp <= 4'b1111 ;
                data_EN_temp <= 1'b1 ;
                data_count <= 4'd10;
                ss_tready_temp <= 1'b1 ;
                data_Di_temp <= ss_tdata ;
                Resetn_fir <= 1'b0 ; 
            end else if ((FIR_STATE==WORK)) begin // steady receive data
                ss_tready_temp <= (tap_count==4'd09)?(1'b1):(1'b0) ;
                data_EN_temp <= 1'b1 ;
                Resetn_fir <= 1'b1 ; 
                if (ss_tready_temp & ss_tvalid) begin
                    data_Di_temp <= ss_tdata ;
                end
                if (tap_count == 4'd10)begin
                    data_WE_temp <= (4'b1111);
                end else begin
                    data_WE_temp <= 4'd0;
                end
            end else if (AP_DONE) begin
                data_EN_temp <= 1'b0 ;
                ss_tready_temp <= 1'b0 ;
                Resetn_fir <= 1'b0 ; 
            end else begin
                ss_tready_temp <= 1'b0 ;
                Resetn_fir <= 1'b0 ; 
                data_EN_temp <= 1'b0 ;
            end
        end
    end
    // AXI-Stream Input Data//




    // FIR kernel //
    FIR_kernel Kernel(   .X(data_Do_out),
                            .tap(tap_Do_out),
                            .CLK(axis_clk),
                            .Y(Y),
                            .Resetn(Resetn_fir),
                            .Done(Done_fir)); 
    // FIR kernel //

    //make Sure Output Data Steady
    always @(posedge axis_clk or negedge axis_rst_n) begin
        if (~axis_rst_n) begin
            Y_temp <= 32'd0;
        end else begin
            Y_temp <= (Done_fir)?(Y):(Y_temp) ;
        end
    end
    //make Sure Output Data Steady

    //  AXI-Stream Output Data //
    always @(posedge axis_clk or negedge axis_rst_n) begin
        if (~axis_rst_n) begin
            sm_tlast_temp <= 1'd0 ;
            sm_tvalid_temp <= 1'd0 ;
            AP_DONE <= 1'd0 ;
            Last = 2'b00 ;
        end else begin
            if (ss_tlast & FIR_STATE==WORK) begin
                Last <= 2'b01 ;
            end
            if (Done_fir) begin    
                if (Last==2'b01) begin 
                    Last <= 2'b00 ;
                    sm_tdata_temp <= Y ; 
                    sm_tvalid_temp <= 1'd1 ;
                    sm_tlast_temp <= 1'd1 ;
                end 
                else begin      
                    sm_tdata_temp <= Y ;
                    sm_tvalid_temp <= 1'd1 ;
                end
            end else if (sm_tready&sm_tvalid_temp) begin   
                sm_tvalid_temp <= 1'b0 ;
                sm_tlast_temp <= 1'd0 ;
                
            end 
            else begin 
                sm_tvalid_temp <= 1'b0 ;
                sm_tlast_temp <= 1'd0 ;
            end


            if (sm_tlast_temp & sm_tready & sm_tvalid_temp) begin
                AP_DONE <= 1 ; 
            end else if (Read_Address==2'b0 &rready & rvalid_temp &arvalid)begin
                AP_DONE <= 0 ;
            end else begin
                AP_DONE <= AP_DONE;
            end
        end
    end
    //  AXI-Stream Output Data //

endmodule

