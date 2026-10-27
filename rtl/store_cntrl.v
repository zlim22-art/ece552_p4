module store_cntrl (
    input  wire [31:0] rs2_data,
    input  wire [31:0] alu_rslt,

    output wire [31:0] o_store_data
);

    wire [1:0] offset;
    assign offset = alu_rslt[1:0];

    // Align based on offset using fixed slice concatenation
    assign o_store_data = (offset == 2'b00) ? rs2_data :
                          (offset == 2'b01) ? {rs2_data[23:0],  8'b0} :
                          (offset == 2'b10) ? {rs2_data[15:0], 16'b0} :
                                              {rs2_data[7:0],  24'b0};

endmodule