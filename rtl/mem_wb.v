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
    output wire [31:0] wb_mem_pc,
    output wire [31:0] wb_pc_rslt,
    output wire [31:0] wb_imm,
    output wire [31:0] wb_load_rslt,
    output wire [31:0] wb_alu_result,
    output wire [31:0] wb_inst,
    output wire [4:0] wb_write_dad_addrs,
    output wire wb_is_lui,
    output wire wb_is_jal,
    output wire wb_is_jalr,
    output wire wb_is_load,
    output wire wb_writes_rd,
    output wire [31:0] wb_rs1_data,
    output wire [31:0] wb_rs2_data,
    output wire [4:0] wb_rs1_addr,
    output wire [4:0] wb_rs2_addr,
    output wire wb_valid,
    output wire wb_is_ebreak,
    output wire wb_trap,
    input wire [31:0] mem_dmem_addr,
    input wire mem_dmem_ren,
    input wire mem_dmem_wen,
    input wire [3:0] mem_dmem_mask,
    input wire [31:0] mem_dmem_wdata,
    input wire [31:0] mem_dmem_rdata,
    output wire [31:0] wb_dmem_addr,
    output wire wb_dmem_ren,
    output wire wb_dmem_wen,
    output wire [3:0] wb_dmem_mask,
    output wire [31:0] wb_dmem_wdata,
    output wire [31:0] wb_dmem_rdata
);
    reg [31:0] int_wb_mem_pc;
    reg [31:0] int_wb_pc_rslt;
    reg [31:0] int_wb_imm;
    reg [31:0] int_wb_load_rslt;
    reg [31:0] int_wb_alu_result;
    reg [31:0] int_wb_inst;
    reg [4:0] int_wb_write_dad_addrs;
    reg int_wb_is_lui;
    reg int_wb_is_jal;
    reg int_wb_is_jalr;
    reg int_wb_is_load;
    reg int_wb_writes_rd;
    reg [31:0] int_wb_rs1_data;
    reg [31:0] int_wb_rs2_data;
    reg [4:0] int_wb_rs1_addr;
    reg [4:0] int_wb_rs2_addr;
    reg int_wb_valid;
    reg int_wb_is_ebreak;
    reg int_wb_trap;
    reg [31:0] int_wb_dmem_addr;
    reg int_wb_dmem_ren;
    reg int_wb_dmem_wen;
    reg [3:0] int_wb_dmem_mask;
    reg [31:0] int_wb_dmem_wdata;
    reg [31:0] int_wb_dmem_rdata;

    always @(posedge clk) begin
        if (!rst_n) begin
            int_wb_mem_pc <= 32'b0;
            int_wb_pc_rslt <= 32'b0;
            int_wb_imm <= 32'b0;
            int_wb_load_rslt <= 32'b0;
            int_wb_alu_result <= 32'b0;
            int_wb_inst <= 32'h00000013;
            int_wb_write_dad_addrs <= 5'b0;
            int_wb_is_lui <= 1'b0;
            int_wb_is_jal <= 1'b0;
            int_wb_is_jalr <= 1'b0;
            int_wb_is_load <= 1'b0;
            int_wb_writes_rd <= 1'b0;
            int_wb_valid <= 1'b0;
            int_wb_is_ebreak <= 1'b0;
            int_wb_trap <= 1'b0;
            int_wb_rs1_addr <= 5'b0;
            int_wb_rs2_addr <= 5'b0;
            int_wb_rs1_data <= 32'b0;
            int_wb_rs2_data <= 32'b0;
            int_wb_dmem_addr <= 32'b0;
            int_wb_dmem_ren <= 1'b0;
            int_wb_dmem_wen <= 1'b0;
            int_wb_dmem_mask <= 4'b0;
            int_wb_dmem_wdata <= 32'b0;
            int_wb_dmem_rdata <= 32'b0;
        end
        else if (flush) begin
            int_wb_mem_pc <= 32'b0;
            int_wb_pc_rslt <= 32'b0;
            int_wb_imm <= 32'b0;
            int_wb_load_rslt <= 32'b0;
            int_wb_alu_result <= 32'b0;
            int_wb_inst <= 32'h00000013;
            int_wb_write_dad_addrs <= 5'b0;
            int_wb_is_lui <= 1'b0;
            int_wb_is_jal <= 1'b0;
            int_wb_is_jalr <= 1'b0;
            int_wb_is_load <= 1'b0;
            int_wb_writes_rd <= 1'b0;
            int_wb_valid <= 1'b0;
            int_wb_is_ebreak <= 1'b0;
            int_wb_trap <= 1'b0;
            int_wb_rs1_addr <= 5'b0;
            int_wb_rs2_addr <= 5'b0;
            int_wb_rs1_data <= 32'b0;
            int_wb_rs2_data <= 32'b0;
            int_wb_dmem_addr <= 32'b0;
            int_wb_dmem_ren <= 1'b0;
            int_wb_dmem_wen <= 1'b0;
            int_wb_dmem_mask <= 4'b0;
            int_wb_dmem_wdata <= 32'b0;
            int_wb_dmem_rdata <= 32'b0;
        end
        else if (!stall) begin
            int_wb_mem_pc <= mem_pc;
            int_wb_pc_rslt <= pc_rslt;
            int_wb_imm <= imm;
            int_wb_load_rslt <= load_rslt;
            int_wb_alu_result <= alu_result;
            int_wb_inst <= mem_inst;
            int_wb_write_dad_addrs <= write_dad_addrs;
            int_wb_is_lui <= is_lui;
            int_wb_is_jal <= is_jal;
            int_wb_is_jalr <= is_jalr;
            int_wb_is_load <= is_load;
            int_wb_writes_rd <= mem_regwrite;
            int_wb_valid <= mem_valid;
            int_wb_is_ebreak <= mem_is_ebreak;
            int_wb_rs1_data <= mem_rs1_data;
            int_wb_rs2_data <= mem_rs2_data;
            int_wb_rs1_addr <= mem_rs1_addr;
            int_wb_rs2_addr <= mem_rs2_addr;
            int_wb_trap <= mem_valid && mem_trap;
            int_wb_dmem_addr <= mem_dmem_addr;
            int_wb_dmem_ren <= mem_dmem_ren;
            int_wb_dmem_wen <= mem_dmem_wen;
            int_wb_dmem_mask <= mem_dmem_mask;
            int_wb_dmem_wdata <= mem_dmem_wdata;
            int_wb_dmem_rdata <= mem_dmem_rdata;
        end
    end

    assign wb_mem_pc = (stall) ? 32'b0 : int_wb_mem_pc;
    assign wb_pc_rslt = (stall) ? 32'b0 : int_wb_pc_rslt;
    assign wb_imm = (stall) ? 32'b0 : int_wb_imm;
    assign wb_load_rslt = (stall) ? 32'b0 : int_wb_load_rslt;
    assign wb_alu_result = (stall) ? 32'b0 : int_wb_alu_result;
    assign wb_inst = (stall) ? 32'h00000013 : int_wb_inst;
    assign wb_write_dad_addrs = (stall) ? 5'b0 : int_wb_write_dad_addrs;
    assign wb_is_lui = (stall) ? 1'b0 : int_wb_is_lui;
    assign wb_is_jal = (stall) ? 1'b0 : int_wb_is_jal;
    assign wb_is_jalr = (stall) ? 1'b0 : int_wb_is_jalr;
    assign wb_is_load = (stall) ? 1'b0 : int_wb_is_load;
    assign wb_writes_rd = (stall) ? 1'b0 : int_wb_writes_rd;
    assign wb_rs1_data = (stall) ? 32'b0 : int_wb_rs1_data;
    assign wb_rs2_data = (stall) ? 32'b0 : int_wb_rs2_data;
    assign wb_rs1_addr = (stall) ? 5'b0 : int_wb_rs1_addr;
    assign wb_rs2_addr = (stall) ? 5'b0 : int_wb_rs2_addr;
    assign wb_valid = (stall) ? 1'b0 : int_wb_valid;
    assign wb_is_ebreak = (stall) ? 1'b0 : int_wb_is_ebreak;
    assign wb_trap = (stall) ? 1'b0 : int_wb_trap;
    assign wb_dmem_addr = (stall) ? 32'b0 : int_wb_dmem_addr;
    assign wb_dmem_ren = (stall) ? 1'b0 : int_wb_dmem_ren;
    assign wb_dmem_wen = (stall) ? 1'b0 : int_wb_dmem_wen;
    assign wb_dmem_mask = (stall) ? 4'b0 : int_wb_dmem_mask;
    assign wb_dmem_wdata = (stall) ? 32'b0 : int_wb_dmem_wdata;
    assign wb_dmem_rdata = (stall) ? 32'b0 : int_wb_dmem_rdata;

endmodule