//use notepad++ open!!!!!!!!!!!
module LTC2992_command
(
	input			I_clk			,
	input			I_rst_n			,
	input			I_done_flag		,
	input	[15:0]	I_read_date		,
	output	[15:0]	O_Vout_date		,
	output			O_recv_en		,
	output			O_send_en		,
	output	[6:0]	O_dev_addr		,	//address
	output	[7:0]	O_word_addr		,	//command
	output	[7:0]	O_write_date	,	//data
	output	[1:0]	O_BYTE			
);

reg	[7:0]		R_state			= 0				;
reg				R_recv_en		= 0				;
reg				R_send_en		= 0				;
reg [7:0]		R_word_addr		= 0				;
reg	[7:0]		R_write_date	= 0				;
reg	[1:0]		R_byte_tar		= 0				;//BYTE目標
reg [23:0]		R_delay_cnt		= 0				;
reg 			R_delay_en		= 0				;
reg	[15:0]		R_Vout_date		= 0				;


assign			O_recv_en		= R_recv_en		;
assign			O_send_en		= R_send_en		;
assign			O_dev_addr		= 7'h6F			;
assign			O_word_addr		= R_word_addr	;
assign			O_write_date	= R_write_date	;
assign			O_BYTE			= R_byte_tar	;
assign			O_Vout_date		= R_Vout_date	;

parameter		T_10ms			= 24'd500_000	,
				T_16ms			= 24'd800_000	,
				T_50ms			= 24'd2_500_000	,
				T_100ms			= 24'd5_000_000	,
				T_150ms			= 24'd7_500_000	;

parameter		ADR_CTRLA		= 8'h00		,
				ADR_NADC		= 8'h04		,
				ADR_S1			= 8'h1E		,
				ADR_S1_2		= 8'h1F		,
				ADR_I1			= 8'h14		,
				
				ADR_ID			= 8'hE8		;
				
always@(*)  //判斷command的BYTE長度
begin  
	case(R_word_addr)   
		8'h00:		R_byte_tar <= 2'd1;
		8'h14:		R_byte_tar <= 2'd2;
		8'h1E:		R_byte_tar <= 2'd2;
		8'h1F:		R_byte_tar <= 2'd2;
		8'hE8:		R_byte_tar <= 2'd1;

		
		default: 	R_byte_tar <= 2'd0;
	endcase 
end

always @(posedge I_clk or negedge I_rst_n)	//計算
begin
	if(!I_rst_n)
		R_delay_cnt <= 0;
	else if(R_delay_en)	
		R_delay_cnt <= R_delay_cnt + 1'b1;
	else
		R_delay_cnt <= 0;
end

always @(posedge I_clk or negedge I_rst_n)
begin
	if(!I_rst_n)
		begin
			R_state <= 0;
			R_recv_en <= 1'b0;
			R_send_en <= 1'b0;
		end
	else
		begin
			case(R_state)
				8'd00:	
					begin
						R_state 		<= 8'd01		;
						R_word_addr 	<= ADR_CTRLA	;
						R_write_date	<= 8'h80		;
						R_send_en 		<= 1'b1			;
					end
					
				8'd01:
					begin
						if(I_done_flag)
							begin
								R_state 		<= 8'd02		;
								R_send_en 		<= 1'b0			;
								R_delay_en		<= 1'b1			; //delay count start
							end
						else 
							R_state 		<= 8'd01		;
					end
				
				8'd02:	
					begin
						if(R_delay_cnt == T_150ms)
							begin
								R_state			<= 8'd03		;
								R_delay_en		<= 1'b0			; //delay count close
							end
					end

				8'd03:	
					begin
						R_state 		<= 8'd04		;
						R_word_addr 	<= ADR_S1		;
						R_recv_en 		<= 1'b1			;
					end
				
				8'd04:
					begin
						if(I_done_flag)
							begin
								R_state 		<= 8'd05		;
								R_recv_en 		<= 1'b0			;
								R_Vout_date		<= {4'b0000 , I_read_date[15:4]};
							end
						else 
							R_state 		<= 8'd04		;
					end

				8'd05:	
					begin
						R_state 		<= 8'd05		;
					end

				default: R_state <= 8'd00;
			endcase
		end
end
endmodule