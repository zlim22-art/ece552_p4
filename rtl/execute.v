
module execute(
    input wire [2:0] alu_opsel,
    input wire alu_sub,
    input wire alu_unsigned,
    input wire alu_arith,
    input wire is_auipc,
    input wire [5:0] flag,
    input wire [31:0] pc,
    input wire [31:0] instruction,
    input wire [31:0] rs1_data,
    input wire [31:0] rs2_data,
    input wire [31:0] imm,
    input wire is_jal,
    input wire is_jalr,
    input wire is_branch,
    input wire is_ebreak,
    output wire [31:0] alu_result,
    output wire alu_eq,
    output wire alu_slt,
    output wire alu_n,
    output wire alu_z,
    output wire alu_v,
    output wire alu_c,
    output wire [31:0] nxt_pc,
    output wire ex_redirect
);

    wire [31:0] alu_op1;
    wire [31:0] alu_op2;
    wire ALUsrc;
    wire [2:0] funct3;

    assign funct3 = instruction[14:12];
    //performing alu operation based on the control signals and operands
    alu alu_i (
        .i_opsel(alu_opsel),
        .i_sub(alu_sub),
        .i_unsigned(alu_unsigned),
        .i_arith(alu_arith),
        .i_op1(alu_op1),
        .i_op2(alu_op2),
        .o_result(alu_result),
        .o_eq(alu_eq),
        .o_slt(alu_slt),
        .o_n(alu_n),
        .o_z(alu_z),
        .o_v(alu_v),
        .o_c(alu_c)
    );
    // controlling next pc based on instruction type and alu flags
    pc_cntrl pc_cntrl_i (
        .functionselect(funct3),
        .jmp_flag(is_jal),
        .jalr_flag(is_jalr),
        .branchStatus(is_branch),
        .ebreak_flag(is_ebreak),
        .z(alu_z),
        .n(alu_n),
        .v(alu_v),
        .c(alu_c),
        .pc_curr(pc),
        .imm_j(imm),
        .imm_b(imm),
        .alu_rslt(alu_result),
        .pc_nxt(nxt_pc),
        .redirect(ex_redirect)
    );
    // getting alu ops and asserting alusrc based on whether we use rs2 or imm
    assign alu_op1 = is_auipc ? pc : rs1_data;
    assign alu_op2 = ALUsrc ? imm : rs2_data;
    assign ALUsrc = ~(flag[0] || flag[3]);

endmodule
