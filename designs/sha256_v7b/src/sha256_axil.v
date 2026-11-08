// ============================================================
// sha256_axil.v - SHA-256 加速器 v7 顶层（AXI4-Lite 从接口 + 多块流式）
//
// 与 v6 (sha256_top.v，裸 wen/wdata/start/rdata 串行接口) 的区别：
//   1) 标准 AXI4-Lite 从接口，任何带 AMBA 总线的主机都能直接挂上去，
//      不需要为这块核单独写一套握手驱动。
//   2) 多块流式：链值 h_ctx 在块之间保持，写满 16 个消息字自动启动压缩，
//      不用"等 done 再 start"。长度超过 64 字节的消息可以连续喂，
//      压缩期间由 awready/wready 反压主机，软件不需要轮询。
//   3) padding 仍由主机完成（软件把消息补齐成 64 字节块后按块喂入）。
//      硬件侧不做 padding —— 这是 v7 明确不做的事，写在文档里，
//      不假装支持任意长度。
//
// 寄存器映射（32-bit，字对齐）：
//   0x00 CTRL      W  bit0 = INIT：把链值重置为 SHA-256 初始值，清块缓冲
//   0x04 STATUS    R  bit0 = READY（可写新块）  bit1 = BUSY（压缩中）
//   0x08 MSG       W  写一个 32-bit 消息字，内部按字 0..15 顺序填入 512-bit 块
//                       写满第 16 字后自动启动一次块压缩
//   0x0C MSGCNT    R  当前块已写入的字数（0..16）
//   0x10..0x2C     R  DIGEST0..DIGEST7：当前链值（8 个 32-bit 字）
//
// 使用顺序：写 CTRL=1(INIT) -> 连续写 16 个 MSG -> 等 STATUS.BUSY 落下
//           -> 读 DIGEST0..7 得到（多块时的中间/最终）链值
// ============================================================

