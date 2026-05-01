# 🪟 SQL Window Value Functions (Analytical Functions)

> **Category:** Window Functions → Value / Analytical Functions
> **Functions Covered:** `LEAD`, `LAG`, `FIRST_VALUE`, `LAST_VALUE`

---

## 📌 Topic Overview

**Value Functions** (also called **Analytical Functions**) are the most important category of window functions for **data analytics**. They allow you to **access a value from another row** within a window — without using complex JOINs or self-joins.

### Why are they called "Value Functions"?

Because they let you pull a value from a **different row** (previous, next, first, or last) into the **current row**, so you can compare them side by side easily.

> 💡 **Real-life analogy:** Imagine you're standing in a queue and you want to know what the person *in front of you* and the person *behind you* are holding — without leaving your spot. That's exactly what value functions do for rows.

---

## 🎯 The 4 Value Functions

| Function | Purpose | Example Use |
|----------|---------|-------------|
| **`LAG`** | Access value from a **previous row** | Get last month's sales |
| **`LEAD`** | Access value from a **next row** | Get next month's sales |
| **`FIRST_VALUE`** | Access value from the **first row** of the window | Get January's sales (first month) |
| **`LAST_VALUE`** | Access value from the **last row** of the window | Get July's sales (last month) |

### Visual Example

```
Month     Sales
-------   -----
January    20  ← FIRST_VALUE returns 20
February   10  ← LAG (previous month from March)
March      30  ← Current row
April       5  ← LEAD (next month from March)
...
July       40  ← LAST_VALUE returns 40
```

---

## 📐 Syntax Quick Reference

### General Rules

| Function | Expression | ORDER BY | PARTITION BY | Frame Clause |
|----------|------------|----------|--------------|--------------|
| `LAG` / `LEAD` | ✅ Required | ✅ Required | ⚪ Optional | ❌ **Not Allowed** |
| `FIRST_VALUE` | ✅ Required | ✅ Required | ⚪ Optional | ⚪ Optional |
| `LAST_VALUE` | ✅ Required | ✅ Required | ⚪ Optional | ⚠️ **Recommended** |

> 🔑 **Golden Rule:** All value functions **MUST** use `ORDER BY` (just like ranking functions).

---

### 🔹 LEAD & LAG Syntax

```sql
LEAD(expression [, offset [, default]]) OVER (
    [PARTITION BY column]
    ORDER BY column
)

LAG(expression [, offset [, default]]) OVER (
    [PARTITION BY column]
    ORDER BY column
)
```

**Arguments Explained:**

| Argument | Required? | Description | Default |
|----------|-----------|-------------|---------|
| `expression` | ✅ Yes | Column to fetch (any data type) | — |
| `offset` | ❌ No | How many rows to jump forward/backward | `1` |
| `default` | ❌ No | Value returned when SQL doesn't find a row | `NULL` |

**Example:**
```sql
LEAD(Sales, 2, 0) OVER (ORDER BY Month)
-- Jump 2 rows ahead, get Sales, return 0 if nothing found
```

---

### 🔹 FIRST_VALUE & LAST_VALUE Syntax

```sql
FIRST_VALUE(expression) OVER (
    [PARTITION BY column]
    ORDER BY column
    [ROWS BETWEEN ... AND ...]
)

LAST_VALUE(expression) OVER (
    [PARTITION BY column]
    ORDER BY column
    ROWS BETWEEN CURRENT ROW AND UNBOUNDED FOLLOWING  -- ⚠️ Required for correct results
)
```

> ⚠️ **Important:** `LAST_VALUE` **does NOT work correctly** with the default frame. You must explicitly define the frame as `ROWS BETWEEN CURRENT ROW AND UNBOUNDED FOLLOWING`.

---

## 🔍 Deep Dive: How SQL Executes These Functions

### LAG vs LEAD — Step by Step

Given this data:

| Month    | Sales |
|----------|-------|
| January  | 20    |
| February | 10    |
| March    | 30    |
| April    | 5     |

**`LEAD(Sales) OVER (ORDER BY Month)`** → Gets sales from the **next** row
**`LAG(Sales) OVER (ORDER BY Month)`** → Gets sales from the **previous** row

| Month    | Sales | LEAD (Next) | LAG (Previous) |
|----------|-------|-------------|----------------|
| January  | 20    | 10          | NULL           |
| February | 10    | 30          | 20             |
| March    | 30    | 5           | 10             |
| April    | 5     | NULL        | 30             |

> 📝 **Pattern:** `LEAD` returns `NULL` for the **last** row · `LAG` returns `NULL` for the **first** row.

---

### Using OFFSET and DEFAULT

**`LEAD(Sales, 2, 0)`** → Jump 2 rows ahead, return 0 if nothing found

| Month    | Sales | LEAD(Sales, 2, 0) | LAG(Sales, 2, 0) |
|----------|-------|-------------------|------------------|
| January  | 20    | 30                | 0                |
| February | 10    | 5                 | 0                |
| March    | 30    | 0 *(no data)*     | 20               |
| April    | 5     | 0 *(no data)*     | 10               |

