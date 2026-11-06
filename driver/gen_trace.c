/* gen_trace.c - 用驱动产生"寄存器写序列"，交给 Verilog 主机模型复现
 *
 * 这一步的意义：
 *   驱动不能被"阅读一遍觉得对"就算验证过。把驱动实际打出的寄存器序列
 *   落成文本 trace，再让 Verilog testbench 原样发到真 RTL 的 AXI 总线上，
 *   最后拿 hashlib 的摘要来对照——三份实现互不依赖。
 *
 * 用法：gen_trace <输出文件> <消息名>   （消息名：abc / a119 / empty）
 * 输出格式（每行一个动作）：
 *   W <addr 8位hex> <data 8位hex>   写寄存器
 *   WAIT                            等 STATUS.BUSY 落下
 *   END                             结束，testbench 读 DIGEST0..7
 */

#include "sha256_axil.h"
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

typedef struct {
    FILE *f;
    int   wait_pending;
} trace_ctx;

static void trace_wr(void *ctx, uint32_t off, uint32_t val)
{
    trace_ctx *t = (trace_ctx *)ctx;
    fprintf(t->f, "W %08x %08x\n", off, val);
}

static uint32_t trace_rd(void *ctx, uint32_t off)
{
    trace_ctx *t = (trace_ctx *)ctx;
    if (off == SHA256_REG_STATUS) {
        if (t->wait_pending) {
            fprintf(t->f, "WAIT\n");
            t->wait_pending = 0;
        }
        return SHA256_STATUS_READY;   /* busy 已落下 */
    }
    return 0u;
}

/* 让 wait 动作能进入 trace：每次 feed 前挂一个 pending 标记 */
static void trace_arm_wait(trace_ctx *t)
{
    t->wait_pending = 1;
}

static size_t build_msg(const char *name, uint8_t *buf, size_t cap)
{
    size_t n = 0, i;

    if (strcmp(name, "abc") == 0) {
        const char *s = "abc";
        n = strlen(s);
        memcpy(buf, s, n);
    } else if (strcmp(name, "empty") == 0) {
        n = 0;
    } else if (strcmp(name, "a119") == 0) {
        for (i = 0; i < 119 && i < cap; i++)
            buf[i] = (uint8_t)'a';
        n = 119;
    } else if (strcmp(name, "fox") == 0) {
        const char *s = "The quick brown fox jumps over the lazy dog";
        n = strlen(s);
        memcpy(buf, s, n);
    } else {
        fprintf(stderr, "未知消息名 %s\n", name);
        exit(2);
    }
    return n;
}

int main(int argc, char **argv)
{
    uint8_t  msg[256];
    uint32_t digest[8];
    size_t   len;
    trace_ctx t;
    sha256_dev dev;
    int rc;

    if (argc != 3) {
        fprintf(stderr, "usage: %s <trace_out> <abc|empty|a119|fox>\n", argv[0]);
        return 2;
    }

    len = build_msg(argv[2], msg, sizeof(msg));
    memset(&t, 0, sizeof(t));
    t.f = fopen(argv[1], "w");
    if (t.f == NULL) {
        perror("fopen");
        return 3;
    }

    dev.ctx  = &t;
    dev.wr32 = trace_wr;
    dev.rd32 = trace_rd;

    /* 每个块喂完都要等一次：把 wait 挂到 rd32 上（见 trace_rd） */
    fprintf(t.f, "# msg=%s len=%zu\n", argv[2], len);

    /* 手工展开 hash 流程，以便在每块前 arm 一次 wait */
    {
        size_t padded_len = ((len + 9 + 63) / 64) * 64;
        uint8_t *buf = (uint8_t *)calloc(padded_len, 1);
        size_t i, blocks;
        uint64_t bits;

        if (buf == NULL)
            return 4;
        if (len)
            memcpy(buf, msg, len);
        buf[len] = 0x80u;
        bits = (uint64_t)len * 8u;
        for (i = 0; i < 8; i++)
            buf[padded_len - 8 + i] = (uint8_t)((bits >> (56 - 8 * i)) & 0xFFu);

        sha256_init(&dev);
        blocks = padded_len / 64;
        for (i = 0; i < blocks; i++) {
            const uint8_t *blk = buf + 64 * i;
            int k;
            for (k = 0; k < 16; k++) {
                uint32_t w = ((uint32_t)blk[4 * k] << 24) |
                             ((uint32_t)blk[4 * k + 1] << 16) |
                             ((uint32_t)blk[4 * k + 2] << 8) |
                             ((uint32_t)blk[4 * k + 3]);
                sha256_write_word(&dev, w);
            }
            trace_arm_wait(&t);
            rc = sha256_wait_idle(&dev, 0);
            if (rc != 0) {
                fprintf(stderr, "wait 失败 %d\n", rc);
                free(buf);
                fclose(t.f);
                return 5;
            }
        }
        free(buf);
    }

    sha256_read_digest(&dev, digest);
    fprintf(t.f, "END\n");
    fclose(t.f);

    printf("trace=%s blocks=%zu len=%zu\n", argv[1],
           ((len + 9 + 63) / 64), len);
    return 0;
}
