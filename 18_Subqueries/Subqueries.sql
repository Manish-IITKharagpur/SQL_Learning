
/* ==============================================================================
   SQL SUBQUERIES
================================================================================
   Description : A subquery is a query inside another query.
                 The subquery (inner query) supports the main query (outer query)
                 by preparing intermediate results — not visible in final output.
   
   Categories Covered:
     1. Result Types         → Scalar, Row, Table
     2. FROM Clause          → Temporary result set as a table
     3. SELECT Clause        → Scalar subquery as a column
     4. JOIN Clause          → Prepare data before joining
     5. WHERE + Comparison   → Filter with a single value
     6. WHERE + IN / NOT IN  → Filter with a list of values
     7. WHERE + ANY / ALL    → Comparative filtering against a list
     8. Correlated Subquery  → Row-by-row dependency on main query
     9. EXISTS / NOT EXISTS  → Test existence of rows in another table
   
   Key Rules:
     - Subquery in SELECT   → Must be SCALAR (1 row, 1 column)
     - Subquery in FROM     → Must have an ALIAS (required in SQL Server)
     - Subquery in WHERE    → Can be scalar (comparison) or row (IN/ANY/ALL)
     - EXISTS subquery      → Always use SELECT 1 (best practice)
================================================================================
*/


/* ==============================================================================
   PART 1: RESULT TYPES
   ============================================================================== 
   Subqueries return different amounts of data. Understanding which type
   is returned determines WHERE you can use the subquery.
*/

-- SCALAR SUBQUERY → Returns 1 row, 1 column (single value)
SELECT AVG(Sales) FROM Sales.Orders;

-- ROW SUBQUERY → Returns multiple rows, 1 column (a list of values)
SELECT CustomerID FROM Sales.Orders;

-- TABLE SUBQUERY → Returns multiple rows, multiple columns
SELECT OrderID, OrderDate FROM Sales.Orders;


/* ==============================================================================
   PART 2: SUBQUERY IN FROM CLAUSE
   ==============================================================================
   Purpose: Create a temporary result set that acts as a table for the main query.
   Use when: You need to prepare/aggregate data BEFORE applying further logic.
   Alias: REQUIRED in SQL Server for any subquery in FROM clause.
*/

/* TASK 1:
   Find the products that have a price higher than the average price of all products.
   
   Steps:
     Step 1 (Subquery)  → Calculate each product's price alongside the average
     Step 2 (Main Query) → Filter only products where price > average
*/
SELECT *
FROM (
    -- Subquery: prepare products with average price side by side
    SELECT
        ProductID,
        Price,
        AVG(Price) OVER () AS AvgPrice   -- Window function: avg across all rows
    FROM Sales.Products
) AS t                                    -- Alias required in SQL Server
WHERE Price > AvgPrice;                   -- Filter happens in main query


/* TASK 2:
   Rank customers based on their total amount of sales.
   
   Steps:
     Step 1 (Subquery)  → Aggregate total sales per customer
     Step 2 (Main Query) → Apply RANK() window function on top of aggregated data
   
   Note: RANK() cannot be applied directly on GROUP BY results — subquery solves this!
*/
SELECT
    *,
    RANK() OVER (ORDER BY TotalSales DESC) AS CustomerRank
FROM (
    -- Subquery: aggregate total sales per customer
    SELECT
        CustomerID,
        SUM(Sales) AS TotalSales
    FROM Sales.Orders
    GROUP BY CustomerID
) AS t;


/* ==============================================================================
   PART 3: SUBQUERY IN SELECT CLAUSE
   ==============================================================================
   Purpose: Add an aggregated or calculated value as a column next to row-level data.
   Rule: MUST be a SCALAR subquery (returns exactly 1 value).
         Using a subquery that returns multiple rows will throw an error.
*/

