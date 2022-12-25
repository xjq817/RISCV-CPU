`include "define.v"

module RS (
	input  wire							clk,
	input  wire							rst,
	input  wire 						rdy,
	input  wire							roll,
//decoder
	input  wire							Dec_flag,
//dispatch
	input  wire							Dis_flag,
	input  wire	[`RS_INDEX_RANGE]		Dis_idx,
	input  wire	[5:0]					Dis_op,
	input  wire	[31:0]					Dis_imm,
	input  wire	[`ROB_INDEX_RANGE]		Dis_ROB_idx,
	input  wire	[31:0]					Dis_PC,
	input  wire							Dis_Rj,
	input  wire	[31:0]					Dis_Vj,
	input  wire 						Dis_Rk,
	input  wire	[31:0]					Dis_Vk,
	input  wire							Dis_ready_flag,
	input  wire	[`RS_INDEX_RANGE]		Dis_ready_idx,
//ALU
	input  wire							ALU_flag,
	input  wire	[`ROB_INDEX_RANGE]		ALU_ROB_idx,
	input  wire	[31:0]		   			ALU_val,
	output reg							ALU_commit,
	output reg	[5:0]					ALU_op,
	output reg	[31:0]					ALU_Vj,
	output reg	[31:0]					ALU_Vk,
	output reg	[`ROB_INDEX_RANGE]		ALU_idx,
	output reg	[31:0]					ALU_imm,
	output reg	[31:0]					ALU_PC, 
