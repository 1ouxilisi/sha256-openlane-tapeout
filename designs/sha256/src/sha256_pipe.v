// ============================================================
// sha256_pipe.v - SHA-256 哈希加速器核心 (3 级流水线化版本)
// 用途: OpenLane + SkyWater 130nm 流片
// 优化(v3): 将 2 级流水再拆为 3 级:
//   级1: W 扩展计算 wc (sigma1+sigma0+加法)
//   级2: t1p = H+Sigma1(E)+Ch+K  与 t2p = Sigma0(A)+Maj 并行
//   级3: E=D+t1p+wc, A=t1p+wc+t2p 完成 A-H 更新与 W 写回
//   每级组合深度 ~8-10ns, 目标频率 ~100MHz (此前 2 级 53MHz)
// 接口: 与 sha256_core 相同 (单块 512-bit 输入 -> 256-bit 摘要)
// ============================================================

module sha256_pipe #(
    parameter DATA_W = 512,
    parameter HASH_W = 256
)(
    input  wire               clk,
    input  wire               reset_n,
    input  wire               start,          // 开始处理当前消息块
    input  wire [DATA_W-1:0]  msg,            // 512-bit 消息块 (big-endian)
    output reg  [HASH_W-1:0]  digest,         // 256-bit 摘要
    output reg                done            // 处理完成标志
);

    // ----------------------------------------------------------
    // 内部状态
    // ----------------------------------------------------------
    localparam IDLE    = 2'd0,
               COMPUTE = 2'd1,
               ACCUM   = 2'd2,
               FINISH  = 2'd3;

    reg [1:0]  state;
    reg [5:0]  t;                       // 轮计数 0..63
    reg [1:0]  phase;                   // 流水级: 0=级1(W扩展), 1=级2(t1p/t2p), 2=级3(完成轮)
    reg [31:0] A, B, C, D, E, F, G, H;  // 工作变量
    reg [31:0] W [0:15];                // 消息调度窗口

    // 流水级间寄存器
    reg [31:0] wc;                      // 级1: 消息字 W[t] (由 W 扩展或输入算出)
    reg [31:0] t1p;                     // 级2: H + Sigma1(E) + Ch(E,F,G) + K[t] (不含 W)
    reg [31:0] t2p;                     // 级2: Sigma0(A) + Maj(A,B,C)

    integer i;

    // ----------------------------------------------------------
    // SHA-256 轮常量 K[0..63]
    // ----------------------------------------------------------
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

    // ----------------------------------------------------------
    // 逻辑函数
    // ----------------------------------------------------------
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

    // ----------------------------------------------------------
    // 消息字选择: t<16 直接取输入, t>=16 由窗口扩展
    // ----------------------------------------------------------
    wire [31:0] w_cur;
    assign w_cur = (t < 16) ? msg[(15 - t)*32 +: 32]
                            : (sigma1(W[(t-2) % 16]) + W[(t-7) % 16]
                               + sigma0(W[(t-15) % 16]) + W[(t-16) % 16]);

    // ----------------------------------------------------------
    // 主状态机 (3 级流水: phase 0 W扩展, phase 1 t1p/t2p, phase 2 完成轮)
    // ----------------------------------------------------------
    always @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            state  <= IDLE;
            done   <= 1'b0;
            t      <= 6'd0;
            phase  <= 2'd0;
            A      <= 32'd0; B <= 32'd0; C <= 32'd0; D <= 32'd0;
            E      <= 32'd0; F <= 32'd0; G <= 32'd0; H <= 32'd0;
            digest <= 256'd0;
            wc     <= 32'd0;
            t1p    <= 32'd0;
            t2p    <= 32'd0;
            for (i = 0; i < 16; i = i + 1)
                W[i] <= 32'd0;
        end
        else begin
            case (state)
                // 空闲: 装载初始值 + 消息块
                IDLE: begin
                    done <= 1'b0;
                    if (start) begin
                        state <= COMPUTE;
                        t     <= 6'd0;
                        phase <= 2'd0;
                        A     <= 32'h6a09e667; B <= 32'hbb67ae85;
                        C     <= 32'h3c6ef372; D <= 32'ha54ff53a;
                        E     <= 32'h510e527f; F <= 32'h9b05688c;
                        G     <= 32'h1f83d9ab; H <= 32'h5be0cd19;
                        for (i = 0; i < 16; i = i + 1)
                            W[i] <= msg[(15 - i)*32 +: 32];
                    end
                end

                // 压缩: 64 轮, 每轮 3 拍流水
                COMPUTE: begin
                    case (phase)
                        // ---- 级 1: 预计算消息字 W[t] ----
                        2'd0: begin
                            wc    <= w_cur;
                            phase <= 2'd1;
                        end
                        // ---- 级 2: t1 不含 W 部分 + t2 并行 ----
                        2'd1: begin
                            t1p   <= H + big_sigma1(E) + ch(E, F, G) + k_const(t);
                            t2p   <= big_sigma0(A) + maj(A, B, C);
                            phase <= 2'd2;
                        end
                        // ---- 级 3: 完成本轮 (更新 A-H 与 W 窗口) ----
                        default: begin
                            W[t[3:0]] <= wc;
                            H <= G; G <= F; F <= E;
                            E <= D + t1p + wc;                     // E = D + t1
                            D <= C; C <= B; B <= A;
                            A <= (t1p + wc) + t2p;                 // A = t1 + t2
                            phase <= 2'd0;
                            if (t == 6'd63)
                                state <= ACCUM;
                            else
                                t <= t + 6'd1;
                        end
                    endcase
                end

                // 累加初始哈希值
                ACCUM: begin
                    A <= A + 32'h6a09e667;
                    B <= B + 32'hbb67ae85;
                    C <= C + 32'h3c6ef372;
                    D <= D + 32'ha54ff53a;
                    E <= E + 32'h510e527f;
                    F <= F + 32'h9b05688c;
                    G <= G + 32'h1f83d9ab;
                    H <= H + 32'h5be0cd19;
                    state <= FINISH;
                end

                // 输出摘要
                FINISH: begin
                    digest <= {A, B, C, D, E, F, G, H};
                    done   <= 1'b1;
                    state  <= IDLE;
                end
            endcase
        end
    end

endmodule
