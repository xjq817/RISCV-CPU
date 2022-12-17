`include "define.v"

module RF(
    input  wire  clk,
    input  wire  rst,
    input  wire  rdy,
    input  wire  jump_wrong,
//decoder
    input  wire [`REG_INDEX_RANGE]  dec_rs1_in,
    input  wire [`REG_INDEX_RANGE]  dec_rs2_in,
    output wire                     dec_rs1_flag_out,
    output wire                     dec_rs2_flag_out,
    output wire [31: 0]             dec_rs1_out,
    output wire [31: 0]             dec_rs2_out,
//ROB
    input  wire                     ROB_new_flag_in,
    input  wire [`ROB_INDEX_RANGE]  ROB_new_idx_in,
    input  wire [`REG_INDEX_RANGE]  ROB_new_rd_in,
    input  wire                     ROB_write_flag_in,
    input  wire [`ROB_INDEX_RANGE]  ROB_write_idx_in,
    input  wire [`REG_INDEX_RANGE]  ROB_write_rd_in,
    input  wire [31:0]              ROB_val_out,
    output wire [`ROB_INDEX_RANGE]  ROB_rs1_idx_out,
    output wire [`ROB_INDEX_RANGE]  ROB_rs2_idx_out
);
    reg [31:0]             reg_val[`REG_INDEX];
    reg [31:0]             reg_status;
    reg [`ROB_INDEX_RANGE] reg_ROB_idx[`REG_INDEX];

    integer i;
    always @(posedge clk) begin
        if (rst) begin
            reg_status <= ~(`ZERO32);
            for (i = 0; i < 32; i = i + 1) begin
                reg_val[i] <= `ZERO32;
            end
        end else if (!rdy) begin
        end else if (jump_wrong) begin
            reg_status <= ~(`ZERO32);
        end else begin
            if (ROB_write_flag_in && ROB_write_rd_in) begin
                reg_val[ROB_write_rd_in] <= ROB_val_out;
                if (reg_ROB_idx[ROB_write_rd_in] == ROB_write_idx_in) begin
                    reg_status[ROB_write_rd_in] <= (ROB_new_rd_in != ROB_write_rd_in);
                end else begin
                    reg_status[ROB_write_rd_in] <= `FALSE;
                end
            end
            if (ROB_new_flag_in && ROB_new_rd_in) begin
                reg_ROB_idx[ROB_new_rd_in] <= ROB_new_idx_in;
                reg_status[ROB_new_rd_in] <= `FALSE;
            end
        end
    end

    assign dec_rs1_flag_out = reg_status[dec_rs1_in];
    assign dec_rs2_flag_out = reg_status[dec_rs2_in];
    assign dec_rs1_out = reg_val[dec_rs1_in];
    assign dec_rs2_out = reg_val[dec_rs2_in];

    assign ROB_rs1_idx_out = reg_ROB_idx[dec_rs1_in];
    assign ROB_rs2_idx_out = reg_ROB_idx[dec_rs2_in];

endmodule