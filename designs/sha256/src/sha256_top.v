// ============================================================
// sha256_top.v - SHA-256 顶层封装 v2 (32-bit 串行接口)
// 用途: OpenLane 综合顶层 (top)
// 优化: 将 512-bit 并行输入 + 256-bit 并行输出 (773 IO pins)
//       改为 32-bit 串行写/读 (约 71 IO pins), 使 die 面积大幅缩小
// 接口 (无 AMBA 依赖, 简单握手):
//   wen    : 写使能, 高电平时 wdata 写入当前 32-bit 消息字 (先写最高字 M[0])
//   wdata  : 32-bit 串行消息输入 (big-endian 字序, 16 拍填满 512-bit)
//   start  : 启动压缩 (需 512-bit 已填满)
//   busy   : 压缩进行中 (期间忽略 wen)
//   done   : 压缩完成, 摘要可读
//   rvalid : 摘要字读有效 (8 拍输出 256-bit, 先读最高字)
//   rdata  : 32-bit 串行摘要输出
// ============================================================

module sha256_top (
    input  wire        clk,
    input  wire        reset_n,
    input  wire        wen,            // 写消息字使能
    input  wire [31:0] wdata,          // 32-bit 消息字输入
    input  wire        start,          // 启动压缩
    output reg         busy,           // 忙
    output reg         done,           // 完成
    output reg         rvalid,         // 摘要读有效
    output reg  [31:0] rdata           // 32-bit 摘要输出
);

    // 内部信号
    reg [511:0] msg_reg;               // 串行装载的消息块
    reg [3:0]   wptr;                  // 写指针 0..15
    reg         msg_full;              // 512-bit 已填满
    reg [255:0] digest;                // 锁存摘要
    reg         reading;               // 摘要读取状态
    reg [2:0]   rptr;                  // 读指针 0..7
    reg         core_start;            // 触发核心 (1 周期脉冲)
    wire        core_done;
    wire [255:0] core_digest;

    // 核心压缩函数 (流水线版本)
    sha256_pipe u_core (
        .clk       (clk),
        .reset_n   (reset_n),
        .start     (core_start),
        .msg       (msg_reg),
        .digest    (core_digest),
        .done      (core_done)
    );

    // ----------------------------------------------------------
    // 串行写 / 启动 / 读取 控制
    // ----------------------------------------------------------
    always @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            msg_reg   <= 512'd0;
            wptr      <= 4'd0;
            msg_full  <= 1'b0;
            busy      <= 1'b0;
            done      <= 1'b0;
            digest    <= 256'd0;
            reading   <= 1'b0;
            rptr      <= 3'd0;
            rvalid    <= 1'b0;
            rdata     <= 32'd0;
            core_start<= 1'b0;
        end
        else begin
            core_start <= 1'b0;            // 默认低 (脉冲)

            // ---- 串行写消息 (busy/reading 时禁止, 防止覆盖压缩中的数据) ----
            if (wen && !busy && !reading) begin
                msg_reg[(15 - wptr)*32 +: 32] <= wdata;
                if (wptr == 4'd15)
                    msg_full <= 1'b1;
                else
                    wptr <= wptr + 4'd1;
            end

            // ---- 启动压缩 (需已填满) ----
            if (start && msg_full && !busy) begin
                core_start <= 1'b1;
                busy       <= 1'b1;
                msg_full   <= 1'b0;
                wptr       <= 4'd0;        // 复位写指针, 准备下一块
            end

            // ---- 压缩完成: 锁存摘要, 进入读取 (字0 由 reading 分支输出) ----
            if (core_done) begin
                busy    <= 1'b0;
                done    <= 1'b1;
                digest  <= core_digest;
                reading <= 1'b1;
                rptr    <= 3'd0;
                rvalid  <= 1'b1;
            end
            // ---- 串行读摘要 (8 拍输出 256-bit, 先读最高字) ----
            else if (reading) begin
                rvalid <= 1'b1;
                rdata  <= digest[(7 - rptr)*32 +: 32];
                if (rptr == 3'd7) begin
                    reading <= 1'b0;
                    rvalid  <= 1'b0;
                    done    <= 1'b0;
                end
                else
                    rptr <= rptr + 3'd1;
            end
        end
    end

endmodule