module sha256_axil (
    input  wire        clk,
    input  wire        reset_n,

    // ---- AXI4-Lite slave ----
    /* verilator lint_off UNUSEDSIGNAL */
    input  wire [5:0]  s_axil_awaddr,    // 寄存器字对齐，[1:0] 不使用
    /* verilator lint_on UNUSEDSIGNAL */
    input  wire        s_axil_awvalid,
    output wire        s_axil_awready,
    input  wire [31:0] s_axil_wdata,
    input  wire [3:0]  s_axil_wstrb,    // 字节选通，MSG/CTRL 写入按键按字节合并
    input  wire        s_axil_wvalid,
    output wire        s_axil_wready,
    output wire [1:0]  s_axil_bresp,
    output wire        s_axil_bvalid,
    input  wire        s_axil_bready,

    /* verilator lint_off UNUSEDSIGNAL */
    input  wire [5:0]  s_axil_araddr,    // 寄存器字对齐，[1:0] 不使用
    /* verilator lint_on UNUSEDSIGNAL */
    input  wire        s_axil_arvalid,
    output wire        s_axil_arready,
    output wire [31:0] s_axil_rdata,
    output wire [1:0]  s_axil_rresp,
    output wire        s_axil_rvalid,
    input  wire        s_axil_rready
);

    // ------------------------------------------------------------
    // 内部寄存器
    // ------------------------------------------------------------
    reg  [511:0] msg_buf;         // 当前块的 16 个字
    reg  [4:0]   wcnt;            // 已写入字数 0..15
    reg  [255:0] h_ctx;           // 链值
    reg          ready;           // 1 = 空闲可写；0 = 压缩中
    reg          core_start;      // 单周期脉冲
    reg          launch;          // 延迟一拍启动（等 msg_buf 落定）
    wire         core_done;
    wire [255:0] core_h_out;

    // AXI 写通道
    reg  [3:0]   aw_addr_l;   // 只存字地址 [5:2]
    reg          aw_hold;
    reg          bvalid_r;
    // AXI 读通道
    reg  [31:0]  rdata_r;
    reg          rvalid_r;

    localparam [255:0] IV = {32'h6a09e667, 32'hbb67ae85, 32'h3c6ef372, 32'ha54ff53a,
                             32'h510e527f, 32'h9b05688c, 32'h1f83d9ab, 32'h5be0cd19};

    // 压缩核
    sha256_core u_core (
        .clk     (clk),
        .reset_n (reset_n),
        .start   (core_start),
        .msg     (msg_buf),
        .h_in    (h_ctx),
        .h_out   (core_h_out),
        .done    (core_done)
    );

    // ------------------------------------------------------------
    // AXI 握手（单 outstanding，压缩期间反压写通道）
    // ------------------------------------------------------------
    assign s_axil_awready = ~aw_hold & ready;
    assign s_axil_wready  =  aw_hold & ready;
    assign s_axil_bresp   = 2'b00;
    assign s_axil_bvalid  = bvalid_r;

    assign s_axil_arready = ~rvalid_r;
    assign s_axil_rresp   = 2'b00;
    assign s_axil_rvalid  = rvalid_r;
    assign s_axil_rdata   = rdata_r;

    wire wr_fire = s_axil_wvalid & s_axil_wready;

    // 写索引：5 位同宽减法（15 - wcnt），避免位宽扩展告警
    wire [4:0] widx = 5'd15 - wcnt;

    // 字节选通掩码（AXI 规范要求 wstrb，按字节合并写入）
    wire [31:0] wmask = {{8{s_axil_wstrb[3]}}, {8{s_axil_wstrb[2]}},
                         {8{s_axil_wstrb[1]}}, {8{s_axil_wstrb[0]}}};

    // ------------------------------------------------------------
    // 写通道 / 寄存器写
    // ------------------------------------------------------------
    always @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            aw_addr_l <= 4'd0;
            aw_hold   <= 1'b0;
            bvalid_r  <= 1'b0;
            msg_buf   <= 512'd0;
            wcnt      <= 5'd0;
            h_ctx     <= IV;
            ready     <= 1'b1;
            core_start<= 1'b0;
            launch    <= 1'b0;
        end
        else begin
            core_start <= 1'b0;        // 默认只持续一拍

            // --- AW 握手 ---
            if (s_axil_awvalid && s_axil_awready) begin
                aw_addr_l <= s_axil_awaddr[5:2];
                aw_hold   <= 1'b1;
            end

            // --- B 通道响应 ---
            if (bvalid_r && s_axil_bready)
                bvalid_r <= 1'b0;

            // --- 写数据落地 ---
            if (wr_fire) begin
                aw_hold  <= 1'b0;
                bvalid_r <= 1'b1;

                case (aw_addr_l)
                    // CTRL
                    4'h0: if (s_axil_wdata[0] && s_axil_wstrb[0]) begin
                        h_ctx  <= IV;
                        msg_buf<= 512'd0;
                        wcnt   <= 5'd0;
                        ready  <= 1'b1;
                    end
                    // MSG
                    4'h2: begin
                        msg_buf[widx*32 +: 32] <= (msg_buf[widx*32 +: 32] & ~wmask)
                                                | (s_axil_wdata & wmask);
                        if (wcnt == 5'd15) begin
                            wcnt   <= 5'd0;
                            launch <= 1'b1;
                            ready  <= 1'b0;     // 当拍就关门，防止下一块首字被压缩读走
                        end
                        else begin
                            wcnt   <= wcnt + 5'd1;
                        end
                    end
                    default: ; // 其余地址写忽略
                endcase
            end

            // --- 写满一块：延迟一拍启动（此时 msg_buf 已更新） ---
            if (launch) begin
                launch     <= 1'b0;
                core_start <= 1'b1;
            end

            // --- 压缩完成：更新链值，重新开门 ---
            if (core_done) begin
                h_ctx <= core_h_out;
                ready <= 1'b1;
            end
        end
    end

    // ------------------------------------------------------------
    // 读通道
    // ------------------------------------------------------------
    always @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            rdata_r  <= 32'd0;
            rvalid_r <= 1'b0;
        end
        else begin
            if (s_axil_arvalid && s_axil_arready) begin
                rvalid_r <= 1'b1;
                case (s_axil_araddr[5:2])
                    4'h1: rdata_r <= {30'd0, ~ready, ready};              // STATUS
                    4'h3: rdata_r <= {27'd0, wcnt};                       // MSGCNT
                    4'h4: rdata_r <= h_ctx[255:224];                      // DIGEST0
                    4'h5: rdata_r <= h_ctx[223:192];
                    4'h6: rdata_r <= h_ctx[191:160];
                    4'h7: rdata_r <= h_ctx[159:128];
                    4'h8: rdata_r <= h_ctx[127:96];
                    4'h9: rdata_r <= h_ctx[95:64];
                    4'ha: rdata_r <= h_ctx[63:32];
                    4'hb: rdata_r <= h_ctx[31:0];                         // DIGEST7
                    default: rdata_r <= 32'hdeadbeef;
                endcase
            end
            else if (rvalid_r && s_axil_rready) begin
                rvalid_r <= 1'b0;
            end
        end
    end

endmodule
