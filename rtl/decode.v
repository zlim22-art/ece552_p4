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
    output wire is_ebreak,
    output wire [4:0] rs1_addr,
    output wire [4:0] rs2_addr,
    output wire [10:0] inst_vector      // makes stuff esier when piping this
);
    // falg generation for cheking instruction type
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
    // generation of immediate
    imm immediate_gen_inst (
        .i_inst (instruction), 
        .i_format (flag),
        .o_immediate (imm) 
    );

    // alu control signals assignment
    alu_cntrl alu_cntrl_inst (
        .instruction (instruction),
        .o_opsel (o_opsel),
        .o_sub (o_sub),
        .o_unsigned  (o_unsigned),
        .o_arith (o_arith)
    );
    // setting up register file
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

    assign rs1_addr = instruction[19:15];
    assign rs2_addr = instruction[24:20];
    // assigning ebreak address and checking if instruction is invalid
    assign is_ebreak = (instruction == 32'h00100073);
    
    assign invalid_instruction = !(is_rtype || is_itype_alu || is_load || is_store ||
                                   is_branch || is_jal || is_jalr || is_lui || is_auipc ||
                                   is_ebreak);
    assign inst_vector = {
        is_rtype,            // [10]
        is_itype_alu,        // [9]
        is_load,             // [8]
        is_store,            // [7]
        is_branch,           // [6]
        is_jal,              // [5]
        is_jalr,             // [4]
        is_lui,              // [3]
        is_auipc,            // [2]
        is_ebreak,           // [1]
        invalid_instruction  // [0]
    };

endmodule
