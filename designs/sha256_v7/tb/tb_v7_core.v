// ============================================================
// tb_v7_core.v - v7 压缩核单块功能验证（三条锚点向量）
// 期望值与 Python hashlib 一致：abc / empty / "The quick brown fox jumps over the lazy dog"
// 注意：Verilog 数字常量不能跨行，这里全部用 32 位字拼接。
// ============================================================
`timescale 1ps/1ps

module tb_v7_core;

    reg          clk = 0;
    reg          reset_n = 0;
    reg          start = 0;
    reg  [511:0] msg;
    reg  [255:0] h_in;
    wire [255:0] h_out;
    wire         done;

    integer pass_cnt = 0;
    integer fail_cnt = 0;

    localparam [255:0] IV = {32'h6a09e667, 32'hbb67ae85, 32'h3c6ef372, 32'ha54ff53a,
                             32'h510e527f, 32'h9b05688c, 32'h1f83d9ab, 32'h5be0cd19};

    sha256_core dut (
        .clk     (clk),
        .reset_n (reset_n),
        .start   (start),
        .msg     (msg),
        .h_in    (h_in),
        .h_out   (h_out),
        .done    (done)
    );

    always #5000 clk = ~clk;   // 100 MHz

    task do_block;
        input [511:0] m;
        input [255:0] expect;
        input [127:0] name;
        begin
            msg  = m;
            h_in = IV;
            @(posedge clk);
            start <= 1'b1;
            @(posedge clk);
            start <= 1'b0;
            @(posedge done);
            @(posedge clk);
            if (h_out === expect) begin
                $display("PASS %s", name);
                pass_cnt = pass_cnt + 1;
            end
            else begin
                $display("FAIL %s", name);
                $display("  got %h", h_out);
                $display("  exp %h", expect);
                fail_cnt = fail_cnt + 1;
            end
            repeat (4) @(posedge clk);
        end
    endtask

    initial begin
        msg  = 512'd0;
        h_in = IV;
        reset_n = 0;
        repeat (4) @(posedge clk);
        reset_n = 1;
        repeat (2) @(posedge clk);

        // --- abc ---
        do_block(
            {32'h61626380, 32'h00000000, 32'h00000000, 32'h00000000,
             32'h00000000, 32'h00000000, 32'h00000000, 32'h00000000,
             32'h00000000, 32'h00000000, 32'h00000000, 32'h00000000,
             32'h00000000, 32'h00000000, 32'h00000000, 32'h00000018},
            {32'hba7816bf, 32'h8f01cfea, 32'h414140de, 32'h5dae2223,
             32'hb00361a3, 32'h96177a9c, 32'hb410ff61, 32'hf20015ad},
            "abc");

        // --- empty ---
        do_block(
            {32'h80000000, 32'h00000000, 32'h00000000, 32'h00000000,
             32'h00000000, 32'h00000000, 32'h00000000, 32'h00000000,
             32'h00000000, 32'h00000000, 32'h00000000, 32'h00000000,
             32'h00000000, 32'h00000000, 32'h00000000, 32'h00000000},
            {32'he3b0c442, 32'h98fc1c14, 32'h9afbf4c8, 32'h996fb924,
             32'h27ae41e4, 32'h649b934c, 32'ha495991b, 32'h7852b855},
            "empty");

        // --- fox ---
        do_block(
            {32'h54686520, 32'h71756963, 32'h6b206272, 32'h6f776e20,
             32'h666f7820, 32'h6a756d70, 32'h73206f76, 32'h65722074,
             32'h6865206c, 32'h617a7920, 32'h646f6780, 32'h00000000,
             32'h00000000, 32'h00000000, 32'h00000000, 32'h00000158},
            {32'hd7a8fbb3, 32'h07d78094, 32'h69ca9abc, 32'hb0082e4f,
             32'h8d5651e4, 32'h6d3cdb76, 32'h2d02d0bf, 32'h37c9e592},
            "fox");

        $display("SUMMARY: pass=%0d fail=%0d", pass_cnt, fail_cnt);
        if (fail_cnt == 0)
            $display("ALL TESTS PASSED");
        else
            $display("SOME TESTS FAILED");
        $finish;
    end

    initial begin
        #20000000;   // 20 us：一块 192 拍 = 1.92 us，留足余量
        $display("TIMEOUT");
        $finish;
    end

endmodule