---

### Why LAST_VALUE Needs a Custom Frame

By default, the window frame is `RANGE BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW`. This means at every row, the "last value" is just the current row — making `LAST_VALUE` useless without fixing the frame.

**❌ Wrong (default frame):**
```sql
LAST_VALUE(Sales) OVER (ORDER BY Month)
```

**✅ Correct:**
```sql
LAST_VALUE(Sales) OVER (
    ORDER BY Month
    ROWS BETWEEN CURRENT ROW AND UNBOUNDED FOLLOWING
)
```

> 💡 **Pro Tip:** Many analysts prefer using `FIRST_VALUE` with reversed `ORDER BY` (DESC) instead of fixing `LAST_VALUE`'s frame — it's simpler and cleaner.

---

## 💼 Real-World Use Cases

### 1️⃣ Time-Series Analysis (Most Common!)

**Goal:** Track business performance over time.

- **Year-over-Year (YoY)** → Long-term growth/decline
- **Month-over-Month (MoM)** → Short-term trends and seasonality

**Example:** Find % change in sales between current and previous month.

```sql
SELECT
    *,
    CurrentMonthSales - PreviousMonthSales AS MoM_Change,
    ROUND(
        CAST((CurrentMonthSales - PreviousMonthSales) AS FLOAT)
        / PreviousMonthSales * 100, 1
    ) AS MoM_Perc
FROM (
    SELECT
        MONTH(OrderDate) AS OrderMonth,
        SUM(Sales) AS CurrentMonthSales,
        LAG(SUM(Sales)) OVER (ORDER BY MONTH(OrderDate)) AS PreviousMonthSales
    FROM Sales.Orders
    GROUP BY MONTH(OrderDate)
) AS MonthlySales;
```

**Result:**

| OrderMonth | CurrentMonthSales | PreviousMonthSales | MoM_Change | MoM_Perc |
|------------|-------------------|---------------------|------------|----------|
| 1          | 105               | NULL                | NULL       | NULL     |
| 2          | 195               | 105                 | +90        | +85.7%   |
| 3          | 80                | 195                 | -115       | -59.0%   |

> 📈 **Insight:** February showed strong growth, but March crashed — time to investigate!

---

### 2️⃣ Customer Retention Analysis

**Goal:** Measure customer loyalty by analyzing the time between their orders.

```sql
SELECT
    CustomerID,
    AVG(DaysUntilNextOrder) AS AvgDays,
    RANK() OVER (ORDER BY COALESCE(AVG(DaysUntilNextOrder), 999999)) AS RankAvg
FROM (
    SELECT
        OrderID,
        CustomerID,
        OrderDate AS CurrentOrder,
        LEAD(OrderDate) OVER (PARTITION BY CustomerID ORDER BY OrderDate) AS NextOrder,
        DATEDIFF(
            day,
            OrderDate,
            LEAD(OrderDate) OVER (PARTITION BY CustomerID ORDER BY OrderDate)
        ) AS DaysUntilNextOrder
    FROM Sales.Orders
) AS CustomerOrdersWithNext
GROUP BY CustomerID;
```

> 🎯 **Why `COALESCE(AVG(...), 999999)`?**
> Customers with only 1 order have NULL average days. We push them to the bottom of the ranking using a high default value — so loyal customers (low average days) appear at the top.

---

### 3️⃣ Comparison with Extremes (Lowest/Highest)

**Goal:** Compare each row's sales to the lowest and highest sales for that product.

```sql
SELECT
    OrderID,
    ProductID,
    Sales,
    FIRST_VALUE(Sales) OVER (PARTITION BY ProductID ORDER BY Sales) AS LowestSales,
    LAST_VALUE(Sales) OVER (
        PARTITION BY ProductID
        ORDER BY Sales
        ROWS BETWEEN CURRENT ROW AND UNBOUNDED FOLLOWING
    ) AS HighestSales,
    Sales - FIRST_VALUE(Sales) OVER (PARTITION BY ProductID ORDER BY Sales) AS SalesDifference
FROM Sales.Orders;
```

### 🌟 Three Ways to Get the Highest Sales

| Approach | Code | Pros |
|----------|------|------|
| **`LAST_VALUE`** | `LAST_VALUE(Sales) OVER (... ROWS BETWEEN CURRENT ROW AND UNBOUNDED FOLLOWING)` | Direct intent |
| **`FIRST_VALUE` (reversed)** | `FIRST_VALUE(Sales) OVER (... ORDER BY Sales DESC)` | ⭐ Simpler — no frame needed |
| **`MAX`** | `MAX(Sales) OVER (PARTITION BY ProductID)` | Cleanest — no order by |

---

## ✅ Best Practices

| ✅ Do | ❌ Don't |
|------|---------|
| Always use `ORDER BY` with value functions | Don't forget the frame for `LAST_VALUE` |
| Use `LAG`/`LEAD` for time-series comparisons | Don't use complex JOINs when LAG/LEAD works |
| Use `COALESCE` to handle NULL results | Don't ignore NULL values from offsets |
| Prefer `FIRST_VALUE` with reversed ORDER over `LAST_VALUE` | Don't use default frame with `LAST_VALUE` |
| Consider `MAX`/`MIN` for simple extremes | Don't overcomplicate when a simple aggregate works |

