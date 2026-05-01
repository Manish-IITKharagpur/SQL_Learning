/* ==============================================================================
   SQL WINDOW VALUE FUNCTIONS (Analytical Functions)
================================================================================
   Description : Window Value Functions allow you to access values from OTHER 
                 rows within a window — without using JOINs or subqueries.
                 They are the most important window functions for analytics.
   
   Functions Covered:
     1. LAG          → Access value from a PREVIOUS row
     2. LEAD         → Access value from a NEXT row
     3. FIRST_VALUE  → Access value from the FIRST row in window
     4. LAST_VALUE   → Access value from the LAST row in window
   
   Key Rules:
     - ORDER BY is REQUIRED for all value functions
     - PARTITION BY is OPTIONAL
     - LAG/LEAD do NOT allow frame clause
     - LAST_VALUE REQUIRES a custom frame clause to work correctly
================================================================================
*/


/* ==============================================================================
   PART 1: LEAD & LAG — TIME-SERIES ANALYSIS
================================================================================
*/

/* ------------------------------------------------------------------------------
   TASK 1: Month-over-Month (MoM) Performance Analysis
   ------------------------------------------------------------------------------
   Goal: Find the % change in sales between current month and previous month.
   
   Approach:
     Step 1 → Aggregate sales by month
     Step 2 → Use LAG() to get previous month's sales in the same row
     Step 3 → Calculate the difference and percentage change
   ----------------------------------------------------------------------------- */

SELECT
    *,
    -- Absolute change (positive = growth, negative = decline)
    CurrentMonthSales - PreviousMonthSales AS MoM_Change,
    
    -- Percentage change (CAST as FLOAT to avoid integer division)
    ROUND(
        CAST((CurrentMonthSales - PreviousMonthSales) AS FLOAT)
        / PreviousMonthSales * 100, 1
    ) AS MoM_Perc
FROM (
    SELECT
        MONTH(OrderDate) AS OrderMonth,
        SUM(Sales) AS CurrentMonthSales,
        
        -- LAG() pulls the previous row's SUM(Sales) into the current row
        LAG(SUM(Sales)) OVER (ORDER BY MONTH(OrderDate)) AS PreviousMonthSales
    FROM Sales.Orders
    GROUP BY MONTH(OrderDate)
) AS MonthlySales;

/* Expected Output:
   OrderMonth | CurrentMonthSales | PreviousMonthSales | MoM_Change | MoM_Perc
   -----------|-------------------|--------------------|------------|---------
       1      |       105         |       NULL         |   NULL     |  NULL
       2      |       195         |       105          |   +90      |  +85.7%
       3      |        80         |       195          |   -115     |  -59.0%
*/


/* ------------------------------------------------------------------------------
   TASK 2: Customer Retention Analysis
   ------------------------------------------------------------------------------
   Goal: Rank customers based on the AVERAGE days between their orders.
         Lower average = more loyal customer (orders more frequently).
   
   Approach:
     Step 1 → Use LEAD() to get each customer's next order date
     Step 2 → Calculate days between current and next order using DATEDIFF
     Step 3 → Average those gaps per customer
     Step 4 → Rank customers (handle NULL for one-time customers)
   ----------------------------------------------------------------------------- */

SELECT
    CustomerID,
    AVG(DaysUntilNextOrder) AS AvgDays,
    
    -- COALESCE pushes one-time customers (NULL avg) to the bottom of the rank
    RANK() OVER (
        ORDER BY COALESCE(AVG(DaysUntilNextOrder), 999999)
    ) AS RankAvg
FROM (
    SELECT
        OrderID,
        CustomerID,
        OrderDate AS CurrentOrder,
        
        -- Get the next order date for the same customer
        LEAD(OrderDate) OVER (
            PARTITION BY CustomerID 
            ORDER BY OrderDate
        ) AS NextOrder,
        
        -- Calculate the gap in days between current and next order
        DATEDIFF(
            day,
            OrderDate,
            LEAD(OrderDate) OVER (
                PARTITION BY CustomerID 
                ORDER BY OrderDate
            )
        ) AS DaysUntilNextOrder
    FROM Sales.Orders
) AS CustomerOrdersWithNext
GROUP BY CustomerID;

/* Insight: Customers with the lowest average gap are your most loyal customers.
   Focus marketing/retention efforts on them.
*/


