// ============================================================
// tb_v7_axil.v - v7 顶层（AXI4-Lite + 多块流式）功能验证
//   用例 1：INIT -> 写 1 块(abc) -> 读 DIGEST，比对 hashlib
//   用例 2：INIT -> 连续写 2 块(119 个 'a') -> 读 DIGEST，比对 hashlib
//           这一条专门验证多块链式：不等 done，直接连写 32 个字。
// ============================================================
`timescale 1ps/1ps

module tb_v7_axil;

    reg         clk = 0;
    reg         reset_n = 0;

    reg  [5:0]  awaddr = 0;
    reg         awvalid = 0;
    wire        awready;
    reg  [31:0] wdata = 0;
    reg  [3:0]  wstrb = 4'hf;
    reg         wvalid = 0;
    wire        wready;
    wire [1:0]  bresp;
    wire        bvalid;
    reg         bready = 0;

    reg  [5:0]  araddr = 0;
    reg         arvalid = 0;
    wire        arready;
    wire [31:0] rdata;
    wire [1:0]  rresp;
    wire        rvalid;
    reg         rready = 0;

    integer pass_cnt = 0;
    integer fail_cnt = 0;
    integer i;
    reg [31:0] rd;

    sha256_axil dut (
        .clk(clk), .reset_n(reset_n),
        .s_axil_awaddr(awaddr), .s_axil_awvalid(awvalid), .s_axil_awready(awready),
        .s_axil_wdata(wdata), .s_axil_wstrb(wstrb), .s_axil_wvalid(wvalid), .s_axil_wready(wready),
        .s_axil_bresp(bresp), .s_axil_bvalid(bvalid), .s_axil_bready(bready),
        .s_axil_araddr(araddr), .s_axil_arvalid(arvalid), .s_axil_arready(arready),
        .s_axil_rdata(rdata), .s_axil_rresp(rresp), .s_axil_rvalid(rvalid), .s_axil_rready(rready)
    );

    always #5000 clk = ~clk;

    // ---------------- AXI 主机 task ----------------
    // 驱动全部在 negedge 落定、采样在 posedge，避免与 slave 的 always 抢同一时刻。
    task axil_write;
        input [5:0] addr;
        input [31:0] data;
        begin
            @(negedge clk);
            awaddr  = addr;
            awvalid = 1'b1;
            @(posedge clk);
            while (awready !== 1'b1) begin
                @(negedge clk);
                @(posedge clk);
            end
            @(negedge clk);
            awvalid = 1'b0;

            wdata  = data;
            wvalid = 1'b1;
            @(posedge clk);
            while (wready !== 1'b1) begin
                @(negedge clk);
                @(posedge clk);
            end
            @(negedge clk);
            wvalid = 1'b0;

            @(posedge clk);
            while (bvalid !== 1'b1) begin
                @(negedge clk);
                @(posedge clk);
            end
            @(negedge clk);
            bready = 1'b1;
            @(posedge clk);
            @(negedge clk);
            bready = 1'b0;
            @(posedge clk);
        end
    endtask

    task axil_read;
        input  [5:0]  addr;
        output [31:0] data;
        begin
            @(negedge clk);
            araddr  = addr;
            arvalid = 1'b1;
            @(posedge clk);
            while (arready !== 1'b1) begin
                @(negedge clk);
                @(posedge clk);
            end
            @(negedge clk);
            arvalid = 1'b0;

            @(posedge clk);
            while (rvalid !== 1'b1) begin
                @(negedge clk);
                @(posedge clk);
            end
            data = rdata;
            @(negedge clk);
            rready = 1'b1;
            @(posedge clk);
            @(negedge clk);
            rready = 1'b0;
            @(posedge clk);
        end
    endtask

    task check_digest;
        input [255:0] expect;
        input [127:0] name;
        reg   [255:0] got;
        begin
            for (i = 0; i < 8; i = i + 1) begin
                axil_read(6'h10 + i*4, rd);
                got[255-32*i -: 32] = rd;
            end
            if (got === expect) begin
                $display("PASS %s", name);
                pass_cnt = pass_cnt + 1;
            end
            else begin
                $display("FAIL %s", name);
                $display("  got %h", got);
                $display("  exp %h", expect);
                fail_cnt = fail_cnt + 1;
            end
        end
    endtask

    task wait_idle;
        begin
            axil_read(6'h04, rd);
            while (rd[0] !== 1'b1) axil_read(6'h04, rd);
        end
    endtask

    initial begin
        reset_n = 0;
        repeat (6) @(posedge clk);
        reset_n = 1;
        repeat (3) @(posedge clk);

        // ============ 用例 1：单块 abc ============
        axil_write(6'h00, 32'h1);        // INIT
        for (i = 0; i < 16; i = i + 1) begin
            case (i)
                0: axil_write(6'h08, 32'h61626380);
                15: axil_write(6'h08, 32'h00000018);
                default: axil_write(6'h08, 32'h00000000);
            endcase
        end
        wait_idle;
        check_digest({32'hba7816bf, 32'h8f01cfea, 32'h414140de, 32'h5dae2223,
                      32'hb00361a3, 32'h96177a9c, 32'hb410ff61, 32'hf20015ad},
                     "abc");

        // ============ 用例 2：两块 119 个 'a'（多块链式） ============
        axil_write(6'h00, 32'h1);        // INIT
        // 块 0：16 × 61616161
        for (i = 0; i < 16; i = i + 1)
            axil_write(6'h08, 32'h61616161);
        // 块 1：13 × 61616161 + 61616180 + 0 + 0x3b8
        for (i = 0; i < 13; i = i + 1)
            axil_write(6'h08, 32'h61616161);
        axil_write(6'h08, 32'h61616180);
        axil_write(6'h08, 32'h00000000);
        axil_write(6'h08, 32'h000003b8);
        wait_idle;
        check_digest({32'h31eba51c, 32'h313a5c08, 32'h226adf18, 32'hd4a359cf,
                      32'hdfd8d2e8, 32'h16b13f4a, 32'hf952f7ea, 32'h6584dcfb},
                     "a119-2blocks");

        $display("SUMMARY: pass=%0d fail=%0d", pass_cnt, fail_cnt);
        if (fail_cnt == 0) $display("ALL TESTS PASSED");
        else               $display("SOME TESTS FAILED");
        $finish;
    end

    initial begin
        #60000000;
        $display("TIMEOUT");
        $finish;
    end

endmodule
