You raise an excellent point. Let me check the document carefully.

---

## What the Document Says

**Page 4 - Level 2:**

> "Spin up a PostgreSQL database using docker-compose.yml."

This means `docker-compose.yml` is specifically required for **Level 2**, not before.

---

## The Issue

If I add `docker-compose.yml` during "Project Setup" (Level 0/1), that would be **building Level 2 features before reaching Level 2**.

The document says (Page 2):

> "Do not skip levels. Work in order, even if you only finish Level 1."

But also (Page 2):

> "Do not add features we did not ask for in order to look impressive."

Adding `docker-compose.yml` in Level 1 is technically adding a Level 2 feature early.

---

## Revised Commit Sequence - Strictly Following Order

### Phase 1: Level 1 ONLY (No Docker, No Database)

| Step | When                                                              | Commit Message                                                          |
| ---- | ----------------------------------------------------------------- | ----------------------------------------------------------------------- |
| 1    | After creating repo                                               | `chore: initialize private GitHub repository`                           |
| 2    | After package.json (Express not yet needed, but TypeScript first) | `chore: add TypeScript configuration and dependencies`                  |
| 3    | After tsconfig.json                                               | `chore: configure strict TypeScript compiler options`                   |
| 4    | After .gitignore                                                  | `chore: add gitignore for node_modules and dist`                        |
| 5    | After NotificationEvent and DeliveryPreference interfaces         | `feat(level1): add NotificationEvent and DeliveryPreference interfaces` |
| 6    | After priorityScore function                                      | `feat(level1): implement pure priorityScore function`                   |
| 7    | After rankQueue function                                          | `feat(level1): implement pure rankQueue sorting function`               |
| 8    | After unit tests                                                  | `test(level1): add 8 unit tests for rankQueue`                          |
| 9    | After README.md (Level 1 only)                                    | `docs(level1): add README with setup and assumptions`                   |
| 10   | After DECISIONS.md (Level 1 only)                                 | `docs(level1): document non-obvious choices for Level 1`                |

**Level 1 Complete - Tag:**

```bash
git tag level-1-complete
```

---

### Phase 2: Level 2 - Now Add Docker and Database

| Step | When                                      | Commit Message                                                                         |
| ---- | ----------------------------------------- | -------------------------------------------------------------------------------------- |
| 11   | After docker-compose.yml                  | `feat(level2): add PostgreSQL docker-compose configuration`                            |
| 12   | After .env.example with DATABASE_URL      | `feat(level2): add environment configuration`                                          |
| 13   | After Drizzle schema                      | `feat(level2): define Drizzle schema for notification_events and delivery_preferences` |
| 14   | After db/index.ts with drizzle connection | `feat(level2): add database connection and drizzle client`                             |
| 15   | After seed script                         | `feat(level2): add seed script with 20 events and 5 preferences`                       |
| 16   | After Express setup with basic middleware | `feat(level2): initialize Express server with JSON middleware`                         |
| 17   | After POST /api/events with Zod           | `feat(level2): implement POST /api/events endpoint`                                    |
| 18   | After GET /api/events with filters        | `feat(level2): implement GET /api/events with channel and status filters`              |
| 19   | After POST /api/delivery/preview          | `feat(level2): implement POST /api/delivery/preview endpoint`                          |
| 20   | After error handling middleware           | `feat(level2): add global error handler with Zod validation`                           |
| 21   | After updating README for Level 2         | `docs(level2): document API endpoints and database setup`                              |

**Level 2 Complete - Tag:**

```bash
git tag level-2-complete
```

---

### Phase 3: Level 3 - Routing Engine

| Step | When                                           | Commit Message                                                            |
| ---- | ---------------------------------------------- | ------------------------------------------------------------------------- |
| 22   | After adding state timestamps to schema        | `feat(level3): add state timestamp columns to notification_events`        |
| 23   | After adding channelWeights to schema          | `feat(level3): add channel_weights column to delivery_preferences`        |
| 24   | After state machine functions                  | `feat(level3): implement state machine with transition validation`        |
| 25   | After DeliveryRouter class                     | `feat(level3): implement DeliveryRouter with weighted channel selection`  |
| 26   | After POST /api/delivery/weights               | `feat(level3): implement POST /api/delivery/weights endpoint`             |
| 27   | After POST /api/delivery/dispatch              | `feat(level3): implement POST /api/delivery/dispatch endpoint`            |
| 28   | After backward compatibility (default weights) | `feat(level3): add backward compatibility for recipients without weights` |
| 29   | After updating seed with default weights       | `feat(level3): update seed script with default weights`                   |
| 30   | After updating README and DECISIONS.md         | `docs(level3): document routing engine and state machine`                 |

**Level 3 Complete - Tag:**

