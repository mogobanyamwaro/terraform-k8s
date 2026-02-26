# Topic 8: Practice – Master Prompt Engineering

## What You'll Learn

- Apply system prompts, few-shot, and structure in real prompts
- Get predictable output format (e.g. JSON, list)
- Test and iterate on prompt changes
- Optional: use a prompt template with variables

---

## Steps

*(Follow the course lab.)*

### 1. System prompt

- Write a system prompt that defines role, tone, and constraints (e.g. “You are a travel assistant. Be concise. Always respond in under 50 words.”).
- Call the API and verify the model follows the instructions.

### 2. Few-shot and structure

- Add 1–2 example Q&A pairs to the prompt. Ask a new question and check that the response format matches the examples.
- Use clear delimiters (e.g. `Example 1:`, `---`) so the model can tell instructions from examples.

### 3. Output format

- Request a structured output (e.g. “Respond with a JSON object with keys: summary, keywords.”). Parse the response and validate that it’s valid JSON.
- If the model misbehaves, refine the prompt (more explicit instructions or another few-shot example).

---

## Practice

1. Break one of your prompts into “system” vs “user” and compare behavior.
2. Add a constraint (“Do not use the word X”) and test that the model obeys it.

---

## Next Topic

**Topic 9: Vector Databases Deep Dive** – indexing, similarity search, and scaling.
