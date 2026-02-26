# Topic 1: How LLMs Work in Real Time

## What You'll Learn

- **Tokenization** – how text becomes tokens; vocabulary and why token count matters
- **Transformers** – architecture (embedding, attention, layers); autoregressive decoding
- **Conversation history** – who keeps it, how it’s sent each request, stateless model
- **Context window** – max input tokens; what counts, truncation, and cost/latency impact
- **Streaming** – token-by-token output; why it matters for UX and cancellation
- **Sampling and temperature** – how the next token is chosen; deterministic vs varied output
- **Inference vs training** – you use a frozen model; no learning during chat
- **Model size and API shape** – parameters, request/response structure
- **Limitations** – no true memory, hallucinations, context and cost limits

---

## Steps

### 1. Tokenization: Text → Tokens

The model never sees raw characters. Your input is turned into **tokens** (words or subwords) from a fixed **vocabulary**:

- **Why tokens?** A finite vocabulary (e.g. 50K–150K tokens) lets the model work with IDs and embeddings. One token is often ~4 characters or ~¾ of a word in English, but it varies by language and tokenizer.

- **What counts.** Every character in system message, history, and your latest message is tokenized. Total token count drives **cost**, **latency**, and whether you fit in the **context window**. APIs often expose a token-count endpoint or document rules of thumb.

- **Implications.** Same idea in fewer words = fewer tokens. Code and non-English text can use more tokens per character.

**Takeaway:** Everything you send is a sequence of token IDs. Token count is the unit of “size” for context and billing.

---

### 2. Transformers: The Engine Under the Hood

Modern LLMs (GPT, Claude, Llama, etc.) are **transformer** models:

- **Embedding.** Each token ID is mapped to a vector (list of numbers). These vectors live in “embedding space”; similar meanings sit close together.

- **Attention.** **Self-attention** lets each token “look at” every other token in the sequence. The model uses this to capture “this pronoun refers to that noun” or “this word negates that one.”

- **Layers.** Many layers of attention and feed-forward networks stack on top. Each layer refines the representation.

- **Next-token prediction.** The model predicts the **next** token only. It then appends that token and predicts again (**autoregressive decoding**). The reply you see is generated one token at a time; there is no pre-written answer.

- **No “thinking” by default.** What you see is the same sequence the model is generating. “Reasoning” or “chain-of-thought” is usually extra steps or a separate pass before the final answer is streamed.

**Takeaway:** Chat output is a transformer reading the current context and emitting one token at a time via attention over that context.

---

### 3. Conversation History: What the Model “Remembers”

The model is **stateless**: it does not retain memory between API calls. “Memory” is **conversation history** sent by the client:

- **Who keeps history?** The client (app, UI, or your code) keeps the list of past messages. Each request typically includes **the full conversation** (or a truncated/summarized version).

- **Roles.** Messages are usually tagged as **system**, **user**, or **assistant**. The API receives something like:  
  `[system], [user 1], [assistant 1], [user 2], ...`  
  The model runs over this sequence and then generates the next reply. “Remembering” is re-reading what you sent.

- **Implications.** Longer history → more tokens → slower and more expensive. If the client doesn’t send old messages, the model cannot “remember” them. Editing or deleting a message in the UI usually means the client resends a shorter or changed history from that point.

**Takeaway:** Conversation history is the list of messages you send with each request. The LLM has no persistent memory; it only sees that payload.

---

### 4. Context Window: The Hard Limit

The **context window** is the maximum number of tokens the model can take as input (and sometimes output) in one request.

- **What counts.** System message + conversation history + latest user message + any injected tools/docs all count. So do “reasoning” or internal tokens if the API exposes them.

- **When you exceed it.** APIs may return an error, or the client/backend **truncates** (e.g. drop oldest messages or summarize them). “Running out of context” means part of the past is no longer visible to the model.

- **Real-time impact.** Larger context = more attention over more tokens = higher latency and cost. **Streaming** only changes how **output** is delivered (token by token); it does not change the context limit.

- **Typical sizes.** 4K, 8K, 32K, 128K, or 1M+ tokens depending on the model. Check docs for “max context” or “context length.”

**Takeaway:** The context window is the fixed cap on how much text (history + current input) the model can process in one go.

---

### 5. Streaming: How Output Appears in Real Time

- **What streaming is.** The model generates one token at a time. The API can send each token to the client as it’s ready instead of waiting for the full reply. The UI then shows text appearing incrementally.

- **Why it matters.** Users see progress immediately (lower perceived latency). The client can also **cancel** the request mid-stream and stop generation.

- **Same model, different delivery.** Streaming does not change how many tokens are generated or how the context window works; it only changes how and when bytes are sent to the client.

**Takeaway:** “Real time” in the UI usually means streaming: the model emits tokens one by one and the client displays them as they arrive.

