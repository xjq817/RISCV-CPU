//constants
`define ZERO_WORD                 32'b0

//range
`define ROB_TAG_RANGE    1:0
`define REG_INDEX_RANGE  4:0

//opcode
`define LUI_OPCODE         7'b0110111
`define AUIPC_OPCODE       7'b0010111
`define JAL_OPCODE         7'b1101111
`define JALR_OPCODE        7'b1100111
`define BRANCH_OPCODE      7'b1100011
`define LOAD_OPCODE        7'b0000011
`define STORE_OPCODE       7'b0100011
`define ARITH_IMM_OPCODE   7'b0010011
`define ARITH_OPCODE       7'b0110011

//funct3
`define ZERO_FUNCT3    3'b000
`define JALR_FUNCT3    3'b000
`define BEQ_FUNCT3     3'b000
`define BNE_FUNCT3     3'b001
`define BLT_FUNCT3     3'b100
`define BGE_FUNCT3     3'b101
`define BLTU_FUNCT3    3'b110
`define BGEU_FUNCT3    3'b111
`define LB_FUNCT3      3'b000
`define LH_FUNCT3      3'b001
`define LW_FUNCT3      3'b010
`define LBU_FUNCT3     3'b100
`define LHU_FUNCT3     3'b101
`define SB_FUNCT3      3'b000
`define SH_FUNCT3      3'b001
`define SW_FUNCT3      3'b010
`define ADDI_FUNCT3    3'b000
`define SLTI_FUNCT3    3'b010
`define SLTIU_FUNCT3   3'b011
`define XORI_FUNCT3    3'b100
`define ORI_FUNCT3     3'b110
`define ANDI_FUNCT3    3'b111
`define SLLI_FUNCT3    3'b001
`define SRxI_FUNCT3    3'b101
`define AS_FUNCT3      3'b000
`define SLL_FUNCT3     3'b001
`define SLT_FUNCT3     3'b010
`define SLTU_FUNCT3    3'b011
`define XOR_FUNCT3     3'b100
`define SRx_FUNCT3     3'b101
`define OR_FUNCT3      3'b110
`define AND_FUNCT3     3'b111

//funct7
`define ZERO_FUNCT7   7'b0000000
`define ONE_FUNCT7    7'b0100000

//INST
`define NOP     6'h0
`define LUI     6'h1
`define AUIPC   6'h2
`define JAL     6'h3
`define JALR    6'h4
`define BEQ     6'h5
`define BNE     6'h6
`define BLT     6'h7
`define BGE     6'h8
`define BLTU    6'h9
`define BGEU    6'hA
`define LB      6'hB
`define LH      6'hC
`define LW      6'hD
`define LBU     6'hE
`define LHU     6'hF
`define SB      6'h10
`define SH      6'h11
`define SW      6'h12
`define ADDI    6'h13
`define SLTI    6'h14
`define SLTIU   6'h15
`define XORI    6'h16
`define ORI     6'h17
`define ANDI    6'h18
`define SLLI    6'h19
`define SRLI    6'h1A
`define SRAI    6'h1B
`define ADD     6'h1C
`define SUB     6'h1D
`define SLL     6'h1E
`define SLT     6'h1F
`define SLTU    6'h20
`define XOR     6'h21
`define SRL     6'h22
`define SRA     6'h23
`define OR      6'h24
`define AND     6'h25