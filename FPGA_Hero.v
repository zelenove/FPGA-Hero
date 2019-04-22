
module FPGA_Hero(
	input [3:0] KEY,
	input [9:0] SW,
	input CLOCK_50,
	
	output			VGA_CLK,   				//	VGA Clock
	output			VGA_HS,					//	VGA H_SYNC
	output			VGA_VS,					//	VGA V_SYNC
	output			VGA_BLANK_N,				//	VGA BLANK
	output			VGA_SYNC_N,				//	VGA SYNC
	output	[9:0]	VGA_R,   				//	VGA Red[9:0]
	output	[9:0]	VGA_G,	 				//	VGA Green[9:0]
	output	[9:0]	VGA_B   				//	VGA Blue[9:0]
	);
	
	wire resetn = SW[9];
	wire [7:0] VGA_X, VGA_Y;
	wire [2:0] VGA_COLOR;
	wire VGA_PLOT;
	
	// Create an Instance of a VGA controller - there can be only one!
	// Define the number of colours as well as the initial background
	// image file (.MIF) for the controller.
	vga_adapter VGA(
			.resetn(resetn),
			.clock(CLOCK_50),
			.colour(draw_color),
			.x(VGA_X),
			.y(VGA_Y),
			.plot(VGA_PLOT),
			/* Signals for the DAC to drive the monitor. */
			.VGA_R(VGA_R),
			.VGA_G(VGA_G),
			.VGA_B(VGA_B),
			.VGA_HS(VGA_HS),
			.VGA_VS(VGA_VS),
			.VGA_BLANK(VGA_BLANK_N),
			.VGA_SYNC(VGA_SYNC_N),
			.VGA_CLK(VGA_CLK));
		defparam VGA.RESOLUTION = "160x120";
		defparam VGA.MONOCHROME = "FALSE";
		defparam VGA.BITS_PER_COLOUR_CHANNEL = 1;
		defparam VGA.BACKGROUND_IMAGE = "black.mif";
	
	wire [7:0] draw_x, draw_y;
	wire [2:0] draw_color;
	wire draw, done;
		
	control c(
		.KEY(KEY),
		.done(done),
		.clock(CLOCK_50),
		.resetn(resetn),
		.draw_x(draw_x),
		.draw_y(draw_y),
		.draw_color(draw_color),
		.draw(draw)
	);
		
	draw_block db(
      .start_x(draw_x),
		.start_y(draw_y),
		.color(draw_color),
		.go(draw),
		.clock(CLOCK_50),
		.resetn(resetn),
		.x_out(VGA_X),
		.y_out(VGA_Y),
		.plot(VGA_PLOT),
		.done(done)
	);
	
endmodule
	
module control(
	input [3:0] KEY,
	input done, clock, resetn,

	output reg [7:0] draw_x, draw_y,
	output reg [2:0] draw_color,
	output reg draw
	);
	
	// Clock counter for how often to move the blocks
	reg [25:0] move_counter = 26'd0;
	
	// same Y coordinate for all blocks
	reg [9:0] b_y = 10'd110;
	
	// Block 1
	reg [7:0] b1_x = 8'd60;
	reg [2:0] b1_color = 3'b100;
	reg [2:0] b1_p_color = 3'b111;
	
	// Block 2
	reg [7:0] b2_x = 8'd70;
	reg [2:0] b2_color = 3'b010;
	reg [2:0] b2_p_color = 3'b110;
	
	// Block 3
	reg [7:0] b3_x = 8'd80;
	reg [2:0] b3_color = 3'b001;
	reg [2:0] b3_p_color = 3'b101;
	
	// Block 4
	reg [7:0] b4_x = 8'd90;
	reg [2:0] b4_color = 3'b101;
	reg [2:0] b4_p_color = 3'b011;
	
	// Falling blocks
	reg [2:0] f_color = 3'b010;
	reg [7:0] f1_x = 8'd60;
	reg [9:0] f1_y = -10'd10;
	
	   reg [3:0] current_state, next_state; 
       
		localparam DRAW_BLOCK1 = 4'd0,
                 DRAW_BLOCK2 = 4'd1,
                 DRAW_BLOCK3 = 4'd2,
					  DRAW_BLOCK4 = 4'd3,
					  DRAW_FALLING1 = 4'd4;
    
    // state table
	always@(*)
	begin: state_table 
		case (current_state)
			DRAW_BLOCK1: next_state = done ? DRAW_BLOCK2 : DRAW_BLOCK1;
			DRAW_BLOCK2: next_state = done ? DRAW_BLOCK3 : DRAW_BLOCK2;
			DRAW_BLOCK3: next_state = done ? DRAW_BLOCK4 : DRAW_BLOCK3;
			DRAW_BLOCK4: next_state = done ? DRAW_FALLING1 : DRAW_BLOCK4;
			DRAW_FALLING1: next_state = done ? DRAW_BLOCK1 : DRAW_FALLING1;
			default: next_state = DRAW_BLOCK1;
		endcase
	end
   
	// Output logic aka all of our datapath control signals
	always @(*)
	begin: enable_signals
		draw_x = 8'b0;
		draw_y = 10'b0;
		draw_color = 3'b0;
		draw = 0;
		
		case (current_state)
			DRAW_BLOCK1: begin
				draw_x = b1_x;
				draw_y = b_y;
				draw_color = ~KEY[3] ? b1_p_color : b1_color;
				draw = 1;
			end
			DRAW_BLOCK2: begin
				draw_x = b2_x;
				draw_y = b_y;
				draw_color = ~KEY[2] ? b1_p_color : b1_color;
				draw = 1;
			end
			DRAW_BLOCK3: begin
				draw_x = b3_x;
				draw_y = b_y;
				draw_color = ~KEY[1] ? b1_p_color : b1_color;
				draw = 1;
			end
			DRAW_BLOCK4: begin
				draw_x = b4_x;
				draw_y = b_y;
				draw_color = ~KEY[0] ? b1_p_color : b1_color;
				draw = 1;
			end
			DRAW_FALLING1: begin
				draw_x = f1_x;
				draw_y = f1_y;
				draw_color = f_color;
				draw = 1;
			end
		endcase
	end
	 
	always@(posedge clock) begin
		if (!resetn)
			move_counter <= 0;
		else if (move_counter >= 26'd15000000) begin
			move_counter <= 0;
			f1_y <= f1_y + 1;
			end
		else
			move_counter <= move_counter + 1;
	end
   
    // current_state registers
	always@(posedge clock) begin: state_transition
		if(!resetn)
			current_state <= DRAW_BLOCK1;
		else
			current_state <= next_state;
	end
endmodule
	