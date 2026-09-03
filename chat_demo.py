#!/usr/bin/env python3
"""DeepSeek 多轮对话 Demo。API Key 与接口地址见 config.json。"""

from __future__ import annotations

import json
import sys
from pathlib import Path

from openai import OpenAI

CONFIG_PATH = Path(__file__).with_name("config.json")


def load_config() -> dict:
    if not CONFIG_PATH.exists():
        example = CONFIG_PATH.with_name("config.example.json")
        raise FileNotFoundError(
            f"未找到 {CONFIG_PATH.name}。请复制 {example.name} 为 config.json，并填入 api_key。"
        )
    with CONFIG_PATH.open(encoding="utf-8") as f:
        config = json.load(f)

    api_key = (config.get("api_key") or "").strip()
    if not api_key or api_key.startswith("sk-your-"):
        raise ValueError("请在 config.json 中填写有效的 DeepSeek api_key。")

    config.setdefault("base_url", "https://api.deepseek.com")
    config.setdefault("model", "deepseek-chat")
    return config


def main() -> None:
    config = load_config()
    client = OpenAI(api_key=config["api_key"], base_url=config["base_url"])
    model = config["model"]

    messages: list[dict[str, str]] = [
        {"role": "system", "content": "你是一个简洁、准确的中文助手。"},
    ]

    print("DeepSeek 多轮对话已启动。输入内容后回车发送。")
    print("命令：/exit 退出  |  /clear 清空上下文  |  /history 查看历史\n")

    while True:
        try:
            user_input = input("你: ").strip()
        except (EOFError, KeyboardInterrupt):
            print("\n已退出。")
            return

        if not user_input:
            continue
        if user_input in {"/exit", "/quit", "q"}:
            print("已退出。")
            return
        if user_input == "/clear":
            messages = [messages[0]]
            print("已清空对话上下文。\n")
            continue
        if user_input == "/history":
            for msg in messages[1:]:
                role = "你" if msg["role"] == "user" else "助手"
                print(f"  [{role}] {msg['content']}")
            print()
            continue

        messages.append({"role": "user", "content": user_input})

        try:
            stream = client.chat.completions.create(
                model=model,
                messages=messages,
                stream=True,
            )
        except Exception as exc:
            messages.pop()
            print(f"请求失败: {exc}\n")
            continue

        print("助手: ", end="", flush=True)
        reply_parts: list[str] = []
        for chunk in stream:
            delta = chunk.choices[0].delta.content or ""
            if delta:
                reply_parts.append(delta)
                print(delta, end="", flush=True)
        print("\n")

        reply = "".join(reply_parts)
        if reply:
            messages.append({"role": "assistant", "content": reply})


if __name__ == "__main__":
    try:
        main()
    except (FileNotFoundError, ValueError) as exc:
        print(exc, file=sys.stderr)
        sys.exit(1)
