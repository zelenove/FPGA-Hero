
module draw_block
	(
		// Your inputs and outputs here
      start_x,
		start_y,
		color,
		go,
		clock,
		resetn,
		x_out,
		y_out,
		plot,
		done
	);

	input	clock, go, resetn;		
	input [7:0] start_x, start_y;
	input [2:0] color;
	
	output [7:0] x_out, y_out;
	output plot, done;
		
	// control wires
	wire [3:0] count;
	wire increment;
	
	draw_control c0(
		.count(count),
		.go(go),
		.resetn(resetn),
		.clock(clock),
		.increment(increment),
		.plot(plot),
		.done(done)
	);
	
	datapath d0(
		.x_in(start_x),
		.y_in(start_y),
		.increment(increment),
		.clock(clock),
		.resetn(resetn),
		.x_out(x_out),
		.y_out(y_out),
		.count(count)
	);
endmodule


module datapath(
	input [7:0] x_in, y_in,
	input increment, clock, resetn,
	
	output [7:0] x_out,
	output [7:0] y_out,
	output reg [3:0] count
	);
	
	wire [1:0] x_offset = count[1:0];
	wire [1:0] y_offset = count[3:2];
	
	// counter
	always @(posedge clock) begin
		if (increment)
			count <= count + 1;
		else
			count <= 4'b0;
	end
	
	// ALU
	assign x_out = x_in + x_offset;
	assign y_out = y_in + y_offset;
endmodule


module draw_control(
    input [3:0] count,
	 input go, resetn, clock,

    output reg increment,
	 output reg plot,
	 output reg done
    );

    reg [1:0] current_state, next_state; 
    
    localparam S_WAIT     = 2'd0,
               S_CYCLE_1  = 2'd1,
               S_CYCLE_N  = 2'd2;
    
    // state table
    always@(*)
    begin: state_table 
        case (current_state)
            S_WAIT: next_state = go ? S_CYCLE_1 : S_WAIT;
            S_CYCLE_1: next_state = S_CYCLE_N;
				S_CYCLE_N: next_state = count == 15 ? S_WAIT : S_CYCLE_N;
            default: next_state = S_WAIT;
        endcase
    end
   

    // Output logic aka all of our datapath control signals
    always @(*)
    begin: enable_signals
        // By default make all our signals 0
		  increment = 0;
		  plot = 0;
		  done = 0;

        case (current_state)
            S_WAIT: done = 1;
            S_CYCLE_1: plot = 1;
				S_CYCLE_N: begin
					increment = 1;
					plot = 1;
				end
        endcase
    end
   
    // current_state registers
    always@(posedge clock)
    begin: state_transition
        if(!resetn)
            current_state <= S_WAIT;
        else
            current_state <= next_state;
    end
endmodule