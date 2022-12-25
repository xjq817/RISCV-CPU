`include "define.v"

// RISCV32I CPU top module
// port modification allowed for debugging purposes

module cpu(
  input  wire                 clk_in,			// system clock signal
  input  wire                 rst_in,			// reset signal
	input  wire					        rdy_in,			// ready signal, pause cpu when low

  input  wire [ 7:0]          mem_din,		// data input bus
  output wire [ 7:0]          mem_dout,		// data output bus
  output wire [31:0]          mem_a,			// address bus (only 17:0 is used)
  output wire                 mem_wr,			// write/read signal (1 for write)
	
	input  wire                 io_buffer_full, // 1 if uart buffer is full
	
	output wire [31:0]			dbgreg_dout		// cpu register output (debugging demo)
);

// implementation goes here

// Specifications:
// - Pause cpu(freeze pc, registers, etc.) when rdy_in is low
// - Memory read result will be returned in the next cycle. Write takes 1 cycle(no need to wait)
// - Memory is of size 128KB, with valid address ranging from 0x0 to 0x20000
// - I/O port is mapped to address higher than 0x30000 (mem_a[17:16]==2'b11)
// - 0x30000 read: read a byte from input
// - 0x30000 write: write a byte to output (write 0x00 is ignored)
// - 0x30004 read: read clocks passed since cpu starts (in dword, 4 bytes)
// - 0x30004 write: indicates program stop (will output '\0' through uart tx)

wire roll;

//MC - IC
wire        IC_MC_flag;
wire [31:0] IC_MC_addr;
wire        MC_IC_commit;
wire [31:0] MC_IC_data;

//MC - LSB
wire        LSB_MC_flag;
wire        LSB_MC_type;
wire [31:0] LSB_MC_addr;
wire [2:0]  LSB_MC_len;
wire [31:0] LSB_MC_data;
wire        MC_LSB_commit;
wire [31:0] MC_LSB_val;

//Dis - Dec
wire [31:0]             Dec_Dis_imm;
wire [`REG_INDEX_RANGE] Dec_Dis_rd;
wire [5:0]              Dec_Dis_op;
wire [31:0]             Dec_Dis_PC;

//Dis - RF
wire        RF_Dis_flag1;
wire        RF_Dis_R1;
wire [31:0] RF_Dis_V1;
wire        RF_Dis_flag2;
wire        RF_Dis_R2;
wire [31:0] RF_Dis_V2;
wire        Dis_RF_write_flag;

//Dis - RS
wire                    Dis_RS_flag;
wire [`RS_INDEX_RANGE]  Dis_RS_put_idx;
wire                    Dis_RS_ready;
wire [`RS_INDEX_RANGE]  Dis_RS_ready_idx;

//Dis - LSB
wire Dis_LSB_flag;

//Dis - ROB
wire                    ROB_Dis_R1;
wire [31:0]             ROB_Dis_V1;
wire                    ROB_Dis_R2;
wire [31:0]             ROB_Dis_V2;
wire                    Dis_ROB_flag;
wire                    Dis_ROB_flag1;
wire [`ROB_INDEX_RANGE] Dis_ROB_rs1_idx;
wire                    Dis_ROB_flag2;
wire [`ROB_INDEX_RANGE] Dis_ROB_rs2_idx;

//IC - IF
wire        IF_IC_flag;
wire [31:0] IF_IC_PC;
wire        IC_IF_commit;
wire [31:0] IC_IF_inst;

//IF - IQ
wire        IF_IQ_flag;
wire [31:0] IF_IQ_inst;
wire [31:0] IF_IQ_PC;

//IF - ROB
wire        ROB_IF_jump_flag;
wire [31:0] ROB_IF_jump_PC;

//IQ - Dec
wire        IQ_Dec_commit;
wire [31:0] IQ_Dec_inst;
wire [31:0] IQ_Dec_PC;

