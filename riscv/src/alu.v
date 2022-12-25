`include "define.v"

module alu (
	input  wire							clk,
	input  wire							rst,
	input  wire 						rdy,
	input  wire							roll,
//RS
	input  wire 						RS_flag,
	input  wire	[5:0]					RS_op,
	input  wire	[31:0]					RS_Vj,
	input  wire	[31:0]					RS_Vk,
	input  wire	[`ROB_INDEX_RANGE]		RS_idx,
	input  wire	[31:0]					RS_imm,
	input  wire	[31:0]					RS_PC,
//alu
	output reg  						ALU_flag,
	output reg	[`ROB_INDEX_RANGE]		ALU_ROB_idx,
	output reg	[31:0]					ALU_val,
	output reg	 						ALU_jump_flag,
	output reg	[31:0]					ALU_jump_PC
);

	always @(posedge clk) begin
		if (rst || roll) begin
			ALU_flag      <= `FALSE;
			ALU_jump_flag <= `FALSE;
		end else if (rdy) begin
			if (RS_flag == `FALSE) begin
				ALU_flag <= `FALSE;
			end else begin
				ALU_flag    <= `TRUE;
				ALU_ROB_idx <= RS_idx;
				case (RS_op)
					`LUI:   ALU_val <= RS_imm;
					`AUIPC: ALU_val <= RS_PC + RS_imm;
					`JAL: begin
						ALU_val       <= RS_PC + 4;
						ALU_jump_flag <=`TRUE;
						ALU_jump_PC   <= RS_PC + RS_imm;
					end
					`JALR: begin
						ALU_val       <= RS_PC + 4;
						ALU_jump_flag <= `TRUE;
						ALU_jump_PC   <= (RS_Vj + RS_imm) & (~1'b1);
					end
					`BEQ: begin
						if (RS_Vj == RS_Vk) begin
							ALU_jump_flag <= `TRUE;
							ALU_jump_PC   <= RS_PC + RS_imm;
						end
					end
					`BNE: begin
						if (RS_Vj != RS_Vk) begin
							ALU_jump_flag <= `TRUE;
							ALU_jump_PC   <= RS_PC + RS_imm;
						end
					end
					`BLT: begin
						if ($signed(RS_Vj) < $signed(RS_Vk)) begin
							ALU_jump_flag <= `TRUE;
							ALU_jump_PC   <= RS_PC + RS_imm;
						end
					end
					`BGE: begin
						if ($signed(RS_Vj) >= $signed(RS_Vk)) begin
							ALU_jump_flag <= `TRUE;
							ALU_jump_PC   <= RS_PC + RS_imm;
						end
					end
					`BLTU: begin
						if (RS_Vj < RS_Vk) begin
							ALU_jump_flag <= `TRUE;
							ALU_jump_PC   <= RS_PC + RS_imm;
						end
					end
					`BGEU: begin
						if (RS_Vj >= RS_Vk) begin
							ALU_jump_flag <= `TRUE;
							ALU_jump_PC   <= RS_PC + RS_imm;
						end
					end
					`ADDI:  ALU_val <= RS_Vj + RS_imm;
					`SLTI:  ALU_val <= $signed(RS_Vj) < $signed(RS_imm);
					`SLTIU: ALU_val <= RS_Vj < RS_imm;
					`XORI:  ALU_val <= RS_Vj ^ RS_imm;
					`ORI:   ALU_val <= RS_Vj | RS_imm;
					`ANDI:  ALU_val <= RS_Vj & RS_imm;
					`SLLI:  ALU_val <= RS_Vj << RS_imm[5:0];
					`SRLI:  ALU_val <= RS_Vj >> RS_imm[5:0];
					`SRAI:  ALU_val <= $signed(RS_Vj) >> RS_imm[5:0];
					`ADD:   ALU_val <= RS_Vj + RS_Vk;
					`SUB:   ALU_val <= RS_Vj - RS_Vk;
					`SLL:   ALU_val <= RS_Vj << RS_Vk[5:0];
					`SLT:   ALU_val <= $signed(RS_Vj) < $signed(RS_Vk);
					`SLTU:  ALU_val <= RS_Vj < RS_Vk;
					`XOR:   ALU_val <= RS_Vj ^ RS_Vk;
					`SRL:   ALU_val <= RS_Vj >> RS_Vk[5:0];
					`SRA:   ALU_val <= $signed(RS_Vj) >> RS_Vk[5:0];
					`OR:    ALU_val <= RS_Vj | RS_Vk;
					`AND:   ALU_val <= RS_Vj & RS_Vk;
				endcase
			end
		end
	end

endmodule