module if_id_pipline(
    input clk,
    input rst_n,
    input wire stall,
    input wire flush,
    input [31:0] if_pc,
    input [31:0] if_inst,
    input wire if_valid,
    output reg [31:0] id_pc,
    output reg [31:0] id_inst,
    output reg id_valid
);


    always @(posedge clk) begin
        if(!rst_n) begin
            id_pc <= 32'b0;
            id_inst <= 32'h00000013;
            id_valid <= 1'b0;
        end
        else if (flush) begin
            id_pc <= 32'b0;
            id_inst <= 32'h00000013;
            id_valid <= 1'b0;
        end
        else if (!stall)begin
            id_pc <= if_pc;
            id_inst <= if_inst;
            id_valid <= if_valid;
        end

        assign id_pc = (stall) ? 32'b0 : id_pc;
        assign id_inst = (stall) ? 32'h00000013 : id_inst;
        assign id_valid = (stall) ? 1'b0 : id_valid;

    end

endmodule