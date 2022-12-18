`include "header.v"

module ROB(
    input  wire  clk,
    input  wire  rst,
    input  wire  rdy,
    output reg   jump_wrong,
//decoder
    input  wire [5:0]               Dec_inst_in,
    input  wire                     Dec_inst_flag_in,
    input  wire                     Dec_jump_flag_in,
    input  wire [`REG_INDEX_RANGE]  Dec_rd_in,
    input  wire [31:0]              Dec_PC_in,
    output wire                     Dec_ROB_full_out,
    output wire [31:0]              Dec_rs1_out,
    output wire                     Dec_rs1_flag_out,
    output wire [31:0]              Dec_rs2_out,
    output wire                     Dec_rs2_flag_out,
//IF
    output reg  [31:0]  IF_jump_PC_out,
//RS
    input  wire                     RS_flag_in,
    input  wire [31:0]              RS_val_in,
    input  wire [`ROB_INDEX_RANGE]  RS_ROB_idx_in,
//LSB
    input  wire                     LSB_flag_in,
    input  wire [31:0]              LSB_val_in,
    input  wire [`ROB_INDEX_RANGE]  LSB_ROB_idx_in,
//RF
    input  wire [`ROB_INDEX_RANGE]  RF_rs1_idx_in,
    input  wire [`ROB_INDEX_RANGE]  RF_rs2_idx_in,
    output wire                     RF_new_flag_out,
    output wire [`ROB_INDEX_RANGE]  RF_new_idx_out,
    output wire [`REG_INDEX_RANGE]  RF_new_rd_out,
    output wire                     RF_write_flag_out,
    output wire [`ROB_INDEX_RANGE]  RF_write_idx_out,
    output wire [`REG_INDEX_RANGE]  RF_write_rd_out,
    output wire [31:0]              RF_val_out,
);

    reg [31:0]             val   [`ROB_INDEX];
    reg [`REG_INDEX_RANGE] RF_idx[`ROB_INDEX];
    reg [5:0]              inst  [`ROB_INDEX];
    reg [`ROB_INDEX]       ready;
    reg [`ROB_INDEX]       jump_flag;

    reg  [`ROB_INDEX_RANGE] head;
    reg  [`ROB_INDEX_RANGE] tail;
    wire [`ROB_INDEX_RANGE] head_next;
    wire [`ROB_INDEX_RANGE] tail_next;

    reg                    jalr_flag;
    reg [`ROB_INDEX_RANGE] jalr_idx;
    reg [31:0]             jalr_PC;

    assign head_next = head == `ROB_SIZE - 1 ? 0 : head + 1;
    assign tail_next = tail == `ROB_SIZE - 1 ? 0 : tail + 1;

    assign Dec_rs1_flag_out = ready[RF_rs1_idx_in];
    assign Dec_rs2_flag_out = ready[RF_rs2_idx_in];
    assign Dec_rs1_out = 
        flag[RF_rs1_idx_in] ? val[RF_rs1_idx_in] : RF_rs1_idx_in;
    assign Dec_rs2_out = 
        flag[RF_rs2_idx_in] ? val[RF_rs2_idx_in] : RF_rs2_idx_in;
    assign Dec_ROB_full_out = head == tail_next;

    assign RF_new_flag_out = 
        Dec_inst_flag_in ? Dec_rd_in != 0 : `FALSE;
    assign RF_new_idx_out = tail;
    assign RF_new_rd_out = Dec_rd_in;

    assign RF_write_flag_out = head != tail && 
                               ready[head] && 
                               inst[head] != `BEQ && 
                               inst[head] != `BNE && 
                               inst[head] != `BLT && 
                               inst[head] != `BGE && 
                               inst[head] != `BLTU && 
                               inst[head] != `BGEU;
    assign RF_write_idx_out = head;
    assign RF_write_rd_out = RF_idx[head];

    assign RF_val_out = val[head];

    always @(posedge clk) begin
        if (rst || jump_wrong) begin
            jump_wrong <= `FALSE;
            
            IF_jump_PC_out <= `ZERO32;

            ready <= `ZERO16;
            head <= `ZERO4;
            tail <= `ZERO4;
            
            jalr_flag <= `FALSE;
            jalr_idx <= `5'b0;
        end else if (rdy) begin
            if (Dec_inst_flag_in) begin
                tail <= tail_next;
                val[tail] <= Dec_PC_in;
                jump_flag[tail] <= Dec_jump_flag_in;
                RF_idx[tail] <= Dec_rd_in;
                inst[tail] <= Dec_inst_in;
                ready[tail] <= (Dec_inst_in == `SB || 
                                Dec_inst_in == `SH || 
                                Dec_inst_in == `SW || 
                                Dec_inst_in == `JAL || 
                                Dec_inst_in == `LUI || 
                                Dec_inst_in == `AUIPC);
                
                if (Dec_inst_in == `JALR && jalr_flag == `FALSE) begin
                    jalr_flag <= `TRUE;
                    jalr_idx <= tail;
                end
            end

            if (RS_flag_in) begin
                ready[RS_ROB_idx_in] <= `TRUE;
                if (inst[RS_ROB_idx_in] == `BEQ || 
                    inst[RS_ROB_idx_in] == `BNE || 
                    inst[RS_ROB_idx_in] == `BLT || 
                    inst[RS_ROB_idx_in] == `BGE || 
                    inst[RS_ROB_idx_in] == `BLTU || 
                    inst[RS_ROB_idx_in] == `BGEU) begin
                    jump_flag[RS_ROB_idx_in] <= 
                        jump_flag[RS_ROB_idx_in] != RS_val_in[0];
                end else begin
                    val[RS_ROB_idx_in] <= RS_val_in;
                    if (inst[RS_ROB_idx_in] == `JALR && 
                        RS_ROB_idx_in == jalr_idx) begin
                        jalr_PC <= RS_val_in;
                    end
                end
            end

            if (LSB_flag_in) begin
                ready[LSB_ROB_idx_in] <= `TRUE;
                val[LSB_ROB_idx_in] <= LSB_val_in;
            end

            if (head != tail) begin
                if (inst[head] == `BEQ || 
                    inst[head] == `BNE || 
                    inst[head] == `BLT || 
                    inst[head] == `BGE || 
                    inst[head] == `BLTU || 
                    inst[head] == `BGEU) begin
                    if (ready[head]) begin
                        if (jump_flag[head]) begin
                            jump_wrong <= `TRUE;
                            IC_jump_PC_out <= val[head];
                        end
                    end

                    if (RS_flag_in && RS_ROB_idx_in == head) begin
                        if (jump_flag[head] != RS_val_in[0]) begin
                            jump_wrong <= `TRUE;
                            IF_jump_PC_out <= val[head];
                        end
                    end 
                end else if (inst[head] == `JALR) begin
                    if (ready[head]) begin
                        jump_wrong <= `TRUE;
                        IF_jump_PC_out <= jalr_PC;
                    end

                    if (RS_flag_in && RS_ROB_idx_in == head) begin
                        jump_wrong <= `TRUE;
                        IF_jump_PC_out <= RS_val_in;
                    end
                end

                if (ready[head]) begin
                    ready[head] <= `FALSE;
                end
            end
        end
    end
endmodule