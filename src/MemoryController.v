`include "define.v"

module MemoryController (
	input  wire					clk,
	input  wire					rst,
	input  wire					rdy,
	input  wire					roll,
	input  wire					io_buffer_full,
	input  wire [7:0]			mem_din,
	output reg  [7:0]			mem_dout,
	output reg  [31:0]			mem_a,
	output reg					mem_wr,
//ICache
	input  wire					IC_flag,
	input  wire [31:0]			IC_addr,
	output reg					IC_commit,
	output reg	[31:0]			IC_data,
//LSB
	input  wire					LSB_flag,
	input  wire					LSB_type,
	input  wire	[31:0]			LSB_addr,
	input  wire	[2:0]			LSB_len,
	input  wire [31:0]			LSB_data,
	output reg					LSB_commit,
	output reg	[31:0]			LSB_val
);

	reg [1:0] 		stall;
	reg				work;
	reg				belong;
	reg 			is_store;
	reg	[31:0]		addr;
	reg [2:0]		len;
	reg [31:0]		store_val;
	reg [2:0]		LSB_step;
	reg [31:0]		data;

	always @(posedge clk) begin
		if (rst) begin
			work       <= `FALSE;
			stall      <= 0;
			IC_commit  <= `FALSE;
			LSB_commit <= `FALSE;
			is_store   <= 0;
			addr       <= 0;
			mem_wr     <= 0;
			mem_a      <= 0;
		end else if (roll) begin
			if (work && is_store) begin
				if (LSB_step == len - 3'b001) begin
					IC_commit  <= `FALSE;
					LSB_commit <= `TRUE;
					work       <= `FALSE;
					mem_wr     <= 0;
					mem_a      <= 0;
				end else begin
					LSB_commit <= `FALSE;
					IC_commit  <= `FALSE;
					mem_wr     <= 1;
					LSB_step   <= LSB_step + 3'b001;
					case (LSB_step)
						3'b000: begin
							mem_dout <= store_val[15:8];
							mem_a    <= addr + 3'b001;
						end
						3'b001: begin
							mem_dout <= store_val[23:16];
							mem_a    <= addr + 3'b010;
						end
						3'b010: begin
							mem_dout <= store_val[31:24];
							mem_a    <= addr + 3'b011;
						end
					endcase
				end
			end else begin
				work       <= `FALSE;
				stall      <= 0;
				IC_commit  <= `FALSE;
				LSB_commit <= `FALSE;
				is_store   <= 0;
				addr       <= 0;
				mem_wr     <= 0;
				mem_a      <= 0;
			end
		end else if (!rdy) begin
			IC_commit  <= `FALSE;
			LSB_commit <= `FALSE;
			mem_wr     <= 0;
			mem_a      <= 0;
		end else begin
			if (work) begin
				if (!is_store) begin
					if (LSB_step == len + 1) begin
						if (belong == 0) begin
							LSB_commit <= `TRUE;
							LSB_val    <= data;
							IC_commit  <= `FALSE;
						end else begin
							IC_commit  <= `TRUE;
							IC_data    <= data;
							LSB_commit <= `FALSE;
						end
						work     <= `FALSE;
						mem_wr   <= 0;
						mem_a    <= 0;
					end else begin
						LSB_commit <= `FALSE;
						IC_commit  <= `FALSE;
						mem_wr     <= 0;
						LSB_step   <= LSB_step + 3'b001;
						case (LSB_step)
							3'b000: begin
								mem_a <= addr + 3'b001;
							end
							3'b001: begin
								data[7:0] <= mem_din;
								mem_a     <= addr + 3'b010;
							end
							3'b010: begin
								data[15:8] <= mem_din;
								mem_a      <= addr + 3'b011;
							end
							3'b011: begin
								data[23:16] <= mem_din;
								mem_a       <= 0;
							end
							3'b100: begin
								data[31:24] <= mem_din;
								mem_a       <= 0;
							end
						endcase
					end
				end else begin
					if (LSB_step == len - 3'b001) begin
						IC_commit  <= `FALSE;
						LSB_commit <= `TRUE;
						work       <= `FALSE;
						mem_wr     <= 0;
						mem_a      <= 0;
					end else begin
						LSB_commit <= `FALSE;
						IC_commit  <= `FALSE;
						mem_wr     <= 1;
						LSB_step   <= LSB_step + 3'b001;
						case (LSB_step)
							3'b000: begin
								mem_dout <= store_val[15:8];
								mem_a    <= addr + 3'b001;
							end
							3'b001: begin
								mem_dout <= store_val[23:16];
								mem_a    <= addr + 3'b010;
							end
							3'b010: begin
								mem_dout <= store_val[31:24];
								mem_a    <= addr + 3'b011;
							end
						endcase
					end
				end
			end else begin
				if (LSB_flag) begin
					if (stall == 2'b11) begin
						if (!LSB_type || LSB_addr[17:16] != 2'b11 || ~io_buffer_full) begin
							stall      <= 0;
							work       <= `TRUE;
							belong     <= 0;
							is_store   <= LSB_type;
							addr       <= LSB_addr;
							len        <= LSB_len;
							store_val  <= LSB_data;
							LSB_step   <= 0;
							data       <= 0;
							mem_wr     <= LSB_type;
							mem_a      <= LSB_addr;
							mem_dout   <= LSB_data[7:0];
							IC_commit  <= `FALSE;
							LSB_commit <= `FALSE;
						end
					end else begin
						stall      <= stall + 1;
						IC_commit  <= `FALSE;
						LSB_commit <= `FALSE;
						mem_wr     <= 0;
						mem_a      <= 0;
						mem_dout   <= 0;
					end
				end else if (IC_flag) begin
					if (stall == 2'b11) begin
						stall      <= 0;
						work       <= `TRUE;
						belong     <= 1;
						is_store   <= 0;
						addr       <= IC_addr;
						len        <= 3'b100;
						LSB_step   <= 0;
						data       <= 0;
						mem_wr     <= 0;
						mem_a      <= IC_addr;
						IC_commit  <= `FALSE;
						LSB_commit <= `FALSE;
					end else begin
						stall      <= stall + 1;
						IC_commit  <= `FALSE;
						LSB_commit <= `FALSE;
						mem_wr     <= 0;
						mem_a      <= 0;
						mem_dout   <= 0;
					end
				end else begin
					IC_commit  <= `FALSE;
					LSB_commit <= `FALSE;
					mem_wr     <= 0;
					mem_a      <= 0;
					mem_dout   <= 0;
				end
			end
		end
	end

endmodule