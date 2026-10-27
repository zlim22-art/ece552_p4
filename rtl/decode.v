module decode (
    input wire clk,
    input wire rst_n,
    input wire [31:0] instruction,
    input wire [4:0]  write_dad_addrs,     // Write-back destination register address
    input wire [31:0] wb_load_rslt,        // Write-back data
    input wire wb_write_enable,     // Register write enable
    output wire [31:0] rs1_data,
    output wire [31:0] rs2_data,
    output wire [31:0] imm,
    output wire [5:0] flag,
    output wire is_rtype,
    output wire is_itype_alu,
    output wire is_load,
    output wire is_store,
    output wire is_branch,
    output wire is_jal,
    output wire is_jalr,
    output wire is_lui,
    output wire is_auipc,
    output wire [2:0]  o_opsel,
    output wire o_sub,
    output wire o_unsigned,
    output wire o_arith,
    output wire invalid_instruction,
    output wire is_ebreak
);

    flag_gen flag_gen_inst (
        .opcode (instruction[6:0]),
        .flag (flag),
        .is_rtype (is_rtype),
        .is_itype_alu(is_itype_alu),
        .is_load (is_load),
        .is_store (is_store),
        .is_branch (is_branch),
        .is_jal (is_jal),
        .is_jalr (is_jalr),
        .is_lui (is_lui),
        .is_auipc (is_auipc)
    );

    imm immediate_gen_inst (
        .i_inst (instruction), 
        .i_format (flag),
        .o_immediate (imm) 
    );

    
    alu_cntrl alu_cntrl_inst (
        .instruction (instruction),
        .o_opsel (o_opsel),
        .o_sub (o_sub),
        .o_unsigned  (o_unsigned),
        .o_arith (o_arith)
    );

    rf rf_inst (
        .i_clk (clk),
        .i_rst (~rst_n),
        .i_rs1_raddr (rs1_addr), 
        .i_rs2_raddr (rs2_addr), 
        .i_rd_waddr (write_dad_addrs),    
        .i_rd_wdata (wb_load_rslt),       
        .i_rd_wen (wb_write_enable),    
        .o_rs1_rdata (rs1_data), 
        .o_rs2_rdata (rs2_data)  
    );

    wire [4:0] rs1_addr;
    wire [4:0] rs2_addr;

    assign rs1_addr = instruction[19:15];
    assign rs2_addr = instruction[24:20];
    
    assign is_ebreak = (instruction == 32'h00100073);
    
    assign invalid_instruction = !(is_rtype || is_itype_alu || is_load || is_store ||
                                   is_branch || is_jal || is_jalr || is_lui || is_auipc ||
                                   is_ebreak);

endmodule
