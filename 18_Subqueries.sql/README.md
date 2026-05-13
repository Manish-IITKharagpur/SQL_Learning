> **Category:** Advanced SQL Techniques
> **Concepts Covered:** Subquery Types, Result Types, Locations/Clauses, Correlated vs Non-Correlated, Operators (IN, ANY, ALL, EXISTS)

---

## 📌 Topic Overview

A **Subquery** is a query inside another query. It acts as a **supporter** — preparing and supplying data to the main (outer) query without showing its own results directly.

```
┌─────────────────────────────────┐
│         MAIN QUERY              │
│  SELECT ... FROM ...            │
│     ┌───────────────────┐       │
│     │    SUBQUERY       │       │
│     │  SELECT ... FROM  │       │
│     └───────────────────┘       │
└─────────────────────────────────┘
```

> 💡 **Real-life analogy:** Think of a subquery like a kitchen helper who preps the ingredients before the chef (main query) cooks the final dish. You only see the final dish, not the prep work.

### Why Use Subqueries?

Complex data tasks have multiple steps:
1. Join tables to prepare data
2. Filter the data
3. Transform values
4. Aggregate results

Instead of cramming all steps into one messy query, subqueries let you **break complexity into clean logical steps** — each step feeding into the next.

### Key Terms

| Term | Meaning |
|------|---------|
| **Subquery / Inner Query** | The query inside another query |
| **Main Query / Outer Query** | The query that uses the subquery's result |
| **Intermediate Result** | The temporary output of the subquery (stored in cache, destroyed after execution) |
| **Nested Query** | Multiple subqueries inside each other |

---

## 🗂️ Types of Subqueries

Subqueries can be categorized **three ways:**

### 1️⃣ By Dependency

| Type | Description | Executes |
|------|-------------|----------|
| **Non-Correlated** | Independent of main query — can run on its own | Once |
| **Correlated** | Depends on main query — references outer query's values | Once per row |

### 2️⃣ By Result Type

| Type | Returns | Example |
|------|---------|---------|
| **Scalar** | 1 row, 1 column (single value) | `SELECT AVG(Sales) FROM Orders` |
| **Row** | Multiple rows, 1 column (a list) | `SELECT CustomerID FROM Orders` |
| **Table** | Multiple rows, multiple columns | `SELECT OrderID, OrderDate FROM Orders` |

### 3️⃣ By Location (Where it's Used)

| Location | Use Case |
|----------|----------|
| **FROM clause** | Creates a temporary table for the main query |
| **SELECT clause** | Adds a calculated column (scalar only) |
| **JOIN clause** | Prepares a dataset before joining |
| **WHERE clause** | Filters the main query dynamically |

---

## 🔧 How SQL Executes Subqueries (Behind the Scenes)

```
Client writes query
        ↓
Database Engine identifies subquery
        ↓
Subquery executes → result stored in CACHE (temporary)
        ↓
Main query executes using cached result
        ↓
Final result returned to client
        ↓
Cache is CLEARED (intermediate result destroyed)
```

> 📝 The intermediate result is **only accessible by the main query** — not by any other external query.

---

## 📐 Syntax Quick Reference

### Subquery in FROM Clause
```sql
SELECT col1, col2
FROM (
    SELECT col1, col2, aggregate_function() AS alias
    FROM table_name
    WHERE condition
) AS t                  -- alias is REQUIRED in SQL Server
WHERE condition;
```

### Subquery in SELECT Clause *(Scalar only)*
```sql
SELECT
    col1,
    col2,
    (SELECT aggregate_function() FROM another_table) AS alias
FROM table_name;
```

### Subquery in JOIN Clause
```sql
SELECT c.*, t.TotalSales
FROM table1 AS c
LEFT JOIN (
    SELECT col1, aggregate AS TotalSales
    FROM table2
    GROUP BY col1
) AS t ON c.id = t.id;
```

