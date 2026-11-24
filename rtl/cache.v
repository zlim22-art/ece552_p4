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
    reg [   31:0] datas0 [DEPTH - 1:0][D - 1:0];
    reg [   31:0] datas1 [DEPTH - 1:0][D - 1:0];
    reg [T - 1:0] tags0  [DEPTH - 1:0];
    reg [T - 1:0] tags1  [DEPTH - 1:0];
    reg [1:0] valid [DEPTH - 1:0];

    // Fill in your implementation here.
    reg nru [DEPTH - 1:0];

    wire [T-1:0] tag_in;
    wire [S-1:0] set_in;
    wire [1:0] offset_in;
    wire hit_way_0, hit_way_1, cache_hit, selected_way;
    wire [31:0] cached_word;
    wire req_active;

    assign tag_in = i_req_addr[31:9];
    assign set_in = i_req_addr[8:4];
    assign offset_in = i_req_addr[3:2];
    assign hit_way_0 = valid[set_in][0] && (tags0[set_in] == tag_in);
    assign hit_way_1 = valid[set_in][1] && (tags1[set_in] == tag_in);
    assign cache_hit = hit_way_0 || hit_way_1;
    assign cached_word = hit_way_0 ? datas0[set_in][offset_in] :
                         hit_way_1 ? datas1[set_in][offset_in] : 32'b0;
    assign selected_way = !valid[set_in][0] ? 1'b0 :
                          !valid[set_in][1] ? 1'b1 : nru[set_in];
    assign req_active = i_req_ren || i_req_wen;

    localparam [1:0]
        LOAD_STORE_REQ = 2'd0,
        LOAD_CACHE     = 2'd1,
        LOAD_REG       = 2'd2,
        STORE_WORD     = 2'd3;

    reg [1:0] state;
    reg [31:0] miss_addr;
    reg [S-1:0] miss_set;
    reg [T-1:0] miss_tag;
    reg [1:0] miss_word;
    reg miss_way;
    reg miss_write;
    reg [3:0] miss_mask;
    reg [31:0] miss_wdata;
    reg [1:0] cnt;
    reg [2:0] issued;
    wire refill_send, refill_receive;
    wire available, hit_store, hit_accept;
    wire [31:0] hit_mask, hit_merged;
    reg [1:0] pending_cnt;
    reg [31:0] pending_addr [0:1];
    reg [31:0] pending_data [0:1];
    wire pending_send, hit_direct, hit_buffer;
    wire store_send;

    assign available = (state == LOAD_STORE_REQ) || (state == LOAD_REG);
    assign hit_store = available && i_req_wen && cache_hit;
    assign pending_send = (pending_cnt != 2'd0) && i_mem_ready && !i_rst;
    assign hit_accept = hit_store && ((pending_cnt != 2'd2) || pending_send);
    assign hit_direct = hit_accept && (pending_cnt == 2'd0) && i_mem_ready;
    assign hit_buffer = hit_accept && !hit_direct;
    assign store_send = (state == STORE_WORD) && i_mem_ready && (pending_cnt == 2'd0);
    assign hit_mask = {{8{i_req_mask[3]}}, {8{i_req_mask[2]}},
                       {8{i_req_mask[1]}}, {8{i_req_mask[0]}}};
    assign hit_merged = (cached_word & ~hit_mask) | (i_req_wdata & hit_mask);

    assign refill_send = (state == LOAD_CACHE) && (issued < 3'd4) && i_mem_ready && (pending_cnt == 2'd0);
    assign refill_receive = (state == LOAD_CACHE) && i_mem_valid &&
                            ((issued > {1'b0, cnt}) || refill_send);

    wire [31:0] stored_word;
    wire [31:0] byte_mask;
    wire [31:0] masked_word;

    always @(posedge i_clk) begin
        pending_cnt <= i_rst ? 2'd0 :
                    (hit_buffer && !pending_send) ? pending_cnt + 2'd1 :
                    (!hit_buffer && pending_send) ? pending_cnt - 2'd1 :
                    pending_cnt;

        // Pending entry 0
        pending_addr[0] <=
            (hit_buffer && (pending_cnt == 2'd0)) ? i_req_addr :
            (hit_buffer && pending_send && (pending_cnt == 2'd1)) ? i_req_addr :
            pending_send ? pending_addr[1] :
            pending_addr[0];

        pending_data[0] <=
            (hit_buffer && (pending_cnt == 2'd0)) ? hit_merged :
            (hit_buffer && pending_send && (pending_cnt == 2'd1)) ? hit_merged :
            pending_send ? pending_data[1] :
            pending_data[0];

        // Pending entry 1
        pending_addr[1] <=
            (hit_buffer && !pending_send && (pending_cnt == 2'd1)) ? i_req_addr :
            (hit_buffer && pending_send && (pending_cnt == 2'd2)) ? i_req_addr :
            pending_addr[1];

        pending_data[1] <=
            (hit_buffer && !pending_send && (pending_cnt == 2'd1)) ? hit_merged :
            (hit_buffer && pending_send && (pending_cnt == 2'd2)) ? hit_merged :
            pending_data[1];
    end

    assign stored_word = miss_way ? datas1[miss_set][miss_word] :
                                    datas0[miss_set][miss_word];
    assign byte_mask = {{8{miss_mask[3]}}, {8{miss_mask[2]}},
                        {8{miss_mask[1]}}, {8{miss_mask[0]}}};
    assign merged_word = (stored_word & ~byte_mask) |
                         (miss_wdata & byte_mask);

    // Read hits have combinational data. After a miss, CPU holds address
    // stable, and the filled line is visible in LOAD_REG.
    assign o_res_rdata = cached_word;

    // Stall on misses or a store hit that cannot be accepted by memory.
    assign o_busy = (state != LOAD_STORE_REQ && state != LOAD_REG) ||
                    (available && req_active &&
                     (!cache_hit || (i_req_wen && !hit_accept)));

    // Each refill transaction reads one aligned 32-bit word.
    assign o_mem_addr = pending_send ? pending_addr[0] :
                        hit_direct ? i_req_addr :
                        (state == LOAD_CACHE) ?
                        {miss_addr[31:4], issued[1:0], 2'b00} : miss_addr;
    assign o_mem_ren = !i_rst && refill_send;
    assign o_mem_wen = !i_rst && (pending_send || hit_direct || store_send);
    assign o_mem_wdata = pending_send ? pending_data[0] :
                         hit_direct ? hit_merged : masked_word;

    // Each set owns its valid and replacement registers.
    genvar g;
    generate
        for (g = 0; g < DEPTH; g = g + 1) begin : gen_metadata
            always @(posedge i_clk) begin
                if (i_rst) begin
                    valid[g] <= 2'b00;
                    nru[g] <= 1'b0;
                end else begin
                    if (available && ((i_req_ren && cache_hit) || hit_accept) &&
                        (set_in == g)) begin
                        nru[g] <= hit_way_0 ? 1'b1 : 1'b0;
                    end else if (refill_receive &&
                                 (cnt == 2'd3) && (miss_set == g)) begin
                        if (miss_way)
                            valid[g][1] <= 1'b1;
                        else
                            valid[g][0] <= 1'b1;
                        nru[g] <= !miss_way;
                    end else if (store_send && (miss_set == g)) begin
                        nru[g] <= !miss_way;
                    end
                end
            end
        end
    endgenerate

    always @(posedge i_clk) begin
        if (i_rst) begin
            state <= LOAD_STORE_REQ;
            cnt <= 2'b0;
            issued <= 3'b0;
            miss_addr <= 32'b0;
            miss_set <= {S{1'b0}};
            miss_tag <= {T{1'b0}};
            miss_word <= 2'b0;
            miss_way <= 1'b0;
            miss_write <= 1'b0;
            miss_mask <= 4'b0;
            miss_wdata <= 32'b0;
        end else begin
            case (state)
                LOAD_STORE_REQ, LOAD_REG: begin
                    state <= LOAD_STORE_REQ;
                    if (req_active) begin
                        if (cache_hit && i_req_ren) begin
                            // Serve load hit combinationally and mark MRU.
                            // Metadata updated by gen_metadata.
                        end else if (hit_accept) begin
                            if (hit_way_1)
                                datas1[set_in][offset_in] <= hit_merged;
                            else
                                datas0[set_in][offset_in] <= hit_merged;
                        end else begin
                            // Capture every CPU request field because the
                            // CPU drops ren/wen while stalled.
                            miss_addr <= i_req_addr;
                            miss_set <= set_in;
                            miss_tag <= tag_in;
                            miss_word <= offset_in;
                            miss_write <= i_req_wen;
                            miss_mask <= i_req_mask;
                            miss_wdata <= i_req_wdata;
                            if (cache_hit) begin
                                // Store hit: no refill, use matching way.
                                miss_way <= hit_way_1;
                                state <= STORE_WORD;
                            end else begin
                                // Miss: choose an invalid way first.
                                miss_way <= selected_way;
                                cnt <= 2'b0;
                                issued <= 3'b0;
                                state <= LOAD_CACHE;
                            end
                        end
                    end
                end

                LOAD_CACHE: begin
                    // Issue and receive independently; memory returns in order.
                    if (refill_send)
                        issued <= issued + 3'd1;
                    if (refill_receive) begin
                        if (miss_way)
                            datas1[miss_set][cnt] <= i_mem_rdata;
                        else
                            datas0[miss_set][cnt] <= i_mem_rdata;

                        if (cnt == 2'd3) begin
                            // Only mark a line valid after all four words.
                            if (miss_way) begin
                                tags1[miss_set] <= miss_tag;
                            end else begin
                                tags0[miss_set] <= miss_tag;
                            end
                            if (miss_write)
                                state <= STORE_WORD;
                            else
                                state <= LOAD_REG;
                        end else begin
                            cnt <= cnt + 2'd1;
                        end
                    end
                end

                STORE_WORD: begin
                    // Apply the masked word on the same edge that backing
                    // memory accepts the write.
                    if (store_send) begin
                        if (miss_way)
                            datas1[miss_set][miss_word] <= masked_word;
                        else
                            datas0[miss_set][miss_word] <= masked_word;
                        state <= LOAD_REG;
                    end
                end

                default: state <= LOAD_STORE_REQ;
            endcase
        end
    end
endmodule

`default_nettype wire
