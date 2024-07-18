module control(
//-- Flash mem i/f (Samsung 128Mx8)  
 inout [7:0] DIO ,
 output reg CLE  , // -- CLE
 output reg ALE  , //  -- ALE
 output reg WE_n , // -- ~WE
 output reg RE_n , //-- ~RE
 output reg CE_n , //-- ~CE
 output reg WP_n ,
 input      R_nB , //-- R/~B
//-- system      
 input clk       ,
 input rst_n     ,
 
 input [1:0]command_in,
 input command_in_vail,
 input [7:0] data,
 input data_vail,
 output reg done,
 output reg error,
 input [5:0] page_address_in,
 input [10:0] block_address_in,
 input address_vail,
 input read_start,
 output reg [7:0] data_out,
 output reg  data_out_vail,
 input erase_start
	
);



reg start;
reg write_start;
reg CLE_trigger_cnt;
reg RE_trigger_cnt;
reg [2:0]CLE_cnt;
reg [2:0]WE_cnt;
reg [2:0]RE_cnt;
reg [2:0] ALE_cnt;
reg [2:0]idle_cnt;
reg [3:0] send_state;
reg idle_flag;
reg trigger_cnt;
reg [2:0] add_cnt;
reg triger_writer_cnt;
reg [11:0] read_index;
reg [3:0] wait_cnt;
reg r_status;
reg [7:0] data_in;
reg send_command;
reg send_command2;
reg send_command3;

reg send_add;
reg send_data;
reg [5:0]page_address;
reg [10:0]block_address;
reg [7:0] page_data[0:2047];
reg [11:0] data_index;
reg send_flag;
reg ALE_trigger_cnt;
reg [2:0] read_idle_cnt;
reg read_idle_flag;
reg [1:0] command;
reg [11:0] write_index;
reg [2:0] write_idle_cnt;
reg write_idle_flag;


