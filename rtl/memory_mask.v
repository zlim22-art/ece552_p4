module memory_mask (
    input  wire [31:0] alu_rslt,
    input  wire [2:0]  funct3,
    output reg  [3:0]  o_mem_mask
);

    wire [1:0] offset;
    assign offset = alu_rslt[1:0];

    always @(*) begin
        case (funct3[1:0])
            // Byte: decode each offset explicitly via ternary
            2'b00: o_mem_mask = (offset == 2'b00) ? 4'b0001 :
                                (offset == 2'b01) ? 4'b0010 :
                                (offset == 2'b10) ? 4'b0100 : 4'b1000;

            // Halfword: bottom half vs top half based on offset[1]
            2'b01: o_mem_mask = offset[1] ? 4'b1100 : 4'b0011;

            // Word
            2'b10: o_mem_mask = 4'b1111;

            default: o_mem_mask = 4'b0000;
        endcase
    end

endmodule