```bash
git tag level-3-complete
```

---

### Phase 4: Level 4 - Observability and Webhooks

| Step | When                                              | Commit Message                                                    |
| ---- | ------------------------------------------------- | ----------------------------------------------------------------- |
| 31   | After webhooks table                              | `feat(level4): add webhooks table to schema`                      |
| 32   | After webhook_deliveries table                    | `feat(level4): add webhook_deliveries table for retry tracking`   |
| 33   | After webhook dispatcher with exponential backoff | `feat(level4): implement webhook dispatcher with 3 retry backoff` |
| 34   | After POST /api/webhooks                          | `feat(level4): implement POST /api/webhooks endpoint`             |
| 35   | After webhook trigger on status change            | `feat(level4): trigger webhooks on every event status change`     |
| 36   | After GET /api/analytics                          | `feat(level4): implement GET /api/analytics endpoint`             |
| 37   | After integration test                            | `test(level4): add integration test covering full lifecycle`      |
| 38   | After updating documentation                      | `docs(level4): document webhook system and analytics`             |

**Level 4 Complete - Tag:**

```bash
git tag level-4-complete
```

---

### Phase 5: Final Polish

| Step | When                                  | Commit Message                                        |
| ---- | ------------------------------------- | ----------------------------------------------------- |
| 39   | After verifying all tests pass        | `test: ensure all unit and integration tests pass`    |
| 40   | After final README review             | `docs: finalize README with complete setup guide`     |
| 41   | After final DECISIONS.md              | `docs: complete DECISIONS.md with all trade-offs`     |
| 42   | After verifying no secrets in history | `chore: verify .env.example and no secrets committed` |

**Final Commit:**

```bash
git tag final-submission
```

---

## Key Changes from Previous Version

| Previous (Wrong)                        | Revised (Correct)                                         |
| --------------------------------------- | --------------------------------------------------------- |
| Added docker-compose in "Project Setup" | Added docker-compose in Level 2 (first commit of Level 2) |
| Added .env.example early                | Added .env.example in Level 2                             |
| Added Express setup early               | Added Express setup in Level 2                            |
| 40 total commits                        | 42 total commits (cleaner separation)                     |

---

## Verification Checklist

| Level   | What's Included                                     | What's NOT Included              |
| ------- | --------------------------------------------------- | -------------------------------- |
| Level 1 | TypeScript, interfaces, pure functions, tests       | Docker, Express, Database, API   |
| Level 2 | Docker, PostgreSQL, Drizzle, Express, API endpoints | Weights, State machine, Webhooks |
| Level 3 | Weights, State machine, Dispatch                    | Webhooks, Analytics              |
| Level 4 | Webhooks, Analytics, Integration test               | -                                |

---

**This follows the document strictly. No feature appears before its level.**



Perfect question. The Loom walkthrough is **critical** - it's worth 5 points in the rubric and shows your communication skills. Here's a **4-minute script** that hits all the required points.

---

## Loom Walkthrough Script (4 Minutes)

### Timing Breakdown

| Section | Duration | Content |
|---------|----------|---------|
| Intro | 30 sec | What you built, quick demo |
| Level 1 | 30 sec | Types, pure functions, tests |
| Level 2 | 45 sec | API endpoints, database, seed |
| Level 3 | 60 sec | Routing engine, state machine, weights (the tricky part) |
| One tricky decision | 45 sec | Explain a hard choice you made |
| What you'd change | 30 sec | Honest reflection |
| Outro | 30 sec | Summary, invite questions |

---

## Full Script

### Intro (0:00 - 0:30)

> "Hi, I'm [your name]. This is my submission for the Simple Lend technical assessment.
>
> I built a multi-channel notification engine that sends alerts through email, SMS, or webhooks. Each recipient can set their own channel preferences with weights that sum to 100.
>
> Let me show you it working."

**[Show terminal with server running]**

> "Server is running on port 3000, PostgreSQL is up in Docker. Let me demonstrate."

---

### Demo - Create an Event (0:30 - 1:00)

> "First, let's create a notification event."

**[Run curl command in terminal]**

```bash
curl -X POST http://localhost:3000/api/events \
  -H "Content-Type: application/json" \
  -d '{"channel":"email","payload":{"message":"Test"},"recipientId":"user1","priority":"high"}'
```

> "You can see it returns the event with status 'queued' and an auto-generated ID."

**[Show response]**

> "Now let's list events sorted by urgency."

```bash
curl http://localhost:3000/api/events
```

> "They're sorted by priorityScore - critical events first, then older events get age bonus points."

---

### Demo - Routing Engine (1:00 - 1:45)

> "Level 3 is where it gets interesting. Let me update a recipient's channel weights."

