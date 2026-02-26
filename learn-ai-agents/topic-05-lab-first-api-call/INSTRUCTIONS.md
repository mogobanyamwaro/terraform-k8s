# Topic 5: Practice – Your First AI API Call

## What You'll Learn

- Call an LLM API (e.g. OpenAI, Anthropic) from code
- Send a simple prompt and receive a completion
- Handle API keys and basic request/response shape
- Optional: streaming a response

---

## Steps

*(Follow the course lab; adjust for your chosen provider and language.)*

### 1. Setup

- Get an API key from your provider (OpenAI, Anthropic, or other).
- Install the official SDK (e.g. `openai`, `anthropic`) or use `requests` with the REST API.
- Store the key in environment variables (e.g. `OPENAI_API_KEY`), not in source code.

### 2. Minimal request

- Build a request with a **model** name and **messages** (e.g. one `user` message).
- Send the request and print the **content** of the assistant reply.
- Check **usage** (prompt_tokens, completion_tokens) if returned.

### 3. Optional: streaming

- Set `stream: true` (or equivalent); iterate over chunks and print each token or delta as it arrives.
- Confirm you see output appearing incrementally.

---

## Practice

1. Change the system message and observe how the reply style changes.
2. Call the API with a multi-turn conversation (user → assistant → user) and verify the model uses context.

---

## Next Topic

**Topic 6: Practice – LangChain** – lab: build a small flow with LangChain.
