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
    output reg [31:0] mem_pc,
    output reg [31:0] mem_inst,
    output reg [31:0] mem_imm,
    output reg [31:0] mem_rs1_data,
    output reg [31:0] mem_rs2_data,
    output reg mem_is_auipc,
    output reg mem_is_jal,
    output reg mem_is_jalr,
    output reg mem_is_branch,
    output reg mem_is_load,
    output reg mem_is_store,
    output reg mem_is_rtype,
    output reg mem_is_itype,
    output reg mem_is_lui,
    output reg [31:0] mem_alu_result,
    output reg [4:0] mem_rs1_addr,
    output reg [4:0] mem_rs2_addr,
    output reg mem_valid,
    output reg mem_is_ebreak,
    output reg mem_invalid_instruction,
    output reg [31:0] mem_next_pc
);

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            mem_pc <= 32'b0;
            mem_inst <= 32'b0;
            mem_imm <= 32'b0;
            mem_rs1_data <= 32'b0;
            mem_rs2_data <= 32'b0;
            mem_rs1_addr <= 5'b0;
            mem_rs2_addr <= 5'b0;
            mem_is_auipc <= 1'b0;
            mem_is_jal <= 1'b0;
            mem_is_jalr <= 1'b0;
            mem_is_branch <= 1'b0;
            mem_is_load <= 1'b0;
            mem_is_store <= 1'b0;
            mem_is_rtype <= 1'b0;
            mem_is_itype <= 1'b0;
            mem_is_lui <= 1'b0;
            mem_alu_result <= 32'b0;
            mem_valid <= 1'b0;
            mem_is_ebreak <= 1'b0;
            mem_invalid_instruction <= 1'b0;
            mem_next_pc <= 32'b0;
        end
        else if (flush) begin
            mem_pc <= 32'b0;
            mem_inst <= 32'b0;
            mem_imm <= 32'b0;
            mem_rs1_data <= 32'b0;
            mem_rs2_data <= 32'b0;
            mem_rs1_addr <= 5'b0;
            mem_rs2_addr <= 5'b0;
            mem_is_auipc <= 1'b0;
            mem_is_jal <= 1'b0;
            mem_is_jalr <= 1'b0;
            mem_is_branch <= 1'b0;
            mem_is_load <= 1'b0;
            mem_is_store <= 1'b0;
            mem_is_rtype <= 1'b0;
            mem_is_itype <= 1'b0;
            mem_is_lui <= 1'b0;
            mem_alu_result <= 32'b0;
            mem_valid <= 1'b0;
            mem_is_ebreak <= 1'b0;
            mem_invalid_instruction <= 1'b0;
            mem_next_pc <= 32'b0;
        end
        else begin
            mem_pc <= ex_pc;
            mem_inst <= ex_inst;
            mem_imm <= ex_imm;
            mem_rs1_data <= ex_rs1_data;
            mem_rs2_data <= ex_rs2_data;
            mem_is_auipc <= ex_is_auipc;
            mem_is_jal <= ex_is_jal;
            mem_is_jalr <= ex_is_jalr;
            mem_is_branch <= ex_is_branch;
            mem_is_load <= ex_is_load;
            mem_is_store <= ex_is_store;
            mem_is_rtype <= ex_is_rtype;
            mem_is_itype <= ex_is_itype;
            mem_is_lui <= ex_is_lui;
            mem_rs1_addr <= ex_rs1_addr;
            mem_rs2_addr <= ex_rs2_addr;
            mem_alu_result <= alu_result;
            mem_valid <= ex_valid;
            mem_is_ebreak <= ex_is_ebreak;
            mem_invalid_instruction <= ex_invalid_instruction;
            mem_next_pc <= ex_next_pc;
        end
    end

    assign mem_pc = (stall) ? 32'b0 : mem_pc;
    assign mem_inst = (stall) ? 32'b0 : mem_inst;
    assign mem_imm = (stall) ? 32'b0 : mem_imm;
    assign mem_rs1_data = (stall) ? 32'b0 : mem_rs1_data;
    assign mem_rs2_data = (stall) ? 32'b0 : mem_rs2_data;
    assign mem_is_auipc = (stall) ? 1'b0 : mem_is_auipc;
    assign mem_is_jal = (stall) ? 1'b0 : mem_is_jal;
    assign mem_is_jalr = (stall) ? 1'b0 : mem_is_jalr;
    assign mem_is_branch = (stall) ? 1'b0 : mem_is_branch;
    assign mem_is_load = (stall) ? 1'b0 : mem_is_load;
    assign mem_is_store = (stall) ? 1'b0 : mem_is_store;
    assign mem_is_rtype = (stall) ? 1'b0 : mem_is_rtype;
    assign mem_is_itype = (stall) ? 1'b0 : mem_is_itype;
    assign mem_is_lui = (stall) ? 1'b0 : mem_is_lui;
    assign mem_alu_result = (stall) ? 32'b0 : mem_alu_result;
    assign mem_rs1_addr = (stall) ? 5'b0 : mem_rs1_addr;
    assign mem_rs2_addr = (stall) ? 5'b0 : mem_rs2_addr;
    assign mem_valid = (stall) ? 1'b0 : mem_valid;
    assign mem_is_ebreak = (stall) ? 1'b0 : mem_is_ebreak;
    assign mem_invalid_instruction = (stall) ? 1'b0 : mem_invalid_instruction;
    assign mem_next_pc = (stall) ? 32'b0 : mem_next_pc;

endmodule
