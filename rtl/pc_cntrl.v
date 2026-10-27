module pc_cntrl (
    input wire [2:0]   functionselect,
    input wire         jmp_flag,        // jump
    input wire         jalr_flag,       // jalr
    input wire         branchStatus,
    input wire         z,
    input wire         n,
    input wire         v,
    input wire         c,
    input wire         ebreak_flag,
    input wire [31:0]  pc_curr,
    input wire [31:0]  imm_j,
    input wire [31:0]  imm_b,
    input wire [31:0]  alu_rslt,
    output wire [31:0] pc_nxt,
    output wire        redirect
);

    wire branch_taken;

    assign branch_taken = (functionselect == 3'b000) ? z :
                          (functionselect == 3'b001) ? ~z :
                          (functionselect == 3'b100) ? (n ^ v) :
                          (functionselect == 3'b101) ? ~(n ^ v) :
                          (functionselect == 3'b110) ? ~c :
                          (functionselect == 3'b111) ? c : 1'b0;

    assign redirect = jmp_flag || jalr_flag || (branch_taken && branchStatus);

    assign pc_nxt = ebreak_flag                   ? pc_curr :
                    jmp_flag                      ? (imm_j + pc_curr) :
                    jalr_flag                     ? (alu_rslt & 32'hFFFFFFFE) :
                    (branch_taken & branchStatus) ? (imm_b + pc_curr) :
                                                    (pc_curr + 32'd4);

endmodule