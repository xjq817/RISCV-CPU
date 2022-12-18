//constants
`define TRUE      1'b1
`define FALSE     1'b0
`define ZERO4     4'b0
`define ZERO6     6'b0
`define ZERO16    16'b0
`define ZERO32    32'b0

//range
`define ROB_INDEX_RANGE    3:0
`define ROB_INDEX          15:0
`define REG_INDEX_RANGE    4:0
`define REG_INDEX          31:0
`define RS_INDEX_RANGE     3:0
`define RS_INDEX           15:0
`define BHB_INDEX_RANGE    10:2
`define BHB_INDEX          511:0
`define IC_INDEX_RANGE     10:2
`define IC_INDEX           511:0
`define IC_TAG_RANGE       17:11

//size
`define RS_SIZE     16
`define ROB_SIZE    16
`define REG_SIZE    32
`define BHB_SIZE    512
`define IC_SIZE     512

//opcode
`define NOP         6'h0
`define LUI         6'h1
`define AUIPC       6'h2
`define JAL         6'h3
`define JALR        6'h4
`define BEQ         6'h5
`define BNE         6'h6
`define BLT         6'h7
`define BGE         6'h8
`define BLTU        6'h9
`define BGEU        6'hA
`define LB          6'hB
`define LH          6'hC
`define LW          6'hD
`define LBU         6'hE
`define LHU         6'hF
`define SB          6'h10
`define SH          6'h11
`define SW          6'h12
`define ADDI        6'h13
`define SLTI        6'h14
`define SLTIU       6'h15
`define XORI        6'h16
`define ORI         6'h17
`define ANDI        6'h18
`define SLLI        6'h19
`define SRLI        6'h1A
`define SRAI        6'h1B
`define ADD         6'h1C
`define SUB         6'h1D
`define SLL         6'h1E
`define SLT         6'h1F
`define SLTU        6'h20
`define XOR         6'h21
`define SRL         6'h22
`define SRA         6'h23
`define OR          6'h24
`define AND         6'h25
`define JALOP       7'b1101111
`define JALROP      7'b1100111
`define LUIOP       7'b0110111
`define AUIPCOP     7'b0010111
`define BRANCHOP    7'b1100011