/* TASK 3:
   Show product IDs, product names, prices, and the total number of orders.
   
   Note: Total orders come from the Orders table — different from Products.
         A scalar subquery lets us add this cross-table aggregate as a column.
*/
SELECT
    ProductID,
    Product,
    Price,
    -- Scalar subquery: returns exactly 1 value (total order count)
    (SELECT COUNT(*) FROM Sales.Orders) AS TotalOrders
FROM Sales.Products;


/* ==============================================================================
   PART 4: SUBQUERY IN JOIN CLAUSE
   ==============================================================================
   Purpose: Prepare/aggregate data from one table before joining it with another.
   Use when: You need to join aggregated data (like totals) with detail data.
*/

/* TASK 4:
   Show customer details along with their total sales.
   
   Why LEFT JOIN? → To include customers with NO orders (like Anna with NULL sales).
*/
SELECT
    c.*,
    t.TotalSales
FROM Sales.Customers AS c
LEFT JOIN (
    -- Subquery: calculate total sales per customer
    SELECT
        CustomerID,
        SUM(Sales) AS TotalSales
    FROM Sales.Orders
    GROUP BY CustomerID
) AS t ON c.CustomerID = t.CustomerID;


/* TASK 5:
   Show all customer details and the total orders of each customer.
*/
SELECT
    c.*,
    o.TotalOrders
FROM Sales.Customers AS c
LEFT JOIN (
    -- Subquery: count total orders per customer
    SELECT
        CustomerID,
        COUNT(*) AS TotalOrders
    FROM Sales.Orders
    GROUP BY CustomerID
) AS o ON c.CustomerID = o.CustomerID;


/* ==============================================================================
   PART 5: SUBQUERY IN WHERE — COMPARISON OPERATORS
   ==============================================================================
   Purpose: Filter main query using a dynamically calculated single value.
   Rule: Subquery MUST return a scalar (1 row, 1 column).
   Operators: =  <>  >  <  >=  <=
*/

/* TASK 6:
   Find products with a price higher than the average price of all products.
   
   This solves the same problem as TASK 1 but using WHERE instead of FROM.
*/
SELECT
    ProductID,
    Price,
    (SELECT AVG(Price) FROM Sales.Products) AS AvgPrice  -- Show avg for reference
FROM Sales.Products
WHERE Price > (SELECT AVG(Price) FROM Sales.Products);   -- Scalar subquery filter


/* ==============================================================================
   PART 6: SUBQUERY IN WHERE — IN / NOT IN OPERATOR
   ==============================================================================
   Purpose: Filter rows where a column matches any value from a dynamically
            generated list (row subquery).
   Advantage over static values: Dynamic — auto-updates when data changes.
*/

/* TASK 7:
   Show the details of orders made by customers in Germany.
   
   Why subquery > static values?
   Static:   WHERE CustomerID IN (1, 4)      ← Breaks when new German customers are added
   Dynamic:  WHERE CustomerID IN (subquery)  ← Always reflects current data
*/
SELECT *
FROM Sales.Orders
WHERE CustomerID IN (
    -- Row subquery: returns list of customer IDs from Germany
    SELECT CustomerID
    FROM Sales.Customers
    WHERE Country = 'Germany'
);


/* TASK 8:
   Show the details of orders made by customers NOT in Germany.
*/
SELECT *
FROM Sales.Orders
WHERE CustomerID NOT IN (
    -- Same subquery, but NOT IN flips the logic
    SELECT CustomerID
    FROM Sales.Customers
    WHERE Country = 'Germany'
);


/* ==============================================================================
   PART 7: SUBQUERY IN WHERE — ANY / ALL OPERATORS
   ==============================================================================
   ANY → Condition must be true for AT LEAST ONE value in the list
   ALL → Condition must be true for EVERY value in the list
   
   Syntax: column operator ANY/ALL (subquery)
*/

/* TASK 9:
   Find female employees whose salaries are greater than the salaries
   of ANY male employee (at least one male salary).
*/
SELECT
    EmployeeID,
    FirstName,
    Salary
FROM Sales.Employees
WHERE Gender = 'F'
  AND Salary > ANY (
      -- Row subquery: list of all male salaries
      SELECT Salary
      FROM Sales.Employees
      WHERE Gender = 'M'
  );

