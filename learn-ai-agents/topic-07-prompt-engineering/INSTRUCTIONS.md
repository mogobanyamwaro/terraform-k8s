# Topic 7: Prompt Engineering Techniques

## What You'll Learn

- **System prompts** – role, constraints, and tone
- **Few-shot** – examples in the prompt to steer format and behavior
- **Structure** – clear instructions, sections, and delimiters
- **Constraints** – length, format (JSON, list), language, and guardrails
- How this shapes model behavior for agent-style tasks

---

## Steps

*(Content to be filled as you follow the course.)*

### 1. System vs user messages

- **System** message sets the assistant’s role, rules, and style. It’s the main lever for “how” the model behaves.
- **User** message is the current request. Keep system for instructions; user for task and context.

### 2. Techniques

- **Few-shot** – include 1–3 example input/output pairs so the model mimics format and reasoning.
- **Structure** – use headings, bullet points, and delimiters (e.g. `---`, XML tags) so the model parses intent clearly.
- **Constraints** – “Respond in one paragraph”, “Output valid JSON only”, “Use Spanish”, “Do not mention X”.

### 3. For agents

- Prompts often specify **when** to call tools, **how** to format tool input, and **how** to summarize tool results for the next step. Clear prompts reduce tool-calling errors.

---

## Practice

1. Write a system prompt that makes the model always respond in exactly three bullet points.
2. Add one few-shot example that shows the model how to turn a user question into a search query.

---

## Next Topic

**Topic 8: Practice – Master Prompt Engineering** – lab: apply these techniques.
