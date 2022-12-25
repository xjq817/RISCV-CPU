`define LUI   6'b000001
`define AUIPC 6'b000010
`define JAL	  6'b000011
`define JALR  6'b000100
`define BEQ   6'b000101
`define BNE   6'b000110
`define BLT   6'b000111
`define BGE   6'b001000
`define BLTU  6'b001001
`define BGEU  6'b001010
`define LB    6'b001011
`define LH    6'b001100
`define LW    6'b001101
`define LBU   6'b001110
`define LHU   6'b001111
`define SB    6'b010000
`define SH    6'b010001
`define SW    6'b010010
`define ADDI  6'b010011
`define SLTI  6'b010100
`define SLTIU 6'b010101
`define XORI  6'b010110
`define ORI   6'b010111
`define ANDI  6'b011000
`define SLLI  6'b011001
`define SRLI  6'b011010
`define SRAI  6'b011011
`define ADD   6'b011100
`define SUB   6'b011101
`define SLL   6'b011110
`define SLT   6'b011111
`define SLTU  6'b100000
`define XOR   6'b100001
`define SRL   6'b100010
`define SRA   6'b100011
`define OR    6'b100100
`define AND   6'b100101

`define LUIOP       7'b0110111
`define AUIPCOP     7'b0010111
`define JALOP       7'b1101111
`define JALROP      7'b1100111
`define BRANCHOP    7'b1100011
`define LOADOP      7'b0000011
`define STOREOP     7'b0100011
`define CALCIOP     7'b0010011
`define CALCOP      7'b0110011

`define ROB_INDEX_RANGE     3:0
`define ROB_INDEX           15:0
`define ROB_SIZE            16
`define RS_INDEX_RANGE      3:0
`define RS_INDEX            15:0
`define RS_SIZE             16
`define LSB_INDEX_RANGE     3:0
`define LSB_INDEX           15:0
`define LSB_SIZE            16
`define REG_INDEX_RANGE     4:0
`define REG_INDEX           31:0
`define REG_SIZE            32
`define IC_INDEX_RANGE      7:0
`define IC_INDEX            255:0
`define IC_TAG_INDEX        23:0
`define IC_TAG              31:8
`define IC_SIZE             256
`define IQ_INDEX_RANGE      3:0
`define IQ_INDEX            15:0
`define IQ_SIZE             16

`define FALSE   1'b0
`define TRUE    1'b1