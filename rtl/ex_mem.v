module ex_mem_pipeline(
    input clk,
    input rst_n,
    input [31:0] ex_pc,
    input [31:0] ex_inst,
    input wire [4:0] ex_rs1_addr,
    input wire [4:0] ex_rs2_addr,
    input wire [31:0] ex_rs1_data,
    input wire [31:0] ex_rs2_data,
    input wire [31:0] ex_imm,
    input wire ex_is_auipc,
    input wire ex_is_jal,
    input wire ex_is_jalr,
    input wire ex_is_branch,
    input wire ex_is_load,
    input wire ex_is_store,
    input wire ex_is_rtype,
    input wire ex_is_itype,
    input wire ex_is_lui, 
    input wire ex_valid,
    input wire ex_is_ebreak,
    input wire ex_invalid_instruction,
    input wire flush,
    input wire stall,
    input wire [31:0] ex_next_pc,    
    input wire [31:0] alu_result,
    output wire [31:0] mem_pc,
    output wire [31:0] mem_inst,
    output wire [31:0] mem_imm,
    output wire [31:0] mem_rs1_data,
    output wire [31:0] mem_rs2_data,
    output wire mem_is_auipc,
    output wire mem_is_jal,
    output wire mem_is_jalr,
    output wire mem_is_branch,
    output wire mem_is_load,
    output wire mem_is_store,
    output wire mem_is_rtype,
    output wire mem_is_itype,
    output wire mem_is_lui,
    output wire [31:0] mem_alu_result,
    output wire [4:0] mem_rs1_addr,
    output wire [4:0] mem_rs2_addr,
    output wire mem_valid,
    output wire mem_is_ebreak,
    output wire mem_invalid_instruction,
    output wire [31:0] mem_next_pc
);
    reg [31:0] int_mem_pc;
    reg [31:0] int_mem_inst;
    reg [31:0] int_mem_imm;
    reg [31:0] int_mem_rs1_data;
    reg [31:0] int_mem_rs2_data;
    reg int_mem_is_auipc;
    reg int_mem_is_jal;
    reg int_mem_is_jalr;
    reg int_mem_is_branch;
    reg int_mem_is_load;
    reg int_mem_is_store;
    reg int_mem_is_rtype;
    reg int_mem_is_itype;
    reg int_mem_is_lui;
    reg [31:0] int_mem_alu_result;
    reg [4:0] int_mem_rs1_addr;
    reg [4:0] int_mem_rs2_addr;
    reg int_mem_valid;
    reg int_mem_is_ebreak;
    reg int_mem_invalid_instruction;
    reg [31:0] int_mem_next_pc;

    always @(posedge clk) begin
        if (!rst_n) begin
            int_mem_pc <= 32'b0;
            int_mem_inst <= 32'b0;
            int_mem_imm <= 32'b0;
            int_mem_rs1_data <= 32'b0;
            int_mem_rs2_data <= 32'b0;
            int_mem_rs1_addr <= 5'b0;
            int_mem_rs2_addr <= 5'b0;
            int_mem_is_auipc <= 1'b0;
            int_mem_is_jal <= 1'b0;
            int_mem_is_jalr <= 1'b0;
            int_mem_is_branch <= 1'b0;
            int_mem_is_load <= 1'b0;
            int_mem_is_store <= 1'b0;
            int_mem_is_rtype <= 1'b0;
            int_mem_is_itype <= 1'b0;
            int_mem_is_lui <= 1'b0;
            int_mem_alu_result <= 32'b0;
            int_mem_valid <= 1'b0;
            int_mem_is_ebreak <= 1'b0;
            int_mem_invalid_instruction <= 1'b0;
            int_mem_next_pc <= 32'b0;
        end
        else if (flush) begin
            int_mem_pc <= 32'b0;
            int_mem_inst <= 32'b0;
            int_mem_imm <= 32'b0;
            int_mem_rs1_data <= 32'b0;
            int_mem_rs2_data <= 32'b0;
            int_mem_rs1_addr <= 5'b0;
            int_mem_rs2_addr <= 5'b0;
            int_mem_is_auipc <= 1'b0;
            int_mem_is_jal <= 1'b0;
            int_mem_is_jalr <= 1'b0;
            int_mem_is_branch <= 1'b0;
            int_mem_is_load <= 1'b0;
            int_mem_is_store <= 1'b0;
            int_mem_is_rtype <= 1'b0;
            int_mem_is_itype <= 1'b0;
            int_mem_is_lui <= 1'b0;
            int_mem_alu_result <= 32'b0;
            int_mem_valid <= 1'b0;
            int_mem_is_ebreak <= 1'b0;
            int_mem_invalid_instruction <= 1'b0;
            int_mem_next_pc <= 32'b0;
        end
        else if (!stall) begin
            int_mem_pc <= ex_pc;
            int_mem_inst <= ex_inst;
            int_mem_imm <= ex_imm;
            int_mem_rs1_data <= ex_rs1_data;
            int_mem_rs2_data <= ex_rs2_data;
            int_mem_is_auipc <= ex_is_auipc;
            int_mem_is_jal <= ex_is_jal;
            int_mem_is_jalr <= ex_is_jalr;
            int_mem_is_branch <= ex_is_branch;
            int_mem_is_load <= ex_is_load;
            int_mem_is_store <= ex_is_store;
            int_mem_is_rtype <= ex_is_rtype;
            int_mem_is_itype <= ex_is_itype;
            int_mem_is_lui <= ex_is_lui;
            int_mem_rs1_addr <= ex_rs1_addr;
            int_mem_rs2_addr <= ex_rs2_addr;
            int_mem_alu_result <= alu_result;
            int_mem_valid <= ex_valid;
            int_mem_is_ebreak <= ex_is_ebreak;
            int_mem_invalid_instruction <= ex_invalid_instruction;
            int_mem_next_pc <= ex_next_pc;
        end
    end

    assign mem_pc = (stall) ? 32'b0 : int_mem_pc;
    assign mem_inst = (stall) ? 32'b0 : int_mem_inst;
    assign mem_imm = (stall) ? 32'b0 : int_mem_imm;
    assign mem_rs1_data = (stall) ? 32'b0 : int_mem_rs1_data;
    assign mem_rs2_data = (stall) ? 32'b0 : int_mem_rs2_data;
    assign mem_is_auipc = (stall) ? 1'b0 : int_mem_is_auipc;
    assign mem_is_jal = (stall) ? 1'b0 : int_mem_is_jal;
    assign mem_is_jalr = (stall) ? 1'b0 : int_mem_is_jalr;
    assign mem_is_branch = (stall) ? 1'b0 : int_mem_is_branch;
    assign mem_is_load = (stall) ? 1'b0 : int_mem_is_load;
    assign mem_is_store = (stall) ? 1'b0 : int_mem_is_store;
    assign mem_is_rtype = (stall) ? 1'b0 : int_mem_is_rtype;
    assign mem_is_itype = (stall) ? 1'b0 : int_mem_is_itype;
    assign mem_is_lui = (stall) ? 1'b0 : int_mem_is_lui;
    assign mem_alu_result = (stall) ? 32'b0 : int_mem_alu_result;
    assign mem_rs1_addr = (stall) ? 5'b0 : int_mem_rs1_addr;
    assign mem_rs2_addr = (stall) ? 5'b0 : int_mem_rs2_addr;
    assign mem_valid = (stall) ? 1'b0 : int_mem_valid;
    assign mem_is_ebreak = (stall) ? 1'b0 : int_mem_is_ebreak;
    assign mem_invalid_instruction = (stall) ? 1'b0 : int_mem_invalid_instruction;
    assign mem_next_pc = (stall) ? 32'b0 : int_mem_next_pc;

endmodule