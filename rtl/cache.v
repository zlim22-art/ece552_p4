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
    
    localparam [3:0]
        IDLE       = 4'b0001,
        LOAD_CACHE = 4'b0010,
        LOAD_REG   = 4'b0100,
        STORE_WORD = 4'b1000;

    reg [3:0] state, next_state;
    reg [2:0] req_cnt;      // 0..4: counts read requests issued to memory
    reg [1:0] resp_cnt;     // 0..3: counts returning words written to cache
    reg       req_is_write;
    reg       miss_way;

    wire [T - 1:0] tag_in    = i_req_addr[31:9];
    wire [S - 1:0] set_in    = i_req_addr[8:4];
    wire [    1:0] offset_in = i_req_addr[3:2];

    wire hit_way_0   = valid[set_in][0] && (tags0[set_in] == tag_in);
    wire hit_way_1   = valid[set_in][1] && (tags1[set_in] == tag_in);
    wire hit         = hit_way_0 || hit_way_1;
    wire miss        = !hit;
    wire reqs_done   = req_cnt[2];          // 1 once all 4 read requests are sent
    wire resp_done   = (resp_cnt == 2'd3);  // 1 when final (4th) word is arriving
    wire replace_way = !valid[set_in][0] ? 1'b0 :
                       !valid[set_in][1] ? 1'b1 : nru[set_in];

    wire [31:0] old_word = hit_way_0 ? datas0[set_in][offset_in] : datas1[set_in][offset_in];
    wire [31:0] masked_data = {
        i_req_mask[3] ? i_req_wdata[31:24] : old_word[31:24],
        i_req_mask[2] ? i_req_wdata[23:16] : old_word[23:16],
        i_req_mask[1] ? i_req_wdata[15:8]  : old_word[15:8],
        i_req_mask[0] ? i_req_wdata[7:0]   : old_word[7:0]
    };

    // Two pending writes; entry 0 is always the oldest.
    reg [1:0] pending_cnt;
    reg [31:0] pending_addr [0:1];
    reg [31:0] pending_data [0:1];

    wire available = (state == IDLE) || (state == LOAD_REG);
    wire pending_send = !i_rst && (pending_cnt != 2'd0) && i_mem_ready;
    wire hit_accept = !i_rst && available && i_req_wen && hit &&
                      ((pending_cnt != 2'd2) || pending_send);
    wire hit_direct = hit_accept && (pending_cnt == 2'd0) && i_mem_ready;
    wire hit_buffer = hit_accept && !hit_direct;
    wire store_send = !i_rst && (state == STORE_WORD) &&
                      i_mem_ready && (pending_cnt == 2'd0);
    wire write_pending_0 = hit_buffer &&
                           ((pending_cnt == 2'd0) ||
                            (pending_send && (pending_cnt == 2'd1)));
    wire write_pending_1 = hit_buffer &&
                           ((!pending_send && (pending_cnt == 2'd1)) ||
                            (pending_send && (pending_cnt == 2'd2)));

    always @(posedge i_clk) begin
        pending_cnt <= i_rst ? 2'd0 :
                       (hit_buffer && !pending_send) ? pending_cnt + 2'd1 :
                       (!hit_buffer && pending_send) ? pending_cnt - 2'd1 :
                       pending_cnt;
        pending_addr[0] <= write_pending_0 ? i_req_addr :
                           pending_send ? pending_addr[1] : pending_addr[0];
        pending_data[0] <= write_pending_0 ? masked_data :
                           pending_send ? pending_data[1] : pending_data[0];
        pending_addr[1] <= write_pending_1 ? i_req_addr : pending_addr[1];
        pending_data[1] <= write_pending_1 ? masked_data : pending_data[1];
    end

    reg           req_inc;
    reg           resp_inc;
    reg           write_enable_to_cache;
    reg           update_nru_only;
    reg [    1:0] target_word;
    reg [   31:0] next_data_0, next_data_1;
    reg [T - 1:0] next_tag_0,  next_tag_1;
    reg [    1:0] next_valid;
    reg           next_nru;

    // Internal regs to drive output wires from always @(*)
    reg [31:0] mem_addr_r;
    reg        mem_ren_r;
    reg        mem_wen_r;
    reg [31:0] mem_wdata_r;
    reg        busy_r;
    reg [31:0] res_rdata_r;

    assign o_mem_addr  = pending_send ? pending_addr[0] : mem_addr_r;
    assign o_mem_ren   = !i_rst && mem_ren_r;
    assign o_mem_wen   = !i_rst && (pending_send || mem_wen_r);
    assign o_mem_wdata = pending_send ? pending_data[0] : mem_wdata_r;
    assign o_busy      = busy_r;
    assign o_res_rdata = res_rdata_r;

    genvar g_idx;
    generate
        for (g_idx = 0; g_idx < DEPTH; g_idx = g_idx + 1) begin : gen_valid_zero
            always @(posedge i_clk) begin
                if (i_rst) begin
                    valid[g_idx] <= 2'b00;
                    nru[g_idx]   <= 1'b0;
                    datas0[g_idx][0] <= 32'b0;
                    datas0[g_idx][1] <= 32'b0;
                    datas0[g_idx][2] <= 32'b0;
                    datas0[g_idx][3] <= 32'b0;
                    datas1[g_idx][0] <= 32'b0;
                    datas1[g_idx][1] <= 32'b0;
                    datas1[g_idx][2] <= 32'b0;
                    datas1[g_idx][3] <= 32'b0;
                end else if (write_enable_to_cache && (g_idx == set_in)) begin
                    datas0[g_idx][target_word] <= next_data_0;
                    datas1[g_idx][target_word] <= next_data_1;
                    tags0[g_idx]               <= next_tag_0;
                    tags1[g_idx]               <= next_tag_1;
                    valid[g_idx]               <= next_valid;
                    nru[g_idx]                 <= next_nru;
                end else if (update_nru_only && (g_idx == set_in)) begin
                    nru[g_idx]                 <= next_nru;
                end
            end
        end
    endgenerate

    always @(posedge i_clk) begin
        if (i_rst) begin
            state        <= IDLE;
            req_cnt      <= 3'd0;
            resp_cnt     <= 2'd0;
            req_is_write <= 1'b0;
            miss_way     <= 1'b0;
        end else begin
            state <= next_state;

            if (available && (i_req_ren || i_req_wen) && miss) begin
                req_is_write <= i_req_wen;
                miss_way <= replace_way;
            end

            if (state == LOAD_CACHE) begin
                if (req_inc) begin
                    req_cnt <= req_cnt + 3'd1;
                end
                if (resp_inc) begin
                    resp_cnt <= resp_cnt + 2'd1;
                end
            end else begin
                req_cnt  <= 3'd0;
                resp_cnt <= 2'd0;
            end
        end
    end

always @(*) begin
        next_state            = state;
        req_inc               = 1'b0;
        resp_inc              = 1'b0;
        write_enable_to_cache = 1'b0;
        update_nru_only       = 1'b0;

        // Use response counter during cache fill, otherwise use requested offset
        case (state)
            LOAD_CACHE: target_word = resp_cnt;
            default:    target_word = offset_in;
        endcase

        next_data_0 = datas0[set_in][target_word];
        next_data_1 = datas1[set_in][target_word];
        next_tag_0  = tags0[set_in];
        next_tag_1  = tags1[set_in];
        next_valid  = valid[set_in];
        next_nru    = nru[set_in];

        busy_r      = 1'b0;
        res_rdata_r = hit_way_0 ? datas0[set_in][offset_in] : hit_way_1 ? datas1[set_in][offset_in] : 32'b0;
        mem_addr_r  = 32'b0;
        mem_ren_r   = 1'b0;
        mem_wen_r   = 1'b0;
        mem_wdata_r = 32'b0;

        case (state)
            IDLE, LOAD_REG: begin
                next_state = IDLE;
                case ({i_req_ren, i_req_wen, hit})
                    3'b101: begin
                        // Read hit: return data immediately and update NRU
                        busy_r          = 1'b0;
                        update_nru_only = 1'b1;
                        case (hit_way_0)
                            1'b1: begin
                                res_rdata_r = datas0[set_in][offset_in];
                                next_nru    = 1'b1;
                            end
                            default: begin
                                res_rdata_r = datas1[set_in][offset_in];
                                next_nru    = 1'b0;
                            end
                        endcase
                    end

                    3'b011: begin
                        // Write hit: update cache now; send directly or buffer.
                        busy_r                = !hit_accept;
                        mem_wen_r             = hit_accept && hit_direct;
                        mem_addr_r            = hit_accept ? i_req_addr : 32'b0;
                        mem_wdata_r           = hit_accept ? masked_data : 32'b0;
                        write_enable_to_cache = hit_accept;
                        next_state            = hit_accept ? IDLE : STORE_WORD;
                        next_data_0 = (hit_accept && hit_way_0) ?
                                      masked_data : datas0[set_in][offset_in];
                        next_data_1 = (hit_accept && !hit_way_0) ?
                                      masked_data : datas1[set_in][offset_in];
                        next_nru = hit_accept ?
                                   (hit_way_0 ? 1'b1 : 1'b0) : nru[set_in];
                    end

                    3'b100,
                    3'b010: begin
                        // Read or write miss: stall CPU and start pipelined line fill
                        busy_r     = 1'b1;
                        next_state = LOAD_CACHE;
                    end

                    default: begin
                        // No active request
                    end
                endcase
            end

            LOAD_CACHE: begin
                busy_r     = 1'b1;
                mem_addr_r = {tag_in, set_in, req_cnt[1:0], 2'b00};

                // Request side: issue up to 4 pipelined reads whenever memory is ready
                case ({reqs_done, (i_mem_ready && (pending_cnt == 2'd0))})
                    2'b01: begin
                        mem_ren_r = 1'b1;
                        req_inc   = 1'b1;
                    end
                    default: begin
                        mem_ren_r = 1'b0;
                        req_inc   = 1'b0;
                    end
                endcase

                // Response side: write each returning word into the replacement way
                case (i_mem_valid && ((req_cnt > {1'b0, resp_cnt}) || req_inc))
                    1'b1: begin
                        resp_inc              = 1'b1;
                        write_enable_to_cache = 1'b1;

                        // Write returning word into replacement way; set valid and NRU on final word
                        case ({miss_way, resp_done})
                            2'b00: begin
                                // Way 0, words 0..2
                                next_data_0   = i_mem_rdata;
                                next_tag_0    = tag_in;
                                next_valid[0] = 1'b0;
                                next_nru      = nru[set_in];
                            end
                            2'b01: begin
                                // Way 0, final word (word 3)
                                next_data_0   = i_mem_rdata;
                                next_tag_0    = tag_in;
                                next_valid[0] = 1'b1;
                                next_nru      = 1'b1;
                            end
                            2'b10: begin
                                // Way 1, words 0..2
                                next_data_1   = i_mem_rdata;
                                next_tag_1    = tag_in;
                                next_valid[1] = 1'b0;
                                next_nru      = nru[set_in];
                            end
                            default: begin
                                // Way 1, final word (word 3)
                                next_data_1   = i_mem_rdata;
                                next_tag_1    = tag_in;
                                next_valid[1] = 1'b1;
                                next_nru      = 1'b0;
                            end
                        endcase

                        // Once all 4 words are loaded, route to write-through or read-return
                        case ({resp_done, req_is_write})
                            2'b11:   next_state = STORE_WORD;
                            2'b10:   next_state = LOAD_REG;
                            default: next_state = LOAD_CACHE;
                        endcase
                    end

                    default: begin
                        // Wait for returning memory word
                    end
                endcase
            end

            STORE_WORD: begin
                busy_r      = 1'b1;
                mem_wen_r   = store_send;
                mem_addr_r  = i_req_addr;
                mem_wdata_r = masked_data;

                case (store_send)
                    1'b1: begin
                        // Keep busy until the write is accepted at the clock edge.
                        write_enable_to_cache = 1'b1;
                        next_state            = LOAD_REG;
                        case (hit_way_0)
                            1'b1: begin
                                next_data_0 = masked_data;
                                next_data_1 = datas1[set_in][offset_in];
                                next_nru    = 1'b1;
                            end
                            default: begin
                                next_data_0 = datas0[set_in][offset_in];
                                next_data_1 = masked_data;
                                next_nru    = 1'b0;
                            end
                        endcase
                    end

                    default: begin
                        // Wait until backing memory is ready
                    end
                endcase
            end

            default: begin
                next_state = IDLE;
            end
        endcase
    end
    // Fill in your implementation here.
endmodule
`default_nettype wire