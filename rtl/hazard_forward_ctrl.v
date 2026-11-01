module hazard_forward_ctrl(
    input wire clk,
    // Source register addresses from the ID stage
    input wire [4:0] id_rs1_addr,
    input wire [4:0] id_rs2_addr,

    //Sourc register addresses from the EX stage
    input wire [4:0] ex_rs1_addr,
    input wire [4:0] ex_rs2_addr,

    // Source register addresses from the MEM stage
    input wire [4:0] mem_rs1_addr,
    input wire [4:0] mem_rs2_addr,

    //Source register addresses from the WB stage
    input wire [4:0] wb_rs1_addr,
    input wire [4:0] wb_rs2_addr,
    
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
    output wire o_trap,


    output wire ex_ex_forwarding,
    output wire ex_ex_forwarding_rs1,
    output wire ex_ex_forwarding_rs2,

    output wire mem_ex_forwarding,
    output wire mem_ex_forwarding_rs1_load_rslt,

    output wire mem_ex_forwarding_rs1_piped_rs1,
    output wire mem_ex_forwarding_rs2_piped_rs2,
    


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

wire forwarding_ex_rs1;
wire forwarding_ex_rs2;
wire forwarding_mem_rs1;
wire forwarding_mem_rs2;

wire forwarding_mem_rs1_ex_rs1;
wire forwarding_mem_rs1_ex_rs2;

wire [2:0] forwarding;


// Whether the current instruction in ID uses rs1 or rs2 
assign uses_rs1 = valid_id && (id_inst_vector[10] || id_inst_vector[9] || id_inst_vector[8] || 
                               id_inst_vector[7]  || id_inst_vector[6] || id_inst_vector[4]);

assign uses_rs2 = valid_id && (id_inst_vector[10] || id_inst_vector[7] || id_inst_vector[6]);



// Whether the current insuction  the mememory instruction uses rs1 or rs2 
assign mem_uses_rs1 = valid_id && (mem_inst_vector[10] || mem_inst_vector[9] || mem_inst_vector[8] || 
                               mem_inst_vector[7]  || mem_inst_vector[6] || mem_inst_vector[4]);

assign mem_uses_rs2 = valid_id && (mem_inst_vector[10] || mem_inst_vector[7] || mem_inst_vector[6]);

// Whether the current insuction  the exucute stage  uses rs1 or rs2 
assign ex_uses_rs1 = valid_id && (ex_inst_vector[10] || ex_inst_vector[9] || ex_inst_vector[8] || 
                               ex_inst_vector[7]  || ex_inst_vector[6] || ex_inst_vector[4]);

assign ex_uses_rs2 = valid_id && (ex_inst_vector[10] || ex_inst_vector[7] || ex_inst_vector[6]);


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
assign RAW_hazzard_in_id_mem  = mem_writes_rd && (mem_rd_addr != 5'd0) &&
                            ((mem_uses_rs1 && (rs1_addr == mem_rd_addr)) || 
                             (mem_uses_rs2 && (rs2_addr == mem_rd_addr)));

assign RAW_hazzard_mem_ex = ex_writes_rd && (ex_rd_addr != 5'd0) &&
                            ((mem_uses_rs1 && (ex_rs1_addr == mem_rd_addr)) || 
                             (mem_uses_rs2 && (ex_rs2_addr == mem_rd_addr)));

// if mem is not writing to ex_rs1 or ex_rs2 but there exists a mistmatch bnetweeen the x_rs1 and mrs_1
// or ex_rs2 and meem_rs2 then we must have msisses somehthing. This shuld only come nto play if the wb instction is writing to
// forward rs1 or rs2 from mem to ex's rs1 or rs2
wire mismatch_reg_ex_mem_rs11= wb_writes_rd && (ex_rs1_addr == mem_rs1_addr || ex_rs2_addr == mem_rs2_addr) && (ex_rs1_addr==wb_rd_addr || ex_rs2_addr==wb_rd_addr) && (ex_rs1_addr==mem_rd_addr || ex_rs2_addr==mem_rd_addr);
wire mismatch_reg_ex_mem_rs12= wb_writes_rd && (ex_rs1_addr == mem_rs1_addr || ex_rs2_addr == mem_rs2_addr) && (ex_rs1_addr==wb_rd_addr || ex_rs2_addr==wb_rd_addr) && (ex_rs1_addr==mem_rd_addr || ex_rs2_addr==mem_rd_addr);
wire mismatch_reg_ex_mem_rs21= wb_writes_rd && (ex_rs1_addr == mem_rs1_addr || ex_rs2_addr == mem_rs2_addr) && (ex_rs1_addr==wb_rd_addr || ex_rs2_addr==wb_rd_addr) && (ex_rs1_addr==mem_rd_addr || ex_rs2_addr==mem_rd_addr);
wire mismatch_reg_ex_mem_rs22= wb_writes_rd && (ex_rs1_addr == mem_rs1_addr || ex_rs2_addr == mem_rs2_addr) && (ex_rs1_addr==wb_rd_addr || ex_rs2_addr==wb_rd_addr) && (ex_rs1_addr==mem_rd_addr || ex_rs2_addr==mem_rd_addr);

// no longer needed beocuse of forwarding
// assign RAW_hazzard_in_wb  = wb_writes_rd && (wb_rd_addr != 5'd0) && 
//                             ((uses_rs1 && (rs1_addr == wb_rd_addr)) ||
//                              (uses_rs2 && (rs2_addr == wb_rd_addr)));

assign RAW_hazzard = RAW_hazzard_in_ex || RAW_hazzard_in_id_mem || RAW_hazzard_mem_ex;

    // assign inst_vector = {
    //     is_rtype,            // [10]
    //     is_itype_alu,        // [9]
    //     is_load,             // [8]
    //     is_store,            // [7]
    //     is_branch,           // [6]
    //     is_jal,              // [5]
    //     is_jalr,             // [4]
    //     is_lui,              // [3]
    //     is_auipc,            // [2]
    //     is_ebreak,           // [1]
    //     invalid_instruction  // [0]
    // };



// CCASE 1: load after sotring
/* fucked cases
// LOAD AFTER STORING 1 cycle difrence fixed with stalling
assign mem_hazard_raw = valid_ex && ex_inst_vector[8] && mem_inst_vector[7] && (ex_rd_addr != 5'd0) && (
                        (uses_rs1 && (rs1_addr == ex_rd_addr)) || 
                        (uses_rs2 && (rs2_addr == ex_rd_addr))
                        );

// LOAD AFTER STORE 2 cycle distance fixed with forwarding
assign mem_hazard_raw = valid_id && id_inst_vector[8] && mem_inst_vector[7] && (id_rd_addr != 5'd0) && (
                        (uses_rs1 && (rs1_addr == id_rd_addr)) || 
                        (uses_rs2 && (rs2_addr == id_rd_addr))
                        );


// gave to stall for thuis
// CASE 2: whatever is in your alu rslt is going to be the base adresss for offset shenegaigs.
// if your loaidng or sotoring but your base regsiter adress iss being modfied in a prior inscution.
assign mem_hazard_base = (id_inst_vector[8] || id_inst_vector[7]) && (
                         (valid_ex  && ex_writes_rd  && (ex_rd_addr  != 5'd0) && (rs1_addr == ex_rd_addr)) ||
                         (valid_mem && mem_writes_rd && (mem_rd_addr != 5'd0) && (rs1_addr == mem_rd_addr))
                         );

*/

// Sub for mem-mem forwarding 
// Loading the destination data from load into the base address for a load/store in the next instruction
assign store_or_load_after_base_modification_ex_mem_with_stall = (ex_inst_vector[8] || ex_inst_vector[7]) && (
                         (valid_mem && mem_writes_rd && (mem_rd_addr != 5'd0) && (ex_rs1_addr == mem_rd_addr))
                         );

// Mem-ex forwarding 
// Loading into a destination register and the store is storing form the mems destiation resigters as the store data 
assign store_after_load_data_hazard = (mem_inst_vector[8]  && ex_inst_vector[7]) && (  
                         (valid_ex &&  |ex_rs2_addr && mem_writes_rd && (mem_rd_addr == ex_rs2_addr)));

assign arith_after_load_data_hazard_rs1 = (mem_inst_vector[8] && (ex_inst_vector[10] || ex_inst_vector[9]) ) && (
                         (valid_ex && |ex_rs1_addr && mem_writes_rd && (mem_rd_addr == ex_rs1_addr)));

assign arith_after_load_data_hazard_rs2 = (mem_inst_vector[8] && (ex_inst_vector[10] || ex_inst_vector[9]) ) && (
                         (valid_ex && |ex_rs2_addr && mem_writes_rd && (mem_rd_addr == ex_rs2_addr)));

assign arith_after_arith_with_intermediate_independent_operation_rs1 = ((ex_inst_vector[10] || ex_inst_vector[9]) && (mem_inst_vector[10] || mem_inst_vector[9])) && (
                         (valid_ex && |ex_rs1_addr && mem_writes_rd && (mem_rd_addr == ex_rs1_addr)));

assign arith_after_arith_with_intermediate_independent_operation_rs2 = ((ex_inst_vector[10] || ex_inst_vector[9]) && (mem_inst_vector[10] || mem_inst_vector[9])) && (
                         (valid_ex && |ex_rs2_addr && mem_writes_rd && (mem_rd_addr == ex_rs2_addr)));

// Ex-ex forwarding
wire arith_arith_ex_ex_forwarding = RAW_hazard_id_ex && (ex_inst_vector[10] || ex_inst_vector[9]) && (mem_inst_vector[10] || mem_inst_vector[9]);

assign mem_hazard= store_or_load_after_base_modification_ex_mem_with_stall;
assign pc_hazzard = valid_ex && ex_redirect;

// Stall IF/ID and freeze PC on Load-Use hazard 
assign freeze_pc    = mem_hazard;
assign stall_if_id  = mem_hazard;
assign stall_id_ex  = 1'b0;
assign stall_ex_mem = 1'b0;
assign stall_mem_wb = 1'b0;

// Flush ID/EX when stalling  or on correcting a mispredicted branch or jump
assign clear_if_id  = pc_hazzard;
assign clear_id_ex  = pc_hazzard || mem_hazard;
assign clear_ex_mem = 1'b0;
assign clear_mem_wb = 1'b0;


// we need to develop the Mem-EX: 2-cycle distance RAW
// we are in the meme stage and are seeing if essetially whatver we are sseing again if the inscction realies on whatver s about to wb. So here it would be wrttien essetially to rs1 or rs2 the alu output.
// final forwaeifng sinals should have peieorty for 1-cycle then 2 cycle.

assign   mem_ex_forwarding     = ~RAW_hazard_in_ex & RAW_hazard_in_mem;

// Ex to Ex signal -> RAW: 1-cycle distance RAW
// We are in the Ex stage and e are sisng if essentially the nextinsuctions r1 or r2 depended on essetially the current inscution in ex
// if so we raise the froewrding singal and maki it so that the ALU pipes rs1 data or rs2 data input is overwriteeen with the current alu ouput

assign ex_ex_forwarding_rs1 =RAW_hazzard_in_ex && (ex_rs1_addr == ex_rd_addr);
assign ex_ex_forwarding_rs2 =RAW_hazzard_in_ex && (ex_rs2_addr == ex_rd_addr);


assign mem_ex_forwarding_rs1_load_rslt_rs1 = 
assign mem_ex_forwarding_rs1_load_rslt_rs2 =

assign mem_ex_forwarding_rs1_piped_rs1 = 
assign mem_ex_forwarding_rs2_piped_rs2 =

assign o_trap = valid_wb && wb_inst_vector[0];


endmodule