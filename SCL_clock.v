//use notepad++ open!!!!!!!!!!!
module SCL_clock
(
	input			I_clk			,
	input			I_rst_n			,
	input			I_SCL_en		,
	//output			O_SCL_POS		,
	output			O_SCL_HIG		,
	output			O_SCL_NEG		,
	output			O_SCL_LOW		,
	output			O_SCL
);

reg	[8:0]		SCL_cnt= 0		;		//產生SCL計數器 
reg				SCL_POS= 0		;
reg				SCL_HIG= 0		;
reg				SCL_NEG= 0		;
reg				SCL_LOW= 0		;
reg 			SCL_r  = 1'b1	;

//assign			O_SCL_POS = SCL_POS;
assign			O_SCL_HIG = SCL_HIG;
assign			O_SCL_NEG = SCL_NEG;
assign			O_SCL_LOW = SCL_LOW;
assign			O_SCL	  = SCL_r  ;

parameter       C_1Mhz			= 9'd50		,
				C_500Khz		= 9'd100	,
				C_400Khz		= 9'd125	,
				C_250Khz		= 9'd200	,
				C_200Khz		= 9'd250	,
				C_100khz		= 9'd500	;
				
parameter       C_CLK_SELECT	= C_400Khz	;

parameter		C_DIV_SELECT0   = (C_CLK_SELECT >> 2)  -  1, //HIG中間 		
				C_DIV_SELECT1	= (C_CLK_SELECT >> 1)  -  1, //下緣			
				C_DIV_SELECT2	= (C_DIV_SELECT0 + C_DIV_SELECT1) + 1;// LOG中間

always@(posedge I_clk or negedge I_rst_n)  
begin  
	if(!I_rst_n)
		SCL_cnt	<= 0;
	else if(I_SCL_en == 1'b1)	//en pin high action
		begin
			if(SCL_cnt == C_CLK_SELECT) //計算到counter次數清0
				SCL_cnt <= 0;
			else
				SCL_cnt	<= SCL_cnt + 1'b1;
		end
	else
		SCL_cnt	<= 0;
end

always@(SCL_cnt)  
begin  
	case(SCL_cnt)   //
		9'd000:				SCL_POS <= 1'b1;
		C_DIV_SELECT0:		SCL_HIG <= 1'b1;
		C_DIV_SELECT1:		SCL_NEG <= 1'b1;
		C_DIV_SELECT2:		SCL_LOW <= 1'b1;
		default: begin
					SCL_POS <=0;
					SCL_HIG <=0;
					SCL_NEG <=0;
					SCL_LOW <=0;
				 end
	endcase 
end

always@(posedge I_clk or negedge I_rst_n)
begin
	if(!I_rst_n)
		SCL_r <= 1'b1;
	else if(SCL_POS)
		SCL_r <= 1'b1;
	else if(SCL_NEG)
		SCL_r <= 1'b0;
	else
		SCL_r <= SCL_r;
end



endmodule 