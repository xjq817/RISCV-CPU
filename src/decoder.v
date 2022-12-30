`include "define.v"

module decoder (
//IQ
	input  wire							IQ_flag,
	input  wire	[31:0]					IQ_inst,
	input  wire	[31:0]					IQ_PC,
	input  wire	[31:0]					IQ_BTB_PC,
	input  wire							IQ_BTB_predict,
//RF
	output reg  						RF_R1,
	output reg	[`REG_INDEX_RANGE] 		RF_rs1,
	output reg  						RF_R2,
	output reg	[`REG_INDEX_RANGE] 		RF_rs2,
//dispatch
	output reg	[5:0]					Dis_op,
	output reg	[`REG_INDEX_RANGE]		Dis_rd,
	output reg	[31:0]					Dis_imm,
	output reg	[31:0]					Dis_PC,
	output wire	[31:0]					Dis_BTB_PC,
	output wire							Dis_BTB_predict,
//RS
	input  wire							RS_full,
//LSB
	input  wire 						LSB_full,
//ROB
	input  wire							ROB_full,
//decoder
	output wire							Dec_flag
);

	assign Dec_flag = IQ_flag && !RS_full && !ROB_full && !LSB_full;

	assign Dis_BTB_PC      = IQ_BTB_PC;
	assign Dis_BTB_predict = IQ_BTB_predict;

	always @(*) begin
		if (IQ_flag && !RS_full && !ROB_full && !LSB_full) begin
			Dis_PC = IQ_PC;
			RF_R1 = `FALSE;
			RF_R2 = `FALSE;
			case (IQ_inst[6:0])
				`LUIOP: begin
					Dis_op  = `LUI;
					Dis_imm = {IQ_inst[31:12], 12'b0};
					Dis_rd  = IQ_inst[11:7];
				end
				`AUIPCOP: begin
					Dis_op  = `AUIPC;
					Dis_imm = {IQ_inst[31:12], 12'b0};
					Dis_rd  = IQ_inst[11:7];
				end
				`JALOP: begin
					Dis_op  = `JAL;
					Dis_imm = {{12{IQ_inst[31]}}, IQ_inst[19:12], IQ_inst[20], IQ_inst[30:21], 1'b0};
					Dis_rd  = IQ_inst[11:7];
				end
				`JALROP: begin
					Dis_op  = `JALR;
					Dis_imm = {{21{IQ_inst[31]}}, IQ_inst[30:20]};
					Dis_rd  = IQ_inst[11:7];
					RF_R1   = `TRUE;
					RF_rs1  = IQ_inst[19:15];
				end
				`BRANCHOP: begin
					case (IQ_inst[14:12])
						3'b000: Dis_op = `BEQ;
						3'b001: Dis_op = `BNE;
						3'b100: Dis_op = `BLT;
						3'b101: Dis_op = `BGE;
						3'b110: Dis_op = `BLTU;
						3'b111: Dis_op = `BGEU;
					endcase
					Dis_imm = {{20{IQ_inst[31]}}, IQ_inst[7], IQ_inst[30:25], IQ_inst[11:8], 1'b0};
					RF_R1   = `TRUE;
					RF_rs1  = IQ_inst[19:15];
					RF_R2   = `TRUE;
					RF_rs2  = IQ_inst[24:20];
				end
				`LOADOP: begin
					case (IQ_inst[14:12])
						3'b000: Dis_op = `LB;
						3'b001: Dis_op = `LH;
						3'b010: Dis_op = `LW;
						3'b100: Dis_op = `LBU;
						3'b101: Dis_op = `LHU;
					endcase
					Dis_imm = {{21{IQ_inst[31]}}, IQ_inst[30:20]};
					Dis_rd  = IQ_inst[11:7];
					RF_R1   = `TRUE;
					RF_rs1  = IQ_inst[19:15];
				end
				`STOREOP: begin
					case (IQ_inst[14:12])
						3'b000: Dis_op = `SB;
						3'b001: Dis_op = `SH;
						3'b010: Dis_op = `SW;
					endcase
					Dis_imm = {{21{IQ_inst[31]}}, IQ_inst[30:25], IQ_inst[11:7]};
					RF_R1   = `TRUE;
					RF_rs1  = IQ_inst[19:15];
					RF_R2   = `TRUE;
					RF_rs2  = IQ_inst[24:20];
				end
				`CALCIOP: begin
					case (IQ_inst[14:12])
						3'b000: Dis_op = `ADDI;
						3'b001: Dis_op = `SLLI;
						3'b010: Dis_op = `SLTI;
						3'b011: Dis_op = `SLTIU;
						3'b100: Dis_op = `XORI;
						3'b101: begin
							case (IQ_inst[31:25])
								7'b0000000: Dis_op = `SRLI;
								7'b0100000: Dis_op = `SRAI;
							endcase
						end
						3'b110: Dis_op = `ORI;
						3'b111: Dis_op = `ANDI;
					endcase
					Dis_imm = {{21{IQ_inst[31]}}, IQ_inst[30:20]};
					Dis_rd  = IQ_inst[11:7];
					RF_R1   = `TRUE;
					RF_rs1  = IQ_inst[19:15];
				end
				`CALCOP: begin
					case (IQ_inst[14:12])
						3'b000: begin
							case (IQ_inst[31:25])
								7'b0000000: Dis_op = `ADD;
								7'b0100000: Dis_op = `SUB;
							endcase
						end
						3'b001: Dis_op = `SLL;
						3'b010: Dis_op = `SLT;
						3'b011: Dis_op = `SLTU;
						3'b100: Dis_op = `XOR;
						3'b101: begin
							case (IQ_inst[31:25])
								7'b0000000: Dis_op = `SRL;
								7'b0100000: Dis_op = `SRA;
							endcase
						end
						3'b110: Dis_op = `OR;
						3'b111: Dis_op = `AND;
					endcase
					Dis_rd = IQ_inst[11:7];
					RF_R1  = `TRUE;
					RF_rs1 = IQ_inst[19:15];
					RF_R2  = `TRUE;
					RF_rs2 = IQ_inst[24:20];
				end
			endcase
		end
	end

endmodule