---

## ⚠️ Common Mistakes

1. **Forgetting `ORDER BY`** → Value functions need ordered data to know "previous" or "next"
2. **Default frame with `LAST_VALUE`** → Returns the current row, not the actual last row
3. **Not handling NULL** → First/last rows return NULL with LAG/LEAD; use the `default` argument or `COALESCE`
4. **Integer division** → Forgetting to `CAST` as `FLOAT` when calculating percentages

---

## 🧠 Practice Questions

<details>
<summary><b>Q1: Find each customer's previous order date and the days since their last order.</b></summary>

```sql
SELECT
    OrderID,
    CustomerID,
    OrderDate AS CurrentOrder,
    LAG(OrderDate) OVER (PARTITION BY CustomerID ORDER BY OrderDate) AS PreviousOrder,
    DATEDIFF(
        day,
        LAG(OrderDate) OVER (PARTITION BY CustomerID ORDER BY OrderDate),
        OrderDate
    ) AS DaysSinceLastOrder
FROM Sales.Orders;
```
</details>

<details>
<summary><b>Q2: For each product, show the sales and how it compares to the highest sales of that product.</b></summary>

```sql
SELECT
    OrderID,
    ProductID,
    Sales,
    FIRST_VALUE(Sales) OVER (PARTITION BY ProductID ORDER BY Sales DESC) AS HighestSales,
    FIRST_VALUE(Sales) OVER (PARTITION BY ProductID ORDER BY Sales DESC) - Sales AS DiffFromHighest
FROM Sales.Orders;
```
</details>

<details>
<summary><b>Q3: Compare each month's sales to the same month last year (YoY analysis).</b></summary>

```sql
SELECT
    YEAR(OrderDate) AS OrderYear,
    MONTH(OrderDate) AS OrderMonth,
    SUM(Sales) AS CurrentYearSales,
    LAG(SUM(Sales)) OVER (
        PARTITION BY MONTH(OrderDate)
        ORDER BY YEAR(OrderDate)
    ) AS PreviousYearSales
FROM Sales.Orders
GROUP BY YEAR(OrderDate), MONTH(OrderDate);
```
</details>

<details>
<summary><b>Q4: Find sales 2 months ahead, with 0 as default if no data exists.</b></summary>

```sql
SELECT
    MONTH(OrderDate) AS Month,
    SUM(Sales) AS CurrentSales,
    LEAD(SUM(Sales), 2, 0) OVER (ORDER BY MONTH(OrderDate)) AS SalesIn2Months
FROM Sales.Orders
GROUP BY MONTH(OrderDate);
```
</details>

<details>
<summary><b>Q5: Identify customers whose order frequency is increasing (each gap is shorter than the previous gap).</b></summary>

```sql
WITH OrderGaps AS (
    SELECT
        CustomerID,
        OrderDate,
        DATEDIFF(day,
            LAG(OrderDate) OVER (PARTITION BY CustomerID ORDER BY OrderDate),
            OrderDate
        ) AS GapDays
    FROM Sales.Orders
)
SELECT
    CustomerID,
    OrderDate,
    GapDays,
    LAG(GapDays) OVER (PARTITION BY CustomerID ORDER BY OrderDate) AS PreviousGap,
    CASE
        WHEN GapDays < LAG(GapDays) OVER (PARTITION BY CustomerID ORDER BY OrderDate)
        THEN 'Increasing Frequency'
        ELSE 'Decreasing Frequency'
    END AS Trend
FROM OrderGaps
WHERE GapDays IS NOT NULL;
```
</details>

---

## 📋 Summary

- **Value Functions** access values from other rows → enabling powerful comparisons
- **`LAG`** = previous row · **`LEAD`** = next row · **`FIRST_VALUE`** = first in window · **`LAST_VALUE`** = last in window
- **All require `ORDER BY`**
- **`LAST_VALUE` is the only function that needs a custom frame clause** to work correctly
- Top use cases: **MoM/YoY analysis**, **customer retention**, **comparing to extremes**
- Often, `FIRST_VALUE` (with reversed ORDER) or `MAX`/`MIN` is cleaner than `LAST_VALUE`

---

## 🔗 Related Topics

- [`14_Window_Functions_Basics`](../14_Window_Functions_Basics/) — Foundation concepts
- [`15_Window_Aggregations`](../15_Window_Aggregations/) — SUM, AVG, COUNT over windows
- [`16_Window_Ranking`](../16_Window_Ranking/) — ROW_NUMBER, RANK, DENSE_RANK
- [`13_Aggregate_Functions`](../13_Aggregate_Functions/) — GROUP BY aggregates

---

> 💬 *"Window value functions turn complex multi-row analyses into a single, elegant query — they're the secret weapon of every data analyst."*

**[⬆ Back to Main Index](../README.md)**