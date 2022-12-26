`include "define.v"

module RF (
	input  wire							clk,
	input  wire 						rst,
	input  wire 						rdy,
	input  wire 						roll,
//decoder
	input  wire 						Dec_R1,
	input  wire	[`REG_INDEX_RANGE] 		Dec_rs1,
	input  wire 						Dec_R2,
	input  wire	[`REG_INDEX_RANGE] 		Dec_rs2,
//dispatch
	input  wire							Dis_flag,
	input  wire	[`REG_INDEX_RANGE]		Dis_rd,
	input  wire	[`ROB_INDEX_RANGE]		Dis_ROB_idx,
	output reg							Dis_flag1,
	output reg							Dis_R1,
	output reg	[31:0] 					Dis_V1,
	output reg							Dis_flag2,
	output reg							Dis_R2,
	output reg	[31:0]					Dis_V2,
//ROB
	input  wire							ROB_flag,
	input  wire	[`ROB_INDEX_RANGE]		ROB_new_idx,
	input  wire	[`REG_INDEX_RANGE] 		ROB_rd,
	input  wire	[31:0]					ROB_val
);

	reg	[31:0]					val[`REG_INDEX];
	reg	[`ROB_INDEX_RANGE]		ROB_idx[`REG_INDEX];
	reg 						ready[`REG_INDEX];

	always @(*) begin
		if (Dec_R1 == `FALSE) begin
			Dis_flag1 = `FALSE;
		end else begin
			Dis_flag1 = `TRUE;
			if (ready[Dec_rs1] == `TRUE) begin
				Dis_R1 = `TRUE;
				Dis_V1 = val[Dec_rs1];
			end else if (ROB_flag == `TRUE && ROB_new_idx ==ROB_idx[Dec_rs1]) begin
				Dis_R1 = `TRUE;
				Dis_V1 = ROB_val;
			end else begin
				Dis_R1 = `FALSE;
				Dis_V1 = {27'b0, ROB_idx[Dec_rs1]};
			end
		end
	end

	always @(*) begin
		if (Dec_R2 == `FALSE) begin
			Dis_flag2 = `FALSE;
		end else begin
			Dis_flag2 = `TRUE;
			if (ready[Dec_rs2] == `TRUE) begin
				Dis_R2 = `TRUE;
				Dis_V2 = val[Dec_rs2];
			end else if (ROB_flag == `TRUE && ROB_new_idx ==ROB_idx[Dec_rs2]) begin
				Dis_R2 = `TRUE;
				Dis_V2 = ROB_val;
			end else begin
				Dis_R2 = `FALSE;
				Dis_V2 = {27'b0, ROB_idx[Dec_rs2]};
			end
		end
	end

	integer i;
	always @(posedge clk) begin
		if (rst) begin
			for (i = 0; i < `REG_SIZE; i = i + 1) begin
				val[i] <= 0;
				ready[i] <= `TRUE;
			end
		end else if (roll) begin
			for (i = 0; i < `REG_SIZE; i = i + 1) begin
				ready[i] <= `TRUE;
			end
			if (ROB_flag == `TRUE && ROB_rd != 0) begin
				val[ROB_rd] <= ROB_val;
			end
		end else if (!rdy) begin
		end else begin
			if (ROB_flag == `TRUE && ROB_rd != 0 && Dis_flag == `TRUE && Dis_rd != 0) begin
				ROB_idx[Dis_rd] <= Dis_ROB_idx;
				ready[Dis_rd]   <= `FALSE;
				val[ROB_rd]     <= ROB_val;
				if (ROB_rd != Dis_rd && ROB_idx[ROB_rd] == ROB_new_idx) begin
					ready[ROB_rd] <= `TRUE;
				end
			end else begin
				if (ROB_flag == `TRUE && ROB_rd != 0) begin
					val[ROB_rd] <= ROB_val;
					if (ROB_idx[ROB_rd] == ROB_new_idx) begin
						ready[ROB_rd] <= `TRUE;
					end
				end
				if (Dis_flag == `TRUE && Dis_rd != 0) begin
					ROB_idx[Dis_rd] <= Dis_ROB_idx;
					ready[Dis_rd]   <= `FALSE;
				end
			end
		end
	end

endmodule