### Subquery in WHERE — Comparison Operators *(Scalar only)*
```sql
SELECT col1
FROM table_name
WHERE col1 > (SELECT AVG(col1) FROM table_name);
```

### Subquery in WHERE — IN Operator *(Row subquery allowed)*
```sql
SELECT *
FROM table1
WHERE col1 IN (
    SELECT col1
    FROM table2
    WHERE condition
);
```

### Subquery in WHERE — ANY / ALL Operators
```sql
-- ANY: condition true for at least one value
WHERE salary > ANY (SELECT salary FROM Employees WHERE Gender = 'M')

-- ALL: condition true for every value
WHERE salary > ALL (SELECT salary FROM Employees WHERE Gender = 'M')
```

### Correlated Subquery with EXISTS
```sql
SELECT *
FROM table1 AS o
WHERE EXISTS (
    SELECT 1                    -- Value doesn't matter, 1 is convention
    FROM table2 AS c
    WHERE c.id = o.id           -- Links subquery to main query
      AND condition
);
```

---

## 💼 Real-World Use Cases

### 1️⃣ Subquery in FROM — Multi-Step Analysis

**Task 1:** Find products with price higher than the average price.

```sql
-- Main Query
SELECT *
FROM (
    -- Subquery: prepare data with average price
    SELECT
        ProductID,
        Price,
        AVG(Price) OVER () AS AvgPrice
    FROM Sales.Products
) AS t
WHERE Price > AvgPrice;
```

**Task 2:** Rank customers by total sales.

```sql
-- Main Query
SELECT
    *,
    RANK() OVER (ORDER BY TotalSales DESC) AS CustomerRank
FROM (
    -- Subquery: aggregate sales per customer
    SELECT
        CustomerID,
        SUM(Sales) AS TotalSales
    FROM Sales.Orders
    GROUP BY CustomerID
) AS t;
```

> 💡 **Debug Tip:** To see the intermediate result of a subquery, **highlight just the subquery** (without parentheses) and execute. SQL Server will run only that part!

---

### 2️⃣ Subquery in SELECT — Adding Aggregate Columns

**Task 3:** Show product details alongside total order count.

```sql
SELECT
    ProductID,
    Product,
    Price,
    (SELECT COUNT(*) FROM Sales.Orders) AS TotalOrders  -- Scalar subquery
FROM Sales.Products;
```

> ⚠️ **Rule:** Subquery in SELECT must return **exactly one value (scalar)**. Using `SELECT OrderID` (multiple rows) will throw an error.

---

### 3️⃣ Subquery in JOIN — Combining Aggregated Data

**Task 4:** Show customer details with their total sales.

```sql
SELECT
    c.*,
    t.TotalSales
FROM Sales.Customers AS c
LEFT JOIN (
    SELECT
        CustomerID,
        SUM(Sales) AS TotalSales
    FROM Sales.Orders
    GROUP BY CustomerID
) AS t ON c.CustomerID = t.CustomerID;
```

**Task 5:** Show all customers with their total order count.

```sql
SELECT
    c.*,
    o.TotalOrders
FROM Sales.Customers AS c
LEFT JOIN (
    SELECT
        CustomerID,
        COUNT(*) AS TotalOrders
    FROM Sales.Orders
    GROUP BY CustomerID
) AS o ON c.CustomerID = o.CustomerID;
```

> 📝 Using `LEFT JOIN` ensures customers with **zero orders** (like Anna) are still included.

---

### 4️⃣ Subquery in WHERE — Comparison Operators

**Task 6:** Find products priced above average.

```sql
SELECT
    ProductID,
    Price,
    (SELECT AVG(Price) FROM Sales.Products) AS AvgPrice
FROM Sales.Products
WHERE Price > (SELECT AVG(Price) FROM Sales.Products);
```

---

### 5️⃣ Subquery in WHERE — IN Operator

**Task 7:** Orders from customers in Germany.

