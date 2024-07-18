`timescale 1ns / 1ps
module top(
//input reset_in_,            //input reset active low
	input clk,                  
	
// fx3 interface
	inout [31:0] fdata,  
	output [1:0] faddr,          //output fifo address  
	output slrd,                 //output read select
	output slwr,                 //output write select
	input flaga,
	input flagb,
	input flagc,
	input flagd,
	output sloe,                //output output enable select
	output clk_out,             //output clk 100 Mhz and 180 phase shift
	output slcs,                //output chip select
	output pktend,              //output pkt end 激活该信号后可将短数据包或零数据包写入从设备FIFO
	
	output led0,
	inout [7:0] DIO ,
    output  CLE  , // -- CLE
    output  ALE  , //  -- ALE
    output  WE_n , // -- ~WE
    output  RE_n , //-- ~RE
    output  CE_n , //-- ~CE
    output  WP_n,
    input      R_nB   //-- R/~B
); 


    wire clk_100;
    //wire clk_200;
    wire lock;
    wire reset_;

    assign reset_ = lock;
    
    wire CLKFBIN;
    
  
   // PLLE2_BASE: Base Phase Locked Loop (PLL)
   //             Artix-7
   // Xilinx HDL Language Template, version 2018.3

   PLLE2_BASE #(
      .BANDWIDTH("OPTIMIZED"),  // OPTIMIZED, HIGH, LOW
      .CLKFBOUT_MULT(10),        // Multiply value for all CLKOUT, (2-64)
      .CLKFBOUT_PHASE(0.0),     // Phase offset in degrees of CLKFB, (-360.000-360.000).
      .CLKIN1_PERIOD(10),      // Input clock period in ns to ps resolution (i.e. 33.333 is 30 MHz).
      // CLKOUT0_DIVIDE - CLKOUT5_DIVIDE: Divide amount for each CLKOUT (1-128)
      .CLKOUT0_DIVIDE(10),
      .CLKOUT1_DIVIDE(10),
      .CLKOUT2_DIVIDE(10),
      .CLKOUT3_DIVIDE(10),
      .CLKOUT4_DIVIDE(10),
      .CLKOUT5_DIVIDE(10),
      // CLKOUT0_DUTY_CYCLE - CLKOUT5_DUTY_CYCLE: Duty cycle for each CLKOUT (0.001-0.999).
      .CLKOUT0_DUTY_CYCLE(0.5),
      .CLKOUT1_DUTY_CYCLE(0.5),
      .CLKOUT2_DUTY_CYCLE(0.5),
      .CLKOUT3_DUTY_CYCLE(0.5),
      .CLKOUT4_DUTY_CYCLE(0.5),
      .CLKOUT5_DUTY_CYCLE(0.5),
      // CLKOUT0_PHASE - CLKOUT5_PHASE: Phase offset for each CLKOUT (-360.000-360.000).
      .CLKOUT0_PHASE(0.0),
      .CLKOUT1_PHASE(180),
      .CLKOUT2_PHASE(0.0),
      .CLKOUT3_PHASE(0.0),
      .CLKOUT4_PHASE(0.0),
      .CLKOUT5_PHASE(0.0),
      .DIVCLK_DIVIDE(1),        // Master division value, (1-56)
      .REF_JITTER1(0.0),        // Reference input jitter in UI, (0.000-0.999).
      .STARTUP_WAIT("FALSE")    // Delay DONE until PLL Locks, ("TRUE"/"FALSE")
   )
   PLLE2_BASE_inst (
      // Clock Outputs: 1-bit (each) output: User configurable clock outputs
      .CLKOUT0(clk_100),   // 1-bit output: CLKOUT0
      .CLKOUT1(clk_out),   // 1-bit output: CLKOUT1
      .CLKOUT2(),   // 1-bit output: CLKOUT2
      .CLKOUT3(),   // 1-bit output: CLKOUT3
      .CLKOUT4(),   // 1-bit output: CLKOUT4
      .CLKOUT5(),   // 1-bit output: CLKOUT5
      // Feedback Clocks: 1-bit (each) output: Clock feedback ports
      .CLKFBOUT(CLKFBIN), // 1-bit output: Feedback clock
      .LOCKED(lock),     // 1-bit output: LOCK
      .CLKIN1(clk),     // 1-bit input: Input clock
      // Control Ports: 1-bit (each) input: PLL control ports
      .PWRDWN(1'b0),     // 1-bit input: Power-down
      .RST(1'b0),           // 1-bit input: Reset
      // Feedback Clocks: 1-bit (each) input: Clock feedback ports
      .CLKFBIN(CLKFBIN)    // 1-bit input: Feedback clock
   );

   // End of PLLE2_BASE_inst instantiation
   
   (* DONT_TOUCH = "yes" *)wire [31:0] data_tx;  //DONT_TOUCH的最直接后果就是使得作用对象在设计的任何阶段都不会被优化掉。
   (* DONT_TOUCH = "yes" *)wire data_tx_pktend;
   (* DONT_TOUCH = "yes" *)wire data_tx_valid;
   (* DONT_TOUCH = "yes" *)reg data_tx_ready;
   
   wire [31:0] ctrl_tx;
   wire ctrl_tx_pktend;
   wire ctrl_tx_valid;
   wire ctrl_tx_ready;
   
   reg [31:0] ctrl_rx;
   reg ctrl_rx_pktend;
   reg ctrl_rx_valid;
   wire ctrl_rx_ready;
   
   reg s_data_tvalid;
   wire s_data_tready;
   wire [31:0] s_data_tdata;
   reg s_data_tlast;

    gpif2_to_fifo32 gpif2_to_fifo32_i (
        // GPIF signals
        .gpif_clk(clk_100),
        .gpif_rst(~reset_),
        .gpif_enb(1'b1),
        .gpif_d(fdata),
        .gpif_ctl({flagd, flagc, flagb, flaga}),
        .sloe(sloe),
        .slrd(slrd),
        .slwr(slwr),
        .slcs(slcs),
        .pktend(pktend),
        .fifoadr(faddr),
        // FIFO interfaces
        // TX Data interface - down stream  output [31:0] tx_tdata, output tx_tlast, output tx_tvalid, input tx_tready,
        .tx_tdata(data_tx), .tx_tlast(data_tx_pktend), .tx_tvalid(data_tx_valid), .tx_tready(data_tx_ready),
        // RX Data interface - up stream  input [31:0] rx_tdata, input rx_tlast, input rx_tvalid, output rx_tready,
        .rx_tdata(s_data_tdata), .rx_tlast(s_data_tlast), .rx_tvalid(s_data_tvalid), .rx_tready(s_data_tready),
        // Incomming control interface
        .ctrl_tdata(ctrl_tx), .ctrl_tlast(ctrl_tx_pktend), .ctrl_tvalid(ctrl_tx_valid), .ctrl_tready(ctrl_tx_ready),
        // Outgoing control interface
        .resp_tdata(ctrl_rx), .resp_tlast(ctrl_rx_pktend), .resp_tvalid(ctrl_rx_valid), .resp_tready(ctrl_rx_ready)
    );
    
    // control path loopback
//    assign ctrl_rx = ctrl_tx;
//    assign ctrl_rx_pktend = ctrl_tx_pktend;
//    assign ctrl_rx_valid = ctrl_tx_valid;
//    assign ctrl_tx_ready = ctrl_rx_ready;
     assign ctrl_tx_ready = 1'b1;
    
    // receice data anytime
    //assign data_tx_ready = 1'b1;
  
parameter              Size = 5;
parameter              B = 3;
    
wire done;
reg [5:0] page_address_in;
reg [10:0] block_address_in;
wire [5:0]  page_address ;
wire [10:0] block_address;
reg address_vail;



wire [7:0] flash_out;
//wire flash_out_vail;
reg read_start;
reg [7:0] flash_out_buf[0:2047];
reg [11:0] flash_out_index;

reg [1:0] command_in;      
reg  command_in_vail;
wire error;  
wire data_out_vail; 
reg erase_start;   
 
localparam STATE_WAITE = 2'b00;
localparam STATE_DATA = 2'b01;
localparam STATE_READ=2'b10;
localparam STATE_ERASE=2'b11;




reg [1:0] con;

reg write_flag;
reg read_flag;
reg erase_flag;

reg          pattern_val;
reg  [7:0]   pattern;  
wire [14:0] position;    
wire position_val;  
wire [11:0]cnt;           

//reg [31:0] trigger_config_data;  
reg config_valid;

reg ctrl_tx_valid1;
wire add_vail;
reg erase_write_end;

wire [7:0] flash_in;
wire flash_in_val;
reg end_flag;
reg read_end;
reg receive_flag;


always @(posedge clk_100) begin
    if(~reset_)begin
        pattern <= 8'd0;
        pattern_val <= 1'b0;
        receive_flag <= 1'b0;
    end
    else if(data_tx_valid && data_tx == 32'hffffffff)begin
         receive_flag <= 1'b1;
    end
    else if(receive_flag)begin    
        pattern <= data_tx[7:0];
        pattern_val <= 1'b1; 
        if(data_tx_pktend) begin
            receive_flag <= 1'b0;
        end     
    end
    else begin
         pattern_val <= 1'b0;
         receive_flag <= 1'b0; 
    end
end
always @(posedge clk_100) begin
       ctrl_tx_valid1 <= ctrl_tx_valid;
end  

always @(posedge clk_100) begin
    if(~reset_)begin
		page_address_in  <=0;
		block_address_in <=0;
	end
	else if(ctrl_tx_valid == 1'b1 && ctrl_tx_valid1 == 1'b0) begin
	   	page_address_in  <=0;
		block_address_in <=0;
	end
	else begin
	    page_address_in  <=page_address; 
		block_address_in <=block_address;
//		page_address_in  <=0;
//		block_address_in <=0;
	end
end


  
always @(posedge clk_100) begin
		if(~reset_)begin 
		  con <= 2'b00;  
		  config_valid <= 1'b0;
		  erase_write_end <= 1'b0;
//		  erase_end <= 1'b0;
		end
		else if(ctrl_tx_valid == 1'b1 && ctrl_tx_valid1 == 1'b0) begin
		  if(ctrl_tx == 32'hffff_ffff)begin
		      erase_write_end <= 1'b1;
		  end 
		  else begin
		      con <= ctrl_tx[1:0]; 
		      config_valid <= 1'b1; 
		      erase_write_end <= 1'b0; 
//		      write_end <= 1'b0;
		  end
		end
		else if(add_vail && ~erase_write_end && ~read_end)begin
		  case(con)
		      2'b11:begin
		          config_valid <= 1'b1;
		          if(block_address == 11'd2047)begin
		              erase_write_end <= 1'b1;		              
		          end else ;
		      end
		      2'b10:begin
		          config_valid <= 1'b1;
		      end
		      2'b01:begin
		          config_valid <= 1'b1;
		      end
		      default:begin
		      end
		  endcase
		end 
		else  if(end_flag)begin
		  erase_write_end <= 1'b0;
		  con <= 2'b00;   
	    end
		else begin
		  config_valid <= 1'b0;
		  con <= con;
		  erase_write_end <= erase_write_end;
		end
end

always @(posedge clk_100) begin
    if(~reset_)begin
        ctrl_rx <= 32'd0;
        ctrl_rx_pktend <= 1'b0;
        ctrl_rx_valid <= 1'b0;
    end
    else if(command_in == 2'b01 && done && ctrl_rx_ready)begin
        ctrl_rx <= 32'hffff_ffff;
        ctrl_rx_pktend <= 1'b1;
        ctrl_rx_valid <= 1'b1;
    end
    else begin
        ctrl_rx <= 32'd0;
        ctrl_rx_pktend <= 1'b0;
        ctrl_rx_valid <= 1'b0;
    end
end

always @(posedge clk_100) begin
	if(~reset_)begin		
        address_vail <= 1'b0;
        command_in <= 2'b00;
        command_in_vail <= 1'b0;
        write_flag<= 1'b0;
        read_flag <= 1'b0;
        erase_flag<= 1'b0;     
	end
	else if(config_valid)begin
		case (con)
            STATE_DATA: begin										
							address_vail <= 1'b1;	
							command_in <= 2'b01;
							command_in_vail <= 1'b1;
							//write_flag<= 1'b1;																				
					    end
		    STATE_READ:begin		                    					
							address_vail <= 1'b1;
							command_in <= 2'b10;
							command_in_vail <= 1'b1;
							read_flag <= 1'b1;																						
		               end
		   STATE_ERASE:begin		                   				
							address_vail <= 1'b1;
							command_in <= 2'b11;
							command_in_vail <= 1'b1;
							erase_flag<= 1'b1; 																						
		               end
            STATE_WAITE:begin				
					end
		endcase
	 end
	 else begin
	       	   address_vail <= 1'b0;
	           command_in_vail <= 1'b0;
	           write_flag<= 1'b0;
               read_flag <= 1'b0;
               erase_flag<= 1'b0;  
	 end
end

reg one;
reg success_we;
reg error_we;
reg data_tx_pktend1;
always @(posedge clk_100) data_tx_pktend1 <= data_tx_pktend;
//reg success_e;
//reg error_e;
always @(posedge clk_100) begin
	if(~reset_)begin
	   one <= 1'b0;
	   data_tx_ready <= 1'b0;	   
	end
	else if(done || one==1'b0)  begin    //写
		data_tx_ready <= 1'b1;	
		one <= 1'b1;
    end 
    else if(data_tx_pktend && ~data_tx_pktend1 )begin
         data_tx_ready <= 1'b0;
    end
    else data_tx_ready <= data_tx_ready;
end


//判断写是否成功
always @(posedge clk_100) begin
	if(~reset_)begin
	   success_we  <= 1'b0;
	   error_we <= 1'b0;
	end
	else if(done && error && (con == 2'b01 || con == 2'b11))begin
	   success_we <= 1'b0;
	   error_we <= 1'b1; 
	end
	else if(done && ~error  && ~error_we && (con == 2'b01 || con == 2'b11))begin
	   success_we <= 1'b1;
	end
	else if(s_data_tlast)begin
	   success_we  <= 1'b0;
	   error_we <= 1'b0;
	end
	else begin
	   error_we <= error_we;
	   success_we <= success_we;
	end
	
end



always @(posedge clk_100) begin
    if(~reset_) begin
       erase_start <= 1'b0;
    end
    else if(erase_flag) begin
        erase_start <= 1'b1;
    end
    else erase_start <= 1'b0;
end

reg read_start1;
always @(posedge clk_100) begin
    if(~reset_) begin
       read_start <= 1'b0;
    end
    else if(read_flag) begin
        read_start <= 1'b1;
    end
    else read_start <= 1'b0;
end

always @(posedge clk_100) read_start1 <=  read_start;


reg is_read;
reg [11:0]count_0;
reg compare_end;
always @(posedge clk_100) begin
    if(~reset_) begin
       flash_out_index<=12'd0;
       is_read <= 1'b0;
       end_flag <= 1'b0;
       count_0 <= 12'd0;
       read_end <= 1'b0;
       compare_end <= 1'b0;
    end
    else if(data_out_vail) begin
        flash_out_buf[flash_out_index] <= flash_out;
        flash_out_index <= flash_out_index+12'd1;
        if(flash_out == 8'hff)begin
            count_0 <= count_0 + 12'd1;
        end
        if(flash_out_index == 2047 || done == 1'b1)begin
            flash_out_index <= 12'd0;
        end
    end
    else if( (~end_flag && erase_write_end && (con != 2'b10)) || (con == 2'b10 &&done == 1'b1)) begin
    //else if( done) begin
        is_read <= 1'b1;
        end_flag <= 1'b1;
        count_0 <= 12'd0;
        if(count_0 == 12'd2048)begin
            read_end <= 1'b1;
            is_read <= 1'b0;         
            compare_end <= 1'b1;
        end else;
       
    end    
    else begin
        is_read <= 1'b0;
        end_flag <= 1'b0;
        read_end <= 1'b0;
        compare_end <= 1'b0;
    end
end

reg  [31:0] position_reg[0:512];    
reg  [15:0] cnt_reg;  
reg [10:0] index_po;
//reg match_start;
reg [10:0] index_tr;
reg match_end;

reg [5:0] page_cnt[0:63];
reg [10:0] block_cnt[0:2047];
reg [5:0] page_index;
reg [10:0] block_index;

//reg [15:0] page_reg[0:]

always @(posedge clk_100) begin
    if(~reset_) begin
        index_po <= 11'd0;
        cnt_reg <= 16'd0;
        page_index <= 6'd0;
        block_index <= 11'd0;
    end
    else if(position_val)begin
        position_reg[index_po] <= {block_address_in,page_address_in,position};
        cnt_reg <= cnt;
        //index_po <= index_po + 11'd1;
    end
    else if(match_end) begin
        index_po <= 11'd0;
        cnt_reg <= 12'd0;
    end
    else ;
 end


reg [31:0] data_out;
reg [11:0]out_index;
reg out_flag;
reg out_flag1;


always @(posedge clk_100) begin    
       if(~reset_) begin
           data_out <= 31'd0;
           out_index <= 12'd0;
           out_flag <= 1'b0;
           out_flag1 <= 1'b0;
//           match_start <= 1'b0;
           index_tr <= 11'd0;
           match_end <= 1'b0;         
       end  
       else if((s_data_tready &&  is_read ) || out_flag ) begin
            s_data_tvalid <= 1'b1;
            if(command_in == 2'b01 ||command_in == 2'b11 )begin
                if(success_we == 1'b1)begin
                    data_out <= 32'd1;
                end
                else begin
                    data_out <= 32'd2;
                end
                s_data_tlast <= 1'b1;
            end   
            else if(command_in == 2'b10)begin
                 out_flag <= 1'b1;
                 data_out <= {flash_out_buf[out_index+3],flash_out_buf[out_index+2],flash_out_buf[out_index+1],flash_out_buf[out_index]};
                 out_index <= out_index+ 12'd4;
                 if(out_index == 12'd2044)begin
                    s_data_tlast <= 1'b1;
                    out_index <= 12'd0;
                    out_flag <= 1'b0;
  //                  match_start <= 1'b1;
                 end
            end                           
        end
        else if((s_data_tready && compare_end) || out_flag1)begin
            out_flag1 <= 1'b1;
            s_data_tvalid <= 1'b1;
            if(index_tr == index_po)begin
                data_out <= {16'd0,cnt_reg}; 
                s_data_tlast <= 1'b1; 
                index_tr <= 11'd0; 
                match_end <= 1'b1; 
                out_flag1 <= 1'b0;          
            end           
            else begin
                data_out <= position_reg[index_tr];
                index_tr <= index_tr + 11'd1;
            end
        end
        else begin
            s_data_tvalid <= 1'b0;
            s_data_tlast <= 1'b0;
            match_end <= 1'b0;  
            index_tr <= 11'd0; 
        end
    end
    
    
    assign s_data_tdata = data_out;   

control control_i(

 .DIO  (DIO ),
 .CLE  (CLE ), // -- CLE
 .ALE  (ALE ), //  -- ALE
 .WE_n (WE_n), // -- ~WE
 .RE_n (RE_n), //-- ~RE
 .CE_n (CE_n), //-- ~CE
 .WP_n (WP_n),
 .R_nB (R_nB), //-- R/~B
//-- system      
 .clk              (clk_100             ),
 .rst_n            (reset_          ),
 .command_in       (command_in      ),
 .command_in_vail  (command_in_vail ),
 .error            (error           ),
 .done             (done            ),
 .page_address_in  (page_address_in ),
 .block_address_in (block_address_in),
 .address_vail     (address_vail    ),
 .data             (flash_in         ),
 .data_vail        (flash_in_val   ),
 .read_start       (read_start1      ),
 .data_out  	   (flash_out       ),
 .data_out_vail    (data_out_vail   ),
 .erase_start      (erase_start     ) 
);  

data_buf  data_buf_i(
    .clk           (clk_100 )      ,
    .rst_n         (reset_  )      ,
    .data_in       (data_tx )      ,
    .data_in_val   (data_tx_valid) ,
    .data_in_last  (data_tx_pktend),
    .data_ready    (data_tx_ready  ) ,
    .command       (con          ),
    .data_out      (flash_in     ) ,
    .data_out_val  (flash_in_val )
);

 match#(
    . Size(Size),
    . B (B)
)
match_i
(
   
 . clk         (clk_100     ),
 . rst_n       (reset_      ),

 . data_in     (flash_out     ),
 . data_in_val (data_out_vail ),
 . pattern     (pattern     ),
 . pattern_val (pattern_val ),
 . done        (done        ),
 . match_end    (compare_end),
              
 . position    (position    ),
 . position_val(position_val),
 . cnt         (cnt         )
 //.page_cnt	   (page_cnt    )
);

address address_i(
    .clk           (clk_100          ),
    .rst_n         (reset_       ),
    .done          (done         ),
    .con           (con         ),    
    .page_address_out  (page_address ),
    .block_address_out (block_address),
    .add_vail      (add_vail     )
);               
     
     
/*           
ila_1 my_ila1 (
	.clk(clk_100), // input wire clk

	.probe0(count_0), // input wire [11:0]  probe0  
	.probe1(flash_in), // input wire [7:0]  probe1 
	.probe2(read_end), // input wire [0:0]  probe2 
	.probe3(data_tx), // input wire [31:0]  probe3 
	.probe4(con), // input wire [1:0]  probe4 
	.probe5(command_in), // input wire [1:0]  probe5 
	.probe6(done), // input wire [0:0]  probe6
	.probe7(data_tx_valid), // input wire [0:0]  probe7 
	.probe8(config_valid), // input wire [0:0]  probe8 
	.probe9(s_data_tlast), // input wire [0:0]  probe9 
	.probe10(data_out), // input wire [31:0]  probe10 
	.probe11(is_read), // input wire [0:0]  probe11 
	.probe12(error_we), // input wire [0:0]  probe12 
	.probe13(success_we), // input wire [0:0]  probe13
	.probe14(page_address_in), // input wire [5:0]  probe14
	.probe15(block_address_in), // input wire [10:0]  probe15
	.probe16(index_po), // input wire [10:0]  probe16 
	.probe17(index_tr), // input wire [10:0]  probe17 
	.probe18(cnt_reg), // input wire [15:0]  probe18 
	.probe19(error) // input wire [0:0]  probe19
);
    */
endmodule


