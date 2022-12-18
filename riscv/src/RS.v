`include "define.v"

module RS(
    input  wire  clk,
    input  wire  rst,
    input  wire  rdy,
    input  wire  jump_wrong,
//alu
    input  wire                     alu_flag_in,
    input  wire [31:0]              alu_val_in,
    input  wire [`ROB_INDEX_RANGE]  alu_to_ROB_in,
//LSB
    input  wire                     LSB_flag_in,
    input  wire [31:0]              LSB_val_in,
    input  wire [`ROB_INDEX_RANGE]  LSB_to_ROB_in,
//decoder
    input  wire         Dec_inst_flag_in,
    input  wire [5:0]   Dec_inst,
    input  wire         Dec_rs1_flag_in,
    input  wire         Dec_rs2_flag_in,
    input  wire [31:0]  Dec_rs1_in,  //ROB idx if flag == false
    input  wire [31:0]  Dec_rs2_in,
    input  wire [31:0]  Dec_imm,
//ROB
    input  wire [`ROB_INDEX_RANGE]  ROB_idx_in,
//for all
    output reg                      flag_out,
    output reg  [31:0]              val_out,
    output reg  [`ROB_INDEX_RANGE]  to_ROB_out,
);
    reg [5:0]              inst[`RS_INDEX];
    reg [`RS_INDEX]        busy;
    reg [31:0]             val1[`RS_INDEX];  //ROB idx if flag == false
    reg [31:0]             val2[`RS_INDEX];
    reg [`RS_INDEX]        flag1;  //is busy
    reg [`RS_INDEX]        flag2;
    reg [`ROB_INDEX_RANGE] ROB_idx[`RS_INDEX];

    reg [31:0] inst_vj;
    reg [31:0] inst_vk;
    reg        inst_qj;
    reg        inst_qk;

    wire [`RS_INDEX] free_RS_idx;
    wire [`RS_INDEX] calc_RS_idx;

    reg [5:0]              alu_inst;
    reg [31:0]             alu_vj;
    reg [31:0]             alu_vk;
    reg [`ROB_INDEX_RANGE] dest;

    integer i;

    assign free_RS_idx = (~busy) & (-(~busy));
    assign calc_RS_idx = (busy & flag1 & flag1) & 
                         (-((busy & flag1 & flag1)));

    always @(*) begin
        if (calc_RS_idx != 0) begin
            flag_out = `TRUE;
            to_ROB_out = dest;
            case (alu_inst)
                `ADD   : val_out = alu_vj + alu_vk;
                `ADDI  : val_out = alu_vj + alu_vk;
                `SUB   : val_out = alu_vj - alu_vk;
                `XOR   : val_out = alu_vj ^ alu_vk;
                `XORI  : val_out = alu_vj ^ alu_vk;
                `OR    : val_out = alu_vj | alu_vk;
                `ORI   : val_out = alu_vj | alu_vk;
                `AND   : val_out = alu_vj & alu_vk;
                `ANDI  : val_out = alu_vj & alu_vk;
                `SLL   : val_out = alu_vj << alu_vk[4:0];
                `SLLI  : val_out = alu_vj << alu_vk[4:0];
                `SRL   : val_out = alu_vj >> alu_vk[4:0];
                `SRLI  : val_out = alu_vj >> alu_vk[4:0];
                `SRA   : val_out = $signed(alu_vj) >> alu_vk[4:0];
                `SRAI  : val_out = $signed(alu_vj) >> alu_vk[4:0];
                `SLT   : val_out = $signed(alu_vj) < $signed(alu_vk);
                `SLTI  : val_out = $signed(alu_vj) < $signed(alu_vk);
                `SLTU  : val_out = alu_vj < alu_vk;
                `SLTIU : val_out = alu_vj < alu_vk;
                `BEQ   : val_out = alu_vj == alu_vk;
                `BNE   : val_out = alu_vj != alu_vk;
                `BLT   : val_out = $signed(alu_vj) < $signed(alu_vk);
                `BGE   : val_out = $signed(alu_vj) >= $signed(alu_vk);
                `BLTU  : val_out = alu_vj < alu_vk;
                `BGEU  : val_out = alu_vj >= alu_vk;
                `JALR  : val_out = (alu_vj + alu_vk) & ~(32'b1);
                default: val_out = `ZERO32;
            endcase
        end
        else begin
            flag_out = `FALSE;
            val_out = `ZERO32;
            to_ROB_out = `ZERO4;
        end
    end

    always @(*) begin
        if (!Dec_rs1_flag_in) begin
            if (alu_flag_in && alu_to_ROB_in == Dec_rs1_in[`ROB_INDEX_RANGE]) begin
                inst_qj = `TRUE;
                inst_vj = alu_val_in;
            end else if (LSB_flag_in && LSB_to_ROB_in == Dec_rs1_in[`ROB_INDEX_RANGE]) begin
                inst_qj = `TRUE;
                inst_vj = LSB_val_in;
            end else begin
                inst_qj = `FALSE;
                inst_vj = Dec_rs1_in;
            end
        end else begin
            inst_qj = `TRUE;
            inst_vj = Dec_rs1_in;
        end
        
        if (!Dec_rs2_flag_in) begin
            if (alu_flag_in && alu_to_ROB_in == Dec_rs2_in[`ROB_INDEX_RANGE]) begin
                inst_qk = `TRUE;
                inst_vk = alu_val_in;
            end else if (LSB_flag_in && LSB_to_ROB_in == Dec_rs2_in[`ROB_INDEX_RANGE]) begin
                inst_qk = `TRUE;
                inst_vk = LSB_val_in;
            end else begin
                inst_qk = `FALSE;
                inst_vk = Dec_rs2_in;
            end
        end else begin
            inst_qk = `TRUE;
            inst_vk = Dec_rs2_in;
        end

        alu_inst = `ZERO6;
        alu_vj = `ZERO32;
        alu_vk = `ZERO32;
        dest = 0;
        for (i = 0; i < `RS_SIZE; i = i + 1) begin
            if (calc_RS_idx[i]) begin
                alu_inst = inst[i];
                alu_vj = val1[i];
                alu_vk = val2[i];
                dest = ROB_idx[i];
            end
        end
    end

    always @(posedge clk) begin
        if (rst || jump_wrong) begin
            busy <= `ZERO16;
        end else if (!rdy) begin
            if (Dec_flag_in) begin
                for (i = 0; i < `RS_SIZE; i = i + 1) begin
                    if (free_RS_idx[i]) begin
                        busy[i] <= `TRUE;
                        inst[i] <= Dec_inst;
                        val1[i] <= inst_vj;
                        flag1[i] <= inst_qj;
                        val2[i] <= inst_vj;
                        flag2[i] <= inst_qj;
                        ROB_idx[i] <= ROB_idx_in;
                    end
                end
            end

            for (i = 0; i < `RS_SIZE; i = i + 1) begin
                if (calc_RS_idx[i]) begin
                    busy[i] = `FALSE;
                end
            end

            for (i = 0; i < `RS_SIZE; i = i + 1) begin
                if (busy[i]) begin
                    if (alu_flag_in) begin
                        if (!flag1[i] && val1[i][`ROB_INDEX_RANGE] == alu_to_ROB_in) begin
                            flag1[i] <= `TRUE;
                            val1[i] <= alu_val_in;
                        end
                        if (!flag2[i] && val2[i][`ROB_INDEX_RANGE] == alu_to_ROB_in) begin
                            flag2[i] <= `TRUE;
                            val2[i] <= alu_val_in;
                        end
                    end
                    if (LSB_flag_in) begin
                        if (!flag1[i] && val1[i][`ROB_INDEX_RANGE] == LSB_to_ROB_in) begin
                            flag1[i] <= `TRUE;
                            val1[i] <= LSB_val_in;
                        end
                        if (!flag2[i] && val2[i][`ROB_INDEX_RANGE] == LSB_to_ROB_in) begin
                            flag2[i] <= `TRUE;
                            val2[i] <= LSB_val_in;
                        end
                    end
                end
            end
        end
    end

endmodule