---

### 6. Sampling and Temperature: Choosing the Next Token

The model outputs **scores** (logits) over the vocabulary. The next token is **sampled** from that distribution:

- **Temperature.** Low temperature (e.g. 0) → pick the highest-probability token (**greedy** / deterministic). High temperature (e.g. 1) → more randomness, more varied and sometimes creative output. Typical range: 0–1 or 0–2.

- **Other knobs.** APIs may expose **top_p** (nucleus sampling), **top_k**, and **stop sequences** to control when and how generation stops.

**Takeaway:** The “next token” is chosen by sampling from the model’s distribution. Temperature and related params control determinism vs variety.

---

### 7. Inference vs Training

- **Inference.** When you chat, you’re doing **inference**: running the model with fixed weights to produce output. No weights are updated. The model does not “learn” from your conversation.

- **Training.** Learning happens during **training** (on huge datasets, offline). What you get from an API is a **trained, frozen** model. Fine-tuning or continual learning are separate processes, not default chat behavior.

**Takeaway:** In normal chat you use a pre-trained model; it does not update from your messages.

---

### 8. Model Size and API Shape

- **Parameters.** “7B”, “70B” = billions of parameters (weights). Larger models generally have more capacity but need more compute and memory; they’re slower and often more expensive per token.

- **Request.** Typical API request: list of **messages** (system/user/assistant) + **parameters** (model, temperature, max_tokens, stream: true/false, etc.).

- **Response.** Either a single **content** string or a **stream** of chunks (e.g. SSE or similar). Response may also include usage (prompt tokens, completion tokens), finish reason, and tool calls if applicable.

**Takeaway:** You send messages + params; you get content or a stream and metadata. Model size affects capability, cost, and latency.

---

### 9. Limitations to Keep in Mind

- **No persistent memory.** Only what’s in the request (history + current message) is visible. For long-term memory you need your own storage and to inject summaries or selected past content into context.

- **Hallucinations.** The model can produce plausible-sounding but wrong or made-up content. Don’t trust critical facts without verification.

- **Context and cost.** Long contexts are expensive and can dilute focus. Truncation or summarization loses information. Design with context limits in mind.

- **Latency and rate limits.** Bigger context and longer replies mean more time and possible rate limits. Streaming improves perceived latency but doesn’t remove backend cost.

**Takeaway:** LLMs are powerful but stateless, can hallucinate, and are bounded by context and cost; agents need to handle these explicitly.

---

## Summary: Real-Time Flow

| Concept | Role |
|--------|------|
| **Tokenization** | Everything you send becomes a sequence of token IDs; token count drives cost and context. |
| **Transformers** | Process that sequence with embedding + attention + layers; output is one token at a time. |
| **Conversation history** | Sent by the client each request; the model “remembers” only what’s in that payload. |
| **Context window** | Hard limit on how many tokens (history + input) the model accepts per request. |
| **Streaming** | Tokens are sent to the client as they’re generated; improves perceived latency and allows cancellation. |
| **Sampling / temperature** | How the next token is chosen; controls determinism vs variety. |
| **Inference** | Frozen model; no learning during chat. |
| **Limitations** | No true memory, risk of hallucination, context and cost limits. |

In one sentence: **An LLM in a chat is a transformer that, on each request, reads the conversation history you send (up to the context window), and streams back a new reply token by token, with no persistent memory and no learning from the conversation.**

---

## Exam Tips

| Concept | Key Point |
|--------|-----------|
| **Tokens** | Input and output are tokenized; count = unit for context and billing. |
| **Transformers** | Embedding → attention over sequence → predict next token; autoregressive. |
| **History** | Client sends full (or truncated) message list each time; model is stateless. |
| **Context window** | Max input tokens per request; overflow → error or truncate/summarize. |
| **Streaming** | Output delivered token by token; same model, different delivery. |
| **Temperature** | Low = deterministic; high = more random. |
| **Inference** | Weights fixed; no learning during chat. |

---

## Practice

1. **Token counting:** Estimate tokens for a short conversation (e.g. 5 user + 5 assistant messages, ~50 words each). Compare to 8K vs 128K context.

2. **History:** If the client sends only the last 2 user messages, what happens to the model’s “memory” of earlier messages?

3. **Streaming:** When text appears word-by-word, is the model generating one token at a time or many? Why does that matter for cancellation?

4. **Temperature:** For a factual Q&A bot vs a creative story bot, would you typically use lower or higher temperature? Why?

5. **Limitations:** How would you implement “remember this for later” across many conversations without relying on the model’s context window alone?

---

## Next Topic

**Topic 2: Introduction to AI Agents** – what agents are, goals, tools, and loops. Then Topic 3 covers embeddings and Topic 7 prompt engineering.
