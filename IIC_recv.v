//use notepad++ open!!!!!!!!!!!
module IIC_recv
(
	input			I_clk			,
	input			I_rst_n			,
	input			I_recv_en		,
	input			I_SCL_HIG		,
	input			I_SCL_NEG		,
	input			I_SCL_LOW		,	
	input	[6:0]	I_dev_addr		,
	input	[7:0]	I_word_addr		,
	input	[1:0]	I_BYTE			,
	output			O_SCL_en		,
	output	[15:0]	O_read_date		,
	output			O_done_flag		,
	inout			IO_SDA
);

//============ 狀態機定義 ============
parameter	INIT				= 8'h00,		
			LOAD1				= 8'h01,		
			START				= 8'h02,		
			ADDRESS				= 8'h03,		
			ACK					= 8'h04,		
			ACK_JUDG			= 8'h05,	
			LOAD2				= 8'h06,	
			COMMAND				= 8'h07,	
			ACK2				= 8'h08,
			ACK_JUDG2			= 8'h09,
			LOAD3				= 8'h0A,	
			reSTART				= 8'h0B,	
			reADDRESS			= 8'h0C,
			ACK3				= 8'h0D,
			ACK_JUDG3			= 8'h0E,
			READ				= 8'h0F,
			NACK				= 8'h10,
			WAIT				= 8'h11,
			STOP				= 8'h12,
			DONE_PULSE			= 8'h13,
			BYTE_JUDG			= 8'h14,
			BYTE_ACK			= 8'h15,
			BYTE_ACK2			= 8'h16,

			SYS_STOP2 			= 8'hFE,
			SYS_STOP 			= 8'hFF;	//最後一個結尾要;不能,

reg	[7:0]	R_state				=	0;
reg 		R_sda_mode			=	0;		//設置SDA模式，1位輸出，0為輸入
reg 		R_sda_reg			=	0;
reg	[3:0]	R_bit_cnt			=	0;		//發送字節狀態中bit個數計數
reg			R_ack_flag			=	0; 		//ack flag
reg 		R_done_flag			=	0;
reg	[15:0]	R_read_data_reg		=	0;
reg	[15:0]	R_read_data_buffer	=	0;
reg			R_scl_en        	=	0;
reg	[7:0]	R_load_data			=	0;		//command byte
reg	[1:0]	R_byte_now			=	0;		//now BYTE


