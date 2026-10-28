module id_ex_pipeline(
    input clk,
    input rst_n,
    input [31:0] id_pc,
    input [31:0] id_inst,
    input wire flush,
    input wire stall,
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
    
    output wire [31:0] ex_pc,
    output wire [31:0] ex_inst,
    output wire [31:0] ex_imm,
    output wire [31:0] ex_rs1_data,
    output wire [31:0] ex_rs2_data,
    output wire ex_is_auipc,
    output wire ex_is_jal,
    output wire ex_is_jalr,
    output wire ex_is_branch,
    output wire ex_is_load,
    output wire ex_is_store,
    output wire ex_is_rtype,
    output wire ex_is_itype,
    output wire ex_is_lui,
    output wire [5:0] ex_flag,
    output wire ex_i_sub,
    output wire ex_i_arith,
    output wire ex_i_unsigned,
    output wire [2:0] ex_op_sell,
    output wire ex_valid,
    output wire ex_is_ebreak,
    output wire ex_invalid_instruction
);

    reg [31:0] int_ex_pc;
    reg [31:0] int_ex_inst;
    reg [31:0] int_ex_imm;
    reg [31:0] int_ex_rs1_data;
    reg [31:0] int_ex_rs2_data;
    reg int_ex_is_auipc;
    reg int_ex_is_jal;
    reg int_ex_is_jalr;
    reg int_ex_is_branch;
    reg int_ex_is_load;
    reg int_ex_is_store;
    reg int_ex_is_rtype;
    reg int_ex_is_itype;
    reg int_ex_is_lui;
    reg [5:0] int_ex_flag;
    reg int_ex_i_sub;
    reg int_ex_i_arith;
    reg int_ex_i_unsigned;
    reg [2:0] int_ex_op_sell;
    reg int_ex_valid;
    reg int_ex_is_ebreak;
    reg int_ex_invalid_instruction;

    always @(posedge clk ) begin
        if (!rst_n) begin
            int_ex_pc                  <= 32'b0;
            int_ex_inst                <= 32'b0;
            int_ex_imm                 <= 32'b0;
            int_ex_rs1_data            <= 32'b0;
            int_ex_rs2_data            <= 32'b0;
            int_ex_is_auipc            <= 1'b0;
            int_ex_is_jal              <= 1'b0;
            int_ex_is_jalr             <= 1'b0;
            int_ex_is_branch           <= 1'b0;
            int_ex_is_load             <= 1'b0;
            int_ex_is_store            <= 1'b0;
            int_ex_is_rtype            <= 1'b0;
            int_ex_is_itype            <= 1'b0;
            int_ex_is_lui              <= 1'b0;
            int_ex_flag                <= 6'b0;
            int_ex_i_sub               <= 1'b0;
            int_ex_i_arith             <= 1'b0;
            int_ex_i_unsigned          <= 1'b0;
            int_ex_op_sell             <= 3'b0;
            int_ex_valid               <= 1'b0;
            int_ex_is_ebreak           <= 1'b0;
            int_ex_invalid_instruction <= 1'b0;
        end else if (flush) begin
            int_ex_pc                  <= 32'b0;
            int_ex_inst                <= 32'b0;
            int_ex_imm                 <= 32'b0;
            int_ex_rs1_data            <= 32'b0;
            int_ex_rs2_data            <= 32'b0;
            int_ex_is_auipc            <= 1'b0;
            int_ex_is_jal              <= 1'b0;
            int_ex_is_jalr             <= 1'b0;
            int_ex_is_branch           <= 1'b0;
            int_ex_is_load             <= 1'b0;
            int_ex_is_store            <= 1'b0;
            int_ex_is_rtype            <= 1'b0;
            int_ex_is_itype            <= 1'b0;
            int_ex_is_lui              <= 1'b0;
            int_ex_flag                <= 6'b0;
            int_ex_i_sub               <= 1'b0;
            int_ex_i_arith             <= 1'b0;
            int_ex_i_unsigned          <= 1'b0;
            int_ex_op_sell             <= 3'b0;
            int_ex_valid               <= 1'b0;
            int_ex_is_ebreak           <= 1'b0;
            int_ex_invalid_instruction <= 1'b0;
        end else if (!stall) begin
            int_ex_pc <= id_pc;
            int_ex_inst <= id_inst;
            int_ex_imm <= imm;
            int_ex_rs1_data <= rs1_data;
            int_ex_rs2_data <= rs2_data;
            int_ex_is_auipc <= is_auipc;
            int_ex_is_jal <= is_jal;
            int_ex_is_jalr <= is_jalr;
            int_ex_is_branch <= is_branch;
            int_ex_is_load <= is_load;
            int_ex_is_store <= is_store;
            int_ex_is_rtype <= is_rtype;
            int_ex_is_itype <= is_itype;
            int_ex_is_lui <= is_lui;
            int_ex_flag <= flag;
            int_ex_i_sub <= i_sub;
            int_ex_i_arith <= i_arith;
            int_ex_i_unsigned <= i_unsigned;
            int_ex_op_sell <= op_sell;
            int_ex_valid <= id_valid;
            int_ex_is_ebreak <= is_ebreak;
            int_ex_invalid_instruction <= invalid_instruction;
        end
    end

    assign ex_pc = (stall) ? 32'b0 : int_ex_pc;
    assign ex_imm = (stall) ? 32'b0 : int_ex_imm;
    assign ex_rs1_data = (stall) ? 32'b0 : int_ex_rs1_data;
    assign ex_rs2_data = (stall) ? 32'b0 : int_ex_rs2_data;
    assign ex_is_auipc = (stall) ? 1'b0  : int_ex_is_auipc;
    assign ex_is_jal = (stall) ? 1'b0  : int_ex_is_jal;
    assign ex_is_jalr = (stall) ? 1'b0  : int_ex_is_jalr;
    assign ex_is_branch = (stall) ? 1'b0  : int_ex_is_branch;
    assign ex_is_load = (stall) ? 1'b0  : int_ex_is_load;
    assign ex_is_store = (stall) ? 1'b0  : int_ex_is_store;
    assign ex_is_rtype = (stall) ? 1'b0  : int_ex_is_rtype;
    assign ex_is_itype = (stall) ? 1'b0  : int_ex_is_itype;
    assign ex_is_lui = (stall) ? 1'b0  : int_ex_is_lui;
    assign ex_flag = (stall) ? 6'b0  : int_ex_flag;
    assign ex_i_sub = (stall) ? 1'b0  : int_ex_i_sub;
    assign ex_i_arith = (stall) ? 1'b0  : int_ex_i_arith;
    assign ex_i_unsigned = (stall) ? 1'b0  : int_ex_i_unsigned;
    assign ex_op_sell = (stall) ? 3'b0  : int_ex_op_sell;
    assign ex_valid = int_ex_valid;
    assign ex_inst  = int_ex_inst;
    assign ex_is_ebreak = (stall) ? 1'b0  : int_ex_is_ebreak;
    assign ex_invalid_instruction = (stall) ? 1'b0  : int_ex_invalid_instruction;

endmodule