always@(posedge clk ) begin
    if(rst_n == 1'b0)begin
        command <= 2'b00;
    end
    else if(command_in_vail)begin
        command <= command_in;
    end
    else ;
end

always@(posedge clk ) begin
    if(rst_n == 1'b0)begin
        page_address <= 6'd0;
        block_address <= 11'd0;
    end
    else if(address_vail)begin
        page_address <= page_address_in;
        block_address <= block_address_in;
    end
    else ;
end

always@(posedge clk ) begin
    if(rst_n == 1'b0)begin
        write_start <= 1'b0;
        data_index <= 12'd0;
    end
    else if(data_vail)begin
        page_data[data_index] <= data;
        data_index <= data_index + 12'd1;
        if(data_index>=12'd2047 )begin
            data_index <= 12'd0;
            write_start <= 1'b1;
        end
        else ;
    end
    else begin
         write_start <= 1'b0;
    end
end



always@(posedge clk ) begin
    if(rst_n == 1'b0)begin   
        CLE_cnt <= 3'd0;
    end
    else if(CLE_trigger_cnt == 1'b1 || (CLE_cnt < 3'd4 && CLE_cnt >= 3'd1))begin
        CLE_cnt <= CLE_cnt + 3'd1;
    end
    else if(CLE_cnt == 3'd4)begin
        CLE_cnt <= 3'd0;
    end
    else CLE_cnt <= 3'd0;
end

always@(posedge clk ) begin
    if(rst_n == 1'b0)begin   
        ALE_cnt <= 3'd0;
    end
    else if(ALE_trigger_cnt == 1'b1)begin
        ALE_cnt <= ALE_cnt + 3'd1;
    end
    else ALE_cnt <= 3'd0;
end

always@(posedge clk ) begin
    if(rst_n == 1'b0)begin   
        WE_cnt <= 3'd0;
    end
    else if(WE_cnt == 3'd2)begin
        WE_cnt <= 3'd0;
    end
    else if(trigger_cnt)begin
        WE_cnt <= WE_cnt + 3'd1;
    end
    else WE_cnt <= 3'd0;
end

always@(posedge clk ) begin
    if(rst_n == 1'b0)begin   
        RE_cnt <= 3'd0;
    end
    else if(RE_trigger_cnt)begin
        RE_cnt <= RE_cnt + 3'd1;
    end
    else RE_cnt <= 3'd0;
end



always@(posedge clk ) begin
    if(rst_n == 1'b0)begin   
        read_idle_cnt <= 3'd0;
    end
    else if(read_idle_flag == 1'b1 )begin
        read_idle_cnt <= read_idle_cnt + 3'd1;
    end
    else read_idle_cnt <= 3'd0;
end

always@(posedge clk ) begin
    if(rst_n == 1'b0)begin   
        write_idle_cnt <= 3'd0;
    end
    else if(write_idle_flag == 1'b1 )begin
        write_idle_cnt <= write_idle_cnt + 3'd1;
    end
    else write_idle_cnt <= 3'd0;
end

always@(posedge clk ) begin
    if(rst_n == 1'b0)begin   
        idle_cnt <= 3'd0;
    end
    else if(idle_flag == 1'b1 )begin
        idle_cnt <= idle_cnt + 3'd1;
    end
    else idle_cnt <= 3'd0;
end


reg [3:0] send_state1;
always@(posedge clk )send_state1 <= send_state;

always@(posedge clk ) begin
    if(rst_n == 1'b0)begin
        CE_n <= 1'b1;
        CLE <= 1'b0;
        WE_n <= 1'b1;
        ALE <= 1'b0;
        RE_n <= 1'b1;
        WP_n <= 1'b1;
        start <= 1'b0; 
        send_state <= 4'd0;
        idle_flag <= 1'b0;
        trigger_cnt <= 1'b0;        
        add_cnt <= 3'd0;       
        CLE_trigger_cnt <= 1'b0;
        triger_writer_cnt <= 1'b0;
        read_index <= 12'd0;
        wait_cnt <= 4'd0;       
        r_status <= 1'b0;  
        send_command <= 1'b0;
        send_add <= 1'b0;
        send_data <= 1'b0;
        send_command2 <= 1'b0;      
        send_flag <= 1'b1;
        done <= 1'b0;
        ALE_trigger_cnt <= 1'b0;
        RE_trigger_cnt <= 1'b0;
        read_idle_flag <= 1'b0;
        write_index <= 12'd0;
        write_idle_flag <= 1'b0;
        send_command3 <= 1'b0;
        error <= 1'b1;
    end
    else if(read_start || write_start || erase_start) begin
        send_flag <= 1'b1;
        CE_n <= 1'b0;
        start <= 1'b1;
        send_state <= 4'd1;
        send_command <= 1'b1;
        CLE_trigger_cnt <= 1'b1;
    end
    else if(start == 1'b1) begin
        CLE_trigger_cnt <= 1'b0;
        r_status <= 1'b0;
        send_command <= 1'b0;
        case(send_state)
            4'b0000:begin  //0   
                    CE_n <= 1'b0;
                    CLE <= 1'b0;
                    WE_n <= 1'b1;
                    ALE <= 1'b0;
                    RE_n <= 1'b1;   
                    if(idle_cnt == 3'd2) begin
                        idle_flag <= 1'b0;
                        if((add_cnt < 3'd5 && command != 2'b11) || add_cnt < 3'd3) begin
                            //send_state <= 4'd2; 
                            send_state <= 4'b0011; 
                            send_add <= 1'd1;                          
                        end else begin
                            add_cnt <= 3'd0;
                            //send_state <= 4'd3;
                            send_state <= 4'b0010;                                                                                    
                        end
                    end else ; 
                    
                   // if(read_idle_cnt==3'd1)begin
                    if(read_idle_flag)begin
                        read_idle_flag <= 1'b0;
                        if(read_index == 2048)begin
                            read_index <= 12'd0;
                            //send_state <= 4'd13;
                            send_state <= 4'b1011;
                        end
                        else begin   
                          //send_state <= 4'd9;  
                          send_state <=  4'b1101;
                        end
                    end
                    
                    if(write_idle_cnt==3'd1)begin
                        write_idle_flag <= 1'b0;
                        if(write_index == 2048)begin
                            write_index <= 12'd0;
                            //send_state <= 4'd5;
                            send_state <= 4'b0111;
                            CLE_trigger_cnt <= 1'b1;
                            send_command2 <= 1'b1;
                        end
                        else begin   
                          //send_state <= 4'd4;  
                          send_state <= 4'b0110; 
                          send_data <= 1'b1;
                        end
                    end
                    
                    
                 end
            4'b0001:begin  // 1 发送00h/80h/60h                 
                    CLE <= 1'b1;
                    WE_n <= 1'b0;
                    trigger_cnt <= 1'b1;
                    if(CLE_cnt == 3'd3)begin                       
                        WE_n <= 1'b1;
                        idle_flag <= 1'b1;
                        send_state <= 4'b0000;
                        trigger_cnt <= 1'b0;
                    end else ;
                    if(WE_cnt == 3'd1) begin
                        trigger_cnt <= 1'b0;
                    end                                                      
                 end
            4'b0011:begin // 2 发送地址
                    send_add <= 1'd0;
                    WE_n <= 1'b0;
                    ALE <= 1'b1;
                    trigger_cnt<= 1'b1;
                    ALE_trigger_cnt <= 1'b1;
                    if(ALE_cnt == 3'd2) begin                      
                        WE_n <= 1'b1;
                        send_state <= 4'b0000;
                        idle_flag <= 1'b1;
                        add_cnt <= add_cnt + 3'd1;
                        trigger_cnt<= 1'b0;
                        ALE_trigger_cnt <= 1'b0;
                    end else ;
                    if(WE_cnt == 3'd1) begin
                        trigger_cnt<= 1'b0;
                    end
                 end 
            4'b0010:begin // 3 
                    if(command == 2'b01)begin
                        //send_state <= 4'd4;
                        send_state <= 4'b0110;
                        send_data <= 1'b1; 
                    end
                    else if(command == 2'b10 || command == 2'b11)begin
                        //send_state <= 4'd5;
                        send_state <= 4'b0111;
                        send_command2 <= 1'b1;
                        CLE_trigger_cnt <= 1'b1;
                    end
                    else ;
                    
                 end
            4'b0110:begin // 4 写数据
                    send_data <= 1'b0;
                    WE_n <= 1'b0;
                    trigger_cnt <= 1'b1;
                    if(WE_cnt == 3'd1) begin                    
                        trigger_cnt <= 1'b0;
                        send_state <= 4'b0000; 
                        write_idle_flag <= 1'b1;
                        write_index <= write_index + 12'd1;
                    end
                 end
            4'b0111:begin // 5 发送30h/10h/D0h                
                    send_command2 <= 1'b0;
                    WE_n <= 1'b0;
                    CLE <= 1'b1;
                    trigger_cnt <= 1'b1;                  
                    if(CLE_cnt == 3'd3)begin
                        WE_n <= 1'b1;                      
                        //send_state <= 4'd6;
                        send_state <=  4'b0101;
                        trigger_cnt <= 1'b0;
                    end else ;
                    if(WE_cnt == 3'd1) begin
                        trigger_cnt <= 1'b0;
                    end
                 end
            4'b0101:begin // 6 等10个周期
                    CLE <= 1'b0;
                    if(wait_cnt == 4'd10)begin
                        wait_cnt <= 4'd0;                      
                        //send_state <= 4'd7;  
                        send_state <= 4'b0100;                           
                    end
                    else begin
                        wait_cnt <=  wait_cnt + 4'd1;
                    end
                 end
            4'b0100:begin //7
                    if(R_nB == 1'b1)begin 
                        if(command == 2'b10 || command == 2'b11)begin
                            //send_state <= 4'd8; 
                            send_state <= 4'b1100;
                        end
                        else if(command == 2'b01)begin
                            //send_state <= 4'd10;
                            send_state <= 4'b1111;
                            send_command3 <= 1'b1;
                            CLE_trigger_cnt <= 1'b1;
                        end
                    end else ; 
                 end
            4'b1100:begin // 8
                    if(wait_cnt == 4'd3)begin
                        wait_cnt <= 4'd0;
                        if(command == 2'b10)begin
                            //send_state <= 4'd9;      
                            send_state <= 4'b1101; 
                        end
                        else if(command == 2'b11)begin
                            //send_state <= 4'd10; 
                            send_state <= 4'b1111;
                            CLE_trigger_cnt <= 1'b1;
                            send_command3 <= 1'b1;
                        end
                    end
                    else begin
                        wait_cnt <=  wait_cnt + 4'd1;
                        if(command == 2'b01) begin
                            send_state <= 4'b1111;
                            send_command3 <= 1'b1;
                            CLE_trigger_cnt <= 1'b1;
                            wait_cnt <= 4'd0;
                        end
                    end
                 end
            4'b1101:begin // 9 读数据
                    if(command == 2'b01)begin
                         send_state <= 4'b1111;
                         send_command3 <= 1'b1;
                         CLE_trigger_cnt <= 1'b1;
                    end
                    else begin
                    send_flag <= 1'b0;
                    RE_n <= 1'b0; 
                    RE_trigger_cnt <= 1'b1;
                    if(RE_cnt == 3'd1)begin
                    //if(RE_trigger_cnt)begin
                        RE_n <= 1'b1; 
                        send_state <= 4'b0000;
                        RE_trigger_cnt <= 1'b0;
                        read_idle_flag <= 1'b1;
                        read_index <= read_index+1;
                    end
                    end
                 end
            4'b1111:begin // 10 发送70h
                    send_command3 <= 1'b0;
                    WE_n <= 1'b0;
                    CLE <= 1'b1;
                    trigger_cnt <= 1'b1;                  
                    if(CLE_cnt == 3'd3)begin
                        WE_n <= 1'b1;                      
                        //send_state <= 4'd11;
                        send_state <= 4'b1110;
                        trigger_cnt <= 1'b0;
                    end else ;
                    if(WE_cnt == 3'd1) begin
                        trigger_cnt <= 1'b0;
                    end
                  end
            4'b1110:begin // 11 
                    CLE <= 1'b0;
                    if(wait_cnt == 4'd6)begin
                        wait_cnt <= 4'd0;
                        //send_state <= 4'd12;  
                        send_state <= 4'b1010;                                         
                    end
                    else begin
                        wait_cnt <=  wait_cnt + 4'd1;
                    end
                  end
            4'b1010:begin // 12
                    RE_n <= 1'b0;
                    send_flag <= 1'b0;               
                    RE_trigger_cnt <= 1'b1; 
                    if(RE_cnt == 3'd2)begin
                        if(data_out[0] == 0)begin                       
                            error <= 1'b0;
                        end
                        else if(data_out[0] == 1)begin
                             error <= 1'b1;                       
                        end  
                        RE_n <= 1'b1;  
                        send_state <= 4'b0000;
                        RE_trigger_cnt <= 1'b0; 
                        start <= 1'b0;
                        done <= 1'b1;
                    end                    
                  end
            4'b1011:begin //13 完成               
                    done <= 1'b1;
                    start <= 1'b0;
                    send_state <= 4'b0000;
                 end
            
            default:begin
                        send_state <= send_state1;
                    end
        endcase    
    end
    else begin      
        done <= 1'b0;
        error <= 1'b1;
        CE_n <= 1'b1;
        CLE <= 1'b0;
        WE_n <= 1'b1;
        ALE <= 1'b0;
        RE_n <= 1'b1;
    end
end

reg [2:0] add_state;
reg [2:0] read_cnt;


always@(posedge clk ) begin
    if(rst_n == 1'b0)begin
        data_in <= 7'd0;
        add_state <= 3'd0;
        data_out_vail <= 1'b0;
    end
    else if(send_command == 1'b1)begin
        if(command == 2'b01)begin
            data_in <= 8'h80;
        end
        else if(command == 2'b10)begin
            data_in <= 8'h00;
        end
        else if(command == 2'b11)begin
            data_in <= 8'h60;
        end
    end
    else if(send_add) begin
        case(add_state)
            3'd0:begin
                    if(command == 2'b11)begin
                        //data_in <= {page_address[5:0],block_address[10:9]};
                         data_in <= {block_address[0],block_address[10],page_address[5:0]};
                    end
                    else begin
                        data_in <= 8'h00;
                    end
                    add_state <= add_state + 3'd1;
                 end
            3'd1:begin
                    if(command == 2'b11)begin
                        data_in <= block_address[8:1];
                    end
                    else begin
                        data_in <= 8'h00;
                    end
                    add_state <= add_state + 3'd1;
                 end
            3'd2:begin
                    if(command == 2'b11)begin
                        //data_in <= {block_address[0],7'b0};
                        data_in <= {7'd0,block_address[0]};
                        add_state <= 3'd0;
                    end
                    else begin                  
                        //data_in <= {page_address[5:0],block_address[10:9]};
                        data_in <= {block_address[0],block_address[10],page_address[5:0]};
                        add_state <= add_state + 3'd1;
                    end
                 end
            3'd3:begin
                    data_in <= block_address[8:1];
                    add_state <= add_state + 3'd1;
                 end
            3'd4:begin
                    //data_in <= {block_address[0],7'b0};
                    data_in <= {7'd0,block_address[0]};
                    add_state <= 3'd0;
                 end
            default:begin
                    end
        endcase
    end
    else if(send_data)begin
        data_in <= page_data[write_index];
    end
    else if(send_command2 == 1'b1)begin
        if(command == 2'b01)begin
            data_in <= 8'h10;
        end
        else if(command == 2'b10)begin
            data_in <= 8'h30;
        end
        else if(command == 2'b11)begin
            data_in <= 8'hd0;
        end
    
    end
    else if(send_command3 == 1'b1)begin      
        data_in <= 8'h70;             
    end
    //else if(send_state == 4'b1101 || send_state == 4'b1010)begin
    else if(send_state == 4'b1101)begin
        data_out <= DIO;
        read_cnt <= read_cnt + 3'd1;
        if(read_cnt == 3'd2)begin
            data_out_vail <= 1'b1;
            read_cnt <= 3'd0;
        end
    end
    else if(send_state == 4'b1010)begin
         data_out <= DIO;
    end
    else data_out_vail <= 1'b0;
end

assign DIO = send_flag ? data_in:8'hzz;
/*
ila_0 my_ila0 (
	.clk(clk), // input wire clk


	.probe0(CLE ), // input wire [0:0]  probe0  
	.probe1(ALE ), // input wire [0:0]  probe1 
	.probe2(WE_n), // input wire [0:0]  probe2 
	.probe3(RE_n), // input wire [0:0]  probe3 
	.probe4(CE_n), // input wire [0:0]  probe4 
	.probe5(R_nB), // input wire [0:0]  probe5 
	.probe6(start), // input wire [0:0]  probe6 
	.probe7(data_in), // input wire [7:0]  probe7 
	.probe8(data_out), // input wire [7:0]  probe8
	.probe9(send_state), // input wire [3:0]  probe9
	.probe10(command), // input wire [1:0]  probe10
	.probe11(done), // input wire [0:0]  probe11 
	.probe12(error), // input wire [0:0]  probe12
	.probe13(data_vail), // input wire [0:0]  probe13 
	.probe14(data), // input wire [7:0]  probe14 
	.probe15(data_index), // input wire [11:0]  probe15
	.probe16(page_address), // input wire [5:0]  probe16 
	.probe17(block_address), // input wire [10:0]  probe17
	.probe18(CLE_cnt), // input wire [2:0]  probe18 
	.probe19(trigger_cnt) // input wire [0:0]  probe19
);*/

endmodule
