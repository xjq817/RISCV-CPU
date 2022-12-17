`include "define.v"

module alu(
    input  wire  clk,
    input  wire  rst,
    input  wire  rdy,
//RS
    input  wire                     RS_flag_in,
    input  wire [5:0]               RS_op_in,
    input  wire [31:0]              RS_val1_in,
    input  wire [31:0]              RS_val2_in,
    input  wire [`ROB_INDEX_RANGE]  RS_idx_in_ROB_in,
//CDB
    output reg                      CDB_flag_out,
    output reg  [31:0]              CDB_val_out,
    output reg  [`ROB_INDEX_RANGE]  CDB_idx_in_ROB_out,
);
    always @(*) begin
        if (RS_flag_in) begin
            CDB_flag_out = `True;
            CDB_idx_out = RS_idx_in_ROB_in;
            case (insty)
                `ADD   : CDB_val_out = RS_val1_in + RS_val2_in;
                `ADDI  : CDB_val_out = RS_val1_in + RS_val2_in;
                `SUB   : CDB_val_out = RS_val1_in - RS_val2_in;
                `XOR   : CDB_val_out = RS_val1_in ^ RS_val2_in;
                `XORI  : CDB_val_out = RS_val1_in ^ RS_val2_in;
                `OR    : CDB_val_out = RS_val1_in | RS_val2_in;
                `ORI   : CDB_val_out = RS_val1_in | RS_val2_in;
                `AND   : CDB_val_out = RS_val1_in & RS_val2_in;
                `ANDI  : CDB_val_out = RS_val1_in & RS_val2_in;
                `SLL   : CDB_val_out = RS_val1_in << RS_val2_in[4:0];
                `SLLI  : CDB_val_out = RS_val1_in << RS_val2_in[4:0];
                `SRL   : CDB_val_out = RS_val1_in >> RS_val2_in[4:0];
                `SRLI  : CDB_val_out = RS_val1_in >> RS_val2_in[4:0];
                `SRA   : CDB_val_out = $signed(RS_val1_in) >> RS_val2_in[4:0];
                `SRAI  : CDB_val_out = $signed(RS_val1_in) >> RS_val2_in[4:0];
                `SLT   : CDB_val_out = $signed(RS_val1_in) < $signed(RS_val2_in);
                `SLTI  : CDB_val_out = $signed(RS_val1_in) < $signed(RS_val2_in);
                `SLTU  : CDB_val_out = RS_val1_in < RS_val2_in;
                `SLTIU : CDB_val_out = RS_val1_in < RS_val2_in;
                `BEQ   : CDB_val_out = RS_val1_in == RS_val2_in;
                `BNE   : CDB_val_out = RS_val1_in != RS_val2_in;
                `BLT   : CDB_val_out = $signed(RS_val1_in) < $signed(RS_val2_in);
                `BGE   : CDB_val_out = $signed(RS_val1_in) >= $signed(RS_val2_in);
                `BLTU  : CDB_val_out = RS_val1_in < RS_val2_in;
                `BGEU  : CDB_val_out = RS_val1_in >= RS_val2_in;
                `JALR  : CDB_val_out = (RS_val1_in + RS_val2_in) & ~(32'b1);
                default: CDB_val_out = `ZERO32;
            endcase
        end
        else begin
            CDB_flag_out = `FALSE;
            CDB_idx_in_ROB_out = `ZERO4;
            CDB_val_out = `ZERO32;
        end
    end

endmodule