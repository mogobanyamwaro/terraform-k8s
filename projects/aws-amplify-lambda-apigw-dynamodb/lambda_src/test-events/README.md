# Lambda test events (for AWS Console)

Use these in the Lambda console **Test** tab: create or edit a test event and paste the JSON.

- **POST /add** – simulates adding two numbers (saves to DynamoDB)
- **GET /results** – simulates listing all saved results

In the Test tab: choose the event from the dropdown and click **Test**. There is no separate “route” or “method” control; the method and path are inside the event JSON (`requestContext.http.method` and `rawPath`).
