module hazard_ctrl (
    input wire id_valid,
    input wire [31:0] id_inst,
    input wire ex_regwrite,
    input wire [4:0] ex_rd_addr,
    input wire mem_regwrite,
    input wire [4:0] mem_rd_addr,
    input wire wb_regwrite,
    input wire [4:0] wb_rd_addr,
    input wire ex_redirect,
    output wire stall_if_id,
    output wire stall_id_ex,
    output wire stall_ex_mem,
    output wire stall_mem_wb,
    output wire clear_if_id,
    output wire clear_id_ex,
    output wire clear_ex_mem,
    output wire clear_mem_wb
);
    wire [6:0] opcode = id_inst[6:0];
    wire [4:0] rs1_addr = id_inst[19:15];
    wire [4:0] rs2_addr = id_inst[24:20];

    wire uses_rs1 = id_valid && (
        opcode == 7'b0110011 || // OP
        opcode == 7'b0010011 || // OP-IMM
        opcode == 7'b0000011 || // LOAD
        opcode == 7'b0100011 || // STORE
        opcode == 7'b1100011 || // BRANCH
        opcode == 7'b1100111);  // JALR

    wire uses_rs2 = id_valid && (
        opcode == 7'b0110011 || // OP
        opcode == 7'b0100011 || // STORE
        opcode == 7'b1100011);  // BRANCH

    wire hazard_ex = ex_regwrite && (ex_rd_addr != 5'd0) &&
        ((uses_rs1 && rs1_addr == ex_rd_addr) ||
         (uses_rs2 && rs2_addr == ex_rd_addr));
    wire hazard_mem = mem_regwrite && (mem_rd_addr != 5'd0) &&
        ((uses_rs1 && rs1_addr == mem_rd_addr) ||
         (uses_rs2 && rs2_addr == mem_rd_addr));
    // Necessary without RF WB-to-ID bypass; WB writes at the next posedge.
    wire hazard_wb = wb_regwrite && (wb_rd_addr != 5'd0) &&
        ((uses_rs1 && rs1_addr == wb_rd_addr) ||
         (uses_rs2 && rs2_addr == wb_rd_addr));

    wire raw_hazard = hazard_ex || hazard_mem || hazard_wb;

    // RAW: hold IF and ID; replace ID->EX transfer with a bubble.
    // Redirect: PC redirects; squash younger IF/ID and ID/EX instructions.
    assign stall_if_id  = raw_hazard && !ex_redirect;
    assign stall_id_ex  = 1'b0;
    assign stall_ex_mem = 1'b0;
    assign stall_mem_wb = 1'b0;

    assign clear_if_id  = ex_redirect;
    assign clear_id_ex  = raw_hazard || ex_redirect;
    assign clear_ex_mem = 1'b0;
    assign clear_mem_wb = 1'b0;
endmodule
