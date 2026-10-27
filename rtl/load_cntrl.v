module load_cntrl (
    input  wire [31:0] i_dmem_rdata,
    input  wire [31:0] alu_rslt,
    input  wire [2:0]  funct3,
    output reg  [31:0] o_load_data
);

    wire [1:0]  offset;
    wire [7:0]  selected_byte;
    wire [15:0] selected_half;

    assign offset = alu_rslt[1:0];

    // Pick byte using ternary mux (no dynamic bit shifts)
    assign selected_byte = (offset == 2'b00) ? i_dmem_rdata[7:0]   :
                           (offset == 2'b01) ? i_dmem_rdata[15:8]  :
                           (offset == 2'b10) ? i_dmem_rdata[23:16] :
                                               i_dmem_rdata[31:24];

    // Pick halfword using ternary mux (aligned to offset[1])
    assign selected_half = offset[1] ? i_dmem_rdata[31:16] : i_dmem_rdata[15:0];

    always @(*) begin
        case (funct3)
            3'b000:  o_load_data = {{24{selected_byte[7]}}, selected_byte}; // LB
            3'b001:  o_load_data = {{16{selected_half[15]}}, selected_half}; // LH
            3'b010:  o_load_data = i_dmem_rdata;                             // LW
            3'b100:  o_load_data = {24'b0, selected_byte};                  // LBU
            3'b101:  o_load_data = {16'b0, selected_half};                  // LHU
            default: o_load_data = 32'b0;
        endcase
    end

endmodule