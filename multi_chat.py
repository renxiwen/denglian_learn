import os
from dotenv import load_dotenv
from openai import OpenAI

load_dotenv()

client = OpenAI(
    api_key=os.environ.get('DEEPSEEK_API_KEY'),
    base_url=os.environ.get('DEEPSEEK_BASE_URL', "https://api.deepseek.com")
)

# Round 1
messages = [{"role": "user", "content": "What's the longest river in the world?"}]
response = client.chat.completions.create(
    model="deepseek-v4-flash",
    messages=messages
)

messages.append(response.choices[0].message)
print(f"Messages Round 1: {messages}\n")

# Round 2
messages.append({"role": "user", "content": "What is the second?"})
response = client.chat.completions.create(
    model="deepseek-v4-flash",
    messages=messages
)

messages.append(response.choices[0].message)
print(f"Messages Round 2: {messages}")