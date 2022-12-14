`include "header.v"

module decoder(
    input  wire         IF_issue_in,
    input  wire [31:0]  IF_inst_in,

    input  wire [31:0]              Vj_in,
    input  wire [31:0]              Vk_in,
    input  wire [`ROB_TAG_RANGE]    Qj_in,
    input  wire [`ROB_TAG_RANGE]    Qk_in,
    
    output wire [`REG_INDEX_RANGE]  rs1_out,
    output wire [`REG_INDEX_RANGE]  rs2_out,
    output wire [`REG_INDEX_RANGE]  rd_out,

    output reg  [31:0]  imm_out,
    output reg  [5:0]   op_out,
);

    wire [31:0] immI, immS, immB, immU, immJ;
    assign immI = {{20{IF_inst_in[31]}}, IF_inst_in[31:20]};
    assign immS = {{20{IF_inst_in[31]}}, IF_inst_in[31:25], IF_inst_in[11:7]};
    assign immB = {{20{IF_inst_in[31]}}, IF_inst_in[7], IF_inst_in[30:25], IF_inst_in[11:8], 1'b0};
    assign immU = {IF_inst_in[31:12], 12'b0};
    assign immJ = {{12{IF_inst_in[31]}}, IF_inst_in[19:12], IF_inst_in[20], IF_inst_in[30:21], 1'b0};

    assign rs1_out = IF_inst_in[19:15];
    assign rs2_out = IF_inst_in[24:20];
    assign rd_out = IF_inst_in[11:7];

    always @(*) begin
        if (IF_issue_in) begin
            case (IF_inst_in[6:0])
                `LUI_OPCODE: begin
                    immOut = immU;
                    op_out  = `LUI;
                end
                `AUIPC_OPCODE: begin
                    imm_out = immU;
                    op_out  = `AUIPC;
                end
                `JAL_OPCODE: begin
                    imm_out = immJ;
                    op_out  = `JAL;
                end
                `JALR_OPCODE: begin
                    imm_out = immI;
                    op_out  = `JALR;
                end
                `BRANCH_OPCODE: begin
                    imm_out = immB;
                    case (IF_inst_in[14:12])
                        `BEQ_FUNCT3:  begin op_out = `BEQ;  end
                        `BNE_FUNCT3:  begin op_out = `BNE;  end
                        `BLT_FUNCT3:  begin op_out = `BLT;  end
                        `BGE_FUNCT3:  begin op_out = `BGE;  end
                        `BLTU_FUNCT3: begin op_out = `BLTU; end
                        `BGEU_FUNCT3: begin op_out = `BGEU; end
                    endcase
                end
                `LOAD_OPCODE: begin
                    imm_out = immI;
                    case (IF_inst_in[14:12])
                        `LB_FUNCT3:  begin op_out = `LB;  lsb_goal_out = 3'b001; end
                        `LH_FUNCT3:  begin op_out = `LH;  lsb_goal_out = 3'b010; end
                        `LW_FUNCT3:  begin op_out = `LW;  lsb_goal_out = 3'b100; end
                        `LBU_FUNCT3: begin op_out = `LBU; lsb_goal_out = 3'b001; end
                        `LHU_FUNCT3: begin op_out = `LHU; lsb_goal_out = 3'b010; end
                    endcase
                end
                `STORE_OPCODE: begin
                    imm_out = immS;
                    case (IF_inst_in[14:12])
                        `SB_FUNCT3: begin op_out = `SB; lsb_goal_out = 3'b001; end
                        `SH_FUNCT3: begin op_out = `SH; lsb_goal_out = 3'b010; end
                        `SW_FUNCT3: begin op_out = `SW; lsb_goal_out = 3'b100; end
                    endcase
                end
                `ARITH_IMM_OPCODE: begin
                    imm_out = immI;
                    case (IF_inst_in[14:12])
                        `ADDI_FUNCT3:  begin op_out = `ADDI;  end
                        `SLTI_FUNCT3:  begin op_out = `SLTI;  end
                        `SLTIU_FUNCT3: begin op_out = `SLTIU; end
                        `XORI_FUNCT3:  begin op_out = `XORI;  end
                        `ORI_FUNCT3:   begin op_out = `ORI;   end
                        `ANDI_FUNCT3:  begin op_out = `ANDI;  end
                        `SLLI_FUNCT3:  begin op_out = `SLLI;  end
                        `SRxI_FUNCT3:  begin
                            if (IF_inst_in[31:25] == `ZERO_FUNCT7) op_out = `SRLI;
                            else op_out = `SRAI;
                        end
                    endcase
                end
                `ARITH_OPCODE: begin
                    imm_out = `ZERO_WORD;
                    case (IF_inst_in[14:12])
                        `AS_FUNCT3:   begin
                            if (IF_inst_in[31:25] == `ZERO_FUNCT7) op_out = `ADD;
                            else op_out = `SUB;
                        end
                        `SLL_FUNCT3:  begin op_out = `SLL;  end
                        `SLT_FUNCT3:  begin op_out = `SLT;  end
                        `SLTU_FUNCT3: begin op_out = `SLTU; end
                        `XOR_FUNCT3:  begin op_out = `XOR;  end
                        `SRx_FUNCT3:  begin
                            if (IF_inst_in[31:25] == `ZERO_FUNCT7) op_out = `SRL;
                            else op_out = `SRA;
                        end
                        `OR_FUNCT3:   begin op_out = `OR;   end
                        `AND_FUNCT3:  begin op_out = `AND;  end
                    endcase
                end
            endcase
        end
    end
endmodule