/* SHA-256 分块状态机 —— 与 RTL 里保留的 8 个 32-bit 状态字等价
   独立文件，供 verify.html 与本地自测页共用 */
(function (g) {
  const K = new Uint32Array([
    0x428a2f98,0x71374491,0xb5c0fbcf,0xe9b5dba5,0x3956c25b,0x59f111f1,0x923f82a4,0xab1c5ed5,
    0xd807aa98,0x12835b01,0x243185be,0x550c7dc3,0x72be5d74,0x80deb1fe,0x9bdc06a7,0xc19bf174,
    0xe49b69c1,0xefbe4786,0x0fc19dc6,0x240ca1cc,0x2de92c6f,0x4a7484aa,0x5cb0a9dc,0x76f988da,
    0x983e5152,0xa831c66d,0xb00327c8,0xbf597fc7,0xc6e00bf3,0xd5a79147,0x06ca6351,0x14292967,
    0x27b70a85,0x2e1b2138,0x4d2c6dfc,0x53380d13,0x650a7354,0x766a0abb,0x81c2c92e,0x92722c85,
    0xa2bfe8a1,0xa81a664b,0xc24b8b70,0xc76c51a3,0xd192e819,0xd6990624,0xf40e3585,0x106aa070,
    0x19a4c116,0x1e376c08,0x2748774c,0x34b0bcb5,0x391c0cb3,0x4ed8aa4a,0x5b9cca4f,0x682e6ff3,
    0x748f82ee,0x78a5636f,0x84c87814,0x8cc70208,0x90befffa,0xa4506ceb,0xbef9a3f7,0xc67178f2
  ]);

  function rotr(x, n) { return (x >>> n) | (x << (32 - n)); }

  function Sha256Stream() {
    this.h = new Uint32Array([0x6a09e667,0xbb67ae85,0x3c6ef372,0xa54ff53a,
                              0x510e527f,0x9b05688c,0x1f83d9ab,0x5be0cd19]);
    this.buf = new Uint8Array(64);
    this.blen = 0;
    this.total = 0;
    this.w = new Uint32Array(64);
  }

  Sha256Stream.prototype._block = function (b, off) {
    const w = this.w, h = this.h;
    for (let i = 0; i < 16; i++) {
      const p = off + i * 4;
      w[i] = (b[p] << 24) | (b[p + 1] << 16) | (b[p + 2] << 8) | b[p + 3];
    }
    for (let i = 16; i < 64; i++) {
      const x = w[i - 15], y = w[i - 2];
      const s0 = rotr(x, 7) ^ rotr(x, 18) ^ (x >>> 3);
      const s1 = rotr(y, 17) ^ rotr(y, 19) ^ (y >>> 10);
      w[i] = (w[i - 16] + s0 + w[i - 7] + s1) >>> 0;
    }
    let a = h[0], b1 = h[1], c = h[2], d = h[3], e = h[4], f = h[5], g2 = h[6], hh = h[7];
    for (let i = 0; i < 64; i++) {
      const S1 = rotr(e, 6) ^ rotr(e, 11) ^ rotr(e, 25);
      const ch = (e & f) ^ (~e & g2);
      const t1 = (hh + S1 + ch + K[i] + w[i]) >>> 0;
      const S0 = rotr(a, 2) ^ rotr(a, 13) ^ rotr(a, 22);
      const maj = (a & b1) ^ (a & c) ^ (b1 & c);
      const t2 = (S0 + maj) >>> 0;
      hh = g2; g2 = f; f = e; e = (d + t1) >>> 0;
      d = c; c = b1; b1 = a; a = (t1 + t2) >>> 0;
    }
    h[0] = (h[0] + a) >>> 0; h[1] = (h[1] + b1) >>> 0;
    h[2] = (h[2] + c) >>> 0; h[3] = (h[3] + d) >>> 0;
    h[4] = (h[4] + e) >>> 0; h[5] = (h[5] + f) >>> 0;
    h[6] = (h[6] + g2) >>> 0; h[7] = (h[7] + hh) >>> 0;
  };

  Sha256Stream.prototype.update = function (bytes) {
    let i = 0;
    while (i < bytes.length) {
      const take = Math.min(64 - this.blen, bytes.length - i);
      this.buf.set(bytes.subarray(i, i + take), this.blen);
      this.blen += take;
      i += take;
      this.total += take;
      if (this.blen === 64) { this._block(this.buf, 0); this.blen = 0; }
    }
    return this;
  };

  Sha256Stream.prototype.hex = function () {
    const bits = this.total * 8;
    const tailLen = (this.blen + 1 + 8 <= 64) ? 64 : 128;
    const tail = new Uint8Array(tailLen);
    tail.set(this.buf.subarray(0, this.blen), 0);
    tail[this.blen] = 0x80;
    const hi = Math.floor(bits / 4294967296);
    const lo = bits >>> 0;
    tail[tailLen - 8] = (hi >>> 24) & 255;
    tail[tailLen - 7] = (hi >>> 16) & 255;
    tail[tailLen - 6] = (hi >>> 8) & 255;
    tail[tailLen - 5] = hi & 255;
    tail[tailLen - 4] = (lo >>> 24) & 255;
    tail[tailLen - 3] = (lo >>> 16) & 255;
    tail[tailLen - 2] = (lo >>> 8) & 255;
    tail[tailLen - 1] = lo & 255;
    this._block(tail, 0);
    if (tailLen === 128) this._block(tail, 64);
    let s = "";
    for (let i = 0; i < 8; i++) s += this.h[i].toString(16).padStart(8, "0");
    return s;
  };

  g.SHA256Impl = {
    Sha256Stream: Sha256Stream,
    hex: function (bytes) { return new Sha256Stream().update(bytes).hex(); }
  };
})(window);
