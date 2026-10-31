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
    // pipe between instruction fetch and instruction decode stage
    always @(posedge clk) begin
        if(!rst_n) begin
            id_pc <= 32'b0;
            id_inst <= 32'h00000000;
            id_valid <= 1'b0;
        end
        else if (flush) begin
            id_pc <= 32'b0;
            id_inst <= 32'h00000000;
            id_valid <= 1'b0;
        end
        else if (stall)begin
            id_pc <= id_pc;
            id_inst <= id_inst;
            id_valid <= id_valid;
        end else begin  // stalling 
            id_pc <= if_pc;
            id_inst <= if_inst;
            id_valid <= if_valid;
        end


    end

endmodule