//Dec - RF
wire                    Dec_RF_R1;
wire [`REG_INDEX_RANGE] Dec_RF_rs1;
wire                    Dec_RF_R2;
wire [`REG_INDEX_RANGE] Dec_RF_rs2;

//LSB - ROB
wire                    ROB_LSB_store_flag;
wire [`ROB_INDEX_RANGE] ROB_LSB_store_idx;
wire                    ROB_LSB_from_ALU_flag;
wire [`ROB_INDEX_RANGE] ROB_LSB_from_ALU_idx;
wire [31:0]             ROB_LSB_from_ALU_val;
wire                    ROB_LSB_from_LSB_flag;
wire [`ROB_INDEX_RANGE] ROB_LSB_from_LSB_idx;
wire [31:0]             ROB_LSB_from_LSB_val;

//ROB - RF
wire                    ROB_RF_flag;
wire [`REG_INDEX_RANGE] ROB_RF_rd;
wire [`ROB_INDEX_RANGE] ROB_RF_idx;
wire [31:0]             ROB_RF_val;

//RS - ALU
wire 						        RS_ALU_flag;
wire [5:0]					    RS_ALU_op;
wire [31:0]					    RS_ALU_Vj;
wire [31:0]					    RS_ALU_Vk;
wire [`ROB_INDEX_RANGE]	RS_ALU_idx;
wire [31:0]					    RS_ALU_imm;
wire [31:0]					    RS_ALU_PC;

//Dis
wire [5:0]              Dis_op;
wire [31:0]             Dis_imm;
wire [`REG_INDEX_RANGE] Dis_rd;
wire [`ROB_INDEX_RANGE] Dis_ROB_idx;
wire [31:0]             Dis_PC;
wire                    Dis_R1;
wire [31:0]             Dis_V1;
wire                    Dis_R2;
wire [31:0]             Dis_V2;

//ROB
wire [`ROB_INDEX_RANGE] ROB_nex_idx;
wire                    ROB_full;
wire                    ROB_head_flag;
wire [`ROB_INDEX_RANGE] ROB_head;

//IQ
wire IQ_full;

//Dec
wire Dec_flag;

//RS
wire                    RS_full;
wire [`RS_INDEX_RANGE]  RS_free_idx;
wire                    RS_ready_flag;
wire [`RS_INDEX_RANGE]  RS_ready_idx;

//LSB
wire                    LSB_full;
wire							      LSB_flag;
wire [`ROB_INDEX_RANGE]	LSB_ROB_idx;
wire [31:0]					    LSB_val;

//ALU
wire                    ALU_flag;
wire [`ROB_INDEX_RANGE] ALU_ROB_idx;
wire [31:0]             ALU_val;
wire                    ALU_jump_flag;
wire [31:0]             ALU_jump_PC;

MemoryController MemoryController(
  .clk(clk_in),
  .rst(rst_in),
  .rdy(rdy_in),
  .roll(roll),
  .io_buffer_full(io_buffer_full),
  .mem_din(mem_din),
	.mem_dout(mem_dout),
	.mem_a(mem_a),
	.mem_wr(mem_wr),
	.IC_flag(IC_MC_flag),
	.IC_addr(IC_MC_addr),
	.IC_commit(MC_IC_commit),
	.IC_data(MC_IC_data),
	.LSB_flag(LSB_MC_flag),
	.LSB_type(LSB_MC_type),
	.LSB_addr(LSB_MC_addr),
	.LSB_len(LSB_MC_len),
	.LSB_data(LSB_MC_data),
	.LSB_commit(MC_LSB_commit),
	.LSB_val(MC_LSB_val)
);

