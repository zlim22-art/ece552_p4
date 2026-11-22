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
    output reg id_valid,
    output wire buffer_full
);

    reg [31:0] buffer_pc;
    reg [31:0] buffer_inst;
    reg buffer_valid;

    assign buffer_full = buffer_valid;
    
    // pipe between instruction fetch and instruction decode stage
    always @(posedge clk) begin
        if(!rst_n) begin
            id_pc <= 32'b0;
            id_inst <= 32'h00000000;
            id_valid <= 1'b0;
            buffer_pc    <= 32'b0;
            buffer_inst  <= 32'b0;
            buffer_valid <= 1'b0;
        end
        else if (flush) begin
            id_pc <= 32'b0;
            id_inst <= 32'h00000000;
            id_valid <= 1'b0;
            buffer_pc    <= 32'b0;
            buffer_inst  <= 32'b0;
            buffer_valid <= 1'b0;
        end
        // stalled
        else if (stall) begin

            // save an incoming instruction
            if (if_valid && !buffer_valid) begin
                buffer_pc    <= if_pc;
                buffer_inst  <= if_inst;
                buffer_valid <= 1'b1;
            end

        end else begin  // not stalling 
            // buffered instruction has priority
            if (buffer_valid) begin
                id_pc <= buffer_pc;
                id_inst <= buffer_inst;
                id_valid <= 1'b1;

                buffer_valid <= 1'b0;
            end

            // otherwise use the incoming instruction
            else begin
                id_pc <= if_pc;
                id_inst <= if_inst;
                id_valid <= if_valid;
            end
        end


    end

endmodule