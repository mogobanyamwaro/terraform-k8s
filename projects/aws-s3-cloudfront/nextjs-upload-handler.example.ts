/**
 * S3 + CloudFront upload API for Next.js (pages router).
 * Use CloudFront URL for fileUrl so images don’t 403 (bucket is private).
 */

import S3 from "aws-sdk/clients/s3";
import { v4 as uuidv4 } from "uuid";
import { v2 as cloudinary } from "cloudinary";
import multer from "multer";

export const s3 = new S3({
  credentials: {
    accessKeyId: process.env.NEXT_AWS_ACCESS_KEY_ID || "",
    secretAccessKey: process.env.NEXT_AWS_SECRET_ACCESS_KEY || "",
  },
  region: process.env.NEXT_AWS_REGION || "eu-central-1",
  httpOptions: { timeout: 15_000, connectTimeout: 10_000 },
  maxRetries: 2,
});

const upload = multer({
  storage: multer.memoryStorage(),
  limits: {
    fileSize: 10 * 1024 * 1024, // 10MB
  },
});

export const config = {
  api: {
    bodyParser: false,
  },
};

cloudinary.config({
  cloud_name: "dqvdojdwi",
  api_key: "311599656359266",
  api_secret: "YVBcCQlGzuwE11Lj1ir1bxIRl1k",
});

export default async function fileUploadHandler(req: any, res: any) {
  if (req.method !== "POST") {
    return res.status(405).json({ message: "Method not allowed" });
  }

  const folder = "homecare/";

  upload.single("file")(req, res, async function (err) {
    if (err) {
      res.status(400).json({ error: err.message });
      return;
    }

    const file = req.file;
    if (!file?.buffer) {
      res.status(400).json({ error: "No file uploaded" });
      return;
    }

    const bucket = process.env.NEXT_AWS_S3_BUCKET_NAME;
    if (!bucket) {
      res.status(500).json({ error: "S3 bucket not configured" });
      return;
    }

    const cloudfrontBase = process.env.NEXT_CLOUDFRONT_URL;
    if (!cloudfrontBase?.trim()) {
      res.status(500).json({
        error:
          "NEXT_CLOUDFRONT_URL not set. Set it to your CloudFront URL so images work.",
      });
      return;
    }

    try {
      const key = `${folder}${uuidv4()}-${file.originalname || "file"}`;

      await s3
        .upload({
          Bucket: bucket,
          Key: key,
          ContentType: file.mimetype,
          Body: file.buffer,
        })
        .promise();

      const fileUrl = `${cloudfrontBase.replace(/\/$/, "")}/${key}`;

      res.status(200).json({
        filename: key,
        fileKey: key,
        fileUrl,
      });
      return;
    } catch (error: any) {
      console.error("S3 upload error:", error);
      const message =
        error?.code === "TimeoutError" || error?.code === "ETIMEDOUT"
          ? "Upload timed out. Check network and AWS."
          : error?.message || "Upload failed";
      res.status(502).json({ error: message });
      return;
    }
  });
}