dispatch dispatch(
  .Dec_flag(Dec_flag),
  .Dec_imm(Dec_Dis_imm),
  .Dec_rd(Dec_Dis_rd),
  .Dec_op(Dec_Dis_op),
  .Dec_PC(Dec_Dis_PC),
  .RF_flag1(RF_Dis_flag1),
  .RF_R1(RF_Dis_R1),
  .RF_V1(RF_Dis_V1),
  .RF_flag2(RF_Dis_flag2),
  .RF_R2(RF_Dis_R2),
  .RF_V2(RF_Dis_V2),
  .RF_write_flag(Dis_RF_write_flag),
  .RS_put_idx_in(RS_free_idx),
  .RS_ready_in(RS_ready_flag),
  .RS_ready_idx_in(RS_ready_idx),
  .RS_flag(Dis_RS_flag),
  .RS_put_idx(Dis_RS_put_idx),
  .RS_ready(Dis_RS_ready),
  .RS_ready_idx(Dis_RS_ready_idx),
  .LSB_flag(Dis_LSB_flag),
  .ROB_nex_idx(ROB_nex_idx),
  .ROB_R1(ROB_Dis_R1),
  .ROB_V1(ROB_Dis_V1),
  .ROB_R2(ROB_Dis_R2),
  .ROB_V2(ROB_Dis_V2),
  .ROB_flag(Dis_ROB_flag),
  .ROB_rs1_flag(Dis_ROB_flag1),
  .ROB_rs1_idx(Dis_ROB_rs1_idx),
  .ROB_rs2_flag(Dis_ROB_flag2),
  .ROB_rs2_idx(Dis_ROB_rs2_idx),
  .Dis_op(Dis_op),
  .Dis_imm(Dis_imm),
  .Dis_rd(Dis_rd),
  .Dis_ROB_idx(Dis_ROB_idx),
  .Dis_PC(Dis_PC),
  .Dis_R1(Dis_R1),
  .Dis_V1(Dis_V1),
  .Dis_R2(Dis_R2),
  .Dis_V2(Dis_V2)
);

ICache ICache(
  .clk(clk_in),
  .rst(rst_in),
  .rdy(rdy_in),
  .roll(roll),
  .IF_flag(IF_IC_flag),
  .IF_PC(IF_IC_PC),
  .IF_commit(IC_IF_commit),
  .IF_inst(IC_IF_inst),
  .MC_flag(MC_IC_commit),
  .MC_inst(MC_IC_data),
  .MC_commit(IC_MC_flag),
  .MC_PC(IC_MC_addr)
);

IF IF(
  .clk(clk_in),
  .rst(rst_in),
  .rdy(rdy_in),
  .IC_commit(IC_IF_commit),
  .IC_val(IC_IF_inst),
  .IC_flag(IF_IC_flag),
  .IC_PC(IF_IC_PC),
  .IQ_full(IQ_full),
  .IQ_flag(IF_IQ_flag),
  .IQ_inst(IF_IQ_inst),
  .IQ_PC(IF_IQ_PC),
  .ROB_jump_flag(ROB_IF_jump_flag),
  .ROB_jump_PC(ROB_IF_jump_PC)
);

IQ IQ(
  .clk(clk_in),
  .rst(rst_in),
  .rdy(rdy_in),
  .roll(roll),
  .IF_flag(IF_IQ_flag),
  .IF_inst(IF_IQ_inst),
  .IF_PC(IF_IQ_PC),
  .Dec_flag(Dec_flag),
  .Dec_commit(IQ_Dec_commit),
  .Dec_inst(IQ_Dec_inst),
  .Dec_PC(IQ_Dec_PC),
  .IQ_full(IQ_full)
);

decoder decoder(
  .IQ_flag(IQ_Dec_commit),
  .IQ_inst(IQ_Dec_inst),
  .IQ_PC(IQ_Dec_PC),
  .RF_R1(Dec_RF_R1),
  .RF_rs1(Dec_RF_rs1),
  .RF_R2(Dec_RF_R2),
  .RF_rs2(Dec_RF_rs2),
  .Dis_op(Dec_Dis_op),
  .Dis_rd(Dec_Dis_rd),
  .Dis_imm(Dec_Dis_imm),
  .Dis_PC(Dec_Dis_PC),
  .RS_full(RS_full),
  .LSB_full(LSB_full),
  .ROB_full(ROB_full),
  .Dec_flag(Dec_flag)
);