```bash
curl -X POST http://localhost:3000/api/delivery/weights \
  -H "Content-Type: application/json" \
  -d '{"recipientId":"user1","weights":{"email":40,"sms":50,"webhook":10}}'
```

> "The system validates that weights sum to exactly 100. Now let's dispatch this event through the state machine."

```bash
curl -X POST http://localhost:3000/api/delivery/dispatch \
  -H "Content-Type: application/json" \
  -d '{"eventId":"<event-id>"}'
```

> "First dispatch moves it from queued to processing. The DeliveryRouter randomly selects a channel based on the recipient's weights - like spinning a weighted wheel."

**[Run second dispatch]**

> "Second dispatch simulates delivery with 80% success rate. If it fails, it goes into retrying state up to 3 times with exponential backoff."

---

### Tricky Decision (1:45 - 2:30)

> "The trickiest decision I made was around the priorityScore function.

> The spec says it should be a pure function that returns a score based on priority and age. But 'age' depends on current time, which would normally make it impure.

> I solved this by injecting the current time as a parameter:

```typescript
priorityScore(event: NotificationEvent, currentTime: Date): number
```

> This keeps the function pure and testable. In the API layer, I call it with `new Date()`.

> Another tricky part was the state machine. I created a explicit validTransitions map:

```typescript
const validTransitions = {
  queued: ['processing'],
  processing: ['delivered', 'failed'],
  failed: ['retrying'],
  retrying: ['delivered', 'failed'],
};
```

> Any illegal transition throws a descriptive error. This prevents silent failures."

---

### What You'd Change (2:30 - 3:00)

> "If I had more time, I'd change three things:

> First, I'd move the priorityScore sorting from memory to the database. Right now for GET /events, I fetch all events then sort in JavaScript. For production with millions of events, that won't scale.

> Second, I'd implement proper quiet hours. The spec only requires representing them, not implementing. But in a real bank system, customers expect alerts to respect their sleep schedule.

> Third, I'd add idempotency keys for webhooks to prevent duplicate processing when retries happen."

---

### Outro (3:00 - 4:00)

> "Let me quickly show the analytics endpoint and webhook system."

```bash
curl http://localhost:3000/api/analytics
```

> "This returns delivery rates by channel, average processing times, and retry success rates - all computed from real data.

> For webhooks, whenever an event changes status, it POSTs to all registered webhook URLs with up to 3 retries and exponential backoff.

> The repo has a README with setup instructions that take under 5 minutes. All tests pass with `npm test`.

> I've also included a DECISIONS.md file explaining every non-obvious choice.

> Thanks for your time - I'm happy to discuss any part of the code in more detail."

**[End video]**

---

## What to Show on Screen

| Timestamp | Show This |
|-----------|-----------|
| 0:00-0:30 | Terminal with `npm start` running |
| 0:30-1:00 | Terminal with curl commands and responses |
| 1:00-1:45 | Terminal with weights and dispatch commands |
| 1:45-2:30 | Code editor - show priorityScore or validTransitions |
| 2:30-3:00 | Code editor - show where you'd make changes |
| 3:00-4:00 | Terminal with analytics curl, then README.md |

---

## Checklist Before Recording

- [ ] Server running (`npm start`)
- [ ] Database running (`docker-compose up -d`)
- [ ] Terminal ready with curl commands copy-pasted
- [ ] Code editor open to the files you'll reference
- [ ] README.md open
- [ ] No private info visible (API keys, etc.)
- [ ] Video kept under 4 minutes (practice once)

---

## Example Curl Commands to Have Ready

```bash
# Create event
curl -X POST http://localhost:3000/api/events -H "Content-Type: application/json" -d '{"channel":"email","payload":{"message":"Test"},"recipientId":"user1","priority":"high"}'

# List events
curl http://localhost:3000/api/events

# Update weights
curl -X POST http://localhost:3000/api/delivery/weights -H "Content-Type: application/json" -d '{"recipientId":"user1","weights":{"email":40,"sms":50,"webhook":10}}'

# Dispatch
curl -X POST http://localhost:3000/api/delivery/dispatch -H "Content-Type: application/json" -d '{"eventId":"<paste-id>"}'

# Analytics
curl http://localhost:3000/api/analytics

# Register webhook
curl -X POST http://localhost:3000/api/webhooks -H "Content-Type: application/json" -d '{"url":"https://webhook.site/test"}'
```

---

## Pro Tips

1. **Practice once** before recording - timing is tight
2. **Speak clearly** - they're evaluating communication
3. **Don't read the script** - use bullet points and talk naturally
4. **If you make a mistake**, pause and restart that section (you can edit)
5. **End with "I'm happy to discuss this further"** - shows openness

---

**Would you like me to condense this further or add anything specific about Level 4?**