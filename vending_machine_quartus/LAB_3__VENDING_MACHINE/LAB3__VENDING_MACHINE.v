
//////////////////////////////////////////////////////////
//				Modulo Principal de la maquina
//////////////////////////////////////////////////////////

module LAB3__VENDING_MACHINE (

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
vending_machine vm_inst ( 
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



//////////////////////////////////////////////////////////
//				Modulo de la maquina de estados
//////////////////////////////////////////////////////////

module vending_machine (

	input clk, 
	input rst, 
	input btn_start, 
	input btn_coin, 
	input btn_buy, 
	input btn_cancel, 
	input [1:0] sw_prod, 
	input collected,		
	output [6:0] seg_credit, // salida para el diaply 
	output [6:0] seg_change, // salida para el display
	output reg led_motor,	// motor simulado 
	output [1:0] led_state, // estado del sistema
	output led_start, 
	output led_coin, 
	output led_buy, 
	output led_cancel
	
); 

	// Estados
	localparam IDLE = 2'b00; 
	localparam COINS = 2'b01; 
	localparam DISP  = 2'b10; 
	localparam PICK  = 2'b11; 

	reg [1:0] state, next_state; 
	reg [3:0] price; 
	reg [3:0] credit; 
	reg [3:0] change; 

	
	reg  prev_coin; 
	wire coin_pulse = btn_coin && ~prev_coin; 

	// LEDs
	assign led_start  = btn_start; 
	assign led_coin   = btn_coin; 
	assign led_buy    = btn_buy; 
	assign led_cancel = btn_cancel; 
	assign led_state  = state; 

	// Motor / temporizador
	reg [25:0] m_count; 
	reg m_active; 

	// Flag: confirmacion tras la compra
	reg        await_collect;

// Precio de los productos
always @(*) begin 
	case (sw_prod) 
		2'b00: price = 4; 
		2'b01: price = 9; 
		2'b10: price = 2; 
		2'b11: price = 7; 
		default: price = 0; 
	endcase 
end 


always @(posedge clk or posedge rst) begin 
	if (rst) begin 
		state         <= IDLE; 
		credit        <= 4'd0; 
		change        <= 4'd0; 
		led_motor     <= 1'b0; 
		prev_coin     <= 1'b0; 
		m_count       <= 4'd0; 
		m_active      <= 1'b0; 
		await_collect <= 1'b0;
	end else begin 
		state     <= next_state; 
		prev_coin <= btn_coin; 

		case (state) 
			IDLE: begin 
				credit     <= 4'd0; 
				led_motor  <= 1'b0; 
				m_active   <= 1'b0; 
				m_count    <= 4'd0; 
				// Limpiar 'change' según origen del monto
				if (!await_collect && btn_start)
					change <= 4'd0;                // limpiar al iniciar nueva compra
				else if (await_collect && collected) begin
					change        <= 4'd0;        // limpiar al recoger
					await_collect <= 1'b0;			// limpio la confirmacion del cambio 
				end
			end 

			COINS: begin 
				led_motor <= 1'b0; 
				if (coin_pulse && credit < 4'd9) 
					credit <= credit + 4'd1; 
				if (btn_cancel) begin 
					change        <= credit;      // devolver cambio completo
					credit        <= 4'd0; 			// vacia el credito
					await_collect <= 1'b0;        // bypass a la confirmacion de collect
				end 
			end 

			DISP: begin 
				if (credit >= price) begin 
					m_active      <= 1'b1; 
					m_count       <= 4'd10; 
					change        <= credit - price; 
					credit        <= 4'd0; 
					await_collect <= 1'b1;          // requerir 'collected' tras compra
				end 
			end 

			PICK: begin 
				// Si hay motor activo, correr hasta que termine elcontador
				if (m_active) begin 
					if (m_count > 0) begin 
						m_count   <= m_count - 4'd1; 
						led_motor <= 1'b1; 
					end else begin 
						led_motor <= 1'b0; 
						m_active  <= 1'b0; 
					end 
				end else begin 
					led_motor <= 1'b0; 
				end
			end 
		endcase 
	end 
end 

// Cambios de estado
always @(*) begin 
	case (state) 
		IDLE: begin
			if (await_collect && !collected)
				next_state = IDLE;
			else
				next_state = btn_start ? COINS : IDLE;
		end

		COINS: begin
			if (btn_cancel)
				next_state = IDLE;      // si cancelo de regreso a idle
			else if (btn_buy && credit >= price)
				next_state = DISP; 
			else
				next_state = COINS;
		end

		DISP:  next_state = PICK; 

		PICK: begin
			if (m_active)
				next_state = PICK; 
			else
				next_state = IDLE;  // regresar al idle despues de recoger el producto 
		end
		default: next_state = IDLE; 
	endcase 
end 

// Displays 
bcd_to_7seg u_credit ( .bcd(credit), .seg(seg_credit) ); 
bcd_to_7seg u_change ( .bcd(change), .seg(seg_change) ); 

endmodule



///////////////////////////////////////////////////////////////////
//    Modulo decorder (logica invertida para display anodo comun)
///////////////////////////////////////////////////////////////////

module bcd_to_7seg ( 
	input [3:0] bcd, 
	output reg [6:0] seg 
); 
	always @(*) begin 
		case (bcd) 
			4'd0: seg = 7'b1000000; 
			4'd1: seg = 7'b1111001; 
			4'd2: seg = 7'b0100100; 
			4'd3: seg = 7'b0110000; 
			4'd4: seg = 7'b0011001; 
			4'd5: seg = 7'b0010010; 
			4'd6: seg = 7'b0000010; 
			4'd7: seg = 7'b1111000; 
			4'd8: seg = 7'b0000000; 
			4'd9: seg = 7'b0010000; 
			default: seg = 7'b1111111; 
		endcase 
	end 
endmodule

