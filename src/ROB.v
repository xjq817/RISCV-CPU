`include "define.v"

module ROB (
	input  wire 						clk,
	input  wire 						rst,
	input  wire 						rdy,
//IF
	output reg							IF_jump_flag,
	output reg	[31:0]					IF_jump_PC,
	output reg							IF_BTB_flag,
	output reg	[31:0]					IF_BTB_PC,
//decoder
	input  wire							Dec_flag,
//dispatch
	input  wire							Dis_flag,
	input  wire	[5:0]					Dis_op,
	input  wire	[`REG_INDEX_RANGE]		Dis_rd,
	input  wire	[31:0]					Dis_PC,
	input  wire							Dis_flag1,
	input  wire	[`ROB_INDEX_RANGE]		Dis_ROB_idx1,
	input  wire 						Dis_flag2,
	input  wire	[`ROB_INDEX_RANGE]		Dis_ROB_idx2,
	input  wire	[31:0]					Dis_BTB_PC,
	input  wire							Dis_BTB_predict,
	output wire							Dis_R1,
	output wire	[31:0]					Dis_V1,
	output wire							Dis_R2,
	output wire	[31:0]					Dis_V2,
//alu
	input  wire							ALU_flag,
	input  wire	[`ROB_INDEX_RANGE]		ALU_ROB_idx,
	input  wire	[31:0]					ALU_val,
	input  wire							ALU_jump_flag,
	input  wire	[31:0]					ALU_jump_PC,
//RF
	output reg							RF_write_flag,
	output reg	[`REG_INDEX_RANGE]		RF_rd,
	output reg	[`ROB_INDEX_RANGE]		RF_ROB_idx,
	output reg	[31:0]					RF_val,
//LSB
	input  wire 						LSB_load_flag,
	input  wire	[`ROB_INDEX_RANGE]		LSB_load_ROB_idx,
	input  wire	[31:0]					LSB_load_val,
	output reg							LSB_store_flag,
	output reg	[`ROB_INDEX_RANGE]		LSB_store_idx,
	output reg							LSB_from_ALU_flag,
	output reg	[`ROB_INDEX_RANGE]		LSB_from_ALU_idx,
	output reg	[31:0]					LSB_from_ALU_val,
	output reg 							LSB_from_LSB_flag,
	output reg	[`ROB_INDEX_RANGE]		LSB_from_LSB_idx,
	output reg	[31:0]					LSB_from_LSB_val,
//ROB
	output wire							ROB_head_flag,
	output wire	[`ROB_INDEX_RANGE]		ROB_head,
	output reg 							ROB_full,
	output reg	 						ROB_roll,
	output wire	[`ROB_INDEX_RANGE]		ROB_nex_idx
);

	reg							ready[`ROB_INDEX];
	reg	[5:0]					op[`ROB_INDEX];
	reg	[`REG_INDEX_RANGE]		dest[`ROB_INDEX];
	reg	[31:0]					val[`ROB_INDEX];
	reg	[31:0]					PC[`ROB_INDEX];
	reg							jump_flag[`ROB_INDEX];
	reg	[31:0]					jump_PC[`ROB_INDEX];
	reg	[31:0]					BTB_PC[`ROB_INDEX];
	reg							BTB_predict[`ROB_INDEX];
	reg	[`ROB_INDEX_RANGE]		head;
	reg	[`ROB_INDEX_RANGE]		tail;
	reg							empty;

	// integer cnti;
	// integer logfile;
	// initial begin
	// 	logfile = $fopen("ROB.log", "w");
	// end

	wire is_store = (Dis_op == `SB || Dis_op == `SW || Dis_op == `SH);
	
	assign ROB_head_flag = !empty;
	assign ROB_head      = head;
	assign ROB_nex_idx   = tail;

	assign Dis_R1 = Dis_flag1 && ready[Dis_ROB_idx1];
	assign Dis_V1 = val[Dis_ROB_idx1];
	assign Dis_R2 = Dis_flag2 && ready[Dis_ROB_idx2];
	assign Dis_V2 = val[Dis_ROB_idx2];

	wire PChead = PC[head];

	integer i;
	// integer corret;
	// integer fail;
	always @(posedge clk) begin
		// if (rst) cnti <= 1;
		// if (rst) begin
		// 	corret <= 0;
		// 	fail   <= 0;
		// end
		if (rst || ROB_roll) begin
			head     <= 0;
			tail     <= 0;
			empty    <= `TRUE;
			ROB_roll <= `FALSE;
			for (i = 0; i < `ROB_SIZE; i = i + 1) begin
				ready[i]     <= 0;
				op[i]        <= 0;
				dest[i]      <= 0;
				val[i]       <= 0;
				jump_flag[i] <= 0;
				jump_PC[i]   <= 0;
				PC[i]        <= 0;
			end
			IF_jump_flag      <= `FALSE;
			RF_write_flag     <= `FALSE;
			LSB_store_flag    <= `FALSE;
			LSB_from_ALU_flag <= `FALSE;
			LSB_from_LSB_flag <= `FALSE;
			IF_BTB_flag       <= `FALSE;
		end else if (!rdy) begin
			ROB_full          <= head == tail && (!empty);
			ROB_roll          <= `FALSE;
			IF_jump_flag      <= `FALSE;
			RF_write_flag     <= `FALSE;
			LSB_store_flag    <= `FALSE;
			LSB_from_ALU_flag <= `FALSE;
			LSB_from_LSB_flag <= `FALSE;
			IF_BTB_flag       <= `FALSE;
		end else begin
			if (head + ((!empty) && ready[head]) == tail + Dis_flag) begin
				ROB_full <= (!empty);
				if (!empty && ready[head] && !Dis_flag) begin
					empty <= `TRUE;
				end
			end else begin
				ROB_full <= `FALSE;
				empty    <= `FALSE;
			end
			if (Dis_flag) begin
				tail              <= tail + 1;
				op[tail]          <= Dis_op;
				dest[tail]        <= Dis_rd;
				val[tail]         <= 0;
				jump_flag[tail]   <= 0;
				jump_PC[tail]     <= 0;
				PC[tail]          <= Dis_PC;
				BTB_PC[tail]      <= Dis_BTB_PC;
				BTB_predict[tail] <= Dis_BTB_predict;
				if (is_store) begin
					ready[tail] <= `TRUE;
				end else begin
					ready[tail] <= `FALSE;
				end
			end
			if (ALU_flag) begin
				val[ALU_ROB_idx]       <= ALU_val;
				jump_flag[ALU_ROB_idx] <= ALU_jump_flag;
				jump_PC[ALU_ROB_idx]   <= ALU_jump_PC;
				ready[ALU_ROB_idx]     <= `TRUE;

				LSB_from_ALU_flag <= `TRUE;
				LSB_from_ALU_idx  <= ALU_ROB_idx;
				LSB_from_ALU_val  <= ALU_val;
			end else begin
				LSB_from_ALU_flag <= `FALSE;
			end
			if (LSB_load_flag) begin
				val[LSB_load_ROB_idx]   <= LSB_load_val;
				ready[LSB_load_ROB_idx] <= `TRUE;

				LSB_from_LSB_flag <= `TRUE;
				LSB_from_LSB_idx  <= LSB_load_ROB_idx;
				LSB_from_LSB_val  <= LSB_load_val;
			end else begin
				LSB_from_LSB_flag <= `FALSE;
			end
			if ((!empty) && ready[head]) begin
				// cnti <= cnti + 1;
				head <= head + 1;
				// $fdisplay(logfile, "clk: %d; commit: %h %h; %d <- %d %d %h", cnti, PC[head], op[head], dest[head], $signed(val[head]),jump_flag[head],jump_PC[head]);
				// $fdisplay(logfile, "%d %h", cnti, PC[head]);
				case (op[head])
					`SB,`SH,`SW: begin
						IF_BTB_flag    <= `FALSE;
						ROB_roll       <= `FALSE;
						IF_jump_flag   <= `FALSE;
						RF_write_flag  <= `FALSE;
						LSB_store_flag <= `TRUE;
						LSB_store_idx  <= head;
					end
					`JALR: begin
						IF_BTB_flag    <= `FALSE;
						ROB_roll       <= `TRUE;
						IF_jump_flag   <= `TRUE;
						IF_jump_PC     <= jump_PC[head];
						RF_write_flag  <= `TRUE;
						RF_ROB_idx     <= head;
						RF_rd          <= dest[head];
						RF_val         <= val[head];
						LSB_store_flag <= `FALSE;
					end
					`BEQ,`BNE,`BLT,`BGE,`BLTU,`BGEU: begin
						// $fdisplay(logfile, "jump_flag=%d BTB_predict=%d jump_PC=%d", jump_flag[head],jump_PC[head]);
						IF_BTB_flag <= `TRUE;
						IF_BTB_PC   <= BTB_PC[head];
						if (jump_flag[head] != BTB_predict[head]) begin
							// fail         <= fail + 1;
							ROB_roll     <= `TRUE;
							IF_jump_flag <= `TRUE;
							IF_jump_PC   <= jump_PC[head];
						end else begin
							// corret       <= corret + 1;
							ROB_roll     <= `FALSE;
							IF_jump_flag <= `FALSE;
						end
						RF_write_flag  <= `FALSE;
						LSB_store_flag <= `FALSE;
						// $fdisplay(logfile, "%d %d", corret, fail);
					end
					default: begin
						IF_BTB_flag    <= `FALSE;
						ROB_roll       <= `FALSE;
						IF_jump_flag   <= `FALSE;
						RF_write_flag  <= `TRUE;
						RF_ROB_idx     <= head;
						RF_rd          <= dest[head];
						RF_val         <= val[head];
						LSB_store_flag <= `FALSE;
					end
				endcase
			end else begin
				IF_BTB_flag    <= `FALSE;
				ROB_roll       <= `FALSE;
				IF_jump_flag   <= `FALSE;
				RF_write_flag  <= `FALSE;
				LSB_store_flag <= `FALSE;
			end
		end
	end

endmodule