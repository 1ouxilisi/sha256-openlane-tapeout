`timescale 1ns/1ps
// ============================================================
// sha256_top_tb.v - SHA-256 顶层串行接口测试台 (v2)
// 验证三个标准锚点哈希 (abc / empty / fox) 的 32-bit 串行读写握手
// 运行: iverilog -o top_sim sha256_pipe.v sha256_top.v sha256_top_tb.v && vvp top_sim
// ============================================================
module sha256_top_tb;

    reg         clk;
    reg         reset_n;
    reg         wen;
    reg  [31:0] wdata;
    reg         start;
    wire        busy;
    wire        done;
    wire        rvalid;
    wire [31:0] rdata;

    sha256_top dut (
        .clk(clk), .reset_n(reset_n),
        .wen(wen), .wdata(wdata), .start(start),
        .busy(busy), .done(done), .rvalid(rvalid), .rdata(rdata)
    );

    // 时钟 10ns
    initial clk = 0;
    always #5 clk = ~clk;

    // 预期摘要
    localparam [255:0] DIG_ABC  = 256'hba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad;
    localparam [255:0] DIG_EMPTY= 256'he3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855;
    localparam [255:0] DIG_FOX  = 256'hd7a8fbb307d7809469ca9abcb0082e4f8d5651e46d3cdb762d02d0bf37c9e592;

    // 锚点消息块 (已填充, big-endian 字序)
    reg [511:0] blk_abc, blk_empty, blk_fox;

    integer k, m;
    reg [255:0] got;
    integer pass_cnt = 0, fail_cnt = 0;

    // ----------------------------------------------------------
    // 任务: 串行加载 + 启动 + 等待 + 读回 + 校验
    // ----------------------------------------------------------
    task load_and_hash;
        input [511:0] block;
        input [255:0] expected;
        input [31:0]  tname;
        begin
            // 等待上一轮完全结束
            while (busy || rvalid || done) @(posedge clk);
            // 写 16 个字 (先最高字 M[0])
            for (k = 0; k < 16; k = k + 1) begin
                @(posedge clk); #1;
                wen = 1;
                wdata = block[(15 - k)*32 +: 32];
                @(posedge clk); #1;
                wen = 0;
            end
            // 启动
            @(posedge clk); #1;
            start = 1;
            @(posedge clk); #1;
            start = 0;
            // 等待完成
            while (!done) @(posedge clk);
            // 读回 8 个字 (done=1 时 rdata 已是最高字)
            #1;
            got[255:224] = rdata;
            for (m = 1; m < 8; m = m + 1) begin
                @(posedge clk); #1;
                got[(7 - m)*32 +: 32] = rdata;
            end
            @(posedge clk); #1;
            // 校验
            if (got === expected) begin
                pass_cnt = pass_cnt + 1;
                $display("PASS  test[%0d]: got=%h", tname, got);
            end
            else begin
                fail_cnt = fail_cnt + 1;
                $display("FAIL  test[%0d]: exp=%h got=%h", tname, expected, got);
            end
        end
    endtask

    // ----------------------------------------------------------
    // 主测试
    // ----------------------------------------------------------
    initial begin
        reset_n = 0; wen = 0; wdata = 0; start = 0;
        blk_abc   = 512'h61626380_00000000_00000000_00000000_00000000_00000000_00000000_00000000_00000000_00000000_00000000_00000000_00000000_00000000_00000000_00000018;
        blk_empty = 512'h80000000_00000000_00000000_00000000_00000000_00000000_00000000_00000000_00000000_00000000_00000000_00000000_00000000_00000000_00000000_00000000;
        blk_fox   = 512'h54686520_71756963_6b206272_6f776e20_666f7820_6a756d70_73206f76_65722074_6865206c_617a7920_646f6780_00000000_00000000_00000000_00000000_00000158;

        repeat (3) @(posedge clk);
        reset_n = 1;
        repeat (3) @(posedge clk);

        $display("=== SHA-256 串行接口锚点测试开始 ===");
        load_and_hash(blk_abc,   DIG_ABC,   "abc  ");
        load_and_hash(blk_empty, DIG_EMPTY, "empty");
        load_and_hash(blk_fox,   DIG_FOX,   "fox  ");
        $display("=== 结果: %0d PASS, %0d FAIL ===", pass_cnt, fail_cnt);

        if (fail_cnt == 0 && pass_cnt == 3)
            $display("ALL TESTS PASSED");
        else
            $display("SOME TESTS FAILED");

        $finish;
    end

    // 超时保护 (8000 周期)
    initial begin
        #80000;
        $display("TIMEOUT");
        $finish;
    end

endmodule
