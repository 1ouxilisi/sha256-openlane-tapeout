// ============================================================
// tb_v7_drv.v - 用 C 驱动产出的寄存器序列，驱动真 RTL 的 AXI 总线
//
// 与 tb_v7_axil.v 的区别：那一版是手写激励、手写期望常量；
// 这一版不含任何期望值，只做一件事——把别人（C 驱动）打出来的
// 寄存器序列原样发出去，再把 DIGEST 打印出来。对错由外部 hashlib 判定。
//
// 程序文件格式（由 trace2hex.py 从驱动 trace 生成）：
//   72-bit 一行 = {cmd[7:0], addr[31:0], data[31:0]}
//   cmd = 01 写寄存器 / 02 等 BUSY 落下 / 03 结束并读 DIGEST
// ============================================================
`timescale 1ps/1ps

// 程序文件路径由外层脚本生成的 prog_path.vh 提供（避免依赖编译期参数传递）
`include "prog_path.vh"

module tb_v7_drv;


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

    reg [71:0] prog [0:4095];
    integer    pc;
    integer    ops;
    integer    waits;
    reg [7:0]  cmd;
    reg [31:0] rd;
    reg [31:0] dg [0:7];
    integer    i;
    integer    poll;

    sha256_axil dut (
        .clk(clk), .reset_n(reset_n),
        .s_axil_awaddr(awaddr), .s_axil_awvalid(awvalid), .s_axil_awready(awready),
        .s_axil_wdata(wdata), .s_axil_wstrb(wstrb), .s_axil_wvalid(wvalid), .s_axil_wready(wready),
        .s_axil_bresp(bresp), .s_axil_bvalid(bvalid), .s_axil_bready(bready),
        .s_axil_araddr(araddr), .s_axil_arvalid(arvalid), .s_axil_arready(arready),
        .s_axil_rdata(rdata), .s_axil_rresp(rresp), .s_axil_rvalid(rvalid), .s_axil_rready(rready)
    );

    always #5000 clk = ~clk;   // 100 MHz

    // 驱动在 negedge 落定、采样在 posedge
    task axil_write;
        input [5:0]  addr;
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

    // 等 STATUS.BUSY 落下，最多等 20000 拍
    task wait_busy_drop;
        begin
            poll = 0;
            rd   = 32'h2;            // 强制先读一次
            while ((rd[1] === 1'b1) && (poll < 20000)) begin
                axil_read(6'h04, rd);
                poll = poll + 1;
            end
            if (rd[1] === 1'b1) begin
                $display("TIMEOUT waiting BUSY drop");
                $finish;
            end
        end
    endtask

    initial begin
        $readmemh(`PROG_FILE, prog);
        ops   = 0;
        waits = 0;

        reset_n = 0;
        repeat (20) @(posedge clk);
        @(negedge clk);
        reset_n = 1'b1;
        repeat (20) @(posedge clk);

        for (pc = 0; pc < 4096; pc = pc + 1) begin
            cmd = prog[pc][71:64];
            if (cmd === 8'h01) begin
                axil_write(prog[pc][63:32], prog[pc][31:0]);
                ops = ops + 1;
            end else if (cmd === 8'h02) begin
                wait_busy_drop();
                waits = waits + 1;
            end else if (cmd === 8'h03) begin
                for (i = 0; i < 8; i = i + 1)
                    axil_read(6'h10 + i[5:0]*4, dg[i]);
                $display("DIGEST %h%h%h%h%h%h%h%h", dg[0], dg[1], dg[2], dg[3], dg[4], dg[5], dg[6], dg[7]);
                $display("OPS %0d WAITS %0d", ops, waits);
                $display("DRV DONE");
                pc = 4096;
            end else if (cmd === 8'hxx) begin
                $display("NO_MORE_PROG %0d", pc);
                $finish;
            end
        end
        $finish;
    end

endmodule
