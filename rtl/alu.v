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

    wire [32:0] add_ext;
    wire [31:0] add_sub_res;
    wire [31:0] shift_left;
    wire [31:0] shift_right;

    assign add_ext     = {1'b0, i_op1} + {1'b0, i_op2};
    assign add_sub_res = i_sub ? (i_op1 - i_op2) : add_ext[31:0];

    // Equality & Zero
    assign o_eq = (i_op1 == i_op2);
    assign o_z  = (o_result == 32'b0);
    assign o_n  = o_result[31];

    assign o_v = (i_opsel == 3'b000) ? 
                 (i_sub ? ((i_op1[31] != i_op2[31]) && (i_op1[31] != add_sub_res[31])) 
                        : ((i_op1[31] == i_op2[31]) && (i_op1[31] != add_sub_res[31]))) 
                 : 1'b0;

    assign o_c = (i_opsel == 3'b000) ? 
                 (i_sub ? (i_op1 >= i_op2) : add_ext[32]) 
                 : 1'b0;

    assign o_slt = i_unsigned ? 
                   (i_op1 < i_op2) : 
                   ((i_op1[31] != i_op2[31]) ? i_op1[31] : (i_op1 < i_op2));

    assign shift_left =
        (i_op2[4:0] == 5'd0)  ? i_op1 :
        (i_op2[4:0] == 5'd1)  ? {i_op1[30:0], 1'b0} :
        (i_op2[4:0] == 5'd2)  ? {i_op1[29:0], 2'b0} :
        (i_op2[4:0] == 5'd3)  ? {i_op1[28:0], 3'b0} :
        (i_op2[4:0] == 5'd4)  ? {i_op1[27:0], 4'b0} :
        (i_op2[4:0] == 5'd5)  ? {i_op1[26:0], 5'b0} :
        (i_op2[4:0] == 5'd6)  ? {i_op1[25:0], 6'b0} :
        (i_op2[4:0] == 5'd7)  ? {i_op1[24:0], 7'b0} :
        (i_op2[4:0] == 5'd8)  ? {i_op1[23:0], 8'b0} :
        (i_op2[4:0] == 5'd9)  ? {i_op1[22:0], 9'b0} :
        (i_op2[4:0] == 5'd10) ? {i_op1[21:0], 10'b0} :
        (i_op2[4:0] == 5'd11) ? {i_op1[20:0], 11'b0} :
        (i_op2[4:0] == 5'd12) ? {i_op1[19:0], 12'b0} :
        (i_op2[4:0] == 5'd13) ? {i_op1[18:0], 13'b0} :
        (i_op2[4:0] == 5'd14) ? {i_op1[17:0], 14'b0} :
        (i_op2[4:0] == 5'd15) ? {i_op1[16:0], 15'b0} :
        (i_op2[4:0] == 5'd16) ? {i_op1[15:0], 16'b0} :
        (i_op2[4:0] == 5'd17) ? {i_op1[14:0], 17'b0} :
        (i_op2[4:0] == 5'd18) ? {i_op1[13:0], 18'b0} :
        (i_op2[4:0] == 5'd19) ? {i_op1[12:0], 19'b0} :
        (i_op2[4:0] == 5'd20) ? {i_op1[11:0], 20'b0} :
        (i_op2[4:0] == 5'd21) ? {i_op1[10:0], 21'b0} :
        (i_op2[4:0] == 5'd22) ? {i_op1[9:0], 22'b0} :
        (i_op2[4:0] == 5'd23) ? {i_op1[8:0], 23'b0} :
        (i_op2[4:0] == 5'd24) ? {i_op1[7:0], 24'b0} :
        (i_op2[4:0] == 5'd25) ? {i_op1[6:0], 25'b0} :
        (i_op2[4:0] == 5'd26) ? {i_op1[5:0], 26'b0} :
        (i_op2[4:0] == 5'd27) ? {i_op1[4:0], 27'b0} :
        (i_op2[4:0] == 5'd28) ? {i_op1[3:0], 28'b0} :
        (i_op2[4:0] == 5'd29) ? {i_op1[2:0], 29'b0} :
        (i_op2[4:0] == 5'd30) ? {i_op1[1:0], 30'b0} :
        (i_op2[4:0] == 5'd31) ? {i_op1[0], 31'b0} :
        32'b0;

    assign shift_right =
        (i_op2[4:0] == 5'd0)  ? i_op1 :
        (i_op2[4:0] == 5'd1)  ? {{1{ i_arith ? i_op1[31] : 1'b0}}, i_op1[31:1]} :
        (i_op2[4:0] == 5'd2)  ? {{2{ i_arith ? i_op1[31] : 1'b0}}, i_op1[31:2]} :
        (i_op2[4:0] == 5'd3)  ? {{3{ i_arith ? i_op1[31] : 1'b0}}, i_op1[31:3]} :
        (i_op2[4:0] == 5'd4)  ? {{4{ i_arith ? i_op1[31] : 1'b0}}, i_op1[31:4]} :
        (i_op2[4:0] == 5'd5)  ? {{5{ i_arith ? i_op1[31] : 1'b0}}, i_op1[31:5]} :
        (i_op2[4:0] == 5'd6)  ? {{6{ i_arith ? i_op1[31] : 1'b0}}, i_op1[31:6]} :
        (i_op2[4:0] == 5'd7)  ? {{7{ i_arith ? i_op1[31] : 1'b0}}, i_op1[31:7]} :
        (i_op2[4:0] == 5'd8)  ? {{8{ i_arith ? i_op1[31] : 1'b0}}, i_op1[31:8]} :
        (i_op2[4:0] == 5'd9)  ? {{9{ i_arith ? i_op1[31] : 1'b0}}, i_op1[31:9]} :
        (i_op2[4:0] == 5'd10) ? {{10{ i_arith ? i_op1[31] : 1'b0}}, i_op1[31:10]} :
        (i_op2[4:0] == 5'd11) ? {{11{ i_arith ? i_op1[31] : 1'b0}}, i_op1[31:11]} :
        (i_op2[4:0] == 5'd12) ? {{12{ i_arith ? i_op1[31] : 1'b0}}, i_op1[31:12]} :
        (i_op2[4:0] == 5'd13) ? {{13{ i_arith ? i_op1[31] : 1'b0}}, i_op1[31:13]} :
        (i_op2[4:0] == 5'd14) ? {{14{ i_arith ? i_op1[31] : 1'b0}}, i_op1[31:14]} :
        (i_op2[4:0] == 5'd15) ? {{15{ i_arith ? i_op1[31] : 1'b0}}, i_op1[31:15]} :
        (i_op2[4:0] == 5'd16) ? {{16{ i_arith ? i_op1[31] : 1'b0}}, i_op1[31:16]} :
        (i_op2[4:0] == 5'd17) ? {{17{ i_arith ? i_op1[31] : 1'b0}}, i_op1[31:17]} :
        (i_op2[4:0] == 5'd18) ? {{18{ i_arith ? i_op1[31] : 1'b0}}, i_op1[31:18]} :
        (i_op2[4:0] == 5'd19) ? {{19{ i_arith ? i_op1[31] : 1'b0}}, i_op1[31:19]} :
        (i_op2[4:0] == 5'd20) ? {{20{ i_arith ? i_op1[31] : 1'b0}}, i_op1[31:20]} :
        (i_op2[4:0] == 5'd21) ? {{21{ i_arith ? i_op1[31] : 1'b0}}, i_op1[31:21]} :
        (i_op2[4:0] == 5'd22) ? {{22{ i_arith ? i_op1[31] : 1'b0}}, i_op1[31:22]} :
        (i_op2[4:0] == 5'd23) ? {{23{ i_arith ? i_op1[31] : 1'b0}}, i_op1[31:23]} :
        (i_op2[4:0] == 5'd24) ? {{24{ i_arith ? i_op1[31] : 1'b0}}, i_op1[31:24]} :
        (i_op2[4:0] == 5'd25) ? {{25{ i_arith ? i_op1[31] : 1'b0}}, i_op1[31:25]} :
        (i_op2[4:0] == 5'd26) ? {{26{ i_arith ? i_op1[31] : 1'b0}}, i_op1[31:26]} :
        (i_op2[4:0] == 5'd27) ? {{27{ i_arith ? i_op1[31] : 1'b0}}, i_op1[31:27]} :
        (i_op2[4:0] == 5'd28) ? {{28{ i_arith ? i_op1[31] : 1'b0}}, i_op1[31:28]} :
        (i_op2[4:0] == 5'd29) ? {{29{ i_arith ? i_op1[31] : 1'b0}}, i_op1[31:29]} :
        (i_op2[4:0] == 5'd30) ? {{30{ i_arith ? i_op1[31] : 1'b0}}, i_op1[31:30]} :
        (i_op2[4:0] == 5'd31) ? {{31{ i_arith ? i_op1[31] : 1'b0}}, i_op1[31]} :
        32'b0;

    assign o_result =
        (i_opsel == 3'b000)                           ? add_sub_res :
        (i_opsel == 3'b001)                           ? shift_left :
        ((i_opsel == 3'b010) || (i_opsel == 3'b011))  ? {31'b0, o_slt} :
        (i_opsel == 3'b100)                           ? (i_op1 ^ i_op2) :
        (i_opsel == 3'b101)                           ? shift_right :
        (i_opsel == 3'b110)                           ? (i_op1 | i_op2) :
        (i_opsel == 3'b111)                           ? (i_op1 & i_op2) :
        32'b0;

endmodule

`default_nettype wire