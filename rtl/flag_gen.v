module flag_gen (
    input  wire [6:0] opcode,
    output reg [5:0] flag,
    output wire is_rtype,
    output wire is_itype_alu,
    output wire is_load,
    output wire is_store,
    output wire is_branch,
    output wire is_jal,
    output wire is_jalr,
    output wire is_lui,
    output wire is_auipc
);
    assign is_rtype = (opcode == 7'b0110011);
    assign is_itype_alu = (opcode == 7'b0010011);
    assign is_load = (opcode == 7'b0000011);
    assign is_store = (opcode == 7'b0100011);
    assign is_branch = (opcode == 7'b1100011);
    assign is_jal = (opcode == 7'b1101111);
    assign is_jalr = (opcode == 7'b1100111);
    assign is_lui = (opcode == 7'b0110111);
    assign is_auipc = (opcode == 7'b0010111);
    // assigning flag based on type of instruction
    always @(*) begin
        case (opcode)
            7'b0110011: flag = 6'b000001; //R 

            7'b1100111,                   //I (jalr)
            7'b0000011,                   //I (load)
            7'b0010011: flag = 6'b000010; //I (addi)

            7'b0100011: flag = 6'b000100; //S (store)

            7'b1100011: flag = 6'b001000; //B

            7'b0110111,
            7'b0010111: flag = 6'b010000; //U 

            7'b1101111: flag = 6'b100000; //J (jal)
            default: flag = 6'b000000;
        endcase
    end

endmodule