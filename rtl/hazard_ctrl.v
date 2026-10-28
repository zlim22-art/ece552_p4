module hazard_ctrl(
    input wire clk,
    // These come straight from the fetch stage
    input wire [4:0] rs1_addr,
    input wire [4:0] rs2_addr,

    // Instruction vectors per stage
    input wire [10:0] id_inst_vector,
    input wire [10:0] ex_inst_vector,
    input wire [10:0] mem_inst_vector,
    input wire [10:0] wb_inst_vector,

    input wire valid_id,
    input wire valid_ex,
    input wire valid_mem,
    input wire valid_wb,

    // Instruction type flags
    input wire [5:0] id_flags,
    input wire [5:0] id_ex_flgs,
    input wire [5:0] ex_mem_flgs,
    input wire [5:0] mem_wb_flgs,

    // Destination register addresses for each stage
    input wire [4:0] ex_rd_addr,
    input wire [4:0] mem_rd_addr,
    input wire [4:0] wb_rd_addr,

    // Added back load/store explicit ports to match hart.v instantiation
    input wire is_load,
    input wire is_store,
    input wire ex_is_load,
    input wire ex_is_store,
    input wire mem_is_load,
    input wire mem_is_store,

    input wire ebreak_triggered,
    input wire ex_redirect,

    output wire stall_ex_mem,
    output wire stall_id_ex,
    output wire stall_if_id,
    output wire stall_mem_wb,

    output wire clear_ex_mem,
    output wire clear_id_ex,
    output wire clear_if_id,
    output wire clear_mem_wb,
    output wire o_trap
);

wire uses_rs1;
wire uses_rs2;
wire writes_ahead;
wire mem_hazard;
wire RAW_hazzard;
wire RAW_hazzard_in_ex;
wire RAW_hazzard_in_mem;
wire pc_hazzard;
wire pc_hazzard_in_ex;

// Declared missing wires
wire reading_from_memory;
wire writing_to_memory;

/*
 assign inst_vector = {
        is_rtype,            [10]
        is_itype_alu,        [9]
        is_load,             [8]
        is_store,            [7]
        is_branch,           [6]
        is_jal,              [5]
        is_jalr,             [4]
        is_lui,              [3]
        is_auipc,            [2]
        is_ebreak,           [1]
        invalid_instruction  [0]
    };
*/

// Whether the current instruction is using rs1 or rs2 
assign uses_rs1 = valid_id && (id_inst_vector[10] || id_inst_vector[9] || id_inst_vector[8] || 
                               id_inst_vector[7]  || id_inst_vector[6] || id_inst_vector[4]);

assign uses_rs2 = valid_id && (id_inst_vector[10] || id_inst_vector[7] || id_inst_vector[6]);

// Writes ahead guarded by valid_ex and valid_mem
wire ex_writes_rd  = valid_ex && (ex_inst_vector[10] || ex_inst_vector[9] || ex_inst_vector[8] || 
                                  ex_inst_vector[5]  || ex_inst_vector[4] || ex_inst_vector[3] || 
                                  ex_inst_vector[2]);

wire mem_writes_rd = valid_mem && (mem_inst_vector[10] || mem_inst_vector[9] || mem_inst_vector[8] || 
                                   mem_inst_vector[5]  || mem_inst_vector[4]  || mem_inst_vector[3]  || 
                                   mem_inst_vector[2]);

assign writes_ahead = (ex_writes_rd && (ex_rd_addr != 5'b0)) || 
                      (mem_writes_rd && (mem_rd_addr != 5'b0));

// RAW hazard detection in the EX and MEM stages
assign RAW_hazzard_in_ex = (uses_rs1 && writes_ahead) &&
                          ((|rs1_addr && rs1_addr == ex_rd_addr) || 
                           (|rs2_addr && rs2_addr == ex_rd_addr));

assign RAW_hazzard_in_mem = (uses_rs1 && writes_ahead) && 
                           ((|rs1_addr && rs1_addr == mem_rd_addr) ||
                            (|rs2_addr && rs2_addr == mem_rd_addr));

assign RAW_hazzard = RAW_hazzard_in_ex || RAW_hazzard_in_mem;

// Memory hazard detection guarded by valid signals
assign reading_from_memory = valid_id && (id_inst_vector[8] || id_inst_vector[7]);
assign writing_to_memory   = valid_id && (id_inst_vector[8] || id_inst_vector[7]);

assign mem_hazard = reading_from_memory && (
                    (valid_ex  && (ex_inst_vector[8]  || ex_inst_vector[7])  && |ex_rd_addr  && (rs1_addr == ex_rd_addr)) ||
                    (valid_mem && (mem_inst_vector[8] || mem_inst_vector[7]) && |mem_rd_addr && (rs1_addr == mem_rd_addr))
                    );

// PC hazard detection
assign pc_hazzard_in_ex = valid_ex && (ex_mem_flgs[3] || ex_mem_flgs[5]);
assign pc_hazzard       = pc_hazzard_in_ex;

// RAW hazard stall control
assign stall_if_id  = RAW_hazzard || mem_hazard;
assign stall_id_ex  = RAW_hazzard || mem_hazard;

assign stall_ex_mem = 1'b0;
assign stall_mem_wb = 1'b0;

// pc control clearing
assign clear_if_id  = ebreak_triggered || (ex_redirect && pc_hazzard);
assign clear_id_ex  = (ex_redirect && pc_hazzard) || ebreak_triggered;

// Ebreak clears the pipeline stages if the program is over
assign clear_ex_mem = ebreak_triggered; 
assign clear_mem_wb = ebreak_triggered; 

assign o_trap = (~|ex_mem_flgs && ~|mem_wb_flgs) && ebreak_triggered;

endmodule