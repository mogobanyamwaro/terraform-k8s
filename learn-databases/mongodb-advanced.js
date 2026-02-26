// ============================================
// MONGODB ADVANCED - Senior / Interview Topics
// ============================================
// Prerequisite: Run mongodb-basics.js first (practice_db + sample data).
// Use: mongosh < mongodb-advanced.js  or paste sections in mongosh.

use practice_db;

// Optional: add numeric customer_id to customers for $lookup examples (run once)
// const cursor = db.customers.find().sort({ _id: 1 });
// let i = 1; cursor.forEach(c => { db.customers.updateOne({ _id: c._id }, { $set: { customer_id: i++ } }); });


// ============================================
// 1. TRANSACTIONS (multi-document ACID)
// ============================================
// Requires replica set or sharded cluster. Single standalone cannot run transactions.

function runTransactionExample() {
  const session = db.getMongo().startSession();
  try {
    session.startTransaction({ readConcern: { level: "snapshot" }, writeConcern: { w: "majority" } });
    // Operations in same session
    db.orders.insertOne(
      { customer_id: 1, order_date: new Date(), total_amount: 99.99, status: "pending", items: [] },
      { session }
    );
    db.products.updateOne(
      { name: "Laptop" },
      { $inc: { stock_quantity: -1 } },
      { session }
    );
    session.commitTransaction();
  } catch (e) {
    session.abortTransaction();
    throw e;
  } finally {
    session.endSession();
  }
}
// runTransactionExample();  // run only with replica set

// withTransaction helper (retries on transient errors)
async function withTransactionExample() {
  const client = db.getMongo();
  await client.withSession(async (session) => {
    await session.withTransaction(async () => {
      await db.orders.insertOne(
        { customer_id: 2, order_date: new Date(), total_amount: 49.99, status: "pending", items: [] },
        { session }
      );
      await db.products.updateOne(
        { name: "Headphones" },
        { $inc: { stock_quantity: -1 } },
        { session }
      );
    });
  });
}


// ============================================
// 2. CHANGE STREAMS (real-time change notifications)
// ============================================
// Requires replica set. Stream of change events: insert, update, replace, delete.

// ---- Watch a single collection ----
function watchOrders() {
  const cs = db.orders.watch([], { fullDocument: "updateLookup" });
  while (true) {
    if (cs.hasNext()) {
      const change = cs.next();
      printjson(change);  // { operationType: "insert"|"update"|"replace"|"delete", fullDocument, ns, documentKey, ... }
    }
  }
}
// watchOrders();

// ---- Watch entire database (all collections) ----
// const dbStream = db.watch([], { fullDocument: "updateLookup" });
// while (dbStream.hasNext()) { const e = dbStream.next(); printjson(e); }

// ---- Filter stream with aggregation pipeline ----
// Only inserts: db.orders.watch([{ $match: { operationType: "insert" } }]);
// Only updates to status: db.orders.watch([{ $match: { "updateDescription.updatedFields.status": { $exists: true } } }]);

// ---- Resume after restart (resume token) ----
// const token = change._id;  // save from last event
// db.orders.watch([], { startAfter: token });

// ---- Change event shape ----
// insert: fullDocument, documentKey. update: updateDescription.{updatedFields, removedFields}, fullDocument if updateLookup. delete: documentKey only.


// ============================================
// 3. ADVANCED AGGREGATION - $lookup (join)
// ============================================

// $lookup: orders with customer info (if customers have customer_id field)
db.orders.aggregate([
  {
    $lookup: {
      from: "customers",
      localField: "customer_id",
      foreignField: "customer_id",
      as: "customer"
    }
  },
  { $unwind: { path: "$customer", preserveNullAndEmptyArrays: true } },
  { $project: { order_date: 1, total_amount: 1, status: 1, "customer.first_name": 1, "customer.last_name": 1, "customer.city": 1 } }
]);

// $lookup with pipeline (flexible join + filter in subpipeline)
db.orders.aggregate([
  {
    $lookup: {
      from: "customers",
      let: { cid: "$customer_id" },
      pipeline: [
        { $match: { $expr: { $eq: ["$customer_id", "$$cid"] } } },
        { $project: { first_name: 1, last_name: 1, city: 1, _id: 0 } }
      ],
      as: "customer"
    }
  },
  { $unwind: "$customer" }
]);


// ============================================
// 4. ADVANCED AGGREGATION - $group, $addFields, $cond
// ============================================

