/* ============================================================================== 
   SQL STORED PROCEDURES PRACTICE
   Focus: Parameters, Variables, Control Flow, and Error Handling
===============================================================================*/

/* ------------------------------------------------------------------------------
   MASTER STORED PROCEDURE
   This procedure demonstrates cleaning data, using variables, and 
   gracefully handling mathematical errors.
------------------------------------------------------------------------------ */

CREATE OR ALTER PROCEDURE GetCustomerSummary 
    @Country NVARCHAR(50) = 'USA' -- Default parameter set to USA
AS
BEGIN
    -- 1. ERROR HANDLING: Start the TRY block
    BEGIN TRY
        
        -- 2. VARIABLES: Declare storage for our message outputs
        DECLARE @TotalCustomers INT;
        DECLARE @AvgScore FLOAT;      

        /* ----------------------------------------------------------------------
           PHASE 1: DATA AUDIT & CLEANUP (Control Flow)
        ---------------------------------------------------------------------- */
        IF EXISTS (SELECT 1 FROM Sales.Customers WHERE Score IS NULL AND Country = @Country)
        BEGIN
            PRINT('Notice: Updating NULL Scores to 0 for ' + @Country);
            
            UPDATE Sales.Customers
            SET Score = 0
            WHERE Score IS NULL AND Country = @Country;
        END
        ELSE
        BEGIN
            PRINT('Notice: Data is clean. No NULL Scores found for ' + @Country);
        END;

        /* ----------------------------------------------------------------------
           PHASE 2: VARIABLE ASSIGNMENT & MESSAGING
        ---------------------------------------------------------------------- */
        SELECT
            @TotalCustomers = COUNT(*),
            @AvgScore = AVG(Score)
        FROM Sales.Customers
        WHERE Country = @Country;

        -- Print customized messages to the console
        PRINT('Total Customers from ' + @Country + ': ' + CAST(@TotalCustomers AS NVARCHAR));
        PRINT('Average Score from ' + @Country + ': ' + CAST(@AvgScore AS NVARCHAR));

        /* ----------------------------------------------------------------------
           PHASE 3: FINAL DATA EXTRACTION (With intentional error for demo)
        ---------------------------------------------------------------------- */
        SELECT
            COUNT(OrderID) AS TotalOrders,
            SUM(Sales) AS TotalSales,
            1/0 AS FaultyCalculation  -- Intentional Divide-by-Zero error to trigger CATCH
        FROM Sales.Orders AS o
        JOIN Sales.Customers AS c
            ON c.CustomerID = o.CustomerID
        WHERE c.Country = @Country;

    END TRY
    
    -- 3. ERROR HANDLING: The CATCH block (Executes if anything above fails)
    BEGIN CATCH
        /* ----------------------------------------------------------------------
           PHASE 4: ERROR LOGGING
        ---------------------------------------------------------------------- */
        PRINT('----- AN ERROR OCCURRED -----');
        PRINT('Error Message: ' + ERROR_MESSAGE());
        PRINT('Error Number: ' + CAST(ERROR_NUMBER() AS NVARCHAR));
        PRINT('Error Severity: ' + CAST(ERROR_SEVERITY() AS NVARCHAR));
        PRINT('Error State: ' + CAST(ERROR_STATE() AS NVARCHAR));
        PRINT('Error Line: ' + CAST(ERROR_LINE() AS NVARCHAR));
        PRINT('Error Procedure: ' + ISNULL(ERROR_PROCEDURE(), 'N/A'));
        PRINT('-----------------------------');
    END CATCH;
END
GO

/* ============================================================================== 
   EXECUTION EXAMPLES
===============================================================================*/

-- Execute using a specific parameter
EXEC GetCustomerSummary @Country = 'Germany';

-- Execute using the default parameter ('USA')
EXEC GetCustomerSummary;