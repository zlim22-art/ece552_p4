module mem_wb_pipline (
    input wire [10:0] mem_inst_vector,
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
    input wire [5:0] mem_flag,          
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
    output reg wb_trap,
    input wire [31:0] mem_dmem_addr,
    input wire mem_dmem_ren,
    input wire mem_dmem_wen,
    input wire [3:0] mem_dmem_mask,
    input wire [31:0] mem_dmem_wdata,
    input wire [31:0] mem_dmem_rdata,
    output reg [31:0] wb_dmem_addr,
    output reg wb_dmem_ren,
    output reg wb_dmem_wen,
    output reg [3:0] wb_dmem_mask,
    output reg [31:0] wb_dmem_wdata,
    output reg [31:0] wb_dmem_rdata,
    output reg [10:0] wb_inst_vector,
    output reg [5:0] wb_flag          
);
    // pipe between memory and write back stage
    always @(posedge clk) begin
        if (!rst_n) begin
            wb_mem_pc            <= 32'b0;
            wb_pc_rslt           <= 32'b0;
            wb_imm               <= 32'b0;
            wb_load_rslt         <= 32'b0;
            wb_alu_result        <= 32'b0;
            wb_inst              <= 32'h00000000;
            wb_write_dad_addrs   <= 5'b0;
            wb_is_lui            <= 1'b0;
            wb_is_jal            <= 1'b0;
            wb_is_jalr           <= 1'b0;
            wb_is_load           <= 1'b0;
            wb_writes_rd         <= 1'b0;
            wb_valid             <= 1'b0;
            wb_is_ebreak         <= 1'b0;
            wb_trap              <= 1'b0;
            wb_rs1_addr          <= 5'b0;
            wb_rs2_addr          <= 5'b0;
            wb_rs1_data          <= 32'b0;
            wb_rs2_data          <= 32'b0;
            wb_dmem_addr         <= 32'b0;
            wb_dmem_ren          <= 1'b0;
            wb_dmem_wen          <= 1'b0;
            wb_dmem_mask         <= 4'b0;
            wb_dmem_wdata        <= 32'b0;
            wb_dmem_rdata        <= 32'b0;
            wb_inst_vector       <= 11'b0;
            wb_flag              <= 6'b0;
        end
        else if (flush) begin
            wb_mem_pc            <= 32'b0;
            wb_pc_rslt           <= 32'b0;
            wb_imm               <= 32'b0;
            wb_load_rslt         <= 32'b0;
            wb_alu_result        <= 32'b0;
            wb_inst              <= 32'h00000000;
            wb_write_dad_addrs   <= 5'b0;
            wb_is_lui            <= 1'b0;
            wb_is_jal            <= 1'b0;
            wb_is_jalr           <= 1'b0;
            wb_is_load           <= 1'b0;
            wb_writes_rd         <= 1'b0;
            wb_valid             <= 1'b0;
            wb_is_ebreak         <= 1'b0;
            wb_trap              <= 1'b0;
            wb_rs1_addr          <= 5'b0;
            wb_rs2_addr          <= 5'b0;
            wb_rs1_data          <= 32'b0;
            wb_rs2_data          <= 32'b0;
            wb_dmem_addr         <= 32'b0;
            wb_dmem_ren          <= 1'b0;
            wb_dmem_wen          <= 1'b0;
            wb_dmem_mask         <= 4'b0;
            wb_dmem_wdata        <= 32'b0;
            wb_dmem_rdata        <= 32'b0;
            wb_inst_vector       <= 11'b0;
            wb_flag              <= 6'b0;
        end
        else if (stall) begin
            // Hold current state during a stall
            wb_mem_pc            <= wb_mem_pc;
            wb_pc_rslt           <= wb_pc_rslt;
            wb_imm               <= wb_imm;
            wb_load_rslt         <= wb_load_rslt;
            wb_alu_result        <= wb_alu_result;
            wb_inst              <= wb_inst;
            wb_write_dad_addrs   <= wb_write_dad_addrs;
            wb_is_lui            <= wb_is_lui;
            wb_is_jal            <= wb_is_jal;
            wb_is_jalr           <= wb_is_jalr;
            wb_is_load           <= wb_is_load;
            wb_writes_rd         <= wb_writes_rd;
            wb_valid             <= wb_valid;
            wb_is_ebreak         <= wb_is_ebreak;
            wb_rs1_data          <= wb_rs1_data;
            wb_rs2_data          <= wb_rs2_data;
            wb_rs1_addr          <= wb_rs1_addr;
            wb_rs2_addr          <= wb_rs2_addr;
            wb_trap              <= wb_trap;
            wb_dmem_addr         <= wb_dmem_addr;
            wb_dmem_ren          <= wb_dmem_ren;
            wb_dmem_wen          <= wb_dmem_wen;
            wb_dmem_mask         <= wb_dmem_mask;
            wb_dmem_wdata        <= wb_dmem_wdata;
            wb_dmem_rdata        <= wb_dmem_rdata;
            wb_inst_vector       <= wb_inst_vector;
            wb_flag              <= wb_flag;
        end
        else begin
            wb_mem_pc            <= mem_pc;
            wb_pc_rslt           <= pc_rslt;
            wb_imm               <= imm;
            wb_load_rslt         <= load_rslt;
            wb_alu_result        <= alu_result;
            wb_inst              <= mem_inst;
            wb_write_dad_addrs   <= write_dad_addrs;
            wb_is_lui            <= is_lui;
            wb_is_jal            <= is_jal;
            wb_is_jalr           <= is_jalr;
            wb_is_load           <= is_load;
            wb_writes_rd         <= mem_regwrite;
            wb_valid             <= mem_valid;
            wb_is_ebreak         <= mem_is_ebreak;
            wb_rs1_data          <= mem_rs1_data;
            wb_rs2_data          <= mem_rs2_data;
            wb_rs1_addr          <= mem_rs1_addr;
            wb_rs2_addr          <= mem_rs2_addr;
            wb_trap              <= mem_valid && mem_trap;
            wb_dmem_addr         <= mem_dmem_addr;
            wb_dmem_ren          <= mem_dmem_ren;
            wb_dmem_wen          <= mem_dmem_wen;
            wb_dmem_mask         <= mem_dmem_mask;
            wb_dmem_wdata        <= mem_dmem_wdata;
            wb_dmem_rdata        <= mem_dmem_rdata;
            wb_inst_vector       <= mem_inst_vector;
            wb_flag              <= mem_flag;
        end
    end

endmodule