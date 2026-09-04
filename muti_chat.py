#!/usr/bin/env python3
"""与 DeepSeek 进行多轮对话：每次请求都会带上完整会话历史。"""

from __future__ import annotations

import os
import sys

from dotenv import load_dotenv
from openai import OpenAI


def load_config() -> tuple[str, str, str]:
    load_dotenv()

    api_key = os.getenv("DEEPSEEK_API_KEY")
    model = os.getenv("DEEPSEEK_MODEL")
    base_url = os.getenv("DEEPSEEK_OPENAI_BASE_URL")

    missing = [
        name
        for name, value in (
            ("DEEPSEEK_API_KEY", api_key),
            ("DEEPSEEK_MODEL", model),
            ("DEEPSEEK_OPENAI_BASE_URL", base_url),
        )
        if not value
    ]
    if missing:
        print(
            "缺少环境变量: " + ", ".join(missing),
            file=sys.stderr,
        )
        sys.exit(1)

    return api_key, model, base_url


def chat_loop(client: OpenAI, model: str) -> None:
    messages: list[dict[str, str]] = []

    print("已进入多轮对话。输入内容后回车发送；输入 /exit 或 /quit 退出。")
    print("输入 /clear 可清空当前会话历史。\n")

    while True:
        try:
            user_input = input("你: ").strip()
        except (EOFError, KeyboardInterrupt):
            print("\n再见。")
            break

        if not user_input:
            continue
        if user_input in ("/exit", "/quit"):
            print("再见。")
            break
        if user_input == "/clear":
            messages.clear()
            print("已清空会话历史。\n")
            continue

        messages.append({"role": "user", "content": user_input})

        try:
            response = client.chat.completions.create(
                model=model,
                messages=messages,
            )
        except Exception as exc:
            messages.pop()
            print(f"请求失败: {exc}\n")
            continue

        assistant_text = (response.choices[0].message.content or "").strip()
        messages.append({"role": "assistant", "content": assistant_text})
        print(f"AI: {assistant_text}\n")


def main() -> None:
    api_key, model, base_url = load_config()
    client = OpenAI(api_key=api_key, base_url=base_url)
    chat_loop(client, model)


if __name__ == "__main__":
    main()
