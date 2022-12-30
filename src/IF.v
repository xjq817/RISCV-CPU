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
	output reg	[31:0]		IQ_BTB_PC,
	output reg				IQ_BTB_predict,
//ROB
	input  wire				ROB_jump_flag,
	input  wire	[31:0]		ROB_jump_PC,
	input  wire				ROB_BTB_flag,
	input  wire	[31:0]		ROB_BTB_PC
);

	reg			stall;
	reg	[31:0]	PC;

	reg [1:0]	BTB[`BTB_INDEX];

	// integer logfile;
	// initial begin
	// 	logfile = $fopen("IF.log", "w");
	// end

	integer i;
	always @(posedge clk) begin
		if (rst) begin
			stall   <= 0;
			PC      <= 0;
			IC_flag <= `FALSE;
			IQ_flag <= `FALSE;
			for (i = 0; i < `BTB_SIZE; i = i + 1) begin
                BTB[i] = 2'b10;
            end
		end else begin
			if (ROB_BTB_flag) begin
				if (ROB_jump_flag) begin
					case (BTB[ROB_BTB_PC[`BTB_TAG]])
						2'b00:   BTB[ROB_BTB_PC[`BTB_TAG]] <= BTB[ROB_BTB_PC[`BTB_TAG]];
						default: BTB[ROB_BTB_PC[`BTB_TAG]] <= BTB[ROB_BTB_PC[`BTB_TAG]] - 1;
					endcase
				end else begin
					case (BTB[ROB_BTB_PC[`BTB_TAG]])
						2'b11:   BTB[ROB_BTB_PC[`BTB_TAG]] <= BTB[ROB_BTB_PC[`BTB_TAG]];
						default: BTB[ROB_BTB_PC[`BTB_TAG]] <= BTB[ROB_BTB_PC[`BTB_TAG]] + 1;
					endcase
				end
			end
			if (ROB_jump_flag) begin
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
						stall   <= 1;
						IC_flag <= `FALSE;
						IQ_flag <= `TRUE;
						IQ_inst <= IC_val;
						IQ_PC   <= PC;
						if (IC_val[6:0] == `JALOP) begin
							PC <= PC + {{12{IC_val[31]}}, IC_val[19:12], IC_val[20], IC_val[30:21], 1'b0};
						end else if (IC_val[6:0] == `BRANCHOP) begin
							IQ_BTB_PC <= PC;
							if (BTB[PC[`BTB_TAG]][1]) begin
								// $fdisplay(logfile, "true %d", BTB[PC[`BTB_TAG]]);
								IQ_BTB_predict <= `TRUE;
								PC <= PC + {{20{IC_val[31]}}, IC_val[7], IC_val[30:25], IC_val[11:8], 1'b0};
							end else begin
								// $fdisplay(logfile, "false %d", BTB[PC[`BTB_TAG]]);
								IQ_BTB_predict <= `FALSE;
								PC <= PC + 4;
							end
						end else begin
							PC <= PC + 4;
						end
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
	end

endmodule