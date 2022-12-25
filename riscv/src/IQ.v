`include "define.v"

module IQ (
	input  wire					clk,
	input  wire					rst,  
	input  wire 				rdy,
	input  wire 				roll,
//IF
	input  wire					IF_flag,
	input  wire	[31:0]			IF_inst,
	input  wire	[31:0]			IF_PC,
//decoder
	input  wire					Dec_flag,
	output reg					Dec_commit,
	output reg	[31:0]			Dec_inst,
	output reg	[31:0]			Dec_PC,
//IQ
	output reg					IQ_full
);

	reg	[31:0]					inst[`IQ_INDEX];
	reg	[31:0]					PC[`IQ_INDEX];
	reg	[`IQ_INDEX_RANGE]		head;
	reg	[`IQ_INDEX_RANGE]		tail;
	reg [4:0]					size;

	always @(posedge clk) begin
		if (rst || roll) begin
			head       <= 0;
			tail       <= 0;
			size       <= 0;
			IQ_full    <= `FALSE;
			Dec_commit <= `FALSE;
		end else if (!rdy) begin
		end else begin
			size    <= size + IF_flag - Dec_flag;
			IQ_full <= (size + IF_flag - Dec_flag == `IQ_SIZE);
			if (Dec_flag) begin
				head <= head + 1;
			end
			if (IF_flag) begin
				tail       <= tail + 1;
				inst[tail] <= IF_inst;
				PC[tail]   <= IF_PC;
			end
			if (size > Dec_flag) begin
				Dec_commit <= `TRUE;
				if (Dec_flag) begin
					Dec_inst <= inst[head + 1];
					Dec_PC   <= PC[head + 1];
				end else begin
					Dec_inst <= inst[head];
					Dec_PC   <= PC[head];
				end
			end else begin
				Dec_commit <= `FALSE;
			end
		end
	end
endmodule