module hazard_ctrl(

    input wire [4:0] rs1_addr,
    input wire [4:0] rs2_addr,
    
    input wire [5:0] id_flags,
    input wire [5:0] id_ex_flgs,
    input wire [5:0] ex_mem_flgs,
    input wire [5:0] mem_wb_flgs,

    input wire ebreak_triggered, // shpuld be some voule stored in a flop maybe
    input wire [4:0] ex_rd_addr,
    input wire [4:0] mem_rd_addr,
    input wire [4:0] wb_rd_addr,

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

wire RAW_hazzard;
wire RAW_hazzard_in_ex;
wire RAW_hazzard_in_mem;
wire pc_hazzard;
wire pc_hazzard_in_ex;
wire pc_hazzard_in_mem;

// for RAW hazzard
assign uses_rs1 = flag[0] || flag[1] || flag[2] || flag[3];

assign writes_ahead =(ex_mem_flgs[0] ||ex_mem_flgs[1] || ex_mem_flgs[2] || ex_mem_flgs[3]) || 
                        ((mem_wb_flgs[0] || mem_wb_flgs[1] || mem_wb_flgs[2] || mem_wb_flgs[3]));

// TODO: RAw hazards need to factor in like the current op and the ufitre pipes ops. 
assign RAW_hazzard_in_ex=(id_uses_rs1 && writes_ahead && |id_rs1_addr) && 
                            ((rs1_addr ==ex_rd_addr) || 
                            (rs2_addr ==ex_rd_addr));

assign RAW_hazzard_in_mem=(uses_rs1 && writes_ahead && |rs1_addr) && 
                            ((id_rs1_addr ==mem_rd_addr)||
                            (id_s2_addr ==mem_rd_addr));

assign  RAW_hazzard= RAW_hazzard_in_ex || RAW_hazzard_in_mem;

assign stall_if_id=(RAW_hazzard);
assign clear_id_ex=(RAW_hazzard);



// THis assumes tht PC control is movvec back

assign pc_hazzard_in_ex=ex_mem_flag[3] || ex_mem_flag[5] || ex_is_jalr;
assign pc_hazzard=  pc_hazzard_in_ex;



// ebreak neets to be set in the wb stage 
// insert nops until the brnahcing is done


// This assumes ebreak is triggered in the id stage and saved so i can spamm clear over and over again
assign clear_if_id=(pc_hazzard || ebreak_triggered);

// essetially here we input noops. untilt the whole thing is filled with noops then we raise flag and the termination is offcial.

// jalr is ,isisng come up with new way to represent if therei sinsitcitons.
assign 0_trap=( ~|ex_mem_flgs && ~|mem_wb_flgs) && ebreak_triggered;




// maybe the


endmodule