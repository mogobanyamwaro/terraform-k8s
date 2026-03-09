/**
 * Email marketing sender: triggered by EventBridge when a CSV is uploaded to S3.
 * Reads the CSV, sends one email per row via SES.
 * CSV must have an "email" column; optional "name" for personalization.
 */

const { S3Client, GetObjectCommand } = require('@aws-sdk/client-s3');
const { SESClient, SendEmailCommand } = require('@aws-sdk/client-ses');
const { Readable } = require('stream');

const s3 = new S3Client({});
const ses = new SESClient({});

const BUCKET = process.env.BUCKET_NAME;
const FROM = process.env.FROM_EMAIL;
const REPLY_TO = process.env.REPLY_TO_EMAIL || process.env.FROM_EMAIL;

const DEFAULT_SUBJECT = 'Hello from our campaign';
const DEFAULT_BODY_TEXT = 'Thank you for being a subscriber.';

function parseCsv(buffer) {
  const text = buffer.toString('utf-8');
  const lines = text.split(/\r?\n/).filter((l) => l.trim());
  if (lines.length < 2) return [];
  const header = lines[0].split(',').map((h) => h.trim().toLowerCase());
  const emailIdx = header.indexOf('email');
  if (emailIdx === -1) throw new Error('CSV must have an "email" column');
  const nameIdx = header.indexOf('name');
  const rows = [];
  for (let i = 1; i < lines.length; i++) {
    const values = lines[i].split(',').map((v) => v.trim());
    const email = values[emailIdx];
    if (email) rows.push({ email, name: nameIdx >= 0 ? values[nameIdx] : '' });
  }
  return rows;
}

function streamToBuffer(stream) {
  return new Promise((resolve, reject) => {
    const chunks = [];
    stream.on('data', (chunk) => chunks.push(chunk));
    stream.on('error', reject);
    stream.on('end', () => resolve(Buffer.concat(chunks)));
  });
}

exports.handler = async (event) => {
  if (!BUCKET || !FROM) {
    console.error('BUCKET_NAME and FROM_EMAIL must be set');
    throw new Error('Missing env');
  }

  const bucket = event.detail?.bucket?.name || event.bucket?.name;
  const key = event.detail?.object?.key || event.object?.key;
  if (!bucket || !key) {
    console.error('No bucket/key in event', JSON.stringify(event));
    return { sent: 0, error: 'Missing bucket or key in event' };
  }

  try {
    const getCmd = new GetObjectCommand({ Bucket: bucket, Key: key });
    const response = await s3.send(getCmd);
    const body = response.Body;
    const buffer = body instanceof Readable
      ? await streamToBuffer(body)
      : Buffer.from(await body.transformToByteArray());
    const recipients = parseCsv(buffer);
    if (recipients.length === 0) {
      console.log('No valid rows in CSV');
      return { sent: 0 };
    }

    let sent = 0;
    for (const row of recipients) {
      const subject = DEFAULT_SUBJECT;
      const bodyText = row.name ? `Hi ${row.name},\n\n${DEFAULT_BODY_TEXT}` : DEFAULT_BODY_TEXT;
      try {
        await ses.send(
          new SendEmailCommand({
            Source: FROM,
            ReplyToAddresses: REPLY_TO ? [REPLY_TO] : undefined,
            Destination: { ToAddresses: [row.email] },
            Message: {
              Subject: { Data: subject, Charset: 'UTF-8' },
              Body: {
                Text: { Data: bodyText, Charset: 'UTF-8' },
              },
            },
          })
        );
        sent++;
      } catch (err) {
        console.error(`Failed to send to ${row.email}:`, err.message);
      }
    }

    console.log(`Sent ${sent}/${recipients.length} emails from s3://${bucket}/${key}`);
    return { sent, total: recipients.length };
  } catch (err) {
    console.error(err);
    throw err;
  }
};
