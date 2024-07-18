module match#(
    parameter              Size = 10,
    parameter              B = 4
)(
   
 input              clk         ,
 input              rst_n       ,
                                
 input [7:0]        data_in     ,
 input              data_in_val ,
 input [7:0]        pattern     ,
 input              pattern_val ,
 input              done        ,
 input              match_end   ,
 
 output reg [14:0]  position    ,
 output reg         position_val,
 output reg [15:0]  cnt         
// output reg [5:0]   page_cnt    
// output reg [10:0]  block_cnt	
);

localparam IDLE = 3'b000;
localparam JUDGE = 3'b001;
localparam PROCESS = 3'b010;
localparam COMPUTE = 3'b011;

reg [7:0] pattern_reg[0:Size-1];
reg [B-1:0] pattern_i;

reg [Size-1:0] flag_qu;
reg [B-1:0] index[0:Size-1];
reg [B-1:0] queue_i;


reg [2:0] state;
reg [2:0] next_state;

reg [15:0] cnt_s;
//reg [31:0] page_cnt;
reg success;
integer i;


always@(posedge clk or negedge rst_n) begin
    if(~rst_n)begin
        pattern_i <= 0;
    end
    else if(pattern_val == 1'b1)begin
        pattern_reg[pattern_i]  <= pattern;
        pattern_i <= pattern_i + 1;
        if(pattern_i == Size -1)begin
            pattern_i <= 0;
        end
   end
   else ;
end

always@(posedge clk or negedge rst_n) begin
    if(~rst_n)begin
        cnt_s <= 16'd0;
        //page_cnt <= 16'd0;
    end
    else if(data_in_val == 1'b1)begin
        cnt_s <= cnt_s + 16'd1;
    end
    else if(done)begin
        cnt_s <= 16'd0;
        //page_cnt <= page_cnt + 16'd1;
    end
//    else if(match_end)begin
//         page_cnt <= 16'd0;
//    end
    else begin
        cnt_s <= cnt_s;
        //page_cnt <= page_cnt;
    end
end

always@(*) begin
    if(~rst_n)begin
        state = IDLE;
    end
    else if(data_in_val == 1'b1)begin
        state = JUDGE;
    end
    else if(match_end)begin
        state = IDLE;
    end
    else state = next_state;
end

always@(posedge clk)begin
    if(~rst_n)begin
        flag_qu <= 0;
		queue_i <= 0;
        success	<= 1'b0;	
        next_state <= IDLE;
    end
    else begin
        success	<= 1'b0;
        case(state)
            IDLE:begin
                flag_qu[queue_i] <= 1'b1;
                index[0] <= 0;
                queue_i <= 0;
                for(i=1;i<Size;i=i+1)begin
                    index[i] <= 0;
                    flag_qu[i] = 1'b0;
                end
            end
            JUDGE:begin
                for(i=0;i<Size;i=i+1)begin
                    if(flag_qu[i] == 1'b1)begin
                        if(data_in == pattern_reg[index[i]]) begin
                            index[i] <= index[i]+1;	
                        end	
                        else begin
                            flag_qu[i] <= 1'b0;
                            index[i] <= 0;
                        end
                    end	
                    else begin
                        queue_i <= i;
                    end			
                end				
                next_state <= PROCESS;
            end
            PROCESS:begin			
                flag_qu[queue_i] = 1'b1;
                index[queue_i] <= 0;
                next_state <= COMPUTE;
            end
            COMPUTE:begin
                for(i=0;i<Size;i=i+1)begin
                    if(index[i] == Size)begin
                        flag_qu[i] <= 1'b0;
                        index[i] <= 0;
                        success	<= 1'b1;
                    end
                end
            end		
        endcase
    end
end

always@(posedge clk or negedge rst_n) begin
    if(~rst_n)begin
        position <= 15'd0;
        position_val <= 1'b0;
        cnt <= 16'd0;
    end
    else if(success == 1'b1)begin
        position <= cnt_s - Size;
        cnt <= cnt + 16'd1;
        position_val <= 1'b1;
    end
    else if(match_end)begin
        cnt <= 16'd0;
    end
    else position_val <= 1'b0;
end
/*
ila_2 ila_i2 (
	.clk(clk), // input wire clk

 	.probe0(pattern_val), // input wire [0:0]  probe0  
	.probe1(pattern), // input wire [7:0]  probe1 
	.probe2(pattern_i), // input wire [2:0]  probe2 
	.probe3(data_in), // input wire [7:0]  probe3 
	.probe4(data_in_val), // input wire [0:0]  probe4 
	.probe5(state), // input wire [2:0]  probe5 
	.probe6(match_end), // input wire [0:0]  probe6 
	.probe7(position_val), // input wire [4:0]  probe7 
	.probe8(queue_i), // input wire [2:0]  probe8 
	.probe9(cnt_s), // input wire [15:0]  probe9 
	.probe10(position), // input wire [14:0]  probe10 
	.probe11(success), // input wire [0:0]  probe11 
	.probe12(cnt) // input wire [15:0]  probe12
	
);*/



endmodule
