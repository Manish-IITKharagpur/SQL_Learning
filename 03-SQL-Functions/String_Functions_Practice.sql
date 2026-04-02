/* ============================================================================== 
   SQL STRING FUNCTIONS PRACTICE
   Focus: Data Cleaning, Text Manipulation, and Formatting
===============================================================================*/

/* ------------------------------------------------------------------------------
   1. STRING MANIPULATION
------------------------------------------------------------------------------ */

-- CONCAT: Combine data for reporting
-- Use Case: Generating a full location identifier
SELECT 
    CONCAT(first_name, '-', country) AS full_info
FROM customers;

-- LOWER / UPPER: Standardize casing
-- Use Case: Preparing data for case-insensitive matching
SELECT 
    first_name,
    LOWER(first_name) AS lower_case_name,
    UPPER(first_name) AS upper_case_name
FROM customers;

-- REPLACE: Swap or remove characters
-- Use Case: Reformatting phone numbers or updating file extensions
SELECT
    '123-456-7890' AS original_phone,
    REPLACE('123-456-7890', '-', '/') AS clean_phone,
    'report.txt' AS old_filename,
    REPLACE('report.txt', '.txt', '.csv') AS new_filename;

/* ------------------------------------------------------------------------------
   2. AUDITING & CALCULATIONS
------------------------------------------------------------------------------ */

-- LEN & TRIM: The Hidden Space Audit
-- Use Case: Identifying rows where users accidentally typed extra spaces
SELECT 
    first_name,
    LEN(first_name) AS raw_length,
    LEN(TRIM(first_name)) AS trimmed_length,
    (LEN(first_name) - LEN(TRIM(first_name))) AS spaces_removed_count
FROM customers
WHERE LEN(first_name) != LEN(TRIM(first_name)); -- Flags dirty data

/* ------------------------------------------------------------------------------
   3. SUBSTRING EXTRACTION
------------------------------------------------------------------------------ */

-- LEFT / RIGHT: Edge extraction
-- Use Case: Grabbing prefixes, suffixes, or masking data
SELECT 
    first_name,
    LEFT(TRIM(first_name), 2) AS first_2_chars,
    RIGHT(TRIM(first_name), 2) AS last_2_chars
FROM customers;

-- SUBSTRING: Precision extraction
-- Use Case: Removing a specific number of characters from the start/middle
-- Syntax: SUBSTRING(string, start_position, length)
SELECT 
    first_name,
    SUBSTRING(TRIM(first_name), 2, LEN(first_name)) AS trimmed_name_minus_first_char
FROM customers;

/* ------------------------------------------------------------------------------
   4. NESTING FUNCTIONS (Inside-Out Execution)
------------------------------------------------------------------------------ */

-- Use Case: Ensuring data is fully lowercase before applying other logic
SELECT
    first_name, 
    UPPER(LOWER(first_name)) AS standard_format
FROM customers;