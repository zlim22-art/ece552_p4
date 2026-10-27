module id_ex_pipeline(
    input clk,
    input rst_n,
    input [31:0] id_pc,
    input [31:0] id_inst,
    input wire flush,
    input wire id_valid,
    input wire [31:0] imm,
    input wire [31:0] rs1_data,
    input wire [31:0] rs2_data,
    input wire is_auipc,
    input wire is_jal,
    input wire is_jalr,
    input wire is_branch,
    input wire is_load,
    input wire is_store,
    input wire is_rtype,
    input wire is_itype,
    input wire is_lui,
    input wire [5:0] flag,
    input wire is_ebreak,
    input wire invalid_instruction,
    input wire i_sub,
    input wire i_arith,
    input wire i_unsigned,
    input wire [2:0] op_sell,
    output reg [31:0] ex_pc,
    output reg [31:0] ex_inst,
    output reg [31:0] ex_imm,
    output reg [31:0] ex_rs1_data,
    output reg [31:0] ex_rs2_data,
    output reg ex_is_auipc,
    output reg ex_is_jal,
    output reg ex_is_jalr,
    output reg ex_is_branch,
    output reg ex_is_load,
    output reg ex_is_store,
    output reg ex_is_rtype,
    output reg ex_is_itype,
    output reg ex_is_lui,
    output reg [5:0] ex_flag,
    output reg ex_i_sub,
    output reg ex_i_arith,
    output reg ex_i_unsigned,
    output reg [2:0] ex_op_sell,
    output reg ex_valid,
    output reg ex_is_ebreak,
    output reg ex_invalid_instruction
);

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n || flush) begin
            ex_pc <= 32'b0;
            ex_inst <= 32'b0;
            ex_imm <= 32'b0;
            ex_rs1_data <= 32'b0;
            ex_rs2_data <= 32'b0;
            ex_is_auipc <= 1'b0;
            ex_is_jal <= 1'b0;
            ex_is_jalr <= 1'b0;
            ex_is_branch <= 1'b0;
            ex_is_load <= 1'b0;
            ex_is_store <= 1'b0;
            ex_is_rtype <= 1'b0;
            ex_is_itype <= 1'b0;
            ex_is_lui <= 1'b0;
            ex_flag <= 6'b0;
            ex_i_sub <= 1'b0;
            ex_i_arith <= 1'b0;
            ex_i_unsigned <= 1'b0;
            ex_op_sell <= 3'b0;
            ex_valid <= 1'b0;
            ex_is_ebreak <= 1'b0;
            ex_invalid_instruction <= 1'b0;
        end else begin
            ex_pc <= id_pc;
            ex_inst <= id_inst;
            ex_imm <= imm;
            ex_rs1_data <= rs1_data;
            ex_rs2_data <= rs2_data;
            ex_is_auipc <= is_auipc;
            ex_is_jal <= is_jal;
            ex_is_jalr <= is_jalr;
            ex_is_branch <= is_branch;
            ex_is_load <= is_load;
            ex_is_store <= is_store;
            ex_is_rtype <= is_rtype;
            ex_is_itype <= is_itype;
            ex_is_lui <= is_lui;
            ex_flag <= flag;
            ex_i_sub <= i_sub;
            ex_i_arith <= i_arith;
            ex_i_unsigned <= i_unsigned;
            ex_op_sell <= op_sell;
            ex_valid <= id_valid;
            ex_is_ebreak <= is_ebreak;
            ex_invalid_instruction <= invalid_instruction;
        end
    end

endmodule
