`include "define.v"

module ICache (
    input  wire  clk,
    input  wire  rst,
    input  wire  rdy,
    input  wire  jump_wrong,
//MemoryController
    input  wire         MC_inst_flag_in,
    input  wire [31:0]  MC_inst_in,
    output wire [31:0]  MC_PC_out,
    output wire         MC_inst_flag_out,
//IF
    input  wire [31:0]  IF_PC_in,
    output reg          IF_inst_flag_out,
    output reg  [31:0]  IF_inst_out,
);
    reg [`IC_INDEX]     valid;
    reg [31:0]          cache[`IC_INDEX];
    reg [`IC_TAG_RANGE] tag[`IC_INDEX];
    wire hit;
    
    assign hit = valid[IF_PC_in[`IC_INDEX_RANGE]] && 
                 tag[IF_PC_in[`IC_INDEX_RANGE]] == IF_PC_in[`IC_TAG_RANGE];
    assign MC_PC_out = IF_PC_in;
    assign MC_inst_flag_out = !hit && !MC_inst_flag_in;

    always @(posedge clk) begin
        if (rst) begin
            valid <= 0;
            IF_inst_flag_out <= `FALSE;
        end else if (rdy) begin
            if (MC_inst_flag_in) begin
                valid[IF_PC_in[`IC_INDEX_RANGE]] <= `TRUE;
                cache[IF_PC_in[`IC_INDEX_RANGE]] <= MC_inst_in;
                tag[IF_PC_in[`IC_INDEX_RANGE]] <= IF_PC_in[`IC_TAG_RANGE];
            end

            if (jump_wrong) begin
                IF_inst_flag_out <= `FALSE;
            end else begin
                if (hit) begin
                    IF_inst_flag_out <= `TRUE;
                    IF_inst_out <= cache[IF_PC_in[`IC_INDEX_RANGE]];
                end else begin
                    IF_inst_flag_out <= MC_inst_flag_in;
                    IF_inst_out <= MC_inst_in;
                end
            end
        end
    end
    
endmodule