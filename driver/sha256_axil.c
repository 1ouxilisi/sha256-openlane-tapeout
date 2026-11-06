/* sha256_axil.c - SHA-256 v7 AXI4-Lite 主机驱动实现 */

#include "sha256_axil.h"
#include <stdlib.h>
#include <string.h>

#define DEFAULT_POLL_LIMIT 1000000u

static uint32_t status(sha256_dev *dev)
{
    return dev->rd32(dev->ctx, SHA256_REG_STATUS);
}

void sha256_init(sha256_dev *dev)
{
    dev->wr32(dev->ctx, SHA256_REG_CTRL, 1u);   /* bit0 = INIT */
}

void sha256_write_word(sha256_dev *dev, uint32_t word)
{
    dev->wr32(dev->ctx, SHA256_REG_MSG, word);
}

int sha256_wait_idle(sha256_dev *dev, uint32_t max_poll)
{
    uint32_t limit = max_poll ? max_poll : DEFAULT_POLL_LIMIT;
    uint32_t i;

    for (i = 0; i < limit; i++) {
        if ((status(dev) & SHA256_STATUS_BUSY) == 0u)
            return 0;
    }
    return SHA256_ERR_TIMEOUT;
}

void sha256_read_digest(sha256_dev *dev, uint32_t out[8])
{
    int i;
    for (i = 0; i < 8; i++)
        out[i] = dev->rd32(dev->ctx, SHA256_REG_DIGEST0 + (uint32_t)(4 * i));
}

/* 把一个 64 字节块拆成 16 个 32-bit 大端字写进去，然后等压缩完成。 */
static int feed_block(sha256_dev *dev, const uint8_t *blk)
{
    int i;
    for (i = 0; i < 16; i++) {
        uint32_t w = ((uint32_t)blk[4 * i] << 24) |
                     ((uint32_t)blk[4 * i + 1] << 16) |
                     ((uint32_t)blk[4 * i + 2] << 8) |
                     ((uint32_t)blk[4 * i + 3]);
        sha256_write_word(dev, w);
    }
    /* 写满第 16 字时硬件当拍拉低 ready 并启动压缩；
     * 这里等它落下再喂下一块，保持与"软件不轮询"的文档说法一致——
     * 实际上连续写也不会丢字，反压由 awready/wready 承担。 */
    return sha256_wait_idle(dev, 0);
}

int sha256_hash(sha256_dev *dev, const uint8_t *msg, size_t len, uint32_t out[8])
{
    size_t padded_len;
    uint8_t *buf;
    size_t i, blocks;
    int rc = 0;

    if (msg == NULL && len != 0)
        return SHA256_ERR_BUSY;

    /* padding：消息 + 0x80 + 若干 0x00 + 64-bit 大端长度，补齐到 64 字节整块 */
    padded_len = ((len + 9 + 63) / 64) * 64;
    buf = (uint8_t *)calloc(padded_len, 1);
    if (buf == NULL)
        return SHA256_ERR_BUSY;

    if (len)
        memcpy(buf, msg, len);
    buf[len] = 0x80u;

    {
        uint64_t bits = (uint64_t)len * 8u;
        size_t pos = padded_len - 8;
        int k;
        for (k = 0; k < 8; k++)
            buf[pos + k] = (uint8_t)((bits >> (56 - 8 * k)) & 0xFFu);
    }

    sha256_init(dev);

    blocks = padded_len / 64;
    for (i = 0; i < blocks; i++) {
        rc = feed_block(dev, buf + 64 * i);
        if (rc != 0)
            break;
    }

    if (rc == 0)
        sha256_read_digest(dev, out);

    free(buf);
    return rc;
}
