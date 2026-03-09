const { DynamoDBClient } = require('@aws-sdk/client-dynamodb');
const { DynamoDBDocumentClient, PutCommand, ScanCommand } = require('@aws-sdk/lib-dynamodb');

const client = new DynamoDBClient({});
const doc = DynamoDBDocumentClient.from(client);
const tableName = process.env.TABLE_NAME;

exports.handler = async (event) => {
  if (!tableName) {
    return response(500, { error: 'TABLE_NAME not set' });
  }

  const httpMethod = event.requestContext?.http?.method || event.httpMethod || 'GET';
  // API Gateway HTTP API includes stage in path (e.g. /default/add). Strip it so we match /add.
  const rawPath = event.rawPath || event.path || '/';
  const path = rawPath.replace(/^\/[^/]+/, '') || '/';

  const body = parseBody(event.body);

  try {
    // POST /add or POST / – add two numbers, save result to DB
    if (httpMethod === 'POST' && (path === '/add' || path === '/')) {
      const num1 = Number(body.num1);
      const num2 = Number(body.num2);
      if (Number.isNaN(num1) || Number.isNaN(num2)) {
        return response(400, { error: 'num1 and num2 must be numbers' });
      }
      const result = num1 + num2;
      const id = require('crypto').randomUUID();
      const item = {
        id,
        num1,
        num2,
        result,
        createdAt: new Date().toISOString(),
      };
      await doc.send(new PutCommand({ TableName: tableName, Item: item }));
      return response(201, item);
    }

    // GET /results – list all saved calculations (optional, for frontend history)
    if (httpMethod === 'GET' && (path === '/results' || path === '/')) {
      const data = await doc.send(new ScanCommand({ TableName: tableName }));
      return response(200, { items: data.Items || [] });
    }

    return response(404, { error: 'Not found', path, rawPath });
  } catch (err) {
    console.error(err);
    return response(500, { error: err.message || 'Internal error' });
  }
};

function parseBody(raw) {
  if (!raw) return {};
  if (typeof raw === 'string') {
    try {
      return JSON.parse(raw);
    } catch {
      return {};
    }
  }
  return raw;
}

function response(statusCode, body) {
  return {
    statusCode,
    headers: {
      'Content-Type': 'application/json',
      'Access-Control-Allow-Origin': '*',
    },
    body: JSON.stringify(body),
  };
}