-- Using ALL instead: salary must be greater than EVERY male salary (more restrictive)
-- In this dataset, no female earns more than ALL males → returns empty result
SELECT
    EmployeeID,
    FirstName,
    Salary
FROM Sales.Employees
WHERE Gender = 'F'
  AND Salary > ALL (
      SELECT Salary
      FROM Sales.Employees
      WHERE Gender = 'M'
  );


/* ==============================================================================
   PART 8: CORRELATED SUBQUERY
   ==============================================================================
   A correlated subquery DEPENDS on the main (outer) query.
   It references a column from the outer query → cannot run independently.
   It executes ONCE PER ROW of the main query (like a loop).
   
   Non-Correlated: Subquery runs once → result passed to main query
   Correlated:     Main query passes each row → subquery runs for each row
*/

/* TASK 10:
   Show all customer details and the total orders for each customer
   using a correlated subquery.
   
   How it works:
     - For customer c.CustomerID = 1 → count orders WHERE CustomerID = 1
     - For customer c.CustomerID = 2 → count orders WHERE CustomerID = 2
     - Repeats for every customer row
*/
SELECT
    *,
    -- Correlated subquery: references c.CustomerID from the outer query
    (SELECT COUNT(*)
     FROM Sales.Orders o
     WHERE o.CustomerID = c.CustomerID) AS TotalOrders   -- c. = outer query table
FROM Sales.Customers AS c;


/* ==============================================================================
   PART 9: SUBQUERY WITH EXISTS / NOT EXISTS
   ==============================================================================
   EXISTS: Returns TRUE if the subquery returns ANY rows → row is included
   NOT EXISTS: Returns TRUE if the subquery returns NO rows → row is included
   
   Always use SELECT 1 inside EXISTS (best practice):
     - SQL only checks IF rows exist, not WHAT they contain
     - SELECT 1 is faster than SELECT * or SELECT column
   
   EXISTS is always a CORRELATED subquery → linked to main query via WHERE.
*/

/* TASK 11:
   Show the details of orders made by customers in Germany.
*/
SELECT *
FROM Sales.Orders AS o
WHERE EXISTS (
    SELECT 1                            -- We only care IF rows exist, not the value
    FROM Sales.Customers AS c
    WHERE Country = 'Germany'
      AND o.CustomerID = c.CustomerID  -- Link to main query (makes it correlated)
);


/* TASK 12:
   Show the details of orders made by customers NOT in Germany.
*/
SELECT *
FROM Sales.Orders AS o
WHERE NOT EXISTS (
    SELECT 1
    FROM Sales.Customers AS c
    WHERE Country = 'Germany'
      AND o.CustomerID = c.CustomerID
);


/* ==============================================================================
   QUICK REFERENCE: SUBQUERY RULES SUMMARY
================================================================================

   LOCATION         | RESULT TYPE ALLOWED  | NOTES
   -----------------|----------------------|-----------------------------
   SELECT clause    | Scalar only          | Must return 1 row, 1 column
   FROM clause      | Scalar/Row/Table     | Must have alias in SQL Server
   JOIN clause      | Scalar/Row/Table     | Must have alias in SQL Server
   WHERE + =,>,<    | Scalar only          | Single value comparison
   WHERE + IN       | Row (list)           | Multi-value list
   WHERE + ANY/ALL  | Row (list)           | Comparative against list
   WHERE + EXISTS   | Any (just checks)    | Use SELECT 1, always correlated

================================================================================
   CORRELATED vs NON-CORRELATED
================================================================================

   Feature          | Non-Correlated           | Correlated
   -----------------|--------------------------|---------------------------
   Dependency       | Independent              | Depends on main query
   Executes         | Once                     | Once per row
   Run standalone?  | Yes                      | No
   Performance      | Faster                   | Slower
   Use case         | Static filtering         | Row-by-row comparison

================================================================================
   END OF FILE
================================================================================
*/
