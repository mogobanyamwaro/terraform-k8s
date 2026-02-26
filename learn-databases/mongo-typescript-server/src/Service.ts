import mongoose from "mongoose";
import { User, Order, OrderItem, IUser, IOrder, IOrderItem } from "./Models";

export { User, Order, OrderItem, IUser, IOrder, IOrderItem };

/** Clears and seeds the DB with sample users, orders, and order items for learning aggregations/streams. */
export async function seedDatabase(): Promise<void> {
  console.log("Seeding database...");
  await OrderItem.deleteMany({});
  await Order.deleteMany({});
  await User.deleteMany({});

  const [alice, bob, carol] = await User.insertMany([
    { name: "Alice", email: "alice@example.com" },
    { name: "Bob", email: "bob@example.com" },
    { name: "Carol", email: "carol@example.com" },
  ]);

  const orders = await Order.insertMany([
    { userId: alice._id, total: 0, status: "paid" },
    { userId: alice._id, total: 0, status: "shipped" },
    { userId: bob._id, total: 0, status: "pending" },
    { userId: bob._id, total: 0, status: "cancelled" },
    { userId: carol._id, total: 0, status: "paid" },
  ]);

  const items = [
    { productName: "Widget", quantity: 2, unitPrice: 9.99 },
    { productName: "Gadget", quantity: 1, unitPrice: 24.5 },
    { productName: "Gizmo", quantity: 4, unitPrice: 5.0 },
    { productName: "Widget", quantity: 1, unitPrice: 9.99 },
    { productName: "Doohickey", quantity: 3, unitPrice: 12.0 },
  ];

  const orderItemsToInsert: Array<{
    orderId: unknown;
    productName: string;
    quantity: number;
    unitPrice: number;
  }> = [];
  const orderTotals: number[] = [];
  orders.forEach((order, orderIndex) => {
    const numItems = 1 + (orderIndex % 3);
    let orderTotal = 0;
    for (let i = 0; i < numItems; i++) {
      const item = items[(orderIndex + i) % items.length];
      orderTotal += item.quantity * item.unitPrice;
      orderItemsToInsert.push({
        orderId: order._id,
        productName: item.productName,
        quantity: item.quantity,
        unitPrice: item.unitPrice,
      });
    }
    orderTotals.push(Math.round(orderTotal * 100) / 100);
  });

  await Order.bulkWrite(
    orders.map((o, i) => ({
      updateOne: {
        filter: { _id: o._id },
        update: { $set: { total: orderTotals[i] } },
      },
    })),
  );
  await OrderItem.insertMany(orderItemsToInsert);
  console.log("Database seeded successfully");
}
export async function playground() {
  // aggregate match
  //   const result = await Order.aggregate([
  //     {
  //       $match: { status: "paid" },
  //     },
  //   ]);
  // group by user id
  //   const result = await Order.aggregate([
  //     {
  //       $group: { _id: "$userId", total: { $sum: "$total" } },
  //     },
  //   ]);
  // unwind order items
  //   const result = await Order.aggregate([
  //     {
  //       $unwind: { path: "$items", preserveNullAndEmptyArrays: true },
  //     },
  //   ]);
  // look up with example
  //   const result = await Order.aggregate([
  //     {
  //       $lookup: {
  //         from: "users",
  //         localField: "userId",
  //         foreignField: "_id",
  //         as: "user",
  //       },
  //     },
  //   ]);
  //   console.log(result);
  // transactions
}
