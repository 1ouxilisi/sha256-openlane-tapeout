// ============================================================
// sha256_core.v - SHA-256 压缩核 v7（移位寄存器消息调度 + 3 级流水）
//
// 与 v6 (sha256_pipe.v) 的区别：
//   1) 消息调度 W 由"16 深循环窗口 + (t-k)%16 动态索引"
//      改为"16 深移位寄存器"，每轮整体移位、新字压入 W[15]。
//      原来 4 个 (t-k)%16 索引各综合成一棵 16 选 1 mux 树（v6 里
//      mux2_2 共 2,239 个，占 18.2% 面积），改为静态索引 W[14]/W[9]/W[1]/W[0]。
//      代价：512 个 W 触发器每轮全部翻转，动态功耗会上升。这个取舍要在
//      metrics 里如实对比，不能只报面积降。
//   2) 链值从 h_in 进、h_out 出（不再写死 IV），使多块流式成为可能：
//      首块由顶层送 IV，之后每块把上一块的 h_out 接回 h_in。
//   3) 流水结构、每轮 3 拍、逻辑函数、K 常量表与 v6 完全一致，
//      时序尺度不变（v6 的 24.0 ns 约束在 v7 上继续可用）。
//
// 接口：单块 512-bit 消息 + 256-bit 链值 -> 256-bit 新链值
// ============================================================