//LSB
	input  wire							LSB_flag,
	input  wire	[`ROB_INDEX_RANGE]		LSB_ROB_idx,
	input  wire	[31:0]					LSB_val,
//RS
	output reg							RS_full,
	output reg	[`RS_INDEX_RANGE]		RS_free_idx,
	output reg							RS_ready_flag,
	output reg	[`RS_INDEX_RANGE]		RS_ready_idx
);

	reg	[5:0]					opcode[`RS_INDEX];
	reg							Rj[`RS_INDEX];
	reg 						Rk[`RS_INDEX];
	reg	[`ROB_INDEX_RANGE]		Qj[`RS_INDEX];
	reg	[`ROB_INDEX_RANGE]		Qk[`RS_INDEX];
	reg	[31:0]					Vj[`RS_INDEX];
	reg	[31:0]					Vk[`RS_INDEX];
	reg	[31:0]					imm[`RS_INDEX];
	reg							busy[`RS_INDEX];
	reg	[`ROB_INDEX_RANGE]		ROB_idx[`RS_INDEX];
	reg	[31:0]					PC[`RS_INDEX];
	reg [4:0]					busy_cnt;


	integer i;
	always @(posedge clk) begin
		if (rst || roll) begin
			ALU_commit <= `FALSE;
			busy_cnt <= 0;
			RS_full <= `FALSE;
			for (i = 0; i < `RS_SIZE; i = i + 1) begin
				busy[i] <= `FALSE;
			end
		end else if (!rdy) begin
		end else begin
			busy_cnt <=  busy_cnt + Dis_flag - Dis_ready_flag;
			RS_full  <= (busy_cnt + Dis_flag - Dis_ready_flag == `RS_SIZE);
			if (ALU_flag) begin
				for (i = 0; i < `RS_SIZE; i = i + 1) begin
					if (busy[i] == `TRUE) begin
						if (Rj[i] == `FALSE && Qj[i] == ALU_ROB_idx) begin
							Rj[i] <= `TRUE;
							Vj[i] <= ALU_val;
						end
						if (Rk[i] == `FALSE && Qk[i] == ALU_ROB_idx) begin
							Rk[i] <= `TRUE;
							Vk[i] <= ALU_val;
						end
					end
				end
			end
			if (LSB_flag) begin
				for (i = 0; i < `RS_SIZE; i = i + 1) begin
					if (busy[i] == `TRUE) begin
						if (Rj[i] == `FALSE && Qj[i] == LSB_ROB_idx) begin
							Rj[i] <= `TRUE;
							Vj[i] <= LSB_val;
						end
						if (Rk[i] == `FALSE && Qk[i] == LSB_ROB_idx) begin
							Rk[i] <= `TRUE;
							Vk[i] <= LSB_val;
						end
					end
				end
			end
			if (Dis_flag) begin
				busy[Dis_idx]    <= `TRUE;
				opcode[Dis_idx]  <= Dis_op;
				imm[Dis_idx]     <= Dis_imm;
				ROB_idx[Dis_idx] <= Dis_ROB_idx;
				PC[Dis_idx]      <= Dis_PC;
				if (Dis_Rj == `TRUE) begin
					Rj[Dis_idx] <= `TRUE;
					Vj[Dis_idx] <= Dis_Vj;
				end else begin
					if (ALU_flag && Dis_Vj[`ROB_INDEX_RANGE] == ALU_ROB_idx) begin
						Rj[Dis_idx] <= `TRUE;
						Vj[Dis_idx] <= ALU_val;
					end else if (LSB_flag && Dis_Vj[`ROB_INDEX_RANGE] == LSB_ROB_idx) begin
						Rj[Dis_idx] <= `TRUE;
						Vj[Dis_idx] <= LSB_val;
					end else begin
						Rj[Dis_idx] <= `FALSE;
						Qj[Dis_idx] <= Dis_Vj[`ROB_INDEX_RANGE];
					end
				end
				if (Dis_Rk == `TRUE) begin
					Rk[Dis_idx] <= `TRUE;
					Vk[Dis_idx] <= Dis_Vk;
				end else begin
					if (ALU_flag && Dis_Vk[`ROB_INDEX_RANGE] == ALU_ROB_idx) begin
						Rk[Dis_idx] <= `TRUE;
						Vk[Dis_idx] <= ALU_val;
					end else if (LSB_flag && Dis_Vk[`ROB_INDEX_RANGE] == LSB_ROB_idx) begin
						Rk[Dis_idx] <= `TRUE;
						Vk[Dis_idx] <= LSB_val;
					end else begin
						Rk[Dis_idx] <= `FALSE;
						Qk[Dis_idx] <= Dis_Vk[`ROB_INDEX_RANGE];
					end
				end
			end
			if (Dis_ready_flag) begin
				ALU_commit          <= `TRUE;
				ALU_op              <= opcode[Dis_ready_idx];
				ALU_Vj              <= Vj[Dis_ready_idx];
				ALU_Vk              <= Vk[Dis_ready_idx];
				ALU_idx             <= ROB_idx[Dis_ready_idx];
				ALU_imm             <= imm[Dis_ready_idx];
				ALU_PC              <= PC[Dis_ready_idx];
				busy[Dis_ready_idx] <= `FALSE;
			end else begin
				ALU_commit<=`FALSE;
			end
		end
	end

	integer j;
	always @(*) begin
		RS_free_idx = 0;
		if (rst || roll || Dec_flag == `FALSE) begin
			RS_free_idx = 0;
		end else begin
			for (j = 0; j < `RS_SIZE; j = j + 1) begin
				if (!busy[j]) begin
					RS_free_idx = j;
				end
			end
		end
	end

	integer k;
	always @(*) begin
		RS_ready_idx  = `FALSE;
		RS_ready_flag = `FALSE;
		if (!rst && !roll) begin
			for (k = 0; k < `RS_SIZE; k = k + 1) begin
				if (busy[k] && RS_ready_flag == `FALSE) begin
					case (opcode[k])
						`LUI, `AUIPC, `JAL: begin
							RS_ready_flag = `TRUE;
							RS_ready_idx  = k;
						end
						`JALR, `ADDI, `SLTI, `SLTIU, `XORI, `ORI, `ANDI, `SLLI, `SRLI, `SRAI: begin
							if (Rj[k] == `TRUE) begin
								RS_ready_flag = `TRUE;
								RS_ready_idx  = k;
							end
						end
						default : begin
							if (Rj[k] == `TRUE && Rk[k] == `TRUE) begin
								RS_ready_flag = `TRUE;
								RS_ready_idx  = k;
							end
						end
					endcase
				end
			end
		end
	end

endmodule