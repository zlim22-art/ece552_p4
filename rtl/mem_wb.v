module mem_wb_pipline (
    input wire clk,
    input wire rst_n,
    input wire [31:0] mem_pc,
    input wire [31:0] pc_rslt,
    input wire [31:0] imm,
    input wire [31:0] load_rslt,
    input wire [31:0] alu_result,
    input wire [31:0] mem_inst,
    input wire [31:0] mem_rs1_data,
    input wire [31:0] mem_rs2_data,
    input wire [4:0] write_dad_addrs,
    input wire is_lui,
    input wire is_jal,
    input wire is_jalr,
    input wire is_load,
    input wire flush,
    input wire stall,
    input wire mem_regwrite,
    input wire mem_valid,
    input wire mem_is_ebreak,
    input wire mem_trap,
    input wire [4:0] mem_rs1_addr,
    input wire [4:0] mem_rs2_addr,
    output reg [31:0] wb_mem_pc,
    output reg [31:0] wb_pc_rslt,
    output reg [31:0] wb_imm,
    output reg [31:0] wb_load_rslt,
    output reg [31:0] wb_alu_result,
    output reg [31:0] wb_inst,
    output reg [4:0] wb_write_dad_addrs,
    output reg wb_is_lui,
    output reg wb_is_jal,
    output reg wb_is_jalr,
    output reg wb_is_load,
    output reg wb_writes_rd,
    output reg [31:0] wb_rs1_data,
    output reg [31:0] wb_rs2_data,
    output reg [4:0] wb_rs1_addr,
    output reg [4:0] wb_rs2_addr,
    output reg wb_valid,
    output reg wb_is_ebreak,
    output reg wb_trap
);

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            wb_mem_pc <= 32'b0;
            wb_pc_rslt <= 32'b0;
            wb_imm <= 32'b0;
            wb_load_rslt <= 32'b0;
            wb_alu_result <= 32'b0;
            wb_inst <= 32'h00000013;
            wb_write_dad_addrs <= 5'b0;
            wb_is_lui <= 1'b0;
            wb_is_jal <= 1'b0;
            wb_is_jalr <= 1'b0;
            wb_is_load <= 1'b0;
            wb_writes_rd <= 1'b0;
            wb_valid <= 1'b0;
            wb_is_ebreak <= 1'b0;
            wb_trap <= 1'b0;
            wb_rs1_addr <= 5'b0;
            wb_rs2_addr <= 5'b0;
            wb_rs1_data <= 32'b0;
            wb_rs2_data <= 32'b0;
        end
        else if (flush) begin
            wb_mem_pc <= 32'b0;
            wb_pc_rslt <= 32'b0;
            wb_imm <= 32'b0;
            wb_load_rslt <= 32'b0;
            wb_alu_result <= 32'b0;
            wb_inst <= 32'h00000013;
            wb_write_dad_addrs <= 5'b0;
            wb_is_lui <= 1'b0;
            wb_is_jal <= 1'b0;
            wb_is_jalr <= 1'b0;
            wb_is_load <= 1'b0;
            wb_writes_rd <= 1'b0;
            wb_valid <= 1'b0;
            wb_is_ebreak <= 1'b0;
            wb_trap <= 1'b0;
            wb_rs1_addr <= 5'b0;
            wb_rs2_addr <= 5'b0;
            wb_rs1_data <= 32'b0;
            wb_rs2_data <= 32'b0;
        end
        else begin
            wb_mem_pc <= mem_pc;
            wb_pc_rslt <= pc_rslt;
            wb_imm <= imm;
            wb_load_rslt <= load_rslt;
            wb_alu_result <= alu_result;
            wb_inst <= mem_inst;
            wb_write_dad_addrs <= write_dad_addrs;
            wb_is_lui <= is_lui;
            wb_is_jal <= is_jal;
            wb_is_jalr <= is_jalr;
            wb_is_load <= is_load;
            wb_writes_rd <= mem_regwrite;
            wb_valid <= mem_valid;
            wb_is_ebreak <= mem_is_ebreak;
            wb_rs1_data <= mem_rs1_data;
            wb_rs2_data <= mem_rs2_data;
            wb_rs1_addr <= mem_rs1_addr;
            wb_rs2_addr <= mem_rs2_addr;
            wb_trap <= mem_valid && mem_trap;
        end
    end

    assign wb_mem_pc = (stall) ? 32'b0 : wb_mem_pc;
    assign wb_pc_rslt = (stall) ? 32'b0 : wb_pc_rslt;
    assign wb_imm = (stall) ? 32'b0 : wb_imm;
    assign wb_load_rslt = (stall) ? 32'b0 : wb_load_rslt;
    assign wb_alu_result = (stall) ? 32'b0 : wb_alu_result;
    assign wb_inst = (stall) ? 32'h00000013 : wb_inst;
    assign wb_write_dad_addrs = (stall) ? 5'b0 : wb_write_dad_addrs;
    assign wb_is_lui = (stall) ? 1'b0 : wb_is_lui;
    assign wb_is_jal = (stall) ? 1'b0 : wb_is_jal;
    assign wb_is_jalr = (stall) ? 1'b0 : wb_is_jalr;
    assign wb_is_load = (stall) ? 1'b0 : wb_is_load;
    assign wb_writes_rd = (stall) ? 1'b0 : wb_writes_rd;
    assign wb_rs1_data = (stall) ? 32'b0 : wb_rs1_data;
    assign wb_rs2_data = (stall) ? 32'b0 : wb_rs2_data;
    assign wb_rs1_addr = (stall) ? 5'b0 : wb_rs1_addr;
    assign wb_rs2_addr = (stall) ? 5'b0 : wb_rs2_addr;
    assign wb_valid = (stall) ? 1'b0 : wb_valid;
    assign wb_is_ebreak = (stall) ? 1'b0 : wb_is_ebreak;
    assign wb_trap = (stall) ? 1'b0 : wb_trap;

endmodule
