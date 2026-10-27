`default_nettype none

module rf #(
    parameter BYPASS_EN = 0
) (
    input  wire        i_clk,
    input  wire        i_rst,

    input  wire [ 4:0] i_rs1_raddr,
    output wire [31:0] o_rs1_rdata,

    input  wire [ 4:0] i_rs2_raddr,
    output wire [31:0] o_rs2_rdata,

    input  wire        i_rd_wen,
    input  wire [ 4:0] i_rd_waddr,
    input  wire [31:0] i_rd_wdata
);

    reg [31:0] Registers [31:0];

    always @(posedge i_clk) begin
        if (i_rst) begin
            Registers[0]  <= 32'b0;
            Registers[1]  <= 32'b0;
            Registers[2]  <= 32'b0;
            Registers[3]  <= 32'b0;
            Registers[4]  <= 32'b0;
            Registers[5]  <= 32'b0;
            Registers[6]  <= 32'b0;
            Registers[7]  <= 32'b0;
            Registers[8]  <= 32'b0;
            Registers[9]  <= 32'b0;
            Registers[10] <= 32'b0;
            Registers[11] <= 32'b0;
            Registers[12] <= 32'b0;
            Registers[13] <= 32'b0;
            Registers[14] <= 32'b0;
            Registers[15] <= 32'b0;
            Registers[16] <= 32'b0;
            Registers[17] <= 32'b0;
            Registers[18] <= 32'b0;
            Registers[19] <= 32'b0;
            Registers[20] <= 32'b0;
            Registers[21] <= 32'b0;
            Registers[22] <= 32'b0;
            Registers[23] <= 32'b0;
            Registers[24] <= 32'b0;
            Registers[25] <= 32'b0;
            Registers[26] <= 32'b0;
            Registers[27] <= 32'b0;
            Registers[28] <= 32'b0;
            Registers[29] <= 32'b0;
            Registers[30] <= 32'b0;
            Registers[31] <= 32'b0;
        end else if (i_rd_wen && (i_rd_waddr != 5'd0)) begin
            Registers[i_rd_waddr] <= i_rd_wdata;
        end
    end

    generate
        if (BYPASS_EN) begin : gen_bypass

            assign o_rs1_rdata =
                (i_rs1_raddr == 5'd0) ? 32'b0 :
                (i_rd_wen && (i_rs1_raddr == i_rd_waddr)) ? i_rd_wdata :
                Registers[i_rs1_raddr];

            assign o_rs2_rdata =
                (i_rs2_raddr == 5'd0) ? 32'b0 :
                (i_rd_wen && (i_rs2_raddr == i_rd_waddr)) ? i_rd_wdata :
                Registers[i_rs2_raddr];

        end else begin : gen_no_bypass

            assign o_rs1_rdata =
                (i_rs1_raddr == 5'd0) ? 32'b0 :
                Registers[i_rs1_raddr];

            assign o_rs2_rdata =
                (i_rs2_raddr == 5'd0) ? 32'b0 :
                Registers[i_rs2_raddr];

        end
    endgenerate

endmodule
