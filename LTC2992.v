//use notepad++ open!!!!!!!!!!!
module LTC2992
(
	input			I_clk			,
	input			I_rst_n			,
	inout			IO_SDA			,
	output			O_SCL			,
	output	[3:0]	O_led_out 
);

wire			W_SCL_HIG					;
wire			W_SCL_NEG					;
wire			W_SCL_LOW					;
wire			W_SCL_en					;
wire			W_SCL_recv_en				;
wire			W_SCL_send_en				;
wire			W_done_flag					;
wire			W_done_recv					;
wire			W_done_send					;
wire			W_recv_en					;
wire			W_send_en					;
wire [1:0]		W_BYTE						;
wire [7:0]		W_dev_addr					;
wire [7:0]		W_word_addr					;
wire [7:0]		W_write_date				;
wire [15:0]		W_read_date					;
wire [15:0]		W_Vout_date					;

assign			W_done_flag	 = W_done_recv | W_done_send;
assign			W_SCL_en	 = W_SCL_recv_en | W_SCL_send_en;
assign			O_led_out	 = (W_read_date == 16'h0840) ? 4'b0101 : 4'b1111 ;
//assign			O_led_out	 = W_read_date[15:12] ;
//assign			O_led_out	 = W_read_date[11:8] ;
SCL_clock U1
(
	.I_clk			(I_clk				),
	.I_rst_n		(I_rst_n			),
	.I_SCL_en		(W_SCL_en			),
	.O_SCL_HIG		(W_SCL_HIG			),
	.O_SCL_NEG		(W_SCL_NEG			),
	.O_SCL_LOW		(W_SCL_LOW			),
	.O_SCL          (O_SCL    			)
);

IIC_recv U2
(
	.I_clk			(I_clk				),
	.I_rst_n		(I_rst_n			),
	.I_recv_en		(W_recv_en			),
	.I_SCL_HIG		(W_SCL_HIG			),
	.I_SCL_NEG		(W_SCL_NEG			),
	.I_SCL_LOW		(W_SCL_LOW			),	
	.I_dev_addr		(W_dev_addr			),
	.I_word_addr	(W_word_addr		),
	.I_BYTE			(W_BYTE				),		
	.O_SCL_en		(W_SCL_recv_en		),
	.O_read_date	(W_read_date		),
	.O_done_flag	(W_done_recv		),
	.IO_SDA         (IO_SDA    			)
);

IIC_send U3
(
	.I_clk			(I_clk				),
	.I_rst_n		(I_rst_n			),
	.I_send_en		(W_send_en			),
	.I_SCL_HIG		(W_SCL_HIG			),
	.I_SCL_NEG		(W_SCL_NEG			),
	.I_SCL_LOW		(W_SCL_LOW			),
	.I_dev_addr		(W_dev_addr			),
	.I_word_addr	(W_word_addr		),
	.I_BYTE			(W_BYTE				),
	.I_write_date	(W_write_date		),	
	.O_SCL_en		(W_SCL_send_en		),
	.O_done_flag	(W_done_send		),
	.IO_SDA         (IO_SDA				)
);

LTC2992_command U4
(
	.I_clk			(I_clk				),
	.I_rst_n		(I_rst_n			),
	.I_done_flag	(W_done_flag		),
	.I_read_date	(W_read_date		),
	.O_Vout_date	(W_Vout_date		),
	.O_recv_en		(W_recv_en			),
	.O_send_en		(W_send_en			),
	.O_dev_addr		(W_dev_addr			),
	.O_word_addr	(W_word_addr		),
	.O_write_date	(W_write_date		),
	.O_BYTE			(W_BYTE				)
);

endmodule
