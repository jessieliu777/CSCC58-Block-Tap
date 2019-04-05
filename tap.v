module tap(
	CLOCK_50,
	KEY,
	VGA_CLK,   						//	VGA Clock
	VGA_HS,							//	VGA H_SYNC
	VGA_VS,							//	VGA V_SYNC
	VGA_BLANK_N,						//	VGA BLANK
	VGA_SYNC_N,						//	VGA SYNC
	VGA_R,   				 		//	VGA Red[9:0]
	VGA_G,	 						//	VGA Green[9:0]
	VGA_B,
	SW, HEX0, HEX1, HEX2, HEX3
	);
	
	input	CLOCK_50;							//	clock used to draw each pixel
	input [3:0] KEY;							// TODO: temp key for reset
	input [3:0] SW;
	output [6:0] HEX0, HEX1, HEX2, HEX3;
	// VGA outputs
	output			VGA_CLK;   				//	VGA Clock
	output			VGA_HS;					//	VGA H_SYNC
	output			VGA_VS;					//	VGA V_SYNC
	output			VGA_BLANK_N;				//	VGA BLANK
	output			VGA_SYNC_N;				//	VGA SYNC
	output	[9:0]	VGA_R;   				//	VGA Red[9:0]
	output	[9:0]	VGA_G;	 				//	VGA Green[9:0]
	output	[9:0]	VGA_B;   				//	VGA Blue[9:0]
	
	wire finished;
	wire erase_block;
	reg in;

	reg [3:0] ones;
	reg [3:0] tens;
	reg [3:0] hundreds;
	reg [3:0] thousands;
	reg [2:0] colour;
	reg [2:0] DEFAULT_COLOUR = 3'b101;
	reg [3:0] BLOCK_SIZE = 4'd15;
	reg [3:0] DEFAULT_BLOCK = 4'd15;
	
	reg [7:0] startx;
	reg [6:0] starty;
	reg [7:0] count;
	// init state stuff
	reg [7:0] cur, nxt;
	parameter init1 = 0,draw = 114, stay = 1,
	stop = 99, update = 100, calculate = 101, init2 = 103, init3 = 104, predraw = 105, init4 = 106, init5 = 107, init6 = 108,
	init7 = 109, init8 = 110, init9 = 111, init10 = 112, init11 = 113;
	hex_display h0(ones, HEX0);
	hex_display h1(tens, HEX1);
	hex_display h2(hundreds, HEX2);
	hex_display h3(thousands, HEX3);
	
	rate_divider rate(2'b01, KEY[0], CLOCK_50, erase_block);
	block_drawer drawer(
		.clock(CLOCK_50),
		.resetn(KEY[0]),
		.start_x(startx),
		.start_y(starty),
		.colour(colour),
		.block_size(BLOCK_SIZE),
		.finished(finished),
		.VGA_CLK(VGA_CLK),
		.VGA_HS(VGA_HS),
		.VGA_VS(VGA_VS),
		.VGA_BLANK_N(VGA_BLANK_N),
		.VGA_SYNC_N(VGA_SYNC_N),
		.VGA_R(VGA_R),
		.VGA_G(VGA_G),
		.VGA_B(VGA_B)
	);
	
	// always for states
	always @(posedge erase_block)
	begin
		case(cur)
		init1: begin
		colour <= 3'b001;
		starty <= 7'b1101000;
		if (erase_block == 0)
					nxt <= init1;
				else
					nxt <= init2;
				end
		init2: begin
		startx <= 8'b00001111;
		if (erase_block == 0)
					nxt <= init2;
				else
					nxt <= init3;
				end
		init3: begin
		startx <= 8'b00011110;
		if (erase_block == 0)
					nxt <= init3;
				else
					nxt <= init4;
				end
		init4: begin
		startx <= 8'b00101101;
		if (erase_block == 0)
					nxt <= init4;
				else
					nxt <= init5;
				end
		init5: begin
		startx <= 8'b00111100;
		if (erase_block == 0)
					nxt <= init5;
				else
					nxt <= init6;
				end
		init6: begin
		startx <= 8'b01001011;
		if (erase_block == 0)
					nxt <= init6;
				else
					nxt <= init7;
				end
		init7: begin
		startx <= 8'b01011010;
		if (erase_block == 0)
					nxt <= init7;
				else
					nxt <= init8;
				end
		init8: begin
		startx <= 8'b01101001; 
		if (erase_block == 0)
					nxt <= init8;
				else
					nxt <= init9;
				end
		init9: begin
		startx <= 8'b01111000;
		if (erase_block == 0)
					nxt <= init9;
				else
					nxt <= init10;
				end
		init10: begin
		startx <= 8'b10000111;
		if (erase_block == 0)
					nxt <= init10;
				else
					nxt <= init11;
				end
		init11: begin
		startx <= 8'b10010110;
		if (erase_block == 0)
					nxt <= init11;
				else
					nxt <= predraw;
				end
		predraw:begin
		starty <= 0;
		colour <= 3'b111;
		startx <= {(startx[6]^startx[1]), startx[6:1]};
					if (erase_block == 0)
					nxt <= predraw;
				else
					nxt <= stay;
				end
			draw: begin// cycle has passed
			colour <= 3'b111;
				if (erase_block == 0)
					nxt <= draw;
				else
					nxt <= stay;
				end
			stay: begin
				// colour black
				if (erase_block == 0)
					nxt <= stay;
				else
					begin	
					if (count == 7'd80)
						begin
						count <= 0;
						nxt <= stop;
						end
					else
						begin
						nxt <= stay;
						count <= count + 1;
						end
					end
				end
			stop: begin
				// colour black
				
				if (erase_block == 0)	
					nxt <= stop;
				else
				begin
				if (starty < 7'b1101000)
				colour <= 3'b000;
				else
				colour <= 3'b001;
				nxt <= update;
					end
				end
			
			update: begin
				if (starty == 7'b1101000)
				
				begin
				nxt = predraw;
					if (SW[0] == ~in)
						begin
						if (ones + 1 < 4'b1010)
						ones <= ones + 1;
						else
							begin
							ones <= 0;
							if (tens + 1 < 10)
								tens <= tens + 1;
							else
								begin
								tens <= 0;
								if (hundreds + 1 < 10)
									hundreds <= hundreds + 1;
								else
									begin
										hundreds <= 0;
										thousands <= thousands + 1;
									end
								end
							end
						end				
				end
				else
				begin
				in <= SW[0];
				starty <= starty + 7'b0000001;
				nxt <= draw;
				end
			end
			endcase
	end
	
	// clocked always to move on to next state
	always@(posedge erase_block)
	begin
		cur <= nxt;
	end
endmodule
	
module hex_display(IN, OUT);
    input [3:0] IN;
	 output reg [7:0] OUT;
	 
	 always @(*)
	 begin
		case(IN[3:0])
			4'b0000: OUT = 7'b1000000;
			4'b0001: OUT = 7'b1111001;
			4'b0010: OUT = 7'b0100100;
			4'b0011: OUT = 7'b0110000;
			4'b0100: OUT = 7'b0011001;
			4'b0101: OUT = 7'b0010010;
			4'b0110: OUT = 7'b0000010;
			4'b0111: OUT = 7'b1111000;
			4'b1000: OUT = 7'b0000000;
			4'b1001: OUT = 7'b0011000;
			4'b1010: OUT = 7'b0001000;
			4'b1011: OUT = 7'b0000011;
			4'b1100: OUT = 7'b1000110;
			4'b1101: OUT = 7'b0100001;
			4'b1110: OUT = 7'b0000110;
			4'b1111: OUT = 7'b0001110;
			
			default: OUT = 7'b0111111;
		endcase

	end
endmodule