LSB LSB(
  .clk(clk_in),
  .rst(rst_in),
  .rdy(rdy_in),
  .roll(roll),
  .MC_flag_in(MC_LSB_commit),
  .MC_val(MC_LSB_val),
  .MC_flag(LSB_MC_flag),
  .MC_op(LSB_MC_type),
  .MC_PC(LSB_MC_addr),
  .MC_LS_len(LSB_MC_len),
  .MC_data(LSB_MC_data),
  .Dis_flag(Dis_LSB_flag),
  .Dis_op(Dis_op),
  .Dis_imm(Dis_imm),
  .Dis_ROB_idx(Dis_ROB_idx),
  .Dis_PC(Dis_PC),
  .Dis_R1(Dis_R1),
  .Dis_V1(Dis_V1),
  .Dis_R2(Dis_R2),
  .Dis_V2(Dis_V2),
  .ROB_store_flag(ROB_LSB_store_flag),
  .ROB_store_idx(ROB_LSB_store_idx),
  .ROB_from_ALU_flag(ROB_LSB_from_ALU_flag),
  .ROB_from_ALU_idx(ROB_LSB_from_ALU_idx),
  .ROB_from_ALU_val(ROB_LSB_from_ALU_val),
  .ROB_from_LSB_flag(ROB_LSB_from_LSB_flag),
  .ROB_from_LSB_idx(ROB_LSB_from_LSB_idx),
  .ROB_from_LSB_val(ROB_LSB_from_LSB_val),
  .ROB_head_flag(ROB_head_flag),
  .ROB_head(ROB_head),
  .LSB_full(LSB_full),
  .LSB_flag(LSB_flag),
  .LSB_ROB_idx(LSB_ROB_idx),
  .LSB_val(LSB_val)
);

ROB ROB(
  .clk(clk_in),
  .rst(rst_in),
  .rdy(rdy_in),
  .IF_jump_flag(ROB_IF_jump_flag),
  .IF_jump_PC(ROB_IF_jump_PC),
  .Dec_flag(Dec_flag),
  .Dis_flag(Dis_ROB_flag),
  .Dis_op(Dis_op),
  .Dis_rd(Dis_rd),
  .Dis_PC(Dis_PC),
  .Dis_flag1(Dis_ROB_flag1),
  .Dis_ROB_idx1(Dis_ROB_rs1_idx),
  .Dis_flag2(Dis_ROB_flag2),
  .Dis_ROB_idx2(Dis_ROB_rs2_idx),
  .Dis_R1(ROB_Dis_R1),
  .Dis_V1(ROB_Dis_V1),
  .Dis_R2(ROB_Dis_R2),
  .Dis_V2(ROB_Dis_V2),
  .ALU_flag(ALU_flag),
  .ALU_ROB_idx(ALU_ROB_idx),
  .ALU_val(ALU_val),
  .ALU_jump_flag(ALU_jump_flag),
  .ALU_jump_PC(ALU_jump_PC),
  .RF_write_flag(ROB_RF_flag),
  .RF_rd(ROB_RF_rd),
  .RF_ROB_idx(ROB_RF_idx),
  .RF_val(ROB_RF_val),
  .LSB_load_flag(LSB_flag),
  .LSB_load_ROB_idx(LSB_ROB_idx),
  .LSB_load_val(LSB_val),
  .LSB_store_flag(ROB_LSB_store_flag),
  .LSB_store_idx(ROB_LSB_store_idx),
  .LSB_from_ALU_flag(ROB_LSB_from_ALU_flag),
  .LSB_from_ALU_idx(ROB_LSB_from_ALU_idx),
  .LSB_from_ALU_val(ROB_LSB_from_ALU_val),
  .LSB_from_LSB_flag(ROB_LSB_from_LSB_flag),
  .LSB_from_LSB_idx(ROB_LSB_from_LSB_idx),
  .LSB_from_LSB_val(ROB_LSB_from_LSB_val),
  .ROB_head_flag(ROB_head_flag),
  .ROB_head(ROB_head),
  .ROB_full(ROB_full),
  .ROB_roll(roll),
  .ROB_nex_idx(ROB_nex_idx)
);

