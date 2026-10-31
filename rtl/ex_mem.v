module ex_mem_pipeline(
    input clk,
    input rst_n,
    input [31:0] ex_pc,
    input [31:0] ex_inst,
    input wire [10:0] ex_inst_vector,
    input wire [4:0] ex_rs1_addr,
    input wire [4:0] ex_rs2_addr,
    input wire [4:0] ex_rd_addr,          
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
    input wire [5:0] ex_flag,          
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
    output reg [4:0] mem_rd_addr,         
    output reg mem_valid,
    output reg mem_is_ebreak,
    output reg mem_invalid_instruction,
    output reg [31:0] mem_next_pc,
    output reg [10:0] mem_inst_vector,
    output reg [5:0] mem_flag        
);

    // pipe between execute and memory stage
    always @(posedge clk) begin
        if (!rst_n) begin
            mem_pc                  <= 32'b0;
            mem_inst                <= 32'b0;
            mem_imm                 <= 32'b0;
            mem_rs1_data            <= 32'b0;
            mem_rs2_data            <= 32'b0;
            mem_rs1_addr            <= 5'b0;
            mem_rs2_addr            <= 5'b0;
            mem_rd_addr             <= 5'b0;
            mem_is_auipc            <= 1'b0;
            mem_is_jal              <= 1'b0;
            mem_is_jalr             <= 1'b0;
            mem_is_branch           <= 1'b0;
            mem_is_load             <= 1'b0;
            mem_is_store            <= 1'b0;
            mem_is_rtype            <= 1'b0;
            mem_is_itype            <= 1'b0;
            mem_is_lui              <= 1'b0;
            mem_alu_result          <= 32'b0;
            mem_valid               <= 1'b0;
            mem_is_ebreak           <= 1'b0;
            mem_invalid_instruction <= 1'b0;
            mem_next_pc             <= 32'b0;
            mem_inst_vector         <= 11'b0;
            mem_flag                <= 6'b0;
        end
        else if (flush) begin
            mem_pc                  <= 32'b0;
            mem_inst                <= 32'b0;
            mem_imm                 <= 32'b0;
            mem_rs1_data            <= 32'b0;
            mem_rs2_data            <= 32'b0;
            mem_rs1_addr            <= 5'b0;
            mem_rs2_addr            <= 5'b0;
            mem_rd_addr             <= 5'b0;
            mem_is_auipc            <= 1'b0;
            mem_is_jal              <= 1'b0;
            mem_is_jalr             <= 1'b0;
            mem_is_branch           <= 1'b0;
            mem_is_load             <= 1'b0;
            mem_is_store            <= 1'b0;
            mem_is_rtype            <= 1'b0;
            mem_is_itype            <= 1'b0;
            mem_is_lui              <= 1'b0;
            mem_alu_result          <= 32'b0;
            mem_valid               <= 1'b0;
            mem_is_ebreak           <= 1'b0;
            mem_invalid_instruction <= 1'b0;
            mem_next_pc             <= 32'b0;
            mem_inst_vector         <= 11'b0;
            mem_flag                <= 6'b0;
        end
        else if (stall) begin
            // Hold current values during a stall
            mem_pc                  <= mem_pc;
            mem_inst                <= mem_inst;
            mem_imm                 <= mem_imm;
            mem_rs1_data            <= mem_rs1_data;
            mem_rs2_data            <= mem_rs2_data;
            mem_rs1_addr            <= mem_rs1_addr;
            mem_rs2_addr            <= mem_rs2_addr;
            mem_rd_addr             <= mem_rd_addr;
            mem_is_auipc            <= mem_is_auipc;
            mem_is_jal              <= mem_is_jal;
            mem_is_jalr             <= mem_is_jalr;
            mem_is_branch           <= mem_is_branch;
            mem_is_load             <= mem_is_load;
            mem_is_store            <= mem_is_store;
            mem_is_rtype            <= mem_is_rtype;
            mem_is_itype            <= mem_is_itype;
            mem_is_lui              <= mem_is_lui;
            mem_alu_result          <= mem_alu_result;
            mem_valid               <= mem_valid;
            mem_is_ebreak           <= mem_is_ebreak;
            mem_invalid_instruction <= mem_invalid_instruction;
            mem_next_pc             <= mem_next_pc;
            mem_inst_vector         <= mem_inst_vector;
            mem_flag                <= mem_flag;
        end
        else begin
            // pipe in updated values if not stalled or flushed
            mem_pc                  <= ex_pc;
            mem_inst                <= ex_inst;
            mem_imm                 <= ex_imm;
            mem_rs1_data            <= ex_rs1_data;
            mem_rs2_data            <= ex_rs2_data;
            mem_is_auipc            <= ex_is_auipc;
            mem_is_jal              <= ex_is_jal;
            mem_is_jalr             <= ex_is_jalr;
            mem_is_branch           <= ex_is_branch;
            mem_is_load             <= ex_is_load;
            mem_is_store            <= ex_is_store;
            mem_is_rtype            <= ex_is_rtype;
            mem_is_itype            <= ex_is_itype;
            mem_is_lui              <= ex_is_lui;
            mem_rs1_addr            <= ex_rs1_addr;
            mem_rs2_addr            <= ex_rs2_addr;
            mem_rd_addr             <= ex_rd_addr;
            mem_alu_result          <= alu_result;
            mem_valid               <= ex_valid;
            mem_is_ebreak           <= ex_is_ebreak;
            mem_invalid_instruction <= ex_invalid_instruction;
            mem_next_pc             <= ex_next_pc;
            mem_inst_vector         <= ex_inst_vector;
            mem_flag                <= ex_flag;
        end
    end

endmodule