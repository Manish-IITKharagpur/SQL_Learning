# 🔤 Module 03: String Functions & Data Cleaning

### 📌 Overview
Real-world data is rarely clean. Users add extra spaces, input lowercase names, and format phone numbers inconsistently. This module focuses on **Single-Row String Functions**, which are essential tools for data engineers and analysts to sanitize, format, and extract text data before analysis.

---

## 🚀 Strategic Use Cases for String Functions

### 1. Data Standardization (The Cleanup)
* **The Problem:** A user enters "   John   " instead of "John" in a web form. If you try to `INNER JOIN` this name with another table, the join will fail because of the hidden spaces.
* **The Solution:** Use `TRIM()`, `LOWER()`, and `UPPER()` to standardize text formats across the entire database, ensuring accurate joins and aggregations.

### 2. Data Transformation (The Format Shift)
* **The Problem:** Your system exports files with a `.txt` extension, but your ingestion pipeline requires `.csv` file names. Or, phone numbers are stored as `123-456-7890` but need to be `123/456/7890`.
* **The Solution:** Use the `REPLACE()` function to programmatically swap specific characters or strings without altering the underlying raw data architecture.

### 3. Data Extraction & Masking
* **The Problem:** You need to analyze sales by area code, but you only have the full 10-digit phone number.
* **The Solution:** Use `LEFT()`, `RIGHT()`, or `SUBSTRING()` to carve out the exact characters you need. This is also heavily used for PII (Personally Identifiable Information) masking, such as only showing the last 4 digits of a credit card.

---

## 🛠 The Core String Functions

### 1. Manipulation
* **`CONCAT(string1, string2)`:** Merges multiple columns or text strings into one (e.g., combining First Name and Last Name).
* **`LOWER()` / `UPPER()`:** Forces consistent casing.
* **`TRIM()`:** Removes leading and trailing white spaces.
* **`REPLACE(string, old_val, new_val)`:** Swaps out specific characters.

### 2. Calculation
* **`LEN()`:** Returns the total number of characters in a string. 

### 3. Extraction
* **`LEFT(string, count)`:** Grabs characters starting from the beginning.
* **`RIGHT(string, count)`:** Grabs characters starting from the end.
* **`SUBSTRING(string, start_position, length)`:** Extracts a specific chunk of text from anywhere within the string.

---

## 💡 Pro-Tip: The "Hidden Space" Audit
A common data auditing technique is to check if your database has "dirty" data with hidden spaces. You can find these problematic rows by comparing the raw length of a string to its trimmed length:
`WHERE LEN(first_name) != LEN(TRIM(first_name))`

## 🔄 Nesting Functions
String functions can be combined (nested). SQL evaluates them from the **inside out**. 
For example: `LEFT(TRIM(first_name), 2)` will first remove the spaces, and *then* grab the first two characters.