module sha256_core (
    input  wire               clk,
    input  wire               reset_n,
    input  wire               start,       // 单周期脉冲，启动一次块压缩
    input  wire [511:0]       msg,         // 512-bit 消息块（字 15 为 M[0]）
    input  wire [255:0]       h_in,        // 输入链值
    output reg  [255:0]       h_out,       // 输出链值
    output reg                done         // 完成，单周期
);

    localparam IDLE    = 2'd0,
               COMPUTE = 2'd1,
               ACCUM   = 2'd2,
               FINISH  = 2'd3;

    reg [1:0]  state;
    reg [5:0]  t;
    reg [1:0]  phase;
    reg [31:0] A, B, C, D, E, F, G, H;
    reg [31:0] W [0:15];          // 移位寄存器窗口，W[15] 最新

    reg [31:0] wc;
    reg [31:0] t1p;
    reg [31:0] t2p;

    // 输入的链值拆成本轮累加用寄存器
    reg [31:0] h0, h1, h2, h3, h4, h5, h6, h7;

    integer i;

    // ---------------- K 常量 ----------------
    function [31:0] k_const;
        input [5:0] idx;
        begin
            case (idx)
                6'd0:  k_const = 32'h428a2f98;
                6'd1:  k_const = 32'h71374491;
                6'd2:  k_const = 32'hb5c0fbcf;
                6'd3:  k_const = 32'he9b5dba5;
                6'd4:  k_const = 32'h3956c25b;
                6'd5:  k_const = 32'h59f111f1;
                6'd6:  k_const = 32'h923f82a4;
                6'd7:  k_const = 32'hab1c5ed5;
                6'd8:  k_const = 32'hd807aa98;
                6'd9:  k_const = 32'h12835b01;
                6'd10: k_const = 32'h243185be;
                6'd11: k_const = 32'h550c7dc3;
                6'd12: k_const = 32'h72be5d74;
                6'd13: k_const = 32'h80deb1fe;
                6'd14: k_const = 32'h9bdc06a7;
                6'd15: k_const = 32'hc19bf174;
                6'd16: k_const = 32'he49b69c1;
                6'd17: k_const = 32'hefbe4786;
                6'd18: k_const = 32'h0fc19dc6;
                6'd19: k_const = 32'h240ca1cc;
                6'd20: k_const = 32'h2de92c6f;
                6'd21: k_const = 32'h4a7484aa;
                6'd22: k_const = 32'h5cb0a9dc;
                6'd23: k_const = 32'h76f988da;
                6'd24: k_const = 32'h983e5152;
                6'd25: k_const = 32'ha831c66d;
                6'd26: k_const = 32'hb00327c8;
                6'd27: k_const = 32'hbf597fc7;
                6'd28: k_const = 32'hc6e00bf3;
                6'd29: k_const = 32'hd5a79147;
                6'd30: k_const = 32'h06ca6351;
                6'd31: k_const = 32'h14292967;
                6'd32: k_const = 32'h27b70a85;
                6'd33: k_const = 32'h2e1b2138;
                6'd34: k_const = 32'h4d2c6dfc;
                6'd35: k_const = 32'h53380d13;
                6'd36: k_const = 32'h650a7354;
                6'd37: k_const = 32'h766a0abb;
                6'd38: k_const = 32'h81c2c92e;
                6'd39: k_const = 32'h92722c85;
                6'd40: k_const = 32'ha2bfe8a1;
                6'd41: k_const = 32'ha81a664b;
                6'd42: k_const = 32'hc24b8b70;
                6'd43: k_const = 32'hc76c51a3;
                6'd44: k_const = 32'hd192e819;
                6'd45: k_const = 32'hd6990624;
                6'd46: k_const = 32'hf40e3585;
                6'd47: k_const = 32'h106aa070;
                6'd48: k_const = 32'h19a4c116;
                6'd49: k_const = 32'h1e376c08;
                6'd50: k_const = 32'h2748774c;
                6'd51: k_const = 32'h34b0bcb5;
                6'd52: k_const = 32'h391c0cb3;
                6'd53: k_const = 32'h4ed8aa4a;
                6'd54: k_const = 32'h5b9cca4f;
                6'd55: k_const = 32'h682e6ff3;
                6'd56: k_const = 32'h748f82ee;
                6'd57: k_const = 32'h78a5636f;
                6'd58: k_const = 32'h84c87814;
                6'd59: k_const = 32'h8cc70208;
                6'd60: k_const = 32'h90befffa;
                6'd61: k_const = 32'ha4506ceb;
                6'd62: k_const = 32'hbef9a3f7;
                default: k_const = 32'hc67178f2;
            endcase
        end
    endfunction

    // ---------------- 逻辑函数 ----------------
    function [31:0] sigma0;
        input [31:0] x;
        begin
            sigma0 = ((x >> 7)  | (x << 25)) ^
                     ((x >> 18) | (x << 14)) ^
                     (x >> 3);
        end
    endfunction

    function [31:0] sigma1;
        input [31:0] x;
        begin
            sigma1 = ((x >> 17) | (x << 15)) ^
                     ((x >> 19) | (x << 13)) ^
                     (x >> 10);
        end
    endfunction

    function [31:0] big_sigma0;
        input [31:0] x;
        begin
            big_sigma0 = ((x >> 2)  | (x << 30)) ^
                         ((x >> 13) | (x << 19)) ^
                         ((x >> 22) | (x << 10));
        end
    endfunction

    function [31:0] big_sigma1;
        input [31:0] x;
        begin
            big_sigma1 = ((x >> 6)  | (x << 26)) ^
                         ((x >> 11) | (x << 21)) ^
                         ((x >> 25) | (x << 7));
        end
    endfunction

    function [31:0] ch;
        input [31:0] x, y, z;
        begin
            ch = (x & y) ^ (~x & z);
        end
    endfunction

    function [31:0] maj;
        input [31:0] x, y, z;
        begin
            maj = (x & y) ^ (x & z) ^ (y & z);
        end
    endfunction

    // ------------------------------------------------------------
    // 新消息字
    //   t < 16 : 直接取输入块的第 (15-t) 个字（M[0] 为最高字）
    //   t >=16 : W[t-2..t-16] 已随移位移到 W[14]/W[9]/W[1]/W[0]
    // ------------------------------------------------------------
    wire [31:0] w_new;
    assign w_new = (t < 6'd16)
                 ? msg[(15 - t)*32 +: 32]
                 : (sigma1(W[14]) + W[9] + sigma0(W[1]) + W[0]);

    // ------------------------------------------------------------
    // 主状态机
    // ------------------------------------------------------------
    always @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            state  <= IDLE;
            done   <= 1'b0;
            t      <= 6'd0;
            phase  <= 2'd0;
            A <= 32'd0; B <= 32'd0; C <= 32'd0; D <= 32'd0;
            E <= 32'd0; F <= 32'd0; G <= 32'd0; H <= 32'd0;
            h_out  <= 256'd0;
            wc     <= 32'd0;
            t1p    <= 32'd0;
            t2p    <= 32'd0;
            h0 <= 32'd0; h1 <= 32'd0; h2 <= 32'd0; h3 <= 32'd0;
            h4 <= 32'd0; h5 <= 32'd0; h6 <= 32'd0; h7 <= 32'd0;
            for (i = 0; i < 16; i = i + 1)
                W[i] <= 32'd0;
        end
        else begin
            case (state)
                IDLE: begin
                    done <= 1'b0;
                    if (start) begin
                        state <= COMPUTE;
                        t     <= 6'd0;
                        phase <= 2'd0;
                        // 链值进寄存器（供 ACCUM 使用）并装入 A-H
                        {h0, h1, h2, h3, h4, h5, h6, h7} <= h_in;
                        A <= h_in[255:224];
                        B <= h_in[223:192];
                        C <= h_in[191:160];
                        D <= h_in[159:128];
                        E <= h_in[127:96];
                        F <= h_in[95:64];
                        G <= h_in[63:32];
                        H <= h_in[31:0];
                        for (i = 0; i < 16; i = i + 1)
                            W[i] <= 32'd0;   // 窗口内容由移位过程自行填充
                    end
                end

                COMPUTE: begin
                    case (phase)
                        2'd0: begin
                            wc    <= w_new;
                            phase <= 2'd1;
                        end
                        2'd1: begin
                            t1p   <= H + big_sigma1(E) + ch(E, F, G) + k_const(t);
                            t2p   <= big_sigma0(A) + maj(A, B, C);
                            phase <= 2'd2;
                        end
                        default: begin
                            // 移位寄存器：整体右移一格，新字压入 W[15]
                            for (i = 0; i < 15; i = i + 1)
                                W[i] <= W[i+1];
                            W[15] <= wc;

                            H <= G; G <= F; F <= E;
                            E <= D + t1p + wc;
                            D <= C; C <= B; B <= A;
                            A <= (t1p + wc) + t2p;
                            phase <= 2'd0;
                            if (t == 6'd63)
                                state <= ACCUM;
                            else
                                t <= t + 6'd1;
                        end
                    endcase
                end

                ACCUM: begin
                    A <= A + h0;
                    B <= B + h1;
                    C <= C + h2;
                    D <= D + h3;
                    E <= E + h4;
                    F <= F + h5;
                    G <= G + h6;
                    H <= H + h7;
                    state <= FINISH;
                end

                FINISH: begin
                    h_out <= {A, B, C, D, E, F, G, H};
                    done  <= 1'b1;
                    state <= IDLE;
                end
            endcase
        end
    end

endmodule
