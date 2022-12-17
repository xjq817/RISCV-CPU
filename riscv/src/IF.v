`include "define.v"

module IF(
    input  wire  clk,
    input  wire  rst,
    input  wire  rdy,
    input  wire  jump_wrong,
//Icache
    input  wire         IC_flag_in,
    input  wire [31:0]  IC_inst_in,
    output reg  [31:0]  IC_PC_out,
//decoder
    input  wire         Dec_flag_in,
    output wire         Dec_inst_flag_out,
    output wire [31:0]  Dec_inst_out,
    output reg          Dec_jump_flag_out,
    output reg  [31:0]  Dec_jump_PC_out,
//ROB
    input  wire [31:0]  ROB_jump_PC_in,
);

    reg [31:0] imm;
    wire [6:0] opcode;
    reg [31:0] PC;

    assign opcode = IC_inst_in[6:0];
    assign Dec_inst_flag_out = IC_flag_in;
    assign Dec_inst_out = IC_inst_in;

    always @(*) begin
        case (opcode)
            `AUIPCOP: imm = {IC_inst_in[31:12], 12'b0};
            `LUIOP  : imm = {IC_inst_in[31:12], 12'b0};                                 
            `JALROP : imm = {{20{IC_inst_in[31]}}, IC_inst_in[31:20]};
            `JALOP  : imm = {{12{IC_inst_in[31]}}, IC_inst_in[19:12], IC_inst_in[20], IC_inst_in[30:21]} << 1;
            default : imm = {{20{IC_inst_in[31]}}, IC_inst_in[7], IC_inst_in[30:25], IC_inst_in[11:8]} << 1;  
        endcase
    end

    always @(*) begin
        if (!IC_flag_in || Dec_flag_in) begin
            IC_PC_out = PC;
            Dec_jump_flag_out = `FALSE;
            Dec_jump_PC_out = `ZERO32; 
        end
        else begin
            case (opcode)
                `BRANCHOP: begin
                    IC_PC_out = PC + 4;
                    Dec_jump_flag_out = `FALSE;
                    Dec_jump_PC_out = PC + imm;
                end 
                `JALOP: begin
                    IC_PC_out = PC + imm;
                    Dec_jump_flag_out = `TRUE;
                    Dec_jump_PC_out = PC + 4;
                end
                `JALROP: begin
                    IC_PC_out = PC + 4;
                    Dec_jump_flag_out = `TRUE;
                    Dec_jump_PC_out = PC + 4;
                end
                `LUIOP: begin
                    IC_PC_out = PC + 4;
                    Dec_jump_flag_out = `TRUE;
                    Dec_jump_PC_out = imm;
                end
                default:  begin
                    IC_PC_out = PC + 4;
                    Dec_jump_flag_out = `TRUE;
                    Dec_jump_PC_out = PC + imm;
                end
            endcase
        end
    end

    integer i;
    always @(posedge clk) begin
        if (rst) begin
            PC <= `ZERO32;
        end else if (!rdy) begin
        end else if (jump_wrong) begin
            PC <= ROB_jump_PC_in;
        end else if (IC_flag_in && !Dec_flag_in) begin
            case (opcode)
                `JALOP    : PC <= PC + imm;
                default   : PC <= PC + 4;
            endcase
        end
    end

endmodule