assign IO_SDA		= (R_sda_mode == 1'b1) ? R_sda_reg : 1'bz ;
assign O_SCL_en		= R_scl_en								;
assign O_done_flag	= R_done_flag							;
assign O_read_date	= R_read_data_buffer					;

always @(posedge I_clk or negedge I_rst_n)
begin
    if(!I_rst_n)
        begin
            R_state		<=  0 ;
        end
    else if(I_recv_en)	//I2C EN
        begin
			case(R_state)
				INIT:
					begin
						R_state         <=  LOAD1 ;
						R_sda_mode      <=  1'b1 ;
						R_sda_reg       <=  1'b1 ;
						R_bit_cnt       <=  4'd0 ;
						R_ack_flag		<=	1'b0 ;
						R_done_flag     <=  1'b0 ;
						R_read_data_reg <=  0 ;
						R_scl_en		<=	1'b0 ;
					end
					
				LOAD1:	//載入address
					begin
						R_state         <= START ;
						R_load_data		<= {I_dev_addr,1'b0};
					end	
					
				START:	//送出起始
					begin
						R_scl_en		<=  1'b1 ; // 開啟SCK
                        R_sda_mode		<=  1'b1 ; // 開啟SDA控制
                        if(I_SCL_HIG)
                            begin
                                R_sda_reg	<=  1'b0 ; // 下降緣start
                                R_state		<=  ADDRESS ; // 
                            end
                        else
                            R_state <= START ;    
					end							
				
				ADDRESS:
					begin
						R_scl_en		<=  1'b1 ; // 開啟SCK
						R_sda_mode		<=  1'b1 ; // 開啟SDA控制
						if(I_SCL_LOW)
							begin
								if(R_bit_cnt == 4'd8)
									begin
										R_state		<= ACK;
										R_bit_cnt 	<= 0;
									end
								else
									begin
										R_sda_reg <= R_load_data[7-R_bit_cnt];
										R_bit_cnt <= R_bit_cnt + 1'b1;
									end
							end
						else
							R_state	<= ADDRESS;
					end
				
				ACK:
					begin
						R_scl_en		<=  1'b1 ; // 開啟SCK
						R_sda_mode		<=  1'b0 ; // close SDA控制
						R_sda_reg		<=	1'b1 ; // 
						if(I_SCL_HIG)
							begin
								R_state		<= ACK_JUDG;
								R_ack_flag	<= IO_SDA;
							end
						else
							R_state	<= ACK;
					end
					
				ACK_JUDG:
					begin
						if(!R_ack_flag)
							begin
								if(I_SCL_NEG)
									begin
										R_state			<= LOAD2; 
										R_sda_mode		<= 1'b1 ; // 開啟SDA控制
										R_sda_reg		<= 1'b1 ; // 
									end
								else 
									R_state		<= ACK_JUDG;
							end
						else
							R_state	<= INIT;	//slave無回應跳回
					end
				
				LOAD2:
					begin
						R_state			<= COMMAND;
						R_load_data		<= I_word_addr;
					end
				
				COMMAND:
					begin
						R_scl_en		<=  1'b1 ; // 開啟SCK
						R_sda_mode		<=  1'b1 ; // 開啟SDA控制
						if(I_SCL_LOW)
							begin
								if(R_bit_cnt == 4'd8)
									begin
										R_state		<= ACK2;
										R_bit_cnt 	<= 0;
									end
								else
									begin
										R_sda_reg <= R_load_data[7-R_bit_cnt];
										R_bit_cnt <= R_bit_cnt + 1'b1;
									end
							end
						else
							R_state	<= COMMAND;
					end
					
				ACK2:
					begin
						R_scl_en		<=  1'b1 ; // 開啟SCK
						R_sda_mode		<=  1'b0 ; // 關SDA控制
						R_sda_reg		<=	1'b1 ; // 
						if(I_SCL_HIG)
							begin
								R_state		<= ACK_JUDG2;
								R_ack_flag	<= IO_SDA;
							end
						else
							R_state	<= ACK2;
					end
					
				ACK_JUDG2:
					begin
						if(!R_ack_flag)
							begin
								if(I_SCL_LOW)
									begin
										R_state			<= LOAD3 ;
										R_sda_mode		<= 1'b1 ; // 開啟SDA控制
										R_sda_reg		<= 1'b1 ; // 
									end
								else 
									R_state		<= ACK_JUDG2;
							end
						else
							R_state	<= INIT;	//slave無回應跳回
					end

				LOAD3:	//載入readdress
					begin
						R_state         <= reSTART ;
						R_load_data		<= {I_dev_addr,1'b1};
					end	
					
				reSTART:
					begin
						R_scl_en		<=  1'b1 ; // 開啟SCK
                        R_sda_mode		<=  1'b1 ; // 開啟SDA控制
                        if(I_SCL_HIG)
                            begin
                                R_sda_reg	<=  1'b0 ; // 下降緣start
                                R_state		<=  reADDRESS ; // 
                            end
                        else
                            R_state <= reSTART ;   
					end	
				
				reADDRESS:
					begin
						R_scl_en		<=  1'b1 ; // 開啟SCK
						R_sda_mode		<=  1'b1 ; // 開啟SDA控制
						if(I_SCL_LOW)
							begin
								if(R_bit_cnt == 4'd8)
									begin
										R_state		<= ACK3;
										R_bit_cnt 	<= 0;
									end
								else
									begin
										R_sda_reg <= R_load_data[7-R_bit_cnt];
										R_bit_cnt <= R_bit_cnt + 1'b1;
									end
							end
						else
							R_state	<= reADDRESS;
					end
					
				ACK3:
					begin
						R_scl_en		<=  1'b1 ; // 開啟SCK
						R_sda_mode		<=  1'b0 ; // 關SDA控制
						R_sda_reg		<=	1'b1 ; // 
						if(I_SCL_HIG)
							begin
								R_state		<= ACK_JUDG3;
								R_ack_flag	<= IO_SDA;
							end
						else
							R_state	<= ACK3;
					end
					
				ACK_JUDG3:
					begin
						if(!R_ack_flag)
							begin
								if(I_SCL_LOW)
									begin
										R_state			<= READ ;
										R_sda_mode		<= 1'b0 ; // close SDA控制
										R_sda_reg		<= 1'b1 ; // 
									end
								else 
									R_state		<= ACK_JUDG3;
							end
						else
							R_state	<= INIT;	//slave無回應跳回
					end
					
				READ:
					begin
						R_scl_en		<=  1'b1 ; // 開啟SCK
						R_sda_mode		<=  1'b0 ; // 關SDA控制
						if(I_SCL_HIG)
							begin
								if(R_bit_cnt == 4'd7)
									begin
										R_state		<= BYTE_JUDG ;
										R_bit_cnt 	<= 0	;	
										R_read_data_reg <= {R_read_data_reg[14:0],IO_SDA};
										R_byte_now	<= R_byte_now + 1'b1;
									end
								else
									begin
										R_read_data_reg <= {R_read_data_reg[14:0],IO_SDA};
										R_bit_cnt <= R_bit_cnt + 1'b1;
									end
							end
						else
							R_state	<= READ;
					end					
				
				BYTE_JUDG:
					begin
						if(R_byte_now == I_BYTE)
							begin
								R_state		<= NACK ;
								R_byte_now	<= 0	;
								R_read_data_buffer <= R_read_data_reg;	//擷取BYTE完畢移至buffer
							end
						else
							R_state		<= BYTE_ACK ;
					end
				
				NACK:	
					begin
						R_scl_en		<=	1'b1 ; // 開啟SCK
						R_sda_mode		<=	1'b1 ; // 開啟SDA控制
						if(I_SCL_LOW)
							begin
								R_state		<= WAIT ;
								R_sda_reg	<= 1'b1 ;
							end
						else
							R_state		<= NACK ;
					end

				BYTE_ACK:	//1 to 2 byte master report ack 0
					begin
						R_scl_en		<=  1'b1 ; // 開啟SCK
						if(I_SCL_LOW)
							begin
								R_state		<=  BYTE_ACK2;
								R_sda_mode	<=  1'b1 ; // 開SDA控制
								R_sda_reg	<=	1'b0 ; // 
							end
						else
							R_state	<= BYTE_ACK;
					end
					
				BYTE_ACK2:	//放開SDA控制讀資料
					begin
						R_scl_en		<=  1'b1 ; // 開啟SCK
						if(I_SCL_LOW)
							begin
								R_state		<=  READ;
								R_sda_mode	<=  1'b0 ; // close SDA
								R_sda_reg	<=	1'b1 ; // 
							end
						else
							R_state	<= BYTE_ACK2;
					end

				WAIT:
					begin
						R_scl_en		<=	1'b1 ; // 開啟SCK
						R_sda_mode		<=	1'b1 ; // 開啟SDA控制
						if(I_SCL_LOW)
							begin
								R_state		<= STOP ;
								R_sda_reg	<= 1'b0 ; //準備下STOP
							end
						else
							R_state		<= WAIT ;
					end
					
				STOP:
					begin
						R_scl_en		<=	1'b1 ; // 開啟SCK
						R_sda_mode		<=	1'b1 ; // 開啟SDA控制
						if(I_SCL_HIG)
							begin
								R_state		<= DONE_PULSE ;
								R_sda_reg	<= 1'b1 ;
							end
						else
							R_state		<= STOP ;
					end
				
				DONE_PULSE:
					begin
						R_state			<=	INIT		;
						R_scl_en		<=	1'b0 		; // 開啟SCK
						R_sda_mode		<=	1'b1 		; // 開啟SDA控制
						R_sda_reg		<=	1'b1 		;
						R_done_flag     <=  1'b1 		;
						R_read_data_reg <=  0			;
					end				
				
				SYS_STOP:
					begin
						R_scl_en		<=  1'b0 ; // open SCK
					end
					
				SYS_STOP2:
					begin
						R_scl_en		<=  1'b1 ; // close SCK
					end					
					
				default: R_state <= INIT;
			endcase
		end
	else
		begin
			R_state         <=  INIT;
			R_sda_mode      <=  1'b1 ;
			R_sda_reg       <=  1'b1 ;
			R_bit_cnt       <=  4'd0 ;
			R_done_flag     <=  1'b0 ;
			R_read_data_reg <=  0 ;
		end
end

endmodule
