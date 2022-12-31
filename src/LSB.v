`include "define.v"

module LSB (
	input  wire							clk,
	input  wire 						rst,
	input  wire 						rdy,
	input  wire 						roll,
//MemoryController
	input  wire							MC_flag_in,
	input  wire	[31:0]					MC_val,
	output reg 							MC_flag,
	output reg							MC_op,
	output reg	[31:0]					MC_PC,
	output reg	[2:0]					MC_LS_len,
	output reg  [31:0]					MC_data,
//dispatch
	input  wire							Dis_flag,
	input  wire	[5:0]					Dis_op,
	input  wire	[31:0]					Dis_imm,
	input  wire	[`ROB_INDEX_RANGE]		Dis_ROB_idx,
	input  wire	[31:0]					Dis_PC,
	input  wire							Dis_R1,
	input  wire	[31:0]					Dis_V1,
	input  wire 						Dis_R2,
	input  wire	[31:0]					Dis_V2,
//ROB
	input  wire 						ROB_store_flag,
	input  wire	[`ROB_INDEX_RANGE]		ROB_store_idx,
	input  wire							ROB_from_ALU_flag,
	input  wire	[`ROB_INDEX_RANGE]		ROB_from_ALU_idx,
	input  wire	[31:0]					ROB_from_ALU_val,
	input  wire							ROB_from_LSB_flag,
	input  wire	[`ROB_INDEX_RANGE]		ROB_from_LSB_idx,
	input  wire	[31:0]					ROB_from_LSB_val,
	input  wire							ROB_head_flag,
	input  wire [`ROB_INDEX_RANGE]		ROB_head,
