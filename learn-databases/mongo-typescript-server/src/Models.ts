import mongoose, { Schema, Document, Model } from "mongoose";

// ---- 1. User (top of the chain: one user has many orders) ----
export interface IUser extends Document {
  _id: mongoose.Types.ObjectId;
  name: string;
  email: string;
  createdAt: Date;
}
// ---- 2. Order (belongs to User; one order has many items) ----
export interface IOrder extends Document {
  _id: mongoose.Types.ObjectId;
  userId: mongoose.Types.ObjectId;
  total: number;
  status: "pending" | "paid" | "shipped" | "cancelled";
  createdAt: Date;
}
// ---- 3. OrderItem (belongs to Order; line items with product + quantity + price) ----
export interface IOrderItem extends Document {
  _id: mongoose.Types.ObjectId;
  orderId: mongoose.Types.ObjectId;
  productName: string;
  quantity: number;
  unitPrice: number;
  createdAt: Date;
}

const userSchema = new Schema<IUser>(
  {
    name: { type: String, required: true },
    email: { type: String, required: true, unique: true },
  },
  { timestamps: true },
);

export const User: Model<IUser> =
  mongoose.models.User ?? mongoose.model<IUser>("User", userSchema);

const orderSchema = new Schema<IOrder>(
  {
    userId: { type: Schema.Types.ObjectId, ref: "User", required: true },
    total: { type: Number, required: true, default: 0 },
    status: {
      type: String,
      enum: ["pending", "paid", "shipped", "cancelled"],
      default: "pending",
    },
  },
  { timestamps: true },
);
orderSchema.index({ userId: 1 });
orderSchema.index({ status: 1, createdAt: -1 });

export const Order: Model<IOrder> =
  mongoose.models.Order ?? mongoose.model<IOrder>("Order", orderSchema);

const orderItemSchema = new Schema<IOrderItem>(
  {
    orderId: { type: Schema.Types.ObjectId, ref: "Order", required: true },
    productName: { type: String, required: true },
    quantity: { type: Number, required: true, min: 1 },
    unitPrice: { type: Number, required: true, min: 0 },
  },
  { timestamps: true },
);
orderItemSchema.index({ orderId: 1 });
orderItemSchema.index({ productName: 1 });

export const OrderItem: Model<IOrderItem> =
  mongoose.models.OrderItem ??
  mongoose.model<IOrderItem>("OrderItem", orderItemSchema);
