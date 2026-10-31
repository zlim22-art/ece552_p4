module hazard_ctrl(
    input wire clk,
    // Source register addresses from the ID stage
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

    input wire is_load,
    input wire is_store,
    input wire ex_is_load,
    input wire ex_is_store,
    input wire mem_is_load,
    input wire mem_is_store,

    input wire ebreak_triggered,
    input wire ex_redirect,

    output wire freeze_pc,
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
wire ex_writes_rd;
wire mem_writes_rd;
wire wb_writes_rd;
wire mem_hazard;
wire RAW_hazzard;
wire RAW_hazzard_in_ex;
wire RAW_hazzard_in_mem;
wire RAW_hazzard_in_wb;
wire pc_hazzard;

wire reading_from_memory;
wire writing_to_memory;


// Whether the current instruction in ID uses rs1 or rs2 
assign uses_rs1 = valid_id && (id_inst_vector[10] || id_inst_vector[9] || id_inst_vector[8] || 
                               id_inst_vector[7]  || id_inst_vector[6] || id_inst_vector[4]);

assign uses_rs2 = valid_id && (id_inst_vector[10] || id_inst_vector[7] || id_inst_vector[6]);

// Whether instructions in EX, MEM, or WB write to rd
assign ex_writes_rd  = valid_ex && (ex_inst_vector[10] || ex_inst_vector[9] || ex_inst_vector[8] || 
                                    ex_inst_vector[5]  || ex_inst_vector[4] || ex_inst_vector[3] || 
                                    ex_inst_vector[2]);

assign mem_writes_rd = valid_mem && (mem_inst_vector[10] || mem_inst_vector[9] || mem_inst_vector[8] || 
                                     mem_inst_vector[5]  || mem_inst_vector[4] || mem_inst_vector[3] || 
                                     mem_inst_vector[2]);

assign wb_writes_rd  = valid_wb && (wb_inst_vector[10] || wb_inst_vector[9] || wb_inst_vector[8] || 
                                    wb_inst_vector[5]  || wb_inst_vector[4] || wb_inst_vector[3] || 
                                    wb_inst_vector[2]);

// RAW hazard detection in EX, MEM, and WB stages
assign RAW_hazzard_in_ex  = ex_writes_rd && (ex_rd_addr != 5'd0) &&
                            ((uses_rs1 && (rs1_addr == ex_rd_addr)) || 
                             (uses_rs2 && (rs2_addr == ex_rd_addr)));

assign RAW_hazzard_in_mem = mem_writes_rd && (mem_rd_addr != 5'd0) && 
                            ((uses_rs1 && (rs1_addr == mem_rd_addr)) ||
                             (uses_rs2 && (rs2_addr == mem_rd_addr)));

assign RAW_hazzard_in_wb  = wb_writes_rd && (wb_rd_addr != 5'd0) && 
                            ((uses_rs1 && (rs1_addr == wb_rd_addr)) ||
                             (uses_rs2 && (rs2_addr == wb_rd_addr)));

assign RAW_hazzard = RAW_hazzard_in_ex || RAW_hazzard_in_mem || RAW_hazzard_in_wb;

// Memory hazard detection guarded by valid signals
assign reading_from_memory = valid_id && (id_inst_vector[8] || id_inst_vector[7]);
assign writing_to_memory   = valid_id && (id_inst_vector[8] || id_inst_vector[7]);




// CAse 1:  RAW
assign mem_hazard_raw = valid_ex && ex_inst_vector[8] && (ex_rd_addr != 5'd0) && (
                        (uses_rs1 && (rs1_addr == ex_rd_addr)) || 
                        (uses_rs2 && (rs2_addr == ex_rd_addr))
                        );

// CASE 2: whatver is in your alu rslt is going to be the base adresss for ofeset shenegaigs.
// if your loaidng or sotoring but your base regsiter adress iss being modfied in a prior inscution.
assign mem_hazard_base = (id_inst_vector[8] || id_inst_vector[7]) && (
                         (valid_ex  && ex_writes_rd  && (ex_rd_addr  != 5'd0) && (rs1_addr == ex_rd_addr)) ||
                         (valid_mem && mem_writes_rd && (mem_rd_addr != 5'd0) && (rs1_addr == mem_rd_addr))
                         );

assign mem_hazard= mem_hazard_raw|| mem_hazard_base;


// PC hazard (branch or jump taken in EX)
assign pc_hazzard = valid_ex && ex_redirect;

// Freeze PC and stall IF/ID during a data hazard
assign freeze_pc    = (RAW_hazzard || mem_hazard) && !pc_hazzard;
assign stall_if_id  = (RAW_hazzard || mem_hazard) && !pc_hazzard;
assign stall_id_ex  = 1'b0;
assign stall_ex_mem = 1'b0;
assign stall_mem_wb = 1'b0;

// Flush IF/ID on a taken branch/jump
assign clear_if_id  = pc_hazzard;

// Flush ID/EX if branch or jumped or when inserting a no operation for a RAW/mem hazard stall
assign clear_id_ex  = pc_hazzard || RAW_hazzard || mem_hazard;

assign clear_ex_mem = 1'b0; 
assign clear_mem_wb = 1'b0; 

assign o_trap = valid_wb && wb_inst_vector[0];

endmodule