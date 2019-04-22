module LFSR (
    input clock,
    input reset,
    output [6:0] rnd
    );

wire feedback = random[6] ^ random[5];

reg [6:0] random, random_next, random_done;
reg [3:0] count, count_next; //to keep track of the shifts

always @ (posedge clock or posedge reset)
begin
 if (reset)
 begin
  random <= 7'hF; //An LFSR cannot have an all 0 state, thus reset to FF
  count <= 0;
 end

 else
 begin
  random <= random_next;
  count <= count_next;
 end
end

always @ (*)
begin
 random_next = random; //default state stays the same
 count_next = count;

  random_next = {random[6:0], feedback}; //shift left the xor'd every posedge clock
  count_next = count + 1;

 if (count == 7)
 begin
  count = 0;
  random_done = random; //assign the random number to output after 7 shifts
 end

end


assign rnd = random_done;

endmodule
