//////////////////////////////////////////////////////
//		Testbench para maquina expendedora
//////////////////////////////////////////////////////

module tb_vending_machine;

	// Parámetros de reloj
	localparam integer CLK_FREQ_HZ  = 50_000_000;	// 50 MHz
	localparam integer CLK_PERIOD_NS= 1_000_000_000 / CLK_FREQ_HZ; // 20 ns
	localparam integer CLK_HALF_NS  = CLK_PERIOD_NS/2;

	// Puertos hacia el TOP
	
	reg clk;
	reg rst;
	reg [3:0] btn;	// activos en 0: [3]=start, [0]=coin, [1]=buy, [2]=cancel
	reg [1:0] sw;	// selector de producto
	reg collected;	// confirmacion de recogida

	wire	[6:0]	hex_credit;		// 7-seg (crédito)
	wire	[6:0]	hex_change;		// 7-seg (cambio)
	wire	[7:0]	led;			// [7]=motor, [6]=eco collected, [5:4]=estado, [3:0]=eco botones

	// Selector de escenario 
	// 0=EXACTO, 1=EXTRA, 2=INSUFICIENTE, 3=CANCELACIÓN
	localparam integer CASE_SEL = 0;


// DUT

top_vending_machine dut (
	.clk		(clk),
	.rst		(rst),
	.btn		(btn),
	.sw			(sw),
	.collected	(collected),
	.hex_credit	(hex_credit),
	.hex_change	(hex_change),
	.led		(led)
);


	// Reloj 50 MHz
	initial clk = 1'b0;
	always #(CLK_HALF_NS) clk = ~clk;

// Tasks de estímulo
// idx: 0=coin, 1=buy, 2=cancel, 3=start
task press_btn;
	input integer idx;
	input integer cycles_low;
	begin
		btn[idx] = 1'b0;	// activo en 0
		repeat (cycles_low) @(posedge clk);
		btn[idx] = 1'b1;
		@(posedge clk);
	end
endtask

// Pulso de collected para confirma recogida
task pulse_collected;
	input integer cycles_high;
	begin
		collected = 1'b1;
		repeat (cycles_high) @(posedge clk);
		collected = 1'b0;
		@(posedge clk);
	end
endtask

	// indice de botones
	localparam integer B_COIN   = 0;
	localparam integer B_BUY    = 1;
	localparam integer B_CANCEL = 2;
	localparam integer B_START  = 3;

// Decoder de 7 seg a decimal (para lectura en consla)
function [3:0] seg_to_bcd;
	input [6:0] seg;
	begin
		case (seg)
			7'b1000000: seg_to_bcd = 4'd0; // 0
			7'b1111001: seg_to_bcd = 4'd1; // 1
			7'b0100100: seg_to_bcd = 4'd2; // 2
			7'b0110000: seg_to_bcd = 4'd3; // 3
			7'b0011001: seg_to_bcd = 4'd4; // 4
			7'b0010010: seg_to_bcd = 4'd5; // 5
			7'b0000010: seg_to_bcd = 4'd6; // 6
			7'b1111000: seg_to_bcd = 4'd7; // 7
			7'b0000000: seg_to_bcd = 4'd8; // 8
			7'b0010000: seg_to_bcd = 4'd9; // 9
			default:    seg_to_bcd = 4'd15; // inválido
		endcase
	end
endfunction


// Monitor en consola
integer cdec, chdec;
initial begin
	$display("t\tst\tmotor\tcol\tcredit\tchange\tsw");
	forever begin
		@(posedge clk);
		cdec  = seg_to_bcd(hex_credit);
		chdec = seg_to_bcd(hex_change);
		if (cdec  == 15) cdec  = -1;
		if (chdec == 15) chdec = -1;
		$display("[%0t]\t%0d\t%0d\t%0b\t%0d\t%0d\t%b",
			$time,
			led[5:4],	// st-estado
			led[7],		// motor-motor
			led[6],		// col-collect
			cdec,		// credit-credit
			chdec,		// change-change
			sw			// sw-selector de producto
		);
	end
end

// Casos simulados 

initial begin
	// Reset
	rst = 1'b1;
	btn = 4'b1111;		
	sw  = 2'b00;
	collected = 1'b0;
	repeat (5) @(posedge clk);
	rst = 1'b0;
	@(posedge clk);

	case (CASE_SEL)
		// Escenario "0" Crédito exacto para el producto
		0: begin : SCENARIO_EXACTO
			sw = 2'b10;								// precio = 2
			press_btn(B_START, 2);				// IDLE -> COINS
			repeat (2) press_btn(B_COIN, 2);	// credito = 2
			press_btn(B_BUY,   2);				// compra , cambio = 0
			wait (led[7] == 1'b1);				// espera al encedido de motor
			wait (led[7] == 1'b0);				// espedra al apagado del motor
			pulse_collected(2);					// confirmacion de recogida
			repeat (20) @(posedge clk);
		end

		// Escenario "1" Crédito mayor al precio del prodcuto
		1: begin : SCENARIO_EXTRA
			sw = 2'b00;								// precio = 4
			press_btn(B_START, 2);				// IDLE -> COINS
			repeat (6) press_btn(B_COIN, 2);	// crédito = 6
			press_btn(B_BUY,   2);				// compra (cambio=2)
			wait (led[7] == 1'b1);				// espera al encedido del motor
			wait (led[7] == 1'b0);				// espera al 
			pulse_collected(2);					// confirmacion de recogida

			repeat (20) @(posedge clk);
		end

		// Escenario "2" Crédito insuficiente 
		2: begin : SCENARIO_INSUF
			sw = 2'b01;								// precio = 9
			press_btn(B_START, 2);				// IDLE -> COINS
			repeat (4) press_btn(B_COIN, 2);	// crédito = 4
			press_btn(B_BUY,   2);				// preciona comprar
			repeat (100) @(posedge clk);
		end

		// Escenario "3" Cancelacion de compra
		3: begin : SCENARIO_CANCEL
			sw = 2'b11;								// precio = 7 (irrelevante para cancelar)
			press_btn(B_START, 2);				// IDLE -> COINS
			repeat (5) press_btn(B_COIN, 2);	// crédito = 5
			press_btn(B_CANCEL, 2);				// change=5, credit=0, vuelve a idle
			repeat (5) @(posedge clk);		
			press_btn(B_START, 2);				// nueva compra, limpia el cambio
			repeat (20) @(posedge clk);
		end

		default: begin
			$display("** CASE_SEL inválido: %0d (usa 0, 1, 2 o 3) **", CASE_SEL);
			repeat (50) @(posedge clk);
		end
	endcase

	$display("Fin de la simulación.");
	$stop;
end

endmodule

