from openai import OpenAI

client = OpenAI(
    base_url="http://10.25.110.159:31412/v1",
    api_key="dummy"
)

question = input("Enter your question: ")

response = client.chat.completions.create(
    model="nvidia/Qwen3.6-35B-A3B-NVFP4",
    messages=[
        {
            "role": "user",
            "content": question
        }
    ]
)

print(response.choices[0].message.content)
