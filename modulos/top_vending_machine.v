
//////////////////////////////////////////////////////////
//				Modulo Principal de la maquina
//////////////////////////////////////////////////////////

module top_vending_machine (

	input clk, // señal reloj
	input rst, // reset
	input [3:0] btn, // botones de la maquina 
	input [1:0] sw, // selector de productos
	input collected,	// confirmacion de producto recogido
	output [6:0] hex_credit, // credito para el display
	output [6:0] hex_change, // cambio para el display
	output [7:0] led	// indicadores 
	
);

	// Protección contra pulsos al inicio
reg [3:0] btn_reg; 
always @(posedge clk or posedge rst) begin 
	if (rst) 
		btn_reg <= 4'b1111; 
	else 
		btn_reg <= btn; 
end 

	// Botones activos en bajo 
	wire btn_start	= ~btn_reg[3]; 
	wire btn_coin	= ~btn_reg[0]; 
	wire btn_buy	= ~btn_reg[1]; 
	wire btn_cancel	= ~btn_reg[2]; 
	wire [1:0] led_state; 

// Instancia de la maquina de estasdos 
fsm vm_inst ( 
	.clk (clk), 
	.rst(rst), 
	.btn_start (btn_start), 
	.btn_coin (btn_coin), 
	.btn_buy (btn_buy), 
	.btn_cancel (btn_cancel), 
	.sw_prod	(sw), 
	.collected (collected), 
	.seg_credit (hex_credit), 
	.seg_change (hex_change), 
	.led_motor (led[7]), 
	.led_state (led_state), 
	.led_start (led[0]), 
	.led_coin (led[1]), 
	.led_buy (led[2]), 
	.led_cancel (led[3]) 
); 

	// Indicadores
	assign led[5:4] = led_state; 
	assign led[6] = collected;	

endmodule