// Department stats: count, avg salary, total, max
db.employees.aggregate([
  { $match: { salary: { $exists: true, $ne: null } } },
  {
    $group: {
      _id: "$dept_name",
      count: { $sum: 1 },
      avg_salary: { $avg: "$salary" },
      total_salary: { $sum: "$salary" },
      max_salary: { $max: "$salary" },
      min_salary: { $min: "$salary" }
    }
  },
  { $sort: { total_salary: -1 } }
]);

// $addFields / $set: computed fields
db.employees.aggregate([
  {
    $addFields: {
      full_name: { $concat: ["$first_name", " ", "$last_name"] },
      salary_band: {
        $switch: {
          branches: [
            { case: { $gte: ["$salary", 90000] }, then: "High" },
            { case: { $gte: ["$salary", 60000] }, then: "Mid" },
            { case: { $gt: ["$salary", null] }, then: "Low" }
          ],
          default: "Unknown"
        }
      }
    }
  },
  { $project: { full_name: 1, salary: 1, salary_band: 1, _id: 0 } }
]);


// ============================================
// 5. $facet (multiple pipelines in one stage)
// ============================================
// Run several aggregations in parallel over the same input (interview favorite).

db.orders.aggregate([
  {
    $facet: {
      by_status: [
        { $group: { _id: "$status", count: { $sum: 1 }, total: { $sum: "$total_amount" } } },
        { $sort: { total: -1 } }
      ],
      by_month: [
        {
          $group: {
            _id: { $dateToString: { format: "%Y-%m", date: "$order_date" } },
            count: { $sum: 1 },
            revenue: { $sum: "$total_amount" }
          }
        },
        { $sort: { _id: 1 } }
      ],
      top_5_orders: [
        { $sort: { total_amount: -1 } },
        { $limit: 5 },
        { $project: { order_date: 1, total_amount: 1, status: 1, customer_id: 1 } }
      ]
    }
  }
]);


// ============================================
// 6. $bucket and $bucketAuto (histograms)
// ============================================

// Salary buckets (ranges)
db.employees.aggregate([
  { $match: { salary: { $ne: null } } },
  {
    $bucket: {
      groupBy: "$salary",
      boundaries: [0, 60000, 80000, 100000, 150000],
      default: "Other",
      output: { count: { $sum: 1 }, names: { $push: "$first_name" } }
    }
  }
]);

// Auto buckets (MongoDB chooses boundaries)
db.employees.aggregate([
  { $match: { salary: { $ne: null } } },
  { $bucketAuto: { groupBy: "$salary", buckets: 4, output: { count: { $sum: 1 } } } }
]);


// ============================================
// 7. $graphLookup (recursive / tree traversal)
// ============================================
// Hierarchy: employees and their managers (connectBy manager_id -> emp_id).
// Our data uses manager_id as number; we need a key to match. Use _id if you store ObjectId refs.
// Example with string key (assume we had emp_code): connectBy: "manager_code", startWith: "$manager_code".

// Simplified: list each employee and "level" if we had self-referential _id
db.employees.aggregate([
  {
    $graphLookup: {
      from: "employees",
      startWith: "$manager_id",
      connectFromField: "manager_id",
      connectToField: "emp_id",   // if we had emp_id field; we don't in basics - use for reference
      as: "manager_chain",
      maxDepth: 2,
      restrictSearchWithMatch: {}
    }
  }
]);
// Note: basics schema uses manager_id as number (1,2,4...) but no emp_id. Add emp_id to employees for full demo, or use _id.


// ============================================
// 8. $merge and $out (write from aggregation)
// ============================================

// $out: replace collection with aggregation result
db.employees.aggregate([
  { $match: { salary: { $gt: 60000 } } },
  { $group: { _id: "$dept_name", avg_salary: { $avg: "$salary" }, count: { $sum: 1 } } },
  { $out: "dept_stats" }
]);
// db.dept_stats.find();

// $merge: upsert into target collection (MongoDB 4.2+)
db.employees.aggregate([
  { $group: { _id: "$dept_name", avg_salary: { $avg: "$salary" }, count: { $sum: 1 } } },
  {
    $merge: {
      into: "dept_stats",
      on: "_id",
      whenMatched: "merge",
      whenNotMatched: "insert"
    }
  }
]);


// ============================================
// 9. ARRAY OPERATORS: $filter, $map, $reduce
// ============================================

// $filter: items in order where quantity > 1
db.orders.aggregate([
  {
    $addFields: {
      multi_qty_items: {
        $filter: {
          input: "$items",
          as: "item",
          cond: { $gt: ["$$item.quantity", 1] }
        }
      }
    }
  },
  { $project: { order_date: 1, total_amount: 1, multi_qty_items: 1 } }
]);

