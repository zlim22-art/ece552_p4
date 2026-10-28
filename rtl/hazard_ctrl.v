module hazard_ctrl(
    input wire clk,
    input wire [4:0] rs1_addr,
    input wire [4:0] rs2_addr,
    


    input wire is_load,
    input wire is_store,

    input wire ex_is_load,
    input wire ex_is_store,

    input wire mem_is_load,
    input wire mem_is_store,

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
wire mem_hazard;
wire RAW_hazzard;
wire RAW_hazzard_in_ex;
wire RAW_hazzard_in_mem;
wire pc_hazzard;
wire pc_hazzard_in_ex;
wire cntrl_hazzard;
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

// adreses matches for RAW or is for whatver reason your wirritng and the next oneis indexing usngt the same one. 

assign mem_hazard = (is_load || is_store) && (
                        ( (ex_is_load || ex_is_store) && |ex_rd_addr && (rs1_addr == ex_rd_addr) ) ||
                        ( (mem_is_load || mem_is_store) && |mem_rd_addr && (rs1_addr == mem_rd_addr) )
                        );

// contorl hazard
assign flush_if_id=ex_redirect;
assign flush_id_ex=ex_redirect;


//

// Stlls makes it insert noops and also not chnage its current value. So the vlaues being frwared all all zero
assign stall_if_id=(RAW_hazzard) ||  ex_redirect || mem_hazard;
assign stall_id_ex=(RAW_hazzard) || ex_redirect || mem_hazard ;


// memeory hazard

assign clear_if_id=(pc_hazzard || ebreak_triggered);
assign 0_trap=( ~|ex_mem_flgs && ~|mem_wb_flgs) && ebreak_triggered;



endmodule