/* ------------------------------------------------------------------------------
   BONUS: Using OFFSET and DEFAULT with LAG/LEAD
   ------------------------------------------------------------------------------
   Syntax: LEAD(expression, offset, default_value)
     - offset       : How many rows to jump (default = 1)
     - default_value: Value returned when no row is found (default = NULL)
   ----------------------------------------------------------------------------- */

-- Example: Get sales 2 months ahead, return 0 if no data
SELECT
    MONTH(OrderDate) AS OrderMonth,
    SUM(Sales) AS CurrentSales,
    LEAD(SUM(Sales), 2, 0) OVER (ORDER BY MONTH(OrderDate)) AS SalesIn2Months,
    LAG(SUM(Sales), 2, 0) OVER (ORDER BY MONTH(OrderDate)) AS Sales2MonthsAgo
FROM Sales.Orders
GROUP BY MONTH(OrderDate);


/* ==============================================================================
   PART 2: FIRST_VALUE & LAST_VALUE — COMPARISON WITH EXTREMES
================================================================================
*/

/* ------------------------------------------------------------------------------
   TASK 3: Find Lowest & Highest Sales for Each Product
   ------------------------------------------------------------------------------
   Goal: For each product, find:
         - The lowest sales (using FIRST_VALUE)
         - The highest sales (using LAST_VALUE with custom frame)
         - The difference between current sales and lowest sales
   
   ⚠️ IMPORTANT: LAST_VALUE requires a custom frame clause:
      ROWS BETWEEN CURRENT ROW AND UNBOUNDED FOLLOWING
   Otherwise, it returns the current row instead of the actual last row.
   ----------------------------------------------------------------------------- */

SELECT
    OrderID,
    ProductID,
    Sales,
    
    -- FIRST_VALUE works correctly with default frame
    FIRST_VALUE(Sales) OVER (
        PARTITION BY ProductID 
        ORDER BY Sales
    ) AS LowestSales,
    
    -- LAST_VALUE NEEDS a custom frame to work as expected
    LAST_VALUE(Sales) OVER (
        PARTITION BY ProductID 
        ORDER BY Sales 
        ROWS BETWEEN CURRENT ROW AND UNBOUNDED FOLLOWING
    ) AS HighestSales,
    
    -- Compare current sales to the lowest sales
    Sales - FIRST_VALUE(Sales) OVER (
        PARTITION BY ProductID 
        ORDER BY Sales
    ) AS SalesDifference
FROM Sales.Orders;


/* ------------------------------------------------------------------------------
   ALTERNATIVE APPROACHES: 3 Ways to Get the Highest Sales
   ----------------------------------------------------------------------------- */

-- ✅ Approach 1: LAST_VALUE (requires custom frame)
SELECT
    OrderID,
    ProductID,
    Sales,
    LAST_VALUE(Sales) OVER (
        PARTITION BY ProductID 
        ORDER BY Sales 
        ROWS BETWEEN CURRENT ROW AND UNBOUNDED FOLLOWING
    ) AS HighestSales
FROM Sales.Orders;


-- ⭐ Approach 2: FIRST_VALUE with reversed ORDER BY (cleaner!)
SELECT
    OrderID,
    ProductID,
    Sales,
    FIRST_VALUE(Sales) OVER (
        PARTITION BY ProductID 
        ORDER BY Sales DESC
    ) AS HighestSales
FROM Sales.Orders;


-- ⭐ Approach 3: MAX() as a window function (simplest!)
SELECT
    OrderID,
    ProductID,
    Sales,
    MAX(Sales) OVER (PARTITION BY ProductID) AS HighestSales,
    MIN(Sales) OVER (PARTITION BY ProductID) AS LowestSales
FROM Sales.Orders;


/* ==============================================================================
   QUICK REFERENCE: SYNTAX SUMMARY
================================================================================

   LAG(expression [, offset [, default]]) OVER (
       [PARTITION BY column]
       ORDER BY column                    -- REQUIRED
   )

   LEAD(expression [, offset [, default]]) OVER (
       [PARTITION BY column]
       ORDER BY column                    -- REQUIRED
   )

   FIRST_VALUE(expression) OVER (
       [PARTITION BY column]
       ORDER BY column                    -- REQUIRED
       [ROWS BETWEEN ... AND ...]         -- Optional
   )

   LAST_VALUE(expression) OVER (
       [PARTITION BY column]
       ORDER BY column                    -- REQUIRED
       ROWS BETWEEN CURRENT ROW AND       -- ⚠️ REQUIRED for correct results
                    UNBOUNDED FOLLOWING
   )

================================================================================
   END OF FILE
================================================================================
*/