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
//for all
    output reg                      flag_out,
    output reg  [31:0]              val_out,
    output reg  [`ROB_INDEX_RANGE]  idx_in_ROB_out,
);
    always @(*) begin
        if (RS_flag_in) begin
            flag_out = `True;
            idx_out = RS_idx_in_ROB_in;
            case (insty)
                `ADD   : val_out = RS_val1_in + RS_val2_in;
                `ADDI  : val_out = RS_val1_in + RS_val2_in;
                `SUB   : val_out = RS_val1_in - RS_val2_in;
                `XOR   : val_out = RS_val1_in ^ RS_val2_in;
                `XORI  : val_out = RS_val1_in ^ RS_val2_in;
                `OR    : val_out = RS_val1_in | RS_val2_in;
                `ORI   : val_out = RS_val1_in | RS_val2_in;
                `AND   : val_out = RS_val1_in & RS_val2_in;
                `ANDI  : val_out = RS_val1_in & RS_val2_in;
                `SLL   : val_out = RS_val1_in << RS_val2_in[4:0];
                `SLLI  : val_out = RS_val1_in << RS_val2_in[4:0];
                `SRL   : val_out = RS_val1_in >> RS_val2_in[4:0];
                `SRLI  : val_out = RS_val1_in >> RS_val2_in[4:0];
                `SRA   : val_out = $signed(RS_val1_in) >> RS_val2_in[4:0];
                `SRAI  : val_out = $signed(RS_val1_in) >> RS_val2_in[4:0];
                `SLT   : val_out = $signed(RS_val1_in) < $signed(RS_val2_in);
                `SLTI  : val_out = $signed(RS_val1_in) < $signed(RS_val2_in);
                `SLTU  : val_out = RS_val1_in < RS_val2_in;
                `SLTIU : val_out = RS_val1_in < RS_val2_in;
                `BEQ   : val_out = RS_val1_in == RS_val2_in;
                `BNE   : val_out = RS_val1_in != RS_val2_in;
                `BLT   : val_out = $signed(RS_val1_in) < $signed(RS_val2_in);
                `BGE   : val_out = $signed(RS_val1_in) >= $signed(RS_val2_in);
                `BLTU  : val_out = RS_val1_in < RS_val2_in;
                `BGEU  : val_out = RS_val1_in >= RS_val2_in;
                `JALR  : val_out = (RS_val1_in + RS_val2_in) & ~(32'b1);
                default: val_out = `ZERO32;
            endcase
        end
        else begin
            flag_out = `FALSE;
            idx_in_ROB_out = `ZERO4;
            val_out = `ZERO32;
        end
    end

endmodule