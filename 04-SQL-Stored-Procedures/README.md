# ⚙️ Module 04: Stored Procedures & Control Flow

### 📌 Overview
A standard SQL query represents a *single* interaction with a database. A **Stored Procedure (SP)** acts like a mini-program stored directly on the database server. It allows for multiple queries, variables, conditional logic, and error handling to be executed in a single call. 

This module covers how to transition from writing static queries to building dynamic, programmatic SQL objects.

---

## 🚀 Strategic Use Cases for Stored Procedures

### 1. Automation & Reusability (The "Run It Daily" Scenario)
* **The Problem:** A reporting team needs a daily summary of customer growth and average scores, filtered by different regions. Writing and modifying a script every day is inefficient.
* **The Solution:** Create a Stored Procedure with a `@Country` parameter. The team can simply execute `EXEC GetCustomerSummary @Country = 'USA'` without ever touching the underlying SQL code.

### 2. Complex Business Logic (Control Flow)
* **The Problem:** Before generating a report, you need to ensure the data is clean. If there are `NULL` scores, they need to be converted to `0`, but only for the specific region being queried.
* **The Solution:** Use `IF/ELSE` statements within the Stored Procedure to check for existence (`IF EXISTS`) and perform data cleanup automatically before the final `SELECT` statement runs.

### 3. Server-Side Error Handling
* **The Problem:** If a query fails in the middle of a massive data pipeline, it can silently break downstream reports or crash applications.
* **The Solution:** Wrap the logic in a `TRY/CATCH` block. If a mathematical error occurs (like dividing by zero), the database handles the error gracefully and outputs a readable error log instead of crashing.

---

## 🛠 The Core Concepts

* **Parameters (`@Variable`):** Placeholders that allow the user to pass dynamic inputs into the procedure.
* **Variables (`DECLARE`):** Temporary storage used inside the procedure to hold calculated values (e.g., storing a `COUNT` to print it as a message later).
* **Control Flow (`IF / ELSE`):** Allows the procedure to make decisions and execute different blocks of code based on the data it finds.
* **Error Handling (`BEGIN TRY / BEGIN CATCH`):** Prevents hard crashes by "catching" execution errors and allowing the developer to log exactly what failed (Error Line, Severity, Message).

---

## 💡 Architecture Insight: When NOT to use Stored Procedures
While Stored Procedures are powerful and execute very quickly (because they are pre-compiled and sit right next to the data), **they should not be used to build entire applications.** Managing thousands of lines of complex business logic, loops, and heavy computations inside a database becomes a maintenance nightmare. Modern data architecture dictates that databases should focus on storage and retrieval, while a programming language like **Python** should handle the heavy business logic and orchestration.