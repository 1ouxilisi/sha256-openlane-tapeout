`timescale 1ns/1ps
// ============================================================
// sha256_tb.v - SHA-256 压缩核 testbench
// 验证向量: Python hashlib.sha256 (FIPS 180-4 填充规则) 生成
// 运行: iverilog -o sim sha256_pipe.v sha256_tb.v && vvp sim
// ============================================================
module sha256_tb;
    reg clk = 0, reset_n = 0, start = 0;
    reg [511:0] msg;
    wire [255:0] digest;
    wire done;
    integer errors = 0;

    sha256_pipe dut(
        .clk(clk), .reset_n(reset_n), .start(start),
        .msg(msg), .digest(digest), .done(done)
    );

    always #5 clk = ~clk;

    task run_test(input [511:0] m, input [255:0] exp);
        integer cycles;
        begin
            msg = m;
            @(posedge clk); #1;
            start = 1;
            @(posedge clk); #1;
            start = 0;
            cycles = 0;
            while (done !== 1'b1 && cycles < 200) begin
                @(posedge clk); #1;
                cycles = cycles + 1;
            end
            if (cycles >= 200) begin
                errors = errors + 1;
                $display("FAIL: done timeout");
            end
            else if (digest !== exp) begin
                errors = errors + 1;
                $display("FAIL: digest mismatch");
                $display("  got  %h", digest);
                $display("  want %h", exp);
            end
            else begin
                $display("PASS: %h", digest);
            end
            @(posedge clk); #1;
        end
    endtask

    initial begin
        reset_n = 0;
        repeat (5) @(posedge clk);
        reset_n = 1;
        @(posedge clk); #1;
        $display("--- test: empty ---");
        run_test(512'h80000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000, 256'he3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855);
        $display("--- test: single_a ---");
        run_test(512'h61800000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000008, 256'hca978112ca1bbdcafac231b39a23dc4da786eff8147c4e72b9807785afee48bb);
        $display("--- test: abc ---");
        run_test(512'h61626380000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000018, 256'hba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad);
        $display("--- test: fox ---");
        run_test(512'h54686520717569636b2062726f776e20666f78206a756d7073206f76657220746865206c617a7920646f67800000000000000000000000000000000000000158, 256'hd7a8fbb307d7809469ca9abcb0082e4f8d5651e46d3cdb762d02d0bf37c9e592);
        $display("--- test: 55_bytes ---");
        run_test(512'h000102030405060708090a0b0c0d0e0f101112131415161718191a1b1c1d1e1f202122232425262728292a2b2c2d2e2f303132333435368000000000000001b8, 256'h463eb28e72f82e0a96c0a4cc53690c571281131f672aa229e0d45ae59b598b59);
        $display("--- test: incr33 ---");
        run_test(512'h0102030405060708090a0b0c0d0e0f101112131415161718191a1b1c1d1e1f202180000000000000000000000000000000000000000000000000000000000108, 256'h31b03c6eaed475dde345b1ce8293b9ae8bfc7bd9666597ddf28c18fa73d5c4f4);
        $display("--- test: zeros44 ---");
        run_test(512'h00000000000000000000000000000000000000000000000000000000000000000000000000000000000000008000000000000000000000000000000000000160, 256'h85759b3811ff7dc47b03792ac85317be51431a3f9e01dcafce317ed736a391b0);
        $display("--- test: all_ff ---");
        run_test(512'hffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff80000000000000000000000000000180, 256'h80a76a18acf8cb64fec3a659ffc4bab4a87cd9a6fde4dab2161a8751d136c9d2);
        $display("--- test: ascii_rep ---");
        run_test(512'h61626331323378797a61626331323378797a61626331323378797a61626331323378797a61626331323378797a80000000000000000000000000000000000168, 256'h22156f861105d1f07da138c4dc5fc653ed052f298701877fffdeb4a9579c68b9);
        $display("--- test: rand32 ---");
        run_test(512'h202122232425262728292a2b2c2d2e2f303132333435363738393a3b3c3d3e3f8000000000000000000000000000000000000000000000000000000000000100, 256'h72dbb7336c76780023f83da4c355f2eeea85733b13d3477697917790c1229084);
        $display("--- test: rand55 ---");
        run_test(512'h00070e151c232a31383f464d545b626970777e858c939aa1a8afb6bdc4cbd2d9e0e7eef5fc030a11181f262d343b424950575e656c737a8000000000000001b8, 256'h576a1bf8d4478657e6dc4af9398544765c2a92cde28478b019235cfed315fc09);
        $display("--- test: numeric ---");
        run_test(512'h30313233343536373839616263646566303132333435363738396162636465663031323334353637383961626364800000000000000000000000000000000170, 256'h7e21a307c1e030bc4a8de43b065998a6d61e59f553641e4932041452d19a4153);
        $display("================================");
        if (errors == 0)
            $display("ALL TESTS PASSED (%0d)", 1);
        else
            $display("TESTS FAILED: %0d error(s)", errors);
        $finish;
    end
endmodule
