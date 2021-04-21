// 10 bit LFSR
module gen_lfsr #(
  parameter WIDTH = 10 )
 (input clk, input rst,
  input load, input en,
  input [WIDTH-1:0] i_pnseq_poly, input [WIDTH-1:0] i_pnseq_seed, input [3:0] i_pnseq_order, // max order of 15
  output pnseq
);

// For a 63 length (maximal) length sequence, the generator poly is x^6 + x^5 + 1. Let's say the seed is 000001
// Input poly : 0000110000    Input Seed : 0000010000 when WIDTH = 10
// Input poly : 000011000     Input Seed : 000001000  When WIDTH = 9
reg [9:0] shift_reg, poly_reg;
reg [3:0] order_reg;

wire next_bit;

always @(posedge clk)
  if(rst) begin
    shift_reg <= 0;
    poly_reg <= 0;
    order_reg <= 0;
  end else begin
    if(load) begin
      shift_reg <= i_pnseq_seed;
      poly_reg <= i_pnseq_poly;
      order_reg <= i_pnseq_order;
    end else if(en) begin
      shift_reg <= {next_bit, shift_reg[WIDTH-1:1]};
    end
  end

assign pnseq = shift_reg[WIDTH - order_reg];
assign next_bit = ^(shift_reg & poly_reg);

endmodule




  