```sql
SELECT *
FROM Sales.Orders
WHERE CustomerID IN (
    SELECT CustomerID
    FROM Sales.Customers
    WHERE Country = 'Germany'
);
```

**Task 8:** Orders from customers NOT in Germany.

```sql
SELECT *
FROM Sales.Orders
WHERE CustomerID NOT IN (
    SELECT CustomerID
    FROM Sales.Customers
    WHERE Country = 'Germany'
);
```

> 💡 **Why use IN over static values?**
> `WHERE CustomerID IN (1, 4)` breaks when new German customers are added.
> The subquery version is **dynamic** — it auto-updates as data changes.

---

### 6️⃣ Subquery with ANY Operator

**Task 9:** Find female employees earning more than ANY male employee.

```sql
SELECT EmployeeID, FirstName, Salary
FROM Sales.Employees
WHERE Gender = 'F'
  AND Salary > ANY (
      SELECT Salary
      FROM Sales.Employees
      WHERE Gender = 'M'
  );
```

> **ANY** = salary must be greater than **at least one** male salary (less restrictive).
> **ALL** = salary must be greater than **every** male salary (more restrictive).

---

### 7️⃣ Correlated Subquery — Row-by-Row Analysis

**Task 10:** Show total orders per customer using a correlated subquery.

```sql
SELECT
    *,
    (SELECT COUNT(*)
     FROM Sales.Orders o
     WHERE o.CustomerID = c.CustomerID) AS TotalOrders
FROM Sales.Customers AS c;
```

> 🔁 **How it works:** For every customer row in the outer query, the subquery runs **again** with that customer's ID. It's like a loop — executed once per row.

---

### 8️⃣ Correlated Subquery with EXISTS

**Task 11:** Orders from customers in Germany (using EXISTS).

```sql
SELECT *
FROM Sales.Orders AS o
WHERE EXISTS (
    SELECT 1
    FROM Sales.Customers AS c
    WHERE Country = 'Germany'
      AND o.CustomerID = c.CustomerID
);
```

**Task 12:** Orders from customers NOT in Germany.

```sql
SELECT *
FROM Sales.Orders AS o
WHERE NOT EXISTS (
    SELECT 1
    FROM Sales.Customers AS c
    WHERE Country = 'Germany'
      AND o.CustomerID = c.CustomerID
);
```

> 💡 **Why `SELECT 1`?** With EXISTS, SQL only checks **whether rows exist** — the actual values returned don't matter. Using `1` is the standard convention and is the most efficient.

---

## 🔄 Correlated vs Non-Correlated — Side by Side

| Feature | Non-Correlated | Correlated |
|---------|---------------|------------|
| **Dependency** | Independent of main query | Depends on main query |
| **Execution** | Once | Once per row |
| **Run alone?** | ✅ Yes | ❌ No |
| **Readability** | Easier | Harder |
| **Performance** | ⚡ Faster | 🐢 Slower |
| **Use case** | Static comparison (one value) | Row-by-row dynamic comparison |

---

## ✅ Best Practices

| ✅ Do | ❌ Don't |
|------|---------|
| Always alias subqueries in FROM clause (`AS t`) | Don't forget the alias in SQL Server — it's required |
| Use `SELECT 1` in EXISTS subqueries | Don't use `SELECT *` in EXISTS — it's wasteful |
| Use IN for multi-value dynamic filtering | Don't hardcode values when a subquery can be dynamic |
| Prefer non-correlated subqueries when possible | Don't use correlated subqueries unnecessarily — they're slower |
| Highlight + execute the subquery alone to debug | Don't nest too many subqueries — consider CTEs instead |
| Use LEFT JOIN with subqueries to preserve all rows | Don't use INNER JOIN when you need to keep unmatched rows |

---

## ⚠️ Common Mistakes