// $map: transform array (e.g. add line total)
db.orders.aggregate([
  {
    $addFields: {
      items_with_total: {
        $map: {
          input: "$items",
          as: "item",
          in: {
            product_name: "$$item.product_name",
            quantity: "$$item.quantity",
            unit_price: "$$item.unit_price",
            line_total: { $multiply: ["$$item.quantity", "$$item.unit_price"] }
          }
        }
      }
    }
  },
  { $project: { order_date: 1, items_with_total: 1 } }
]);

// $reduce: single value from array (e.g. total item count per order)
db.orders.aggregate([
  {
    $addFields: {
      total_items: {
        $reduce: {
          input: "$items",
          initialValue: 0,
          in: { $add: ["$$value", "$$this.quantity"] }
        }
      }
    }
  },
  { $project: { order_date: 1, total_amount: 1, total_items: 1 } }
]);


// ============================================
// 10. $expr (compare fields, use expressions in $match)
// ============================================

// Orders where total_amount > 500
db.orders.find({ $expr: { $gt: ["$total_amount", 500] } });

// Employees where salary > 70000 and hire year is 2020+
db.employees.find({
  $expr: {
    $and: [
      { $gt: ["$salary", 70000] },
      { $gte: [{ $year: "$hire_date" }, 2020] }
    ]
  }
});


// ============================================
// 11. findAndModify / findOneAndUpdate (atomic)
// ============================================
// Atomic read + update; good for queues, counters, "take one".

// Increment stock and return updated document
db.products.findOneAndUpdate(
  { name: "Laptop" },
  { $inc: { stock_quantity: 1 } },
  { returnDocument: "after" }
);

// Take one "pending" order (queue pattern) - process and set status
db.orders.findOneAndUpdate(
  { status: "pending" },
  { $set: { status: "processing", processed_at: new Date() } },
  { sort: { order_date: 1 }, returnDocument: "after" }
);

// findOneAndReplace, findOneAndDelete
// db.products.findOneAndDelete({ name: "Obsolete Product" });


// ============================================
// 12. UPSERT (insert if not found)
// ============================================

db.products.updateOne(
  { name: "Wireless Mouse" },
  {
    $setOnInsert: { name: "Wireless Mouse", category: "Electronics", price: 39.99, stock_quantity: 100 },
    $set: { updated_at: new Date() }
  },
  { upsert: true }
);


// ============================================
// 13. BULK WRITE (batch operations)
// ============================================