//LSB
	output reg							LSB_full,
	output reg							LSB_flag,
	output reg	[`ROB_INDEX_RANGE]		LSB_ROB_idx,
	output reg	[31:0]					LSB_val
);

	reg 						busy[`LSB_INDEX];
	integer						busy_cnt;
	reg	[`LSB_INDEX_RANGE]		head;
	reg	[`LSB_INDEX_RANGE]		tail;
	reg	[5:0]					op[`LSB_INDEX];
	// wire ophead = op[head];
	reg							Rj[`LSB_INDEX];
	// wire rjhead = Rj[head];
	reg							Rk[`LSB_INDEX];
	// wire rkhead = Rk[head];
	reg	[`ROB_INDEX_RANGE]		Qj[`LSB_INDEX];
	// wire qjhead = Qj[head];
	reg	[`ROB_INDEX_RANGE]		Qk[`LSB_INDEX];
	// wire qkhead = Qk[head];
	reg	[31:0]					Vj[`LSB_INDEX];
	// wire vjhead = Vj[head];
	reg	[31:0]					Vk[`LSB_INDEX];
	// wire vkhead = Vk[head];
	reg	[31:0]					imm[`LSB_INDEX];
	// wire immhead = imm[head];
	reg	[`ROB_INDEX_RANGE]		ROB_idx[`LSB_INDEX];
	// wire robidxhead = ROB_idx[head];
	reg	[31:0]					PC[`LSB_INDEX];
	// wire pchead = PC[head];
	reg 						commit[`LSB_INDEX];
	// wire commithead = commit[head];
	integer						commit_cnt;

	wire head_store  = (op[head] == `SB || op[head] == `SH || op[head] == `SW);
	wire head_commit = (busy_cnt>0 && busy[head] && head_store && MC_flag_in);

	wire [31:0] load_addr = Vj[head] + imm[head];
	wire        io_first  = (load_addr[17:16]==3 && ROB_head_flag && ROB_idx[head] == ROB_head);

	integer i;
	always @(posedge clk) begin
		if (rst) begin
			for (i = 0; i < `LSB_SIZE; i = i + 1) begin
				busy[i] <= `FALSE;
			end
			head       <= 0;
			tail       <= 0;
			busy_cnt   <= 0;
			commit_cnt <= 0;
			LSB_full   <= `FALSE;
			MC_flag    <= `FALSE;
			LSB_flag   <= `FALSE;
		end else if (roll) begin
			MC_flag  <= `FALSE;
			LSB_flag <= `FALSE;
			if (MC_flag_in && commit[head]) begin
				for (i = 0; i < `LSB_SIZE; i = i + 1) begin
					if (head == i || !commit[i]) begin
						busy[i] <= `FALSE;
					end
				end
				commit[head] <= `FALSE;
				commit_cnt   <= commit_cnt - 1;
				busy[head]   <= `FALSE;
				busy_cnt     <= commit_cnt - 1;
				LSB_full     <= `FALSE;
				head         <= head + 1;
				tail         <= head + commit_cnt;
			end else begin
				for (i = 0; i < `LSB_SIZE; i = i + 1) begin
					if (!commit[i]) begin
						busy[i] <= `FALSE;
					end
				end
				busy_cnt <= commit_cnt;
				LSB_full <= (commit_cnt == `LSB_SIZE);
				tail     <= head + commit_cnt;
			end
		end else if (!rdy) begin
		end else begin
			if (ROB_from_ALU_flag) begin
				for (i = 0; i < `LSB_SIZE; i = i + 1) begin
					if (busy[i]) begin
						if (Rj[i] == `FALSE && Qj[i] == ROB_from_ALU_idx) begin
							Rj[i] <= `TRUE;
							Vj[i] <= ROB_from_ALU_val;
						end
						if (Rk[i] == `FALSE && Qk[i] == ROB_from_ALU_idx) begin
							Rk[i] <= `TRUE;
							Vk[i] <= ROB_from_ALU_val;
						end
					end
				end
			end
			if (ROB_from_LSB_flag) begin
				for (i = 0; i < `LSB_SIZE; i = i + 1) begin
					if (busy[i]) begin
						if (Rj[i] == `FALSE && Qj[i] == ROB_from_LSB_idx) begin
							Rj[i] <= `TRUE;
							Vj[i] <= ROB_from_LSB_val;
						end
						if (Rk[i] == `FALSE && Qk[i] == ROB_from_LSB_idx) begin
							Rk[i] <= `TRUE;
							Vk[i] <= ROB_from_LSB_val;
						end
					end
				end
			end
			if (Dis_flag) begin
				busy[tail]    <= `TRUE;
				op[tail]      <= Dis_op;
				imm[tail]     <= Dis_imm;
				ROB_idx[tail] <= Dis_ROB_idx;
				PC[tail]      <= Dis_PC;
				commit[tail]  <= `FALSE;
				tail          <= tail + 1;
				if (Dis_R1 == `TRUE) begin
					Rj[tail] <= `TRUE;
					Vj[tail] <= Dis_V1;
				end else begin
					if (ROB_from_ALU_flag && Dis_V1 == ROB_from_ALU_idx) begin
						Rj[tail] <= `TRUE;
						Vj[tail] <= ROB_from_ALU_val;
					end else if (ROB_from_LSB_flag && Dis_V1 == ROB_from_LSB_idx) begin
						Rj[tail] <= `TRUE;
						Vj[tail] <= ROB_from_LSB_val;
					end else begin
						Rj[tail] <= `FALSE;
						Qj[tail] <= Dis_V1;
					end
				end
				if (Dis_R2 == `TRUE) begin
					Rk[tail] <= `TRUE;
					Vk[tail] <= Dis_V2;
				end else begin
					if (ROB_from_ALU_flag && Dis_V2 == ROB_from_ALU_idx) begin
						Rk[tail] <= `TRUE;
						Vk[tail] <= ROB_from_ALU_val;
					end else if (ROB_from_LSB_flag && Dis_V2 == ROB_from_LSB_idx) begin
						Rk[tail] <= `TRUE;
						Vk[tail] <= ROB_from_LSB_val;
					end else begin
						Rk[tail] <= `FALSE;
						Qk[tail] <= Dis_V2;
					end
				end
			end
			if (busy_cnt > 0 && busy[head]) begin
				if (!head_store) begin
					if (Rj[head] == `TRUE && (load_addr[17:16]!=3 || io_first)) begin
						if (MC_flag_in) begin
							MC_flag     <= `FALSE;
							LSB_flag    <= `TRUE;
							LSB_ROB_idx <= ROB_idx[head];
							busy[head]  <= `FALSE;
							head        <= head + 1;
						end else begin
							MC_flag  <= `TRUE;
							MC_op    <= 1'b0;
							MC_PC    <= Vj[head] + imm[head];
							LSB_flag <= `FALSE;
						end
						busy_cnt <=  busy_cnt - MC_flag_in + Dis_flag;
						LSB_full <= (busy_cnt - MC_flag_in + Dis_flag == `LSB_SIZE);
						case (op[head])
							`LB: begin
								if (MC_flag_in) begin
									LSB_val <= {{25{MC_val[7]}}, MC_val[6:0]};
								end else begin
									MC_LS_len <= 1'b1;
								end
							end
							`LH: begin
								if (MC_flag_in) begin
									LSB_val <= {{17{MC_val[15]}}, MC_val[14:0]};
								end else begin
									MC_LS_len <= 2'b10;
								end
							end
							`LW: begin
								if (MC_flag_in) begin
									LSB_val <= MC_val;
								end else begin
									MC_LS_len <= 3'b100;
								end
							end
							`LBU: begin
								if (MC_flag_in) begin
									LSB_val <= MC_val;
								end else begin
									MC_LS_len <= 1'b1;
								end
							end
							`LHU: begin
								if (MC_flag_in) begin
									LSB_val <= MC_val;
								end else begin
									MC_LS_len <= 2'b10;
								end
							end
						endcase
					end else begin
						MC_flag  <= `FALSE;
						LSB_flag <= `FALSE;
						busy_cnt <= busy_cnt + Dis_flag;
						LSB_full <= (busy_cnt + Dis_flag == `LSB_SIZE);
					end
				end else begin
					LSB_flag <= `FALSE;
					if (commit[head]) begin
						busy_cnt <=  busy_cnt - MC_flag_in + Dis_flag;
						LSB_full <= (busy_cnt - MC_flag_in + Dis_flag == `LSB_SIZE);
						if (MC_flag_in) begin
							MC_flag      <= `FALSE;
							busy[head]   <= `FALSE;
							commit[head] <= `FALSE;
							head         <= head + 1;
						end else begin
							MC_flag <= `TRUE;
							MC_op   <= 1'b1;
							if (ROB_from_ALU_flag && Rj[head] == `FALSE && Qj[head] == ROB_from_ALU_idx) begin
								MC_PC <= ROB_from_ALU_val + imm[head];
							end else if (ROB_from_LSB_flag && Rj[head] == `FALSE && Qj[head] == ROB_from_LSB_idx) begin
								MC_PC <= ROB_from_LSB_val + imm[head];
							end else begin
								MC_PC <= Vj[head] + imm[head];
							end
							if (ROB_from_ALU_flag && Rk[head] == `FALSE && Qk[head] == ROB_from_ALU_idx) begin
								MC_data <= ROB_from_ALU_val;
							end else if (ROB_from_LSB_flag && Rk[head] == `FALSE && Qk[head] == ROB_from_LSB_idx) begin
								MC_data <= ROB_from_LSB_val;
							end else begin
								MC_data <= Vk[head];
							end
						end
						case (op[head])
							`SB: MC_LS_len <= 1'b1;
							`SH: MC_LS_len <= 2'b10;
							`SW: MC_LS_len <= 3'b100;
						endcase
					end
					else begin
						MC_flag  <= `FALSE;
						busy_cnt <=  busy_cnt + Dis_flag;
						LSB_full <= (busy_cnt + Dis_flag == `LSB_SIZE);
					end
				end
			end else begin
				MC_flag  <= `FALSE;
				LSB_flag <= `FALSE;
				busy_cnt <=  busy_cnt + Dis_flag;
				LSB_full <= (busy_cnt + Dis_flag == `LSB_SIZE);
			end

			if (ROB_store_flag) begin
				for (i = 0; i < `LSB_SIZE; i = i + 1) begin
					if (busy[i] && ROB_store_idx == ROB_idx[i]) begin
						commit[i]  <= `TRUE;
						commit_cnt <= commit_cnt + 1 - head_commit;
					end
				end
			end else begin
				commit_cnt <= commit_cnt - head_commit;
			end
		end
	end

endmodule