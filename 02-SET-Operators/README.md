# 🥞 Module 02: SET Operators

### 📌 Overview
While `JOINS` are used to combine data *column-wise* (adding more attributes to existing records), **SET Operators** are used to combine data *row-wise* (appending new records to an existing dataset). This module covers the rules, performance impacts, and business logic of combining result sets.


---

## 🚀 Strategic Use Cases for SET Operators

### 1. Data Consolidation (Historical Merging)
* **The Problem:** A company stores current orders in a `Sales.Orders` table and past orders in a `Sales.OrdersArchive` table to improve daily query speed. A recruiter wants a complete year-over-year report.
* **The Solution:** Use `UNION` or `UNION ALL` to stack the two tables vertically, creating a seamless master dataset for analysis.

### 2. Delta Detection (Finding the Gap)
* **The Problem:** You need to audit two systems to see which employees are *not* currently registered as customers.
* **The Solution:** Use `EXCEPT` to take the master list of Employees and subtract the list of Customers. This instantly isolates the "delta" or missing records.

### 3. Data Completeness & Overlap (The Intersection)
* **The Problem:** You are running a promotion specifically for staff members who actively buy your products.
* **The Solution:** Use `INTERSECT` to find the exact overlapping rows between the Employee dataset and the Customer dataset.

---

## 🛠 The 4 Core SET Operators

### 1. UNION (The Deduplicator)
**Logic:** Returns all rows from both sets, eliminating duplicates.
* **Impact:** Clean, distinct lists. However, checking for duplicates requires the database to perform extra sorting operations behind the scenes.

### 2. UNION ALL (The Performance Booster)
**Logic:** Returns all rows from both sets, including duplicates.
* **Pro-Tip:** `UNION ALL` has significantly better performance than `UNION` because it skips the duplicate-checking process. If you, as the analyst, know the datasets do not contain overlapping data, *always* default to `UNION ALL`.

### 3. EXCEPT / MINUS (The Subtractor)
**Logic:** Returns unique rows in the first set that are *not* in the second table. Order matters heavily here.

### 4. INTERSECT (The Common Ground)
**Logic:** Returns only the common rows between two sets. Order does not matter.

---

## ⚠️ The Golden Rules of SET Operations
SQL is very strict when using SET operators. To avoid execution errors, ensure:
1.  **Equal Columns:** Both queries must have the exact same number of columns.
2.  **Matching Data Types:** The data types of columns in each query must match. The first query dictates the expected data type.
3.  **Column Order:** The order of the columns in each query must be the same.
4.  **Naming Convention:** Column aliases in the final result set are determined *only* by the column names specified in the very first `SELECT` statement.
5.  **Sorting:** `ORDER BY` can only be used once, at the very end of the entire query, to sort the final combined result.

## 💡 Best Practice: Future-Proofing
Never use `SELECT *` with SET operators. Always explicitly name your columns. If the underlying table structure changes (e.g., a database administrator adds a column to one table but not the other), a `SELECT *` query will break. Hardcoding a 'SourceTable' string is also highly recommended to track data lineage!
