`include "header.v"

module ROB(
    input  wire  clk,
    input  wire  rst,
    input  wire  rdy,
    output reg   jump_wrong,
//decoder
//IF
//RS
//LSB
//CDB
//RF
);
    reg [`ROB_INDEX]       flag;
    reg [31:0]             val   [`ROB_INDEX];
    reg [`REG_INDEX_RANGE] RF_idx[`ROB_INDEX];
    reg [5:0]              inst  [`ROB_INDEX];

    always @(posedge clk) begin
        if (rst || jump_wrong) begin
            jump_wrong <= `FALSE;

            flag <= `ZERO16;
        end else if (rdy) begin
            
        end
    end
endmodule