1. **Multiple values in SELECT subquery** → Only scalar (single value) subqueries allowed in SELECT clause
2. **Missing alias in FROM subquery** → SQL Server requires an alias after every subquery in FROM
3. **Using comparison operator with row subquery** → `WHERE col = (subquery returning 3 rows)` → Error; use `IN` instead
4. **Hardcoding values instead of subquery** → `IN (1, 4)` breaks when data changes; use a subquery for dynamic filtering
5. **Forgetting to link correlated subquery** → Without `WHERE o.CustomerID = c.CustomerID`, you'll get total count instead of per-customer count

---

## 🧠 Practice Questions

<details>
<summary><b>Q1: Find all products whose price is above the average price. Show ProductID, Product name, Price, and the average price.</b></summary>

```sql
SELECT
    ProductID,
    Product,
    Price,
    (SELECT AVG(Price) FROM Sales.Products) AS AvgPrice
FROM Sales.Products
WHERE Price > (SELECT AVG(Price) FROM Sales.Products);
```
</details>

<details>
<summary><b>Q2: Show all customers and their total number of orders. Include customers with zero orders.</b></summary>

```sql
SELECT
    c.*,
    COALESCE(o.TotalOrders, 0) AS TotalOrders
FROM Sales.Customers AS c
LEFT JOIN (
    SELECT CustomerID, COUNT(*) AS TotalOrders
    FROM Sales.Orders
    GROUP BY CustomerID
) AS o ON c.CustomerID = o.CustomerID;
```
</details>

<details>
<summary><b>Q3: Find employees whose salary is greater than ALL female employees' salaries.</b></summary>

```sql
SELECT EmployeeID, FirstName, Salary
FROM Sales.Employees
WHERE Salary > ALL (
    SELECT Salary
    FROM Sales.Employees
    WHERE Gender = 'F'
);
```
</details>

<details>
<summary><b>Q4: Rank customers by their total sales using a subquery.</b></summary>

```sql
SELECT
    *,
    RANK() OVER (ORDER BY TotalSales DESC) AS SalesRank
FROM (
    SELECT
        CustomerID,
        SUM(Sales) AS TotalSales
    FROM Sales.Orders
    GROUP BY CustomerID
) AS t;
```
</details>

<details>
<summary><b>Q5: Show all orders where the customer does NOT exist in the Customers table (orphan orders).</b></summary>

```sql
SELECT *
FROM Sales.Orders AS o
WHERE NOT EXISTS (
    SELECT 1
    FROM Sales.Customers AS c
    WHERE c.CustomerID = o.CustomerID
);
```
</details>

---

## 📋 Summary

- A **subquery** is a query inside another query — it supports the main query with data
- The subquery result is **temporary** (cached during execution, destroyed after)
- **3 ways to categorize:** by dependency (correlated/non-correlated), by result type (scalar/row/table), by location (FROM/SELECT/JOIN/WHERE)
- **Non-correlated** = independent, executes once, faster, easier to read
- **Correlated** = depends on main query, executes per row, slower but enables row-by-row logic
- **Operators:** `=` / `>` / `<` for scalar · `IN` / `NOT IN` for lists · `ANY` / `ALL` for comparative lists · `EXISTS` / `NOT EXISTS` for existence checks
- **Key rule:** SELECT clause subqueries must be scalar; FROM/JOIN/WHERE can use row or table subqueries

---

## 🔗 Related Topics

- [`05_JOINs`](../05_JOINs/) — Alternative to subqueries for combining tables
- [`19_Common_Table_Expressions_CTE`](../19_Common_Table_Expressions_CTE/) — Cleaner alternative to nested subqueries
- [`13_Aggregate_Functions`](../13_Aggregate_Functions/) — Often used inside subqueries
- [`15_Window_Aggregations`](../15_Window_Aggregations/) — Alternative to subqueries for aggregations with detail

---

> 💬 *"Subqueries are the building blocks of complex SQL — they let you think in steps, not in one giant tangled mess."*

**[⬆ Back to Main Index](../README.md)**

