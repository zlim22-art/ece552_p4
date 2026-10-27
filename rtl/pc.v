module pc #(
    parameter RESET_ADDR = 32'h0000_0000 // Passed as a parameter, not a 1-bit wire
)(
    input wire clk,
    input wire rst_n, // Assuming active-low reset based on the '_n'
    input wire [31:0] next_pc,
    input wire redirect,
    input wire stall,
    output reg [31:0] current_pc
);

    always @(posedge clk) begin
        if (!rst_n)
            current_pc <= RESET_ADDR;
        else if (redirect)
            current_pc <= next_pc;
        else if (!stall)
            current_pc <= current_pc + 32'd4;
    end

endmodule