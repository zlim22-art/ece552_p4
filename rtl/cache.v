`default_nettype none

module cache (
    // Global clock.
    input  wire        i_clk,
    // Synchronous active-high reset.
    input  wire        i_rst,
    // External memory interface. See hart interface for details. This
    // interface is nearly identical to the phase 5 memory interface, with the
    // exception that the byte mask (`o_mem_mask`) has been removed. This is
    // no longer needed as the cache will only access the memory at word
    // granularity, and implement masking internally.
    input  wire        i_mem_ready,
    output wire [31:0] o_mem_addr,
    output wire        o_mem_ren,
    output wire        o_mem_wen,
    output wire [31:0] o_mem_wdata,
    input  wire [31:0] i_mem_rdata,
    input  wire        i_mem_valid,
    // Interface to CPU hart. This is nearly identical to the phase 5 hart memory
    // interface, but includes a stall signal (`o_busy`), and the input/output
    // polarities are swapped for obvious reasons.
    //
    // The CPU should use this as a stall signal for both instruction fetch
    // (IF) and memory (MEM) stages, from the instruction or data cache
    // respectively. If a memory request is made (`i_req_ren` for instruction
    // cache, or either `i_req_ren` or `i_req_wen` for data cache), this
    // should be asserted *combinationally* if the request results in a cache
    // miss.
    //
    // In case of a cache miss, the CPU must stall the respective pipeline
    // stage and deassert ren/wen on subsequent cycles, until the cache
    // deasserts `o_busy` to indicate it has serviced the cache miss. However,
    // the CPU must keep the other request lines constant. For example, the
    // CPU should not change the request address while stalling.
    output wire        o_busy,
    // 32-bit read/write address to access from the cache. This should be
    // 32-bit aligned (i.e. the two LSBs should be zero). See `i_req_mask` for
    // how to perform half-word and byte accesses to unaligned addresses.
    input  wire [31:0] i_req_addr,
    // When asserted, the cache should perform a read at the aligned address
    // specified by `i_req_addr` and return the 32-bit word at that address,
    // either immediately (i.e. combinationally) on a cache hit, or
    // synchronously on a cache miss. It is illegal to assert this and
    // `i_dmem_wen` on the same cycle.
    input  wire        i_req_ren,
    // When asserted, the cache should perform a write at the aligned address
    // specified by `i_req_addr` with the 32-bit word provided in
    // `o_req_wdata` (specified by the mask). This is necessarily synchronous,
    // but may either happen on the next clock edge (on a cache hit) or after
    // multiple cycles of latency (cache miss). As the cache is write-through
    // and write-allocate, writes must be applied to both the cache and
    // underlying memory.
    // It is illegal to assert this and `i_dmem_ren` on the same cycle.
    input  wire        i_req_wen,
    // The memory interface expects word (32 bit) aligned addresses. However,
    // the processor supports byte and half-word loads and stores at unaligned and
    // 16-bit aligned addresses, respectively. To support this, the access
    // mask specifies which bytes within the 32-bit word are actually read
    // from or written to memory.
    input  wire [ 3:0] i_req_mask,
    // The 32-bit word to write to memory, if the request is a write
    // (i_req_wen is asserted). Only the bytes corresponding to set bits in
    // the mask should be written into the cache (and to backing memory).
    input  wire [31:0] i_req_wdata,
    // THe 32-bit data word read from memory on a read request.
    output wire [31:0] o_res_rdata
);
    // These parameters are equivalent to those provided in the project
    // 6 specification. Feel free to use them, but hardcoding these numbers
    // rather than using the localparams is also permitted, as long as the
    // same values are used (and consistent with the project specification).
    //
    // 32 sets * 2 ways per set * 16 bytes per way = 1K cache
    localparam O = 4;            // 4 bit offset => 16 byte cache line
    localparam S = 5;            // 5 bit set index => 32 sets
    // ** and / are course-rules-banned (real hardware power/divide
    // operators synthesize poorly); O and S are fixed per the note above,
    // so these are equivalent shift-based constant expressions, not a
    // behavior change.
    localparam DEPTH = 1 << S;   // 32 sets
    localparam W = 2;            // 2 way set associative, NMRU
    localparam T = 32 - O - S;   // 23 bit tag
    localparam D = (1 << O) >> 2; // 16 bytes per line / 4 bytes per word = 4 words per line

    // The following memory arrays model the cache structure. As this is
    // an internal implementation detail, you are *free* to modify these
    // arrays as you please.

    // Backing memory, modeled as two separate ways.
    reg [   31:0] datas0 [DEPTH - 1:0][D - 1:0]; // 4 words per line, 32 sets,  way 1
    reg [   31:0] datas1 [DEPTH - 1:0][D - 1:0]; // 4 words per line, 32 sets, way 2
    reg [T - 1:0] tags0  [DEPTH - 1:0]; // 23 bit tag, way 1
    reg [T - 1:0] tags1  [DEPTH - 1:0]; // 23 bit tag, way 2
    reg [1:0] valid [DEPTH - 1:0]; // 2 bit valid vector, one per way
    //reg       lru   [DEPTH - 1:0]; // 1 bit LRU vector, one per set
    reg       nru   [DEPTH - 1:0]; // 1 bit NMRU vector, one per set

    genvar g_idx;
    reg [2:0] cnt;
    wire start_cnt;
    reg [4:0] state, next_state;


    localparam [4:0] 
    IDLE           = 5'b00001, // IDLE (After Fetch)
    LOAD_STORE_REQ = 5'b00010, // LOAD/STORE REQ
    LOAD_CACHE     = 5'b00100, // LOAD CACHE (singular word)
    LOAD_REG       = 5'b01000, // LOAD REG (with word from cache)
    STORE_WORD     = 5'b10000; // STORE WORD IN CACHE, MEM


    assign tag_in = i_req_addr[31:9];
    assign set_in = i_req_addr[8:4];
    assign offset_in = i_req_addr[3:2];


    assign hit_way_0 = (valid[set_in][0] && (tags0[set_in] == tag_in)) ? 1'b0 : 1'b1;
    assign hit_way_1 = (valid[set_in][1] && (tags1[set_in] == tag_in)) ? 1'b1 : 1'b0;
    assign cnt_done = cnt[2];




    generate
        for (g_idx = 0; g_idx < DEPTH; g_idx = g_idx + 1) begin : gen_valid_zero
            always @(posedge i_clk) begin
                if (i_rst) begin
                    valid[g_idx] <= 2'b00;
                    nru[g_idx]   <= 1'b0;
                end if (write_enable) begin
                
                end begin :

            
                end
            end
        end
    endgenerate


   
    always @(posedge i_clk) begin
        if (i_rst) begin
            state <= IDLE;
            cnt <= 0;
        end else begin
            state <= next_state;

            if (start_cnt) begin
                cnt <= 0;
            end else if (state == LOAD_CACHE && inc_enable) begin
                cnt <= cnt + 1;
            end

        end
    end


    always @(*) begin
        next_state = state; // default hold
        start_cnt = 1'b0;
        o_res_rdata = 32'b0;
        inc_enable = 1'b0;
            case (state)
                IDLE: begin
                    if (i_req_ren || i_req_wen) begin
                        next_state = LOAD_STORE_REQ;
                    end
                end

                LOAD_STORE_REQ: begin
                    if (i_dmem_ready) begin
                        if (hit_way_0 || hit_way_1) begin
                            next_state = LOAD_REG;
                        end else begin
                            next_state = LOAD_CACHE;
                            start_cnt = 1'b1;

                        end
                    end
                end

                LOAD_CACHE: begin
                    inc_enable = 1'b0;
                    next_state = LOAD_CACHE;
                    if (i_dmem_valid && cnt_done) begin
                        if (i_req_ren) begin
                            next_state = LOAD_REG;

                        end else if (i_req_wen) begin
                            next_state = STORE_WORD;
                        end
                    end 
                    if i_dmem_valid begin
                        inc_enable = 1'b1;

                        if (nru[set_in] == 1'b0) begin
                            tags0[set_in] = tag_in;
                            data0[set_in][cnt] = i_dmem_rdata;
                            valid[set_in][0] = 1'b1;
                            nru[set_in] = 1'b1;
                        end else begin
                            tags1[set_in] = tag_in;
                            valid[set_in][1] = 1'b1;
                            nru[set_in] = 1'b0;
                            data1[set_in][cnt] = i_dmem_rdata;
                        end
                    end
                end

                LOAD_REG: begin
                    next_state = IDLE;
                if (hit_way_0) begin
                        o_res_rdata = datas0[set_in][offset_in];
                    end else if (hit_way_1) begin
                        o_res_rdata = datas1[set_in][offset_in];
                    end
                end

                STORE_WORD: begin
                    next_state = IDLE;
                end

                default: begin
                    next_state = IDLE;
                end
        endcase
end











    // Fill in your implementation here.
endmodule

`default_nettype wire
