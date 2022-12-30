`include "define.v"

module dispatch (
//decoder
	input  wire							Dec_flag,
	input  wire	[31:0]					Dec_imm,
	input  wire [`REG_INDEX_RANGE]		Dec_rd,
	input  wire	[5:0] 					Dec_op,
	input  wire	[31:0]					Dec_PC,
	input  wire	[31:0]					Dec_BTB_PC,
	input  wire							Dec_BTB_predict,
//RF
	input  wire 						RF_flag1,
	input  wire 						RF_R1,
	input  wire	[31:0]					RF_V1,
	input  wire 						RF_flag2,
	input  wire							RF_R2,
	input  wire [31:0]					RF_V2,
	output wire							RF_write_flag,
//RS
	input  wire	[`RS_INDEX_RANGE]		RS_put_idx_in,
	input  wire							RS_ready_in,
	input  wire	[`RS_INDEX_RANGE]		RS_ready_idx_in,
	output wire							RS_flag,
	output wire	[`RS_INDEX_RANGE]		RS_put_idx,
	output wire							RS_ready,
	output wire	[`RS_INDEX_RANGE]		RS_ready_idx,
//LSB
	output wire							LSB_flag,
//ROB
	input  wire	[`ROB_INDEX_RANGE]		ROB_nex_idx,
	input  wire							ROB_R1,
	input  wire	[31:0]					ROB_V1,
	input  wire							ROB_R2,
	input  wire	[31:0]					ROB_V2,
	output wire							ROB_flag,
	output reg							ROB_rs1_flag,
	output reg	[`ROB_INDEX_RANGE]		ROB_rs1_idx,
	output reg 							ROB_rs2_flag,
	output reg	[`ROB_INDEX_RANGE]		ROB_rs2_idx,
//dispatch
	output reg	[5:0]					Dis_op,
	output reg	[31:0]					Dis_imm,
	output reg	[`REG_INDEX_RANGE]		Dis_rd,
	output reg	[`ROB_INDEX_RANGE]		Dis_ROB_idx,
	output reg	[31:0]					Dis_PC,
	output reg							Dis_R1,
	output reg	[31:0]					Dis_V1,
	output reg							Dis_R2,
	output reg	[31:0]					Dis_V2,
	output reg	[31:0]					Dis_BTB_PC,
	output reg							Dis_BTB_predict
);
	wire is_load   = (Dec_op == `LB  || Dec_op == `LH   || Dec_op == `LW || 
					  Dec_op == `LBU || Dec_op == `LHU);
	wire is_store  = (Dec_op == `SB  || Dec_op == `SH   || Dec_op == `SW);
	wire is_branch = (Dec_op == `BEQ || Dec_op == `BNE  || Dec_op == `BLT || 
					  Dec_op == `BGE || Dec_op == `BLTU || Dec_op == `BGEU);

	assign ROB_flag      = Dec_flag;
	assign LSB_flag      = (Dec_flag && (is_load || is_store));
	assign RF_write_flag = (Dec_flag && !is_store && !is_branch);
	assign RS_flag       = (Dec_flag && !is_load && !is_store);
	assign RS_put_idx    = RS_flag ? RS_put_idx_in : 0;
	assign RS_ready      = RS_ready_in;
	assign RS_ready_idx  = RS_ready_idx_in;

	always @(*) begin
		if (Dec_flag) begin
			Dis_op      = Dec_op;
			Dis_imm     = Dec_imm;
			Dis_rd      = Dec_rd;
			Dis_ROB_idx = ROB_nex_idx;
			Dis_PC      = Dec_PC;

			Dis_BTB_PC      = Dec_BTB_PC;
			Dis_BTB_predict = Dec_BTB_predict;
		end else begin
			Dis_op      = 0;
			Dis_imm     = 0;
			Dis_rd      = 0;
			Dis_ROB_idx = 0;
			Dis_PC      = 0;

			Dis_BTB_PC      = 0;
			Dis_BTB_predict = 0;
		end
	end

	always @(*) begin
		if (Dec_flag && RF_flag1) begin
			if (RF_R1 == `TRUE) begin
				ROB_rs1_flag = `FALSE;
				ROB_rs1_idx  = 0;
				Dis_R1       = `TRUE;
				Dis_V1       = RF_V1;
			end else begin
				ROB_rs1_flag = `TRUE;
				ROB_rs1_idx  = RF_V1;
				if (ROB_R1) begin
					Dis_R1 = `TRUE;
					Dis_V1 = ROB_V1;
				end else begin
					Dis_R1 = `FALSE;
					Dis_V1 = RF_V1;
				end
			end
		end else begin
			ROB_rs1_flag = `FALSE;
			ROB_rs1_idx  = 0;
			Dis_R1       = `FALSE;
			Dis_V1       = 0;
		end
	end

	always @(*) begin
		if (Dec_flag && RF_flag2) begin
			if (RF_R2 == `TRUE) begin
				ROB_rs2_flag = `FALSE;
				ROB_rs2_idx  = 0;
				Dis_R2       = `TRUE;
				Dis_V2       = RF_V2;
			end else begin
				ROB_rs2_flag = `TRUE;
				ROB_rs2_idx  = RF_V2;
				if (ROB_R2) begin
					Dis_R2 = `TRUE;
					Dis_V2 = ROB_V2;
				end else begin
					Dis_R2 = `FALSE;
					Dis_V2 = RF_V2;
				end
			end
		end else begin
			ROB_rs2_flag = `FALSE;
			ROB_rs2_idx  = 0;
			Dis_R2       = `FALSE;
			Dis_V2       = 0;
		end
	end

endmodule