RF RF(
  .clk(clk_in),
  .rst(rst_in),
  .rdy(rdy_in),
  .roll(roll),
  .Dec_R1(Dec_RF_R1),
  .Dec_rs1(Dec_RF_rs1),
  .Dec_R2(Dec_RF_R2),
  .Dec_rs2(Dec_RF_rs2),
  .Dis_flag(Dis_RF_write_flag),
  .Dis_rd(Dis_rd),
  .Dis_ROB_idx(Dis_ROB_idx),
  .Dis_flag1(RF_Dis_flag1),
  .Dis_R1(RF_Dis_R1),
  .Dis_V1(RF_Dis_V1),
  .Dis_flag2(RF_Dis_flag2),
  .Dis_R2(RF_Dis_R2),
  .Dis_V2(RF_Dis_V2),
  .ROB_flag(ROB_RF_flag),
  .ROB_new_idx(ROB_RF_idx),
  .ROB_rd(ROB_RF_rd),
  .ROB_val(ROB_RF_val)
);

RS RS(
  .clk(clk_in),
  .rst(rst_in),
  .rdy(rdy_in),
  .roll(roll),
  .Dec_flag(Dec_flag),
  .Dis_flag(Dis_RS_flag),
  .Dis_idx(Dis_RS_put_idx),
  .Dis_op(Dis_op),
  .Dis_imm(Dis_imm),
  .Dis_ROB_idx(Dis_ROB_idx),
  .Dis_PC(Dis_PC),
  .Dis_Rj(Dis_R1),
  .Dis_Vj(Dis_V1),
  .Dis_Rk(Dis_R2),
  .Dis_Vk(Dis_V2),
  .Dis_ready_flag(Dis_RS_ready),
  .Dis_ready_idx(Dis_RS_ready_idx),
  .ALU_flag(ALU_flag),
  .ALU_ROB_idx(ALU_ROB_idx),
  .ALU_val(ALU_val),
  .ALU_commit(RS_ALU_flag),
  .ALU_op(RS_ALU_op),
  .ALU_Vj(RS_ALU_Vj),
  .ALU_Vk(RS_ALU_Vk),
  .ALU_idx(RS_ALU_idx),
  .ALU_imm(RS_ALU_imm),
  .ALU_PC(RS_ALU_PC),
  .LSB_flag(LSB_flag),
  .LSB_ROB_idx(LSB_ROB_idx),
  .LSB_val(LSB_val),
  .RS_full(RS_full),
  .RS_free_idx(RS_free_idx),
  .RS_ready_flag(RS_ready_flag),
  .RS_ready_idx(RS_ready_idx)
);

alu alu(
  .clk(clk_in),
  .rst(rst_in),
  .rdy(rdy_in),
  .roll(roll),
  .RS_flag(RS_ALU_flag),
  .RS_op(RS_ALU_op),
  .RS_Vj(RS_ALU_Vj),
  .RS_Vk(RS_ALU_Vk),
  .RS_idx(RS_ALU_idx),
  .RS_imm(RS_ALU_imm),
  .RS_PC(RS_ALU_PC),
  .ALU_flag(ALU_flag),
  .ALU_ROB_idx(ALU_ROB_idx),
  .ALU_val(ALU_val),
  .ALU_jump_flag(ALU_jump_flag),
  .ALU_jump_PC(ALU_jump_PC)
);

endmodule