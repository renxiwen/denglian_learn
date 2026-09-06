#!/usr/bin/env python3
"""用 "web3" + nonce 做 SHA256，统计前导 0 达到 4 位和 5 位所需时间。"""

from __future__ import annotations

import hashlib
import random
import time


PREFIX = "web3"


def sha256_hex(text: str) -> str:
    return hashlib.sha256(text.encode("utf-8")).hexdigest()


def main() -> None:
    nonce = random.randint(0, 2**32 - 1)
    print(f"前缀: {PREFIX!r}")
    print(f"起始 nonce: {nonce}")
    print()

    found_4 = False
    started = time.perf_counter()

    while True:
        digest = sha256_hex(f"{PREFIX}{nonce}")
        if not found_4 and digest.startswith("0000"):
            elapsed = time.perf_counter() - started
            print("满足 4 个 0 开头")
            print(f"  nonce : {nonce}")
            print(f"  hash  : {digest}")
            print(f"  耗时  : {elapsed:.6f} 秒")
            print()
            found_4 = True
            if digest.startswith("00000"):
                print("该结果同时满足 5 个 0 开头")
                return
        if digest.startswith("00000"):
            elapsed = time.perf_counter() - started
            print("满足 5 个 0 开头")
            print(f"  nonce : {nonce}")
            print(f"  hash  : {digest}")
            print(f"  耗时  : {elapsed:.6f} 秒")
            return
        nonce += 1


if __name__ == "__main__":
    main()
