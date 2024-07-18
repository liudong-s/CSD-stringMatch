`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2024/04/02 20:01:52
// Design Name: 
// Module Name: match_tb
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


module match_tb(
    );
reg clk;
reg rst_n;  
//reg [7:0] data_in;
reg data_in_val;  
reg [7:0] pattern;
reg pattern_val;
reg done;
reg match_end;
reg data_en;
  
 wire [14:0] position;
 wire position_val;
 wire [15:0] cnt;
 reg [7:0] data;
 initial begin
    clk    <= 1'b1;
    rst_n  <= 1'b0;
    pattern <= 8'd0;
    pattern_val <= 1'b0;
    data_en <= 1'b0;
    data_in_val <= 1'b0;
    #20
    rst_n  <= 1'b1;
    #20
    pattern <= "a";
    pattern_val <= 1'b1;
     #20
    pattern <= "b";
    pattern_val <= 1'b1;
     #20
    pattern <= "c";
    pattern_val <= 1'b1;
     #20
    pattern <= "a";
    pattern_val <= 1'b1;
     #20
    pattern <= "b";
    pattern_val <= 1'b1;
    #20
    pattern_val <= 1'b0;
    #20
    data_en <= 1'b1;
 end 
 
 always #10 clk = ~clk;
 

reg [6:0] con;

initial begin
    #200
    send_data;
end 

task    send_data(
);
    reg [6:0] i;
    for(i=0; i<100; i=i+1)   
      begin
        con <= i;
 //       data_in <= data;
        data_in_val <= 1'b1;
        #20
        data_in_val <= 1'b0;
        #40;
    end        
endtask 
always@(*)begin
    case(con)
        0: data = "a";
        1: data = "b";
        2: data = "a";
        3: data = "b";
        4: data = "c";
        5: data = "a";
        6: data = "b";
        7: data = "c";
        8: data = "a";
        9: data = "b";
        10: data = "b";
        11: data = "a";
        12: data = "d";
        13: data = "a";
        14: data = "b";
        15: data = "c";
        16: data = "a";
        17: data = "c";
        18: data = "c";
        19: data = "a";
        20: data = "c";
        21: data = "d";
        default: data = 8'd0; 
    endcase
end  
    
match match_i
(
   
 . clk         (clk         ),
 . rst_n       (rst_n       ),

 . data_in     (data        ),
 . data_in_val (data_in_val ),
 . pattern     (pattern     ),
 . pattern_val (pattern_val ),
 . done        (done        ),
 . match_end    (match_end),
              
 . position    (position    ),
 . position_val(position_val),
 . cnt         (cnt         )
 //.page_cnt	   (page_cnt    )
);

endmodule
