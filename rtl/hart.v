module hart #(
    // After reset, the program counter (PC) should be initialized to this
    // address and start executing instructions from there.
    parameter RESET_ADDR = 32'h00000000
) (
    // Global clock.
    input  wire        i_clk,
    // Synchronous active-high reset.
    input  wire        i_rst,
    // Instruction fetch goes through a read only instruction memory (imem)
    // port. The port accepts a 32-bit address (e.g. from the program counter)
    // per cycle and combinationally returns a 32-bit instruction word. This
    // is not representative of a realistic memory interface; it has been
    // modeled as more similar to a DFF or SRAM to simplify phase 3. In
    // later phases, you will replace this with a more realistic memory.
    //
    // 32-bit read address for the instruction memory. This is expected to be
    // 4 byte aligned - that is, the two LSBs should be zero.
    output wire [31:0] o_imem_raddr,
    // Instruction word fetched from memory, available on the same cycle.
    input  wire [31:0] i_imem_rdata,
    // Data memory accesses go through a separate read/write data memory (dmem)
    // that is shared between read (load) and write (stored). The port accepts
    // a 32-bit address, read or write enable, and mask (explained below) each
    // cycle. Reads are combinational - values are available immediately after
    // updating the address and asserting read enable. Writes occur on (and
    // are visible at) the next clock edge.
    //
    // Read/write address for the data memory. This should be 32-bit aligned
    // (i.e. the two LSB should be zero). See `o_dmem_mask` for how to perform
    // half-word and byte accesses at unaligned addresses.
    output wire [31:0] o_dmem_addr,
    // When asserted, the memory will perform a read at the aligned address
    // specified by `i_addr` and return the 32-bit word at that address
    // immediately (i.e. combinationally). It is illegal to assert this and
    // `o_dmem_wen` on the same cycle.
    output wire        o_dmem_ren,
    // When asserted, the memory will perform a write to the aligned address
    // `o_dmem_addr`. When asserted, the memory will write the bytes in
    // `o_dmem_wdata` (specified by the mask) to memory at the specified
    // address on the next rising clock edge. It is illegal to assert this and
    // `o_dmem_ren` on the same cycle.
    output wire        o_dmem_wen,
    // The 32-bit word to write to memory when `o_dmem_wen` is asserted. When
    // write enable is asserted, the byte lanes specified by the mask will be
    // written to the memory word at the aligned address at the next rising
    // clock edge. The other byte lanes of the word will be unaffected.
    output wire [31:0] o_dmem_wdata,
    // The dmem interface expects word (32 bit) aligned addresses. However,
    // the processor supports byte and half-word loads and stores at unaligned and
    // 16-bit aligned addresses, respectively. To support this, the access
    // mask specifies which bytes within the 32-bit word are actually read
    // from or written to memory.
    //
    // To perform a half-word read at address 0x00001002, align `o_dmem_addr`
    // to 0x00001000, assert `o_dmem_ren`, and set the mask to 0b1100 to
    // indicate that only the upper two bytes should be read. Only the upper
    // two bytes of `i_dmem_rdata` can be assumed to have valid data; to
    // calculate the final value of the `lh[u]` instruction, shift the rdata
    // word right by 16 bits and sign/zero extend as appropriate.
    //
    // To perform a byte write at address 0x00002003, align `o_dmem_addr` to
    // `0x00002000`, assert `o_dmem_wen`, and set the mask to 0b1000 to
    // indicate that only the upper byte should be written. On the next clock
    // cycle, the upper byte of `o_dmem_wdata` will be written to memory, with
    // the other three bytes of the aligned word unaffected. Remember to shift
    // the value of the `sb` instruction left by 24 bits to place it in the
    // appropriate byte lane.
    output wire [ 3:0] o_dmem_mask,
    // The 32-bit word read from data memory. When `o_dmem_ren` is asserted,
    // this will immediately reflect the contents of memory at the specified
    // address, for the bytes enabled by the mask. When read enable is not
    // asserted, or for bytes not set in the mask, the value is undefined.
    input  wire [31:0] i_dmem_rdata,
    // The output `retire` interface is used to signal to the testbench that
    // the CPU has completed and retired an instruction. A single cycle
    // implementation will assert this every cycle; however, a pipelined
    // implementation that needs to stall (due to internal hazards or waiting
    // on memory accesses) will not assert the signal on cycles where the
    // instruction in the writeback stage is not retiring.
    //
    // Asserted when an instruction is being retired this cycle. If this is
    // not asserted, the other retire signals are ignored and may be left invalid.
    output wire        o_retire_valid,
    // The 32 bit instruction word of the instrution being retired. This
    // should be the unmodified instruction word fetched from instruction
    // memory.
    output wire [31:0] o_retire_inst,
    // Asserted if the instruction produced a trap, due to an illegal
    // instruction, unaligned data memory access, or unaligned instruction
    // address on a taken branch or jump.
    output wire        o_retire_trap,
    // Asserted if the instruction is an `ebreak` instruction used to halt the
    // processor. This is used for debugging and testing purposes to end
    // a program.
    output wire        o_retire_halt,
    // The first register address read by the instruction being retired. If
    // the instruction does not read from a register (like `lui`), this is
    // don't-care -- the grading testbench doesn't look at it in that case.
    output wire [ 4:0] o_retire_rs1_raddr,
    // The second register address read by the instruction being retired. If
    // the instruction does not read from a second register (like `addi`),
    // this is don't-care -- the grading testbench doesn't look at it in that
    // case.
    output wire [ 4:0] o_retire_rs2_raddr,
    // The first source register data read from the register file (in the
    // decode stage) for the instruction being retired. If rs1 is 5'd0, this
    // should also be 32'd0.
    output wire [31:0] o_retire_rs1_rdata,
    // The second source register data read from the register file (in the
    // decode stage) for the instruction being retired. If rs2 is 5'd0, this
    // should also be 32'd0.
    output wire [31:0] o_retire_rs2_rdata,
    // The destination register address written by the instruction being
    // retired. If the instruction does not write to a register (like `sw`),
    // this should be 5'd0.
    output wire [ 4:0] o_retire_rd_waddr,
    // The destination register data written to the register file in the
    // writeback stage by this instruction. If rd is 5'd0, this field is
    // ignored and can be treated as a don't care.
    output wire [31:0] o_retire_rd_wdata,
    // The current program counter of the instruction being retired - i.e.
    // the instruction memory address that the instruction was fetched from.
    output wire [31:0] o_retire_pc,
    // the next program counter after the instruction is retired. For most
    // instructions, this is `o_retire_pc + 4`, but must be the branch or jump
    // target for *taken* branches and jumps.
    output wire [31:0] o_retire_next_pc

`ifdef RISCV_FORMAL
    ,`RVFI_OUTPUTS
`endif
);
    
    wire [31:0] pc;
    wire [31:0] pc_plus4;
    wire [31:0] rs1_data, rs2_data, imm;
    wire is_rtype, is_itype_alu, is_load, is_store, is_branch;
    wire is_jal, is_jalr, is_lui, is_auipc;
    wire [2:0]  alu_opsel;
    wire alu_sub, alu_unsigned, alu_arith;
    wire is_ebreak;
    wire [31:0] alu_result;
    wire alu_eq, alu_slt, alu_n, alu_z, alu_v, alu_c;
    wire [31:0] load_data;
    wire memory_misaligned;
    wire [31:0] if_inst;
    wire [31:0] id_pc;
    wire [31:0] id_inst;
    wire [4:0]  id_rs1_addr;
    wire [4:0]  id_rs2_addr;
    wire stall_pc;
    wire stall_if_id;
    wire clear_if_id;
    wire if_valid;
    wire id_valid;
    wire [31:0] ex_next_pc;
    wire [5:0] id_flags;
    wire invalid_instruction;
    wire [31:0] ex_pc;
    wire [31:0] ex_inst;
    wire [31:0] ex_imm;
    wire [31:0] ex_rs1_data;
    wire [31:0] ex_rs2_data;
    wire [4:0] ex_rs1_addr;
    wire [4:0] ex_rs2_addr;
    wire ex_is_auipc;
    wire ex_is_jal;
    wire ex_is_jalr;
    wire ex_is_branch;
    wire ex_is_load;
    wire ex_is_store;
    wire ex_is_rtype;
    wire ex_is_itype;
    wire ex_is_lui;
    wire [5:0] ex_flag;
    wire ex_i_sub;
    wire ex_i_arith;
    wire ex_i_unsigned;
    wire [2:0] ex_op_sell;
    wire ex_valid;
    wire ex_is_ebreak;
    wire ex_invalid_instruction;
    wire ex_redirect_raw;
    wire ex_redirect;
    wire [31:0] mem_pc;
    wire [31:0] mem_inst;
    wire [31:0] mem_imm;
    wire [31:0] mem_rs1_data;
    wire [31:0] mem_rs2_data;
    wire [31:0] mem_alu_result;
    wire [4:0] mem_rs1_addr;
    wire [4:0] mem_rs2_addr;
    wire [31:0] mem_next_pc;
    wire mem_is_auipc;
    wire mem_is_jal;
    wire mem_is_jalr;
    wire mem_is_branch;
    wire mem_is_load;
    wire mem_is_store;
    wire mem_is_rtype;
    wire mem_is_itype;
    wire mem_is_lui;
    wire mem_valid;
    wire mem_is_ebreak;
    wire mem_invalid_instruction;
    wire [31:0] wb_mem_pc;
    wire [31:0] wb_pc_rslt;
    wire [31:0] wb_imm;
    wire [31:0] wb_load_rslt;
    wire [31:0] wb_alu_result;
    wire [31:0] wb_inst;
    wire [4:0] wb_write_dad_addrs;
    wire [4:0] wb_rs1_addr;
    wire [4:0] wb_rs2_addr;
    wire wb_is_lui;
    wire wb_is_jal;
    wire wb_is_jalr;
    wire wb_is_load;
    wire wb_writes_rd;
    wire wb_valid;
    wire wb_is_ebreak;
    wire wb_trap;
    wire [4:0] wb_rd_addr;
    wire [31:0] wb_rd_data;
    wire wb_regwrite;
    wire mem_regwrite;
    wire mem_trap;
    wire ex_regwrite;

    fetch #(
        .RESET_ADDR(RESET_ADDR)
    ) fetch_inst (
        .clk(i_clk),
        .rst_n(~i_rst),
        .stall(stall_pc),
        .redirect(ex_redirect),
        .next_pc(ex_next_pc),
        .current_pc(pc),
        .pc_plus4(pc_plus4)
    );

    assign o_imem_raddr = pc;
    assign if_inst = i_imem_rdata;
    assign if_valid = !i_rst;

    if_id_pipline if_id_inst (
        .clk(i_clk),
        .rst_n(~i_rst),
        .stall(stall_if_id),
        .flush(clear_if_id),
        .if_pc(pc),
        .if_inst(if_inst),
        .if_valid(if_valid),
        .id_pc(id_pc),
        .id_inst(id_inst),
        .id_valid(id_valid)
    );

    // Hold Fetch whenever IF/ID is stalled.
    assign stall_pc = stall_if_id;

    decode decode_inst (
        .clk(i_clk),
        .rst_n(~i_rst),
        .instruction(id_inst),
        .write_dad_addrs(wb_rd_addr),
        .wb_load_rslt(wb_rd_data),
        .wb_write_enable(wb_regwrite),
        .rs1_data(rs1_data),
        .rs2_data(rs2_data),
        .imm(imm),
        .flag(id_flags),
        .is_rtype(is_rtype),
        .is_itype_alu(is_itype_alu),
        .is_load(is_load),
        .is_store(is_store),
        .is_branch(is_branch),
        .is_jal(is_jal),
        .is_jalr(is_jalr),
        .is_lui(is_lui),
        .is_auipc(is_auipc),
        .o_opsel(alu_opsel),
        .o_sub(alu_sub),
        .o_unsigned(alu_unsigned),
        .o_arith(alu_arith),
        .invalid_instruction(invalid_instruction),
        .is_ebreak(is_ebreak),
        .rs1_addr(id_rs1_addr),
        .rs2_addr(id_rs2_addr)
    );

    id_ex_pipeline id_ex_inst (
        .clk(i_clk),
        .rst_n(~i_rst),
        .flush(clear_id_ex),
        .stall(stall_id_ex),
        .id_pc(id_pc),
        .id_inst(id_inst),
        .id_rs1_addr(id_rs1_addr),
        .id_rs2_addr(id_rs2_addr),
        .id_valid(id_valid),
        .imm(imm),
        .rs1_data(rs1_data),
        .rs2_data(rs2_data),
        .is_auipc(is_auipc),
        .is_jal(is_jal),
        .is_jalr(is_jalr),
        .is_branch(is_branch),
        .is_load(is_load),
        .is_store(is_store),
        .is_rtype(is_rtype),
        .is_itype(is_itype_alu),
        .is_lui(is_lui),
        .flag(id_flags),
        .i_sub(alu_sub),
        .i_arith(alu_arith),
        .i_unsigned(alu_unsigned),
        .op_sell(alu_opsel),
        .is_ebreak(is_ebreak),
        .invalid_instruction(invalid_instruction),
        .ex_pc(ex_pc),
        .ex_inst(ex_inst),
        .ex_rs1_addr(ex_rs1_addr),
        .ex_rs2_addr(ex_rs2_addr),
        .ex_imm(ex_imm),
        .ex_rs1_data(ex_rs1_data),
        .ex_rs2_data(ex_rs2_data),
        .ex_is_auipc(ex_is_auipc),
        .ex_is_jal(ex_is_jal),
        .ex_is_jalr(ex_is_jalr),
        .ex_is_branch(ex_is_branch),
        .ex_is_load(ex_is_load),
        .ex_is_store(ex_is_store),
        .ex_is_rtype(ex_is_rtype),
        .ex_is_itype(ex_is_itype),
        .ex_is_lui(ex_is_lui),
        .ex_flag(ex_flag),
        .ex_i_sub(ex_i_sub),
        .ex_i_arith(ex_i_arith),
        .ex_i_unsigned(ex_i_unsigned),
        .ex_op_sell(ex_op_sell),
        .ex_valid(ex_valid),
        .ex_is_ebreak(ex_is_ebreak),
        .ex_invalid_instruction(ex_invalid_instruction)
    );

    execute execute_inst (
        .alu_opsel(ex_op_sell),
        .alu_sub(ex_i_sub),
        .alu_unsigned(ex_i_unsigned),
        .alu_arith(ex_i_arith),
        .is_auipc(ex_is_auipc),
        .flag(ex_flag),
        .pc(ex_pc),
        .instruction(ex_inst),
        .rs1_data(ex_rs1_data),
        .rs2_data(ex_rs2_data),
        .imm(ex_imm),
        .is_jal(ex_is_jal),
        .is_jalr(ex_is_jalr),
        .is_branch(ex_is_branch),
        .is_ebreak(ex_is_ebreak),
        .alu_result(alu_result),
        .alu_eq(alu_eq),
        .alu_slt(alu_slt),
        .alu_n(alu_n),
        .alu_z(alu_z),
        .alu_v(alu_v),
        .alu_c(alu_c),
        .nxt_pc(ex_next_pc),
        .ex_redirect(ex_redirect_raw)
    );

    ex_mem_pipeline ex_mem_inst (
        .clk(i_clk),
        .rst_n(~i_rst),
        .flush(clear_ex_mem),
        .stall(stall_ex_mem),
        .ex_pc(ex_pc),
        .ex_inst(ex_inst),
        .ex_imm(ex_imm),
        .ex_rs1_data(ex_rs1_data),
        .ex_rs2_data(ex_rs2_data),
        .ex_is_auipc(ex_is_auipc),
        .ex_is_jal(ex_is_jal),
        .ex_is_jalr(ex_is_jalr),
        .ex_is_branch(ex_is_branch),
        .ex_is_load(ex_is_load),
        .ex_is_store(ex_is_store),
        .ex_is_rtype(ex_is_rtype),
        .ex_is_itype(ex_is_itype),
        .ex_is_lui(ex_is_lui),
        .alu_result(alu_result),
        .ex_next_pc(ex_next_pc),
        .ex_valid(ex_valid),
        .ex_is_ebreak(ex_is_ebreak),
        .ex_invalid_instruction(ex_invalid_instruction),
        .ex_rs1_addr(ex_rs1_addr),
        .ex_rs2_addr(ex_rs2_addr),
        .mem_pc(mem_pc),
        .mem_inst(mem_inst),
        .mem_imm(mem_imm),
        .mem_rs1_data(mem_rs1_data),
        .mem_rs2_data(mem_rs2_data),
        .mem_alu_result(mem_alu_result),
        .mem_is_auipc(mem_is_auipc),
        .mem_is_jal(mem_is_jal),
        .mem_is_jalr(mem_is_jalr),
        .mem_is_branch(mem_is_branch),
        .mem_is_load(mem_is_load),
        .mem_is_store(mem_is_store),
        .mem_is_rtype(mem_is_rtype),
        .mem_is_itype(mem_is_itype),
        .mem_is_lui(mem_is_lui),
        .mem_valid(mem_valid),
        .mem_is_ebreak(mem_is_ebreak),
        .mem_invalid_instruction(mem_invalid_instruction),
        .mem_next_pc(mem_next_pc),
        .mem_rs1_addr(mem_rs1_addr),
        .mem_rs2_addr(mem_rs2_addr)
    );

    assign ex_redirect = ex_valid && ex_redirect_raw;

    mem mem_inst (
        .i_dmem_rdata(i_dmem_rdata),
        .rs2_data(mem_rs2_data),
        .alu_result(mem_alu_result),
        .instruction(mem_inst),
        .is_load(mem_is_load),
        .is_store(mem_is_store),
        .illegal_instruction(mem_invalid_instruction),
        .mem_valid(mem_valid),
        .i_rst(i_rst),
        .load_data(load_data),
        .o_dmem_addr(o_dmem_addr),
        .o_dmem_mask(o_dmem_mask),
        .o_dmem_wdata(o_dmem_wdata),
        .o_dmem_ren(o_dmem_ren),
        .o_dmem_wen(o_dmem_wen),
        .memory_misaligned(memory_misaligned)
    );

    mem_wb_pipline mem_wb_inst (
        .clk(i_clk),
        .rst_n(~i_rst),
        .flush(clear_mem_wb),
        .stall(stall_mem_wb),
        .mem_pc(mem_pc),
        .pc_rslt(mem_next_pc),
        .imm(mem_imm),
        .load_rslt(load_data),
        .alu_result(mem_alu_result),
        .mem_inst(mem_inst),
        .write_dad_addrs(mem_inst[11:7]),
        .mem_rs1_addr(mem_rs1_addr),
        .mem_rs2_addr(mem_rs2_addr),
        .mem_rs1_data(mem_rs1_data),
        .mem_rs2_data(mem_rs2_data),
        .is_lui(mem_is_lui),
        .is_jal(mem_is_jal),
        .is_jalr(mem_is_jalr),
        .is_load(mem_is_load),
        .mem_regwrite(mem_regwrite),
        .mem_valid(mem_valid),
        .mem_is_ebreak(mem_is_ebreak),
        .mem_trap(mem_trap),
        .wb_mem_pc(wb_mem_pc),
        .wb_pc_rslt(wb_pc_rslt),
        .wb_imm(wb_imm),
        .wb_load_rslt(wb_load_rslt),
        .wb_alu_result(wb_alu_result),
        .wb_inst(wb_inst),
        .wb_write_dad_addrs(wb_write_dad_addrs),
        .wb_rs1_addr(wb_rs1_addr),
        .wb_rs2_addr(wb_rs2_addr),
        .wb_rs1_data(wb_rs1_data),
        .wb_rs2_data(wb_rs2_data),
        .wb_is_lui(wb_is_lui),
        .wb_is_jal(wb_is_jal),
        .wb_is_jalr(wb_is_jalr),
        .wb_is_load(wb_is_load),
        .wb_writes_rd(wb_writes_rd),
        .wb_valid(wb_valid),
        .wb_is_ebreak(wb_is_ebreak),
        .wb_trap(wb_trap)
    );

    assign mem_trap = mem_invalid_instruction || memory_misaligned;

    assign mem_regwrite = mem_valid &&
        !mem_trap &&
        (mem_is_rtype ||
        mem_is_itype ||
        mem_is_load ||
        mem_is_lui ||
        mem_is_auipc ||
        mem_is_jal ||
        mem_is_jalr) &&
        (mem_inst[11:7] != 5'd0);
    
    hazard_ctrl hazard_ctrl_inst (
        .rs1_addr(id_inst[19:15]),
        .rs2_addr(id_inst[24:20]),
        .id_uses_rs1(uses_rs1),
        .id_uses_rs2(uses_rs2),
        .id_flags(id_flags),
        .id_ex_flgs(ex_flag),
        .ex_mem_flgs(mem_flags),
        .mem_wb_flgs(wb_flags),
        .ebreak_triggered(is_ebreak),
        .ex_rd_addr(ex_inst[11:7]),
        .mem_rd_addr(mem_inst[11:7]),
        .ex_redirect(ex_redirect),
        .stall_ex_mem(stall_ex_mem),
        .stall_id_ex(stall_id_ex),
        .stall_if_id(stall_if_id),
        .stall_mem_wb(stall_mem_wb),
        .clear_ex_mem(clear_ex_mem),
        .clear_id_ex(clear_id_ex),
        .clear_if_id(clear_if_id),
        .clear_mem_wb(clear_mem_wb),
        .o_trap(hazard_trap),
        .ex_regwrite(ex_regwrite),
        .mem_regwrite(mem_regwrite),
        .wb_regwrite(wb_regwrite),
        .wb_rd_addr(wb_rd_addr)
    );

    assign wb_rd_data =
        wb_is_lui ? wb_imm :
        (wb_is_jal || wb_is_jalr) ?
            (wb_mem_pc + 32'd4) :
        wb_is_load ? wb_load_rslt :
        wb_alu_result;

    assign wb_rd_addr = wb_write_dad_addrs;

    assign wb_regwrite =
        wb_valid &&
        wb_writes_rd &&
        !wb_trap &&
        (wb_rd_addr != 5'd0);

    assign ex_regwrite =
        ex_valid &&
        !ex_invalid_instruction &&
        (ex_is_rtype ||
        ex_is_itype ||
        ex_is_load ||
        ex_is_lui ||
        ex_is_auipc ||
        ex_is_jal ||
        ex_is_jalr) &&
        (ex_inst[11:7] != 5'd0);

    // wire uses_rs1 = id_valid && (is_rtype || is_itype_alu || is_load || is_store || is_branch || is_jalr);
    // wire uses_rs2 = id_valid && (is_rtype || is_store || is_branch);

    wire wb_uses_rs1 = wb_valid && (wb_inst[6:0] == 7'b0110011 || wb_inst[6:0] == 7'b0010011 || wb_inst[6:0] == 7'b0000011 || wb_inst[6:0] == 7'b0100011 || wb_inst[6:0] == 7'b1100011 || wb_inst[6:0] == 7'b1100111);
    wire wb_uses_rs2 = wb_valid && (wb_inst[6:0] == 7'b0110011 || wb_inst[6:0] == 7'b0100011 || wb_inst[6:0] == 7'b1100011);


    assign o_retire_valid     = wb_valid;
    //Changed from instruction to wb_inst after passing through all pipes
    assign o_retire_inst      = wb_inst;
    // TODO: do we pass through iligal isncutions all the way torugh or do we isnert noop? ALex-> I think it should be like we pass it all the way through
    assign o_retire_trap      = wb_trap;
    assign o_retire_halt      = wb_halt;
    //TODO: Change from instruction[19:15] to wb_rs1_addr and instruction[24:20] to wb_rs2_addr after passing through the fetch pipe
    assign o_retire_rs1_raddr = wb_uses_rs1 ? wb_rs1_addr : 5'd0;
    assign o_retire_rs2_raddr = wb_uses_rs2 ? wb_rs2_addr : 5'd0;
    //Changed rs1_data and rs2_data to ex_reg_data_1 and ex_reg_data_2 after passing through all pipes
    assign o_retire_rs1_rdata = wb_reg_data_1;
    assign o_retire_rs2_rdata = wb_reg_data_2;

    wire reg_write_allowed = wb_regwrite;
    //TODO: Change from rd_waddr to wb_write_dad_addrs after passing through the mem pipe
    assign o_retire_rd_waddr  = reg_write_allowed ? wb_write_dad_addrs : 5'd0;

    assign o_retire_rd_wdata  = wb_data_out;
    assign o_retire_pc        = wb_mem_pc;
    assign o_retire_next_pc   = wb_pc_rslt;

endmodule

`default_nettype wire