const bulkOps = [
  { updateOne: { filter: { name: "Laptop" }, update: { $inc: { stock_quantity: -1 } } },
  { updateOne: { filter: { name: "Headphones" }, update: { $inc: { stock_quantity: 2 } } },
  { insertOne: { document: { name: "USB Cable", category: "Electronics", price: 9.99, stock_quantity: 500 } } }
];
db.products.bulkWrite(bulkOps, { ordered: false });  // ordered: false = continue on error


// ============================================
// 14. READ CONCERN & WRITE CONCERN
// ============================================

// Read concern: how fresh/consistent the read is
// db.orders.find().readConcern("local");       // default
// db.orders.find().readConcern("majority");    // read committed to majority
// db.orders.find().readConcern("snapshot");    // snapshot (replica set)

// Write concern: how many nodes must acknowledge
// db.orders.insertOne({ ... }, { writeConcern: { w: 1 } });        // default: primary only
// db.orders.insertOne({ ... }, { writeConcern: { w: "majority" } });
// db.orders.insertOne({ ... }, { writeConcern: { w: 2 } });         // 2 nodes
// db.orders.insertOne({ ... }, { writeConcern: { w: 1, j: true } }); // journal


// ============================================
// 15. INDEXES: Compound, Partial, Text, TTL
// ============================================

// Compound (order matters for sort and range)
db.orders.createIndex({ customer_id: 1, order_date: -1 });
db.employees.createIndex({ dept_name: 1, salary: -1 });

// Partial index (only index documents matching condition)
db.orders.createIndex(
  { customer_id: 1, order_date: -1 },
  { partialFilterExpression: { status: "pending" } }
);

// Text index (full-text search)
db.products.createIndex({ name: "text", category: "text" });
db.products.find({ $text: { $search: "laptop book" } });
db.products.find({ $text: { $search: "laptop", $caseSensitive: false } });

// TTL index (auto-delete after expiry)
// db.sessions.createIndex({ createdAt: 1 }, { expireAfterSeconds: 3600 });


// ============================================
// 16. AGGREGATION: $setWindowFields (MongoDB 5.0+)
// ============================================
// Running total, rank, moving average in one pass.

db.orders.aggregate([
  { $sort: { order_date: 1 } },
  {
    $setWindowFields: {
      partitionBy: null,
      sortBy: { order_date: 1 },
      output: {
        running_total: { $sum: "$total_amount", window: { documents: ["unbounded", "current"] } },
        order_rank: { $rank: {} }
      }
    }
  }
]);


// ============================================
// 17. NTH DOCUMENT (e.g. second highest salary)
// ============================================

// Second highest salary using $sort + $skip + $limit in aggregation
db.employees.aggregate([
  { $match: { salary: { $ne: null } } },
  { $sort: { salary: -1 } },
  { $skip: 1 },
  { $limit: 1 },
  { $project: { first_name: 1, last_name: 1, salary: 1, _id: 0 } }
]);

// Top N per group (e.g. top 2 earners per department)
db.employees.aggregate([
  { $sort: { dept_name: 1, salary: -1 } },
  {
    $group: {
      _id: "$dept_name",
      employees: { $push: { name: { $concat: ["$first_name", " ", "$last_name"] }, salary: "$salary" } }
    }
  },
  { $addFields: { top2: { $slice: ["$employees", 2] } } },
  { $project: { _id: 1, top2: 1 } }
]);


// ============================================
// 18. PAGINATION: skip/limit vs keyset (cursor)
// ============================================

// Offset-based (slow on large skip)
db.orders.find().sort({ order_date: -1 }).skip(10).limit(5);

// Keyset / cursor-based (efficient)
const lastDate = new Date("2024-02-15");
const lastId = ObjectId("...");  // last _id from previous page
db.orders.find({
  $or: [
    { order_date: { $lt: lastDate } },
    { order_date: lastDate, _id: { $lt: lastId } }
  ]
}).sort({ order_date: -1, _id: -1 }).limit(5);


// ============================================
// 19. COLLATION (string comparison rules)
// ============================================

// Case-insensitive sort or match
db.customers.find({ city: "scranton" }).collation({ locale: "en", strength: 2 });
db.customers.find().sort({ first_name: 1 }).collation({ locale: "en", strength: 1 });


// ============================================
// 20. $regex with aggregation $match
// ============================================

db.employees.aggregate([
  { $match: { email: { $regex: /company\.com$/ } } },
  { $project: { first_name: 1, last_name: 1, email: 1 } }
]);


// ============================================
// 21. COUNT with aggregation
// ============================================

db.orders.aggregate([
  { $match: { status: "completed" } },
  { $count: "completed_orders" }
]);


// ============================================
// 22. $unwind + $group (flatten then re-aggregate)
// ============================================

// Total quantity sold per product (from orders.items)
db.orders.aggregate([
  { $unwind: "$items" },
  {
    $group: {
      _id: "$items.product_name",
      total_qty: { $sum: "$items.quantity" },
      revenue: { $sum: { $multiply: ["$items.quantity", "$items.unit_price"] } }
    }
  },
  { $sort: { revenue: -1 } }
]);


// ============================================
// 23. $sortByCount (shorthand for $group + $sort)
// ============================================

db.orders.aggregate([{ $sortByCount: "$status" }]);


// ============================================
// 24. $replaceRoot / $replaceWith
// ============================================

db.orders.aggregate([
  { $unwind: "$items" },
  { $replaceRoot: { newRoot: "$items" } },
  { $limit: 3 }
]);


// ============================================
// 25. explain("executionStats") for query tuning
// ============================================

db.orders.find({ customer_id: 1, status: "completed" }).explain("executionStats");
db.orders.aggregate([{ $match: { customer_id: 1 } }]).explain("executionStats");


// ============================================
// QUICK REFERENCE (Interview)
// ============================================
// Transactions: startSession, withTransaction, readConcern, writeConcern
// Change streams: watch(), operationType, fullDocument, startAfter
// $lookup: localField/foreignField or pipeline
// $facet: multiple pipelines in one
// $bucket / $bucketAuto: histograms
// $graphLookup: recursive/tree
// $merge / $out: write from aggregation
// $filter, $map, $reduce: array ops
// $expr: expressions in find/aggregate
// findOneAndUpdate: atomic read-modify-write
// upsert: true, $setOnInsert
// bulkWrite: ordered / unordered
// Read/Write concern: local, majority, w, j
// Indexes: compound, partial, text, TTL
// $setWindowFields: rank, running sum
// Nth doc: $sort + $skip + $limit
// Keyset pagination: $lt(lastDate, lastId)
// Collation: locale, strength

print("MongoDB advanced script loaded. Run sections in mongosh (transactions/change streams need replica set).");
