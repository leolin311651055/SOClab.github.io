`timescale 1ns / 100ps

module FIR_kernel(
    input [31:0] X,
    input [31:0] tap,
    input CLK,
    input Resetn,
    output reg [31:0] Y,
    output Done
);

reg [3:0] Done_count;

always @(posedge CLK or negedge Resetn) begin
    if (~Resetn) begin
        Done_count <= 4'b0001; // Initialize to 0001
        Y <= 32'b0;
    end else begin
        if (Done_count == 4'b1011) begin
            Y <= (X * tap);
            Done_count <= 4'b0001;
        end else begin
            Y <= Y + (X * tap);
            Done_count <= Done_count + 1;
        end
    end
end

assign Done = (Done_count == 4'b1011) ? 1'b1 : 1'b0;

endmodule
