/* sha256_axil.h - SHA-256 v7 AXI4-Lite 加速器主机驱动（可移植版）
 *
 * 设计原则：驱动不假设任何平台。
 *   - 只依赖两个回调：读一个 32-bit 寄存器、写一个 32-bit 寄存器；
 *   - 不直接访问 /dev/mem、不依赖 mmap、不依赖中断控制器；
 *   - 上层把这层换成 Xilinx Xil_In32/Xil_Out32、Linux /dev/mem、UIO，
 *     或本仓库自带的 trace 后端，就能在裸机、Linux、仿真三种环境里跑同一份代码。
 *
 * 寄存器映射（见 src/sha256_axil.v 头注释）：
 *   0x00 CTRL      W  bit0 INIT
 *   0x04 STATUS    R  bit0 READY / bit1 BUSY
 *   0x08 MSG       W  一个 32-bit 消息字，写满 16 字自动启动压缩
 *   0x0C MSGCNT    R  当前块已写字数
 *   0x10..0x2C     R  DIGEST0..7
 *
 * 明确不做的事（不要假装支持）：
 *   - padding 由软件完成。芯片不接受任意长度输入，只接受已经补齐成
 *     64 字节整块的消息。sha256_hash() 内部负责补齐。
 *   - 没有中断。压缩完成靠轮询 STATUS.BUSY 或由上层按吞吐时序控制。
 *   - 没有并发保护。多个上下文同时使用需由软件串行化。
 */
#ifndef SHA256_AXIL_H
#define SHA256_AXIL_H

#include <stdint.h>
#include <stddef.h>

#define SHA256_REG_CTRL      0x00u
#define SHA256_REG_STATUS    0x04u
#define SHA256_REG_MSG       0x08u
#define SHA256_REG_MSGCNT    0x0Cu
#define SHA256_REG_DIGEST0   0x10u

#define SHA256_STATUS_READY  (1u << 0)
#define SHA256_STATUS_BUSY   (1u << 1)

/* 返回 0 表示正常，负值表示硬件异常/超时 */
#define SHA256_ERR_TIMEOUT   (-1)
#define SHA256_ERR_BUSY      (-2)

typedef void     (*sha256_wr32_fn)(void *ctx, uint32_t reg_off, uint32_t value);
typedef uint32_t (*sha256_rd32_fn)(void *ctx, uint32_t reg_off);

typedef struct {
    void          *ctx;     /* 后端私有数据（映射基址、trace 文件句柄等） */
    sha256_wr32_fn wr32;
    sha256_rd32_fn rd32;
} sha256_dev;

#ifdef __cplusplus
extern "C" {
#endif

/* 把链值重置为 SHA-256 初始值并清块缓冲。每个新消息调用一次。 */
void sha256_init(sha256_dev *dev);

/* 写一个消息字。调用者保证每 16 个字构成一个完整的 64 字节块。 */
void sha256_write_word(sha256_dev *dev, uint32_t word);

/* 轮询到 BUSY 落下。max_poll 为 0 时使用默认上限。 */
int sha256_wait_idle(sha256_dev *dev, uint32_t max_poll);

/* 读回当前链值（8 个 32-bit 字，大端序语义） */
void sha256_read_digest(sha256_dev *dev, uint32_t out[8]);

/* 完整一次哈希：内部完成 padding，按 64 字节块连续喂入，块间自动等待。
 * len 为原始消息字节数；out 接收 8 个 32-bit 字。
 * 返回 0 表示成功。 */
int sha256_hash(sha256_dev *dev, const uint8_t *msg, size_t len, uint32_t out[8]);

#ifdef __cplusplus
}
#endif

#endif /* SHA256_AXIL_H */
