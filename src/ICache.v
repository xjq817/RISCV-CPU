`include "define.v"

module ICache (
	input  wire					clk,
	input  wire					rst,
	input  wire					rdy,
	input  wire					roll,
//IF
	input  wire					IF_flag,
	input  wire	[31:0]			IF_PC,
	output reg 					IF_commit,
	output reg	[31:0]			IF_inst,
//MemoryController
	input  wire					MC_flag,
	input  wire [31:0]			MC_inst,
	output reg					MC_commit,
	output reg	[31:0]			MC_PC
);

	reg						stall;
	reg						valid[`IC_INDEX];
	reg	[`IC_TAG_INDEX]		tag[`IC_INDEX];
	reg	[31:0]				data[`IC_INDEX];

	integer i;
	always @(posedge clk) begin
		if (rst) begin
			for (i = 0; i < `IC_SIZE; i = i + 1) begin
				valid[i] <= `FALSE;
			end
			stall <= 0;
		end else if (roll || !rdy) begin
			MC_commit <= `FALSE;
			IF_commit <= `FALSE;
		end else begin
			if (IF_flag) begin
				if (stall) begin
					MC_commit <= `FALSE;
					IF_commit <= `FALSE;
					stall     <= 0;
				end else begin
					if (valid[IF_PC[`IC_INDEX_RANGE]] && tag[IF_PC[`IC_INDEX_RANGE]] == IF_PC[`IC_TAG]) begin
						MC_commit <= `FALSE;
						IF_commit <= `TRUE;
						IF_inst   <= data[IF_PC[`IC_INDEX_RANGE]];
						stall     <= 1;
					end else begin
						if (MC_flag) begin
							MC_commit <= `FALSE;
							IF_commit <= `TRUE;
							IF_inst   <= MC_inst;
							stall     <= 1;

							valid[IF_PC[`IC_INDEX_RANGE]] <= `TRUE;
							tag[IF_PC[`IC_INDEX_RANGE]]   <= IF_PC[`IC_TAG];
							data[IF_PC[`IC_INDEX_RANGE]]  <= MC_inst;
						end else begin
							MC_commit <= `TRUE;
							MC_PC     <= IF_PC;
						end
					end
				end
			end else begin
				MC_commit <= `FALSE;
				IF_commit <= `FALSE;
			end
		end
	end

endmodule