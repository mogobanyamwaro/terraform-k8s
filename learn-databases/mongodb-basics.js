// ============================================
// MONGODB BASICS - Run with: mongosh < mongodb-basics.js
// Or paste sections into mongosh. Uses database: practice_db
// ============================================

// ---------------------------------------------------------------------------
// 1. DATABASE & COLLECTIONS
// ---------------------------------------------------------------------------

use practice_db;

// List all databases
// show dbs

// Create collection implicitly by inserting, or explicitly:
// db.createCollection("employees");

// Drop collections for clean run (optional)
db.departments.drop();
db.employees.drop();
db.customers.drop();
db.categories.drop();
db.products.drop();
db.orders.drop();


// ---------------------------------------------------------------------------
// 2. INSERT DOCUMENTS
// ---------------------------------------------------------------------------

// insertOne - returns { acknowledged: true, insertedId: ObjectId("...") }
db.departments.insertOne({
  name: "Engineering",
  location: "New York"
});

// insertMany - insert multiple at once
db.departments.insertMany([
  { name: "Marketing", location: "Los Angeles" },
  { name: "Sales", location: "Chicago" },
  { name: "HR", location: "New York" },
  { name: "Finance", location: "Boston" }
]);

// Insert employees (reference department by name for simplicity; in production often ObjectId)
db.employees.insertMany([
  { first_name: "John", last_name: "Smith", email: "john.smith@company.com", hire_date: new Date("2020-01-15"), salary: 75000, manager_id: null, dept_name: "Engineering" },
  { first_name: "Jane", last_name: "Doe", email: "jane.doe@company.com", hire_date: new Date("2019-03-20"), salary: 85000, manager_id: 1, dept_name: "Engineering" },
  { first_name: "Bob", last_name: "Johnson", email: "bob.johnson@company.com", hire_date: new Date("2021-06-01"), salary: 65000, manager_id: 1, dept_name: "Engineering" },
  { first_name: "Alice", last_name: "Williams", email: "alice.williams@company.com", hire_date: new Date("2018-09-10"), salary: 95000, manager_id: null, dept_name: "Marketing" },
  { first_name: "Charlie", last_name: "Brown", email: "charlie.brown@company.com", hire_date: new Date("2022-02-14"), salary: 55000, manager_id: 2, dept_name: "Marketing" },
  { first_name: "Diana", last_name: "Davis", email: "diana.davis@company.com", hire_date: new Date("2020-11-30"), salary: 72000, manager_id: 2, dept_name: "Sales" },
  { first_name: "Eve", last_name: "Miller", email: "eve.miller@company.com", hire_date: new Date("2019-07-22"), salary: 68000, manager_id: null, dept_name: "HR" },
  { first_name: "Frank", last_name: "Wilson", email: "frank.wilson@company.com", hire_date: new Date("2021-04-05"), salary: 78000, manager_id: 4, dept_name: "HR" },
  { first_name: "Grace", last_name: "Moore", email: "grace.moore@company.com", hire_date: new Date("2017-12-01"), salary: 110000, manager_id: null, dept_name: "Finance" },
  { first_name: "Henry", last_name: "Taylor", email: "henry.taylor@company.com", hire_date: new Date("2023-01-10"), salary: 52000, manager_id: 5, dept_name: "Finance" },
  { first_name: "Ivy", last_name: "Anderson", email: "ivy.anderson@company.com", hire_date: new Date("2020-08-15"), salary: 71000, manager_id: 1, dept_name: "Engineering" },
  { first_name: "Jack", last_name: "Thomas", email: "jack.thomas@company.com", hire_date: new Date("2019-05-20"), salary: null, manager_id: 4, dept_name: "Sales" }
]);

// Customers
db.customers.insertMany([
  { first_name: "Michael", last_name: "Scott", email: "michael@dundermifflin.com", city: "Scranton", country: "USA" },
  { first_name: "Dwight", last_name: "Schrute", email: "dwight@dundermifflin.com", city: "Scranton", country: "USA" },
  { first_name: "Jim", last_name: "Halpert", email: "jim@dundermifflin.com", city: "Scranton", country: "USA" },
  { first_name: "Pam", last_name: "Beesly", email: "pam@dundermifflin.com", city: "Scranton", country: "USA" },
  { first_name: "Angela", last_name: "Martin", email: "angela@dundermifflin.com", city: "Scranton", country: "USA" },
  { first_name: "Kevin", last_name: "Malone", email: "kevin@dundermifflin.com", city: "Scranton", country: "USA" },
  { first_name: "Oscar", last_name: "Martinez", email: "oscar@dundermifflin.com", city: "Los Angeles", country: "USA" },
  { first_name: "Stanley", last_name: "Hudson", email: "stanley@dundermifflin.com", city: "Chicago", country: "USA" },
  { first_name: "Phyllis", last_name: "Vance", email: "phyllis@dundermifflin.com", city: "Chicago", country: "USA" },
  { first_name: "Andy", last_name: "Bernard", email: "andy@dundermifflin.com", city: "Stamford", country: "USA" },
  { first_name: "Emma", last_name: "Watson", email: "emma@example.com", city: "London", country: "UK" },
  { first_name: "Tom", last_name: "Hardy", email: "tom@example.com", city: "London", country: "UK" }
]);

// Categories
db.categories.insertMany([
  { name: "Electronics" },
  { name: "Clothing" },
  { name: "Books" },
  { name: "Home & Garden" },
  { name: "Sports" }
]);

// Products (category by name for simplicity)
db.products.insertMany([
  { name: "Laptop", category: "Electronics", price: 999.99, stock_quantity: 50 },
  { name: "Smartphone", category: "Electronics", price: 699.99, stock_quantity: 100 },
  { name: "Headphones", category: "Electronics", price: 149.99, stock_quantity: 200 },
  { name: "T-Shirt", category: "Clothing", price: 29.99, stock_quantity: 500 },
  { name: "Jeans", category: "Clothing", price: 59.99, stock_quantity: 300 },
  { name: "SQL Guide Book", category: "Books", price: 49.99, stock_quantity: 150 },
  { name: "Data Science Handbook", category: "Books", price: 39.99, stock_quantity: 100 },
  { name: "Garden Tools Set", category: "Home & Garden", price: 89.99, stock_quantity: 75 },
  { name: "Basketball", category: "Sports", price: 24.99, stock_quantity: 200 },
  { name: "Tennis Racket", category: "Sports", price: 79.99, stock_quantity: 80 }
]);

// Orders with embedded line items (customer_id as 1-based for simplicity; use ObjectId in real app)
db.orders.insertMany([
  { customer_id: 1, order_date: new Date("2024-01-15"), total_amount: 1149.98, status: "completed", items: [
      { product_name: "Laptop", quantity: 1, unit_price: 999.99 },
      { product_name: "Headphones", quantity: 1, unit_price: 149.99 }
  ]},
  { customer_id: 2, order_date: new Date("2024-01-16"), total_amount: 699.99, status: "completed", items: [
      { product_name: "Smartphone", quantity: 1, unit_price: 699.99 }
  ]},
  { customer_id: 3, order_date: new Date("2024-01-17"), total_amount: 89.98, status: "completed", items: [
      { product_name: "T-Shirt", quantity: 2, unit_price: 29.99 },
      { product_name: "Basketball", quantity: 1, unit_price: 24.99 }
  ]},
  { customer_id: 1, order_date: new Date("2024-01-20"), total_amount: 149.99, status: "completed", items: [
      { product_name: "Headphones", quantity: 1, unit_price: 149.99 }
  ]},
  { customer_id: 4, order_date: new Date("2024-02-01"), total_amount: 999.99, status: "pending", items: [
      { product_name: "Laptop", quantity: 1, unit_price: 999.99 }
  ]},
  { customer_id: 5, order_date: new Date("2024-02-05"), total_amount: 59.99, status: "shipped", items: [
      { product_name: "Jeans", quantity: 1, unit_price: 59.99 }
  ]},
  { customer_id: 6, order_date: new Date("2024-02-10"), total_amount: 239.97, status: "completed", items: [
      { product_name: "Headphones", quantity: 1, unit_price: 149.99 },
      { product_name: "SQL Guide Book", quantity: 1, unit_price: 49.99 },
      { product_name: "Data Science Handbook", quantity: 1, unit_price: 39.99 }
  ]},
  { customer_id: 7, order_date: new Date("2024-02-15"), total_amount: 49.99, status: "cancelled", items: [
      { product_name: "SQL Guide Book", quantity: 1, unit_price: 49.99 }
  ]},
  { customer_id: 8, order_date: new Date("2024-02-20"), total_amount: 1699.98, status: "completed", items: [
      { product_name: "Laptop", quantity: 1, unit_price: 999.99 },
      { product_name: "Smartphone", quantity: 1, unit_price: 699.99 }
  ]},
  { customer_id: 3, order_date: new Date("2024-03-01"), total_amount: 129.98, status: "pending", items: [
      { product_name: "T-Shirt", quantity: 1, unit_price: 29.99 },
      { product_name: "SQL Guide Book", quantity: 1, unit_price: 49.99 },
      { product_name: "Garden Tools Set", quantity: 1, unit_price: 89.99 }
  ]},
  { customer_id: 9, order_date: new Date("2024-03-05"), total_amount: 79.99, status: "shipped", items: [
      { product_name: "Tennis Racket", quantity: 1, unit_price: 79.99 }
  ]},
  { customer_id: 10, order_date: new Date("2024-03-10"), total_amount: 449.97, status: "completed", items: [
      { product_name: "Headphones", quantity: 3, unit_price: 149.99 }
  ]}
]);


// ---------------------------------------------------------------------------
// 3. FIND (READ)
// ---------------------------------------------------------------------------

// Find all documents in a collection
db.employees.find();

// Find one document (returns first match or null)
db.employees.findOne();

// Find with empty filter = find all (same as find({}))
db.customers.find({});

// Find with criteria (equality)
db.employees.find({ dept_name: "Engineering" });
db.employees.find({ first_name: "John", last_name: "Smith" });

// Find by _id (need ObjectId)
// db.employees.findOne({ _id: ObjectId("...") });


// ---------------------------------------------------------------------------
// 4. QUERY OPERATORS
// ---------------------------------------------------------------------------

// Comparison: $eq, $ne, $gt, $gte, $lt, $lte
db.employees.find({ salary: { $gt: 70000 } });
db.employees.find({ salary: { $gte: 60000, $lte: 80000 } });
db.employees.find({ salary: { $ne: null } });

// $in, $nin
db.employees.find({ dept_name: { $in: ["Engineering", "Marketing"] } });
db.employees.find({ dept_name: { $nin: ["HR"] } });

// $and (default when you pass multiple keys; explicit for complex logic)
db.employees.find({ $and: [
  { salary: { $gt: 60000 } },
  { hire_date: { $gte: new Date("2020-01-01") } }
]});

// $or
db.employees.find({ $or: [
  { dept_name: "Engineering" },
  { dept_name: "Finance" }
]});

// $not
db.employees.find({ salary: { $not: { $lte: 50000 } } });  // salary > 50000 or null

// $regex (pattern match)
db.employees.find({ email: /company\.com$/ });
db.employees.find({ first_name: { $regex: "^J", $options: "i" } });  // case insensitive

// $exists (field present or not)
db.employees.find({ salary: { $exists: true } });
db.employees.find({ salary: { $exists: true, $ne: null } });

// $type (BSON type)
db.employees.find({ salary: { $type: "double" } });
// Number: "double", "int", "long"; String: "string"; Date: "date"; Array: "array"; Object: "object"; Null: "null"


// ---------------------------------------------------------------------------
// 5. PROJECTION (choose which fields to return)
// ---------------------------------------------------------------------------

// Include only certain fields (1 = include)
db.employees.find({}, { first_name: 1, last_name: 1, salary: 1 });
// _id is included by default; exclude with _id: 0
db.employees.find({}, { first_name: 1, last_name: 1, _id: 0 });

// Exclude fields (0 = exclude)
db.employees.find({}, { email: 0, manager_id: 0 });

// Cannot mix include and exclude (except _id)
// db.employees.find({}, { first_name: 1, email: 0 });  // invalid


// ---------------------------------------------------------------------------
// 6. SORT, SKIP, LIMIT
// ---------------------------------------------------------------------------

// sort: 1 = ascending, -1 = descending
db.employees.find().sort({ salary: -1 });
db.employees.find().sort({ dept_name: 1, salary: -1 });

// limit
db.employees.find().sort({ salary: -1 }).limit(5);

// skip (e.g. pagination)
db.employees.find().sort({ hire_date: 1 }).skip(2).limit(5);

// Chained: find -> sort -> skip -> limit (order matters for correctness)


// ---------------------------------------------------------------------------
// 7. UPDATE
// ---------------------------------------------------------------------------

// updateOne - update first matching document
// db.employees.updateOne(
//   { email: "john.smith@company.com" },
//   { $set: { salary: 76000 } }
// );

// $set: set field(s); $unset: remove field; $inc: increment
// db.employees.updateOne(
//   { email: "john.smith@company.com" },
//   { $inc: { salary: 1000 } }
// );

// updateMany - update all matching
// db.employees.updateMany(
//   { dept_name: "Engineering" },
//   { $set: { location: "Remote" } }
// );

// replaceOne - replace entire document (except _id)
// db.employees.replaceOne({ email: "john.smith@company.com" }, { first_name: "John", last_name: "Smith", email: "john.smith@company.com", salary: 76000 });


// ---------------------------------------------------------------------------
// 8. DELETE
// ---------------------------------------------------------------------------

// deleteOne - delete first match
// db.employees.deleteOne({ email: "old@company.com" });

// deleteMany - delete all matching
// db.orders.deleteMany({ status: "cancelled" });

// Delete all documents in collection (keep collection)
// db.orders.deleteMany({});


// ---------------------------------------------------------------------------
// 9. COUNT DOCUMENTS
// ---------------------------------------------------------------------------

db.employees.countDocuments({});                    // total count
db.employees.countDocuments({ dept_name: "Engineering" });
db.orders.countDocuments({ status: "completed" });

// estimatedDocumentCount() - fast, no filter (uses metadata)
db.employees.estimatedDocumentCount();


// ---------------------------------------------------------------------------
// 10. AGGREGATION PIPELINE BASICS
// ---------------------------------------------------------------------------

// $match - filter (like find)
db.employees.aggregate([
  { $match: { dept_name: "Engineering" } }
]);

// $project - shape output (like projection + computed fields)
db.employees.aggregate([
  { $project: { full_name: { $concat: ["$first_name", " ", "$last_name"] }, salary: 1, _id: 0 } }
]);

// $group - group by key and compute aggregates
db.employees.aggregate([
  { $group: { _id: "$dept_name", count: { $sum: 1 }, avg_salary: { $avg: "$salary" }, total_salary: { $sum: "$salary" } } }
]);

// $sort in pipeline
db.employees.aggregate([
  { $group: { _id: "$dept_name", count: { $sum: 1 } } },
  { $sort: { count: -1 } }
]);

// $limit in pipeline
db.employees.aggregate([
  { $sort: { salary: -1 } },
  { $limit: 5 }
]);

// Full example: total revenue by order status
db.orders.aggregate([
  { $group: { _id: "$status", total: { $sum: "$total_amount" }, count: { $sum: 1 } } },
  { $sort: { total: -1 } }
]);


// ---------------------------------------------------------------------------
// 11. MORE AGGREGATION: $lookup (join-like), $unwind
// ---------------------------------------------------------------------------

// $lookup - join with another collection (e.g. orders with customer names)
// First we need a way to match; here we use customer_id and assume we stored same id in customers
// If using ObjectId refs, $lookup on that field.

// $unwind - deconstruct array to one doc per element
db.orders.aggregate([
  { $match: { status: "completed" } },
  { $unwind: "$items" },
  { $group: { _id: "$items.product_name", total_qty: { $sum: "$items.quantity" }, total_revenue: { $sum: { $multiply: ["$items.quantity", "$items.unit_price"] } } } },
  { $sort: { total_revenue: -1 } }
]);


// ---------------------------------------------------------------------------
// 12. INDEXES (BASICS)
// ---------------------------------------------------------------------------

// Create single-field index
db.employees.createIndex({ email: 1 });        // ascending
db.employees.createIndex({ salary: -1 });      // descending
db.orders.createIndex({ customer_id: 1, order_date: -1 });

// Unique index
db.employees.createIndex({ email: 1 }, { unique: true });

// Compound index (order of fields matters for queries)
db.employees.createIndex({ dept_name: 1, salary: -1 });

// List indexes
db.employees.getIndexes();

// Drop index
// db.employees.dropIndex({ email: 1 });


// ---------------------------------------------------------------------------
// 13. DATA TYPES QUICK REFERENCE
// ---------------------------------------------------------------------------
// String, Number (int/long/double), Boolean, Date (new Date()), Array [], Object {}, null
// ObjectId (ObjectId("...")), Binary, Regex

// Insert with explicit types
// db.demo.insertOne({
//   name: "test",
//   count: NumberInt(42),
//   price: NumberDecimal("99.99"),
//   created: new Date(),
//   tags: ["a", "b"],
//   meta: { source: "web" }
// });


// ---------------------------------------------------------------------------
// 14. USEFUL METHODS SUMMARY
// ---------------------------------------------------------------------------
// db.collection.insertOne(doc)     db.collection.insertMany([...])
// db.collection.find(filter, projection)   db.collection.findOne(...)
// db.collection.updateOne(filter, update)   db.collection.updateMany(...)
// db.collection.replaceOne(filter, doc)
// db.collection.deleteOne(filter)   db.collection.deleteMany(filter)
// db.collection.countDocuments(filter)   db.collection.estimatedDocumentCount()
// db.collection.aggregate([...])
// db.collection.createIndex(keys, options)   db.collection.getIndexes()
// db.collection.drop()   db.collection.dropIndex(...)

print("MongoDB basics script loaded. Run individual sections in mongosh or: mongosh < mongodb-basics.js");
