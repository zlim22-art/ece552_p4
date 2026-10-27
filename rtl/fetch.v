module fetch #(
    parameter RESET_ADDR = 32'h0000_0000
) (
    input wire clk,
    input wire rst_n,
    input wire stall,
    input wire redirect,
    input wire [31:0] next_pc,
    output wire [31:0] current_pc, // Changed from reg to wire (driven by pc_inst)
    output wire [31:0] pc_plus4    // Added pc_plus4 output expected by hart.v
);

    pc pc_inst (
        .clk(clk),
        .rst_n(rst_n),
        .stall(stall),
        .redirect(redirect),
        .next_pc(next_pc),
        .current_pc(current_pc)
    );

    // Calculate PC + 4 for jumps/branches
    assign pc_plus4 = current_pc + 32'd4;

endmodule