`default_nettype none

module alu (
    input wire [2:0]  i_opsel,
    input wire        i_sub,
    input wire        i_unsigned,
    input wire        i_arith,
    input wire [31:0] i_op1,
    input wire [31:0] i_op2,

    output wire [31:0] o_result,
    output wire        o_eq,
    output wire        o_slt,
    output wire        o_n,
    output wire        o_z,
    output wire        o_v,
    output wire        o_c
);
    wire [31:0] shift_1, shift_2, shift_4, shift_8, shift_16;
    wire [32:0] add_ext;
    wire [31:0] add_sub_res;
    wire [31:0] shift_left;
    wire [31:0] shift_right;

    assign add_ext     = {1'b0, i_op1} + {1'b0, i_op2};
    assign add_sub_res = i_sub ? (i_op1 - i_op2) : add_ext[31:0];

    // zero, equality and negative flags
    assign o_eq = (i_op1 == i_op2);
    assign o_z  = (o_result == 32'b0);
    assign o_n  = o_result[31];
    // for overflow
    assign o_v = (i_opsel == 3'b000) ? 
                 (i_sub ? ((i_op1[31] != i_op2[31]) && (i_op1[31] != add_sub_res[31])) 
                        : ((i_op1[31] == i_op2[31]) && (i_op1[31] != add_sub_res[31]))) 
                 : 1'b0;
    // for checking carry out
    assign o_c = (i_opsel == 3'b000) ? 
                 (i_sub ? (i_op1 >= i_op2) : add_ext[32]) 
                 : 1'b0;
    // for set less than
    assign o_slt = i_unsigned ? 
                   (i_op1 < i_op2) : 
                   ((i_op1[31] != i_op2[31]) ? i_op1[31] : (i_op1 < i_op2));


    //Left shuft

    // Stage 1: Shift by 1 if i_op2[0] is 1, else keep original
    assign shift_1 = i_op2[0] ? {i_op1[30:0], 1'b0} : i_op1;

    // Stage 2: Shift by 2 if i_op2[1] is 1, else keep stage 1
    assign shift_2 = i_op2[1] ? {shift_1[29:0], 2'b00} : shift_1;

    // Stage 3: Shift by 4 if i_op2[2] is 1, else keep stage 2
    assign shift_4 = i_op2[2] ? {shift_2[27:0], 4'b0000} : shift_2;

    // Stage 4: Shift by 8 if i_op2[3] is 1, else keep stage 3
    assign shift_8 = i_op2[3] ? {shift_4[23:0], 8'b00000000} : shift_4;

    // Stage 5: Shift by 16 if i_op2[4] is 1, else keep stage 4
    assign shift_16 = i_op2[4] ? {shift_8[15:0], 16'b0000000000000000} : shift_8;

    //Logical right shift
    wire [31:0] srl_1, srl_2, srl_4, srl_8, srl_16;

    // Stage 1: Shift right by 1 if i_op2[0] is 1, else keep original
    assign srl_1 = i_op2[0] ? {1'b0, i_op1[31:1]} : i_op1;

    // Stage 2: Shift right by 2 if i_op2[1] is 1, else keep stage 1
    assign srl_2 = i_op2[1] ? {2'b00, srl_1[31:2]} : srl_1;

    // Stage 3: Shift right by 4 if i_op2[2] is 1, else keep stage 2
    assign srl_4 = i_op2[2] ? {4'b0000, srl_2[31:4]} : srl_2;

    // Stage 4: Shift right by 8 if i_op2[3] is 1, else keep stage 3
    assign srl_8 = i_op2[3] ? {8'b00000000, srl_4[31:8]} : srl_4;

    // Stage 5: Shift right by 16 if i_op2[4] is 1, else keep stage 4
    assign srl_16 = i_op2[4] ? {16'b0000000000000000, srl_8[31:16]} : srl_8;

    // Arithmetic right shift
    wire [31:0] arl_1, arl_2, arl_4, arl_8, arl_16;

    // Stage 1: Shift right by 1 if i_op2[0] is 1, else keep original
    assign arl_1 = i_op2[0] ? {{1{i_op1[31]}}, i_op1[31:1]} : i_op1;

    // Stage 2: Shift right by 2 if i_op2[1] is 1, else keep stage 1
    assign arl_2 = i_op2[1] ? {{2{i_op1[31]}}, arl_1[31:2]} : arl_1;

    // Stage 3: Shift right by 4 if i_op2[2] is 1, else keep stage 2
    assign arl_4 = i_op2[2] ? {{4{i_op1[31]}}, arl_2[31:4]} : arl_2;

    // Stage 4: Shift right by 8 if i_op2[3] is 1, else keep stage 3
    assign arl_8 = i_op2[3] ? {{8{i_op1[31]}}, arl_4[31:8]} : arl_4;

    // Stage 5: Shift right by 16 if i_op2[4] is 1, else keep stage 4
    assign arl_16 = i_op2[4] ? {{16{i_op1[31]}}, arl_8[31:16]} : arl_8;
    
    // result assigned based on operation conducted
    assign o_result =
        (i_opsel == 3'b000)                           ? add_sub_res :
        (i_opsel == 3'b001)                           ? shift_16 :
        ((i_opsel == 3'b010) || (i_opsel == 3'b011))  ? {31'b0, o_slt} :
        (i_opsel == 3'b100)                           ? (i_op1 ^ i_op2) :
        (i_opsel == 3'b101)                           ? i_arith ? arl_16 : srl_16 :
        (i_opsel == 3'b110)                           ? (i_op1 | i_op2) :
        (i_opsel == 3'b111)                           ? (i_op1 & i_op2) :
        32'b0;

endmodule

`default_nettype wire