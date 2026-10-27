module alu_cntrl (
    input  wire [31:0] instruction,

    output reg [2:0] o_opsel,
    output reg o_sub,
    output reg o_unsigned,
    output reg o_arith
);
    wire [2:0] func3;
    wire [6:0] func7;
    wire [6:0] opcode;

    assign func3 = instruction[14:12];
    assign func7 = instruction[31:25];
    assign opcode = instruction[6:0];

    always @(*) begin
        case (opcode)
            7'b0110011: begin
                o_opsel = instruction[14:12];
                o_sub = (func3 == 3'b000 && func7[5]) ? 1'b1 : 1'b0;
                o_unsigned = (func3 == 3'b011);
                o_arith = (func3 == 3'b101) && instruction[30];
            end

            7'b0010011: begin 
                o_opsel    = instruction[14:12];
                o_sub      = 1'b0;
                o_unsigned = func3[0];
                o_arith    = func7[5];
            end
            7'b0010111: begin //U (auipc)
                o_opsel = 3'b000;
                o_sub = 1'b0;
                o_unsigned = 1'b0;
                o_arith = 1'b0;
            end

            7'b0000011: begin //I (load)
                o_opsel = 3'b000;
                o_sub = 1'b0;
                o_unsigned = 1'b0;
                o_arith = 1'b0;
            end

            7'b0100011: begin //S (store)
                o_opsel = 3'b000;
                o_sub = 1'b0;
                o_unsigned = 1'b0;
                o_arith = 1'b0;
            end

            7'b1100011: begin //B
                o_opsel = 3'b000;
                o_sub = 1'b1;
                o_unsigned = func3[1];
                o_arith = 1'b0;
            end

            7'b1100111: begin //I (jalr)
                o_opsel = 3'b000;
                o_sub = 1'b0;
                o_unsigned = 1'b0;
                o_arith = 1'b0;
            end

            default: begin
                o_opsel = 3'b000;
                o_sub = 1'b0;
                o_unsigned = 1'b0;
                o_arith = 1'b0;
            end
        endcase
    end

endmodule