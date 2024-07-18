`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2024/03/27 20:37:12
// Design Name: 
// Module Name: data_fifo
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module data_buf(
    input clk,
    input rst_n,
    input [31:0]data_in,
    input data_in_val,
    input data_in_last,
    input data_ready,
    input [1:0] command,
    
    output reg [7:0] data_out,
    output reg data_out_val

    );
    
reg [31:0] ram32[0:511];
reg [9:0] addr32;
reg send;
reg [31:0] mov;
reg [2:0] mov_num;
reg data_in_last1;
always@(posedge clk) data_in_last1 <= data_in_last;

always@(posedge clk)begin
    if(~rst_n)begin
        data_out <= 8'd0;
        data_out_val <= 1'b0;
        addr32 <= 10'd0;
        send <= 1'b0;
        mov_num <= 3'd0;
    end
    else if(data_in_val && data_ready &&  ~data_in_last && command == 2'b01) begin
            ram32[addr32] <= data_in;
            addr32 <= addr32 + 10'd1;
    end
    else if(data_in_last && ~data_in_last1 &&  command == 2'b01)begin
        addr32 <= 10'd1;
        send <= 1'b1;
        mov <= ram32[0];
    end 
    else if(send == 1'b1)begin
        data_out_val <= 1'b0;           
        data_out <= mov[7:0];
        data_out_val <= 1'b1;
        mov <= mov >> 8;
        mov_num <= mov_num + 3'd1;
        if(mov_num == 3'd3)begin
            if(addr32 == 10'd512)begin
                addr32 <= 10'd0;
                send <= 1'b0;       
                mov_num <= 3'd0;     
            end
            else begin
                mov <= ram32[addr32];
                addr32 <= addr32 + 10'd1;
                mov_num <= 3'd0;  
            end                  
        end  else;                  
    end
    else begin      
        data_out_val <= 1'b0;
    end
end


endmodule
