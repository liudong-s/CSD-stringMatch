module address(
    input  clk,
    input  rst_n,
    input  done,
    input  [1:0] con,
       
    output   [5:0]page_address_out,
    output   [10:0]block_address_out,
    output  reg add_vail
);
reg [1:0] con1;
reg [5:0]page_address;
reg [10:0]block_address;

assign page_address_out = page_address;
assign block_address_out = block_address;

always@(posedge clk or negedge rst_n) begin
    if(rst_n == 1'b0)begin
        con1 <= 2'd0;
    end
    else con1 <= con;
end
always@(posedge clk or negedge rst_n) begin
        if(rst_n == 1'b0) begin           
            page_address <= 0;                                 
            block_address <= 0;  	
            add_vail <= 1'b0;	
        end
         else if(con1 != con)begin
            page_address <= 0;                                 
            block_address <= 0;  
        end
        else if(done == 1'b1 && (con == 2'b01 || con == 2'b10)) begin
            add_vail <= 1'b1;
            if(page_address == 6'd63) begin
                  page_address <= 6'd0;
                  block_address <= block_address + 11'd1;
            end    
            else
                  page_address <= page_address + 6'd1;                  
        end
        else if(done == 1'b1 && con == 2'b11 ) begin
             add_vail <= 1'b1;
             block_address <= block_address + 11'd1;
             if(block_address == 11'd2047)begin
                 block_address <= 0;  	
             end
        end
        else begin
            page_address <= page_address;
            block_address <= block_address;
            add_vail <= 1'b0;	
        end
end





//always@(posedge clk or negedge rst_n) begin
//        if(rst_n == 1'b0) begin           
//            page_address <= 0;                                 
//            block_address <= 0;  	
//            add_vail <= 1'b0;	
//        end
//        else if(con1 != con)begin
//            page_address <= 0;                                 
//            block_address <= 0;  
//        end
//        else if(done)begin
//            case(con)
//                2'b11: begin
//                     add_vail <= 1'b1;
//                     block_address <= block_address + 10'd1;
//                     if(block_address == 11'd2047)begin
//                        block_address <= 0;  	
//                     end else;
//                end
//                default:begin
//                    add_vail <= 1'b1;
//                    if(page_address == 6'd63) begin
//                        page_address <= 6'd0;
//                        block_address <= block_address + 10'd1;
//                    end       
//                    else begin
//                        page_address <= page_address + 6'd1;
//                    end                    
//                end
//            endcase
//        end
//        else begin
//            page_address <= page_address;
//            block_address <= block_address;
//            add_vail <= 1'b0;	
//        end
//end
endmodule