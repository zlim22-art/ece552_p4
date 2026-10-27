
module mem(
    input wire [31:0] i_dmem_rdata,
    input wire [31:0] rs2_data,
    input wire [31:0] alu_result,
    input wire [31:0] instruction,
    input wire is_load,
    input wire is_store,
    input wire illegal_instruction,
    input wire i_rst,
    input wire mem_valid,
    output wire [31:0] load_data,
    output wire [31:0] o_dmem_addr,
    output wire [3:0] o_dmem_mask,
    output wire [31:0] o_dmem_wdata,
    output wire o_dmem_ren,
    output wire o_dmem_wen,
    output wire memory_misaligned
);

    wire [31:0] store_data;
    wire [3:0] mem_mask;
    wire [2:0] funct3;

    assign funct3 = instruction[14:12];

    load_cntrl load_cntrl_i (
        .i_dmem_rdata(i_dmem_rdata),
        .alu_rslt(alu_result),
        .funct3(funct3),
        .o_load_data(load_data)
    );

    store_cntrl store_cntrl_i (
        .rs2_data(rs2_data),
        .alu_rslt(alu_result),
        .o_store_data(store_data)
    );

    memory_mask memory_mask_i (
        .alu_rslt(alu_result),
        .funct3(funct3),
        .o_mem_mask(mem_mask)
    );

    assign o_dmem_addr = {alu_result[31:2], 2'b00};
    assign o_dmem_mask = mem_mask;
    assign o_dmem_wdata = store_data;

    assign memory_misaligned =
        (is_load || is_store) &&
        (
            ((funct3[1:0] == 2'b01) && alu_result[0]) ||
            ((funct3[1:0] == 2'b10) &&
             (alu_result[1:0] != 2'b00))
        );

    assign o_dmem_ren =
        mem_valid &&
        is_load &&
        !memory_misaligned &&
        !illegal_instruction && 
        !i_rst;

    assign o_dmem_wen =
        mem_valid &&
        is_store &&
        !memory_misaligned &&
        !illegal_instruction && 
        !i_rst;

endmodule
