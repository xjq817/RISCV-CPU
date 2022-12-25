`include "define.v"

module IF (
	input  wire				clk,
	input  wire 			rst,
	input  wire 			rdy,
//ICache
	input  wire 			IC_commit,
	input  wire	[31:0]		IC_val,
	output reg	 			IC_flag,
	output reg	[31:0]		IC_PC,
//IQ
	input  wire				IQ_full,
	output reg				IQ_flag,
	output reg	[31:0]		IQ_inst,
	output reg	[31:0]		IQ_PC,
//ROB
	input  wire				ROB_jump_flag,
	input  wire	[31:0]		ROB_jump_PC
);

	reg			stall;
	reg	[31:0]	PC;

	always @(posedge clk) begin
		if (rst) begin
			stall   <= 0;
			PC      <= 0;
			IC_flag <= `FALSE;
			IQ_flag <= `FALSE;
		end else if (ROB_jump_flag) begin
			stall   <= 0;
			PC      <= ROB_jump_PC;
			IC_flag <= `FALSE;
			IQ_flag <= `FALSE;
		end else if (IQ_full || !rdy) begin
			IC_flag <= `FALSE;
			IQ_flag <= `FALSE;
		end else begin
			if (stall == 0) begin
				if (IC_commit) begin
					IC_flag <= `FALSE;
					IQ_flag <= `TRUE;
					IQ_inst <= IC_val;
					IQ_PC   <= PC;
					PC      <= PC + 4;
					stall   <= 1;
				end else begin
					IC_flag <= `TRUE;
					IC_PC   <= PC;
					IQ_flag <= `FALSE;
				end
			end else begin
				stall   <= 0;
				IC_flag <= `FALSE;
				IQ_flag <= `FALSE;
			end
		end
	end

endmodule