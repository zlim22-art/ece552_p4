module mem_wb_pipline (
    input wire clk,
    input wire rst_n,
    input wire [31:0] mem_pc,
    input wire [31:0] pc_rslt,
    input wire [31:0] imm,
    input wire [31:0] load_rslt,
    input wire [31:0] alu_result,
    input wire [31:0] mem_inst,
    input wire [4:0] write_dad_addrs,
    input wire is_lui,
    input wire is_jal,
    input wire is_jalr,
    input wire is_load,
    input wire mem_regwrite,
    input wire mem_valid,
    input wire mem_is_ebreak,
    input wire mem_trap,
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
            wb_trap <= mem_valid && mem_trap;
        end
    end

endmodule
