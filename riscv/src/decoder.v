`include "define.v"

module decoder(
    input  wire  clk,
    input  wire  rst,
    input  wire  rdy,
    input  wire  jump_wrong,
//IF
    input  wire         IF_inst_flag_in,
    input  wire [31:0]  IF_inst_in,
    input  wire         IF_jump_flag_in,
    input  wire [31:0]  IF_PC_in,
    output wire         IF_flag_out,
//RF
    input  wire                     RF_rs1_flag_in,
    input  wire [31:0]              RF_rs1_in,
    input  wire                     RF_rs2_flag_in,
    input  wire [31:0]              RF_rs2_in,
//RS
    output reg  RS_inst_flag_out,
//LSB
    input  wire        LSB_full_in,
    output wire [2:0]  LSB_op_out,
    output reg         LSB_inst_flag_out,
//ROB
    input  wire         ROB_full_in,
    input  wire         ROB_rs1_ready_in,
    input  wire [31:0]  ROB_rs1_in,
    input  wire         ROB_rs2_ready_in,
    input  wire [31:0]  ROB_rs2_in,
    output reg          ROB_inst_flag_out,
    output reg          ROB_inst_out,
    output reg          ROB_jump_flag_out,
    output reg [31:0]   ROB_PC_out,
//for all
    output reg  [`REG_INDEX_RANGE]  rs1_out,
    output wire                     rs1_ready_out,
    output wire [31:0]              rs1_val_out,
    output reg  [`REG_INDEX_RANGE]  rs2_out,
    output wire                     rs2_ready_out,
    output wire [31:0]              rs2_val_out,
    output reg  [31:0]              imm_out,
    output reg  [`REG_INDEX_RANGE]  rd_out,
    output reg  [5:0]               inst_out,
);
    reg  [31:0] now_inst;
    wire [6:0]  opcode;
    
    assign opcode = now_inst[6:0];

    assign rs1_ready_out = RF_rs1_flag_in ? `TRUE : ROB_rs1_ready_in;
    assign rs2_ready_out = RF_rs2_flag_in ? `TRUE : ROB_rs2_ready_in;
    assign rs1_val_out = RF_rs1_flag_in ? RF_rs1_in : ROB_rs1_in;
    assign rs2_val_out = RF_rs2_flag_in ? RF_rs2_in : ROB_rs2_in;
    
    assign IF_flag_out = ROB_full_in || LSB_full_in;

    assign LSB_inst_flag_out = inst_out[2:0];

    always @(posedge clk) begin
        if (rst || jump_wrong || !IF_inst_flag_in || ROB_full_in || LSB_full_in) begin
            now_inst <= `ZERO32;
            ROB_inst_flag_out <= `FALSE;
            ROB_jump_flag_out <= `FALSE;
            ROB_PC_out <= `ZERO32;
        end else if (rdy) begin
            now_inst <= IF_inst_in;
            ROB_inst_flag_out <= `TRUE;
            ROB_jump_flag_out <= IF_jump_flag_in;
            ROB_PC_out <= IF_PC_in;
        end
    end

    always @(*) begin
        if (ROB_inst_flag_out) begin
            case (opcode)
                
            endcase
            LSB_inst_flag_out = ;
            rd_out = ;
            rs1_out = ;
            rs2_out = ;
        end else begin
            LSB_inst_flag_out = `FALSE;
            RS_inst_flag_out = `FALSE;
            rd_out = 5'b0;
            rs1_out = 5'b0;
            rs2_out = 5'b0;
            inst_out = `ZERO6;
            imm_out = `ZERO32;
        end
    end
    
endmodule