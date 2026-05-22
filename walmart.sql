-- AUTHOR		   : Hilmy Septian Nursyekha
-- PROJECT GOAL    : Build a Clean Data Warehouse Foundation for Demand Forecasting.
-- DISCIPLINE      : Data Engineering & Dimensional Modeling
-- DESCRIPTION     : Consolidates historical sales with macroeconomic features and store
--                   metadata. Enforces strict ISO date formatting to eliminate hidden 
--                   timestamp pollution that breaks Power BI evaluation contexts.

CREATE TABLE train AS 
SELECT * FROM read_csv_auto('E:/Data Analysis/Walmart1/train.csv', nullstr='NA');

CREATE TABLE test AS 
SELECT * FROM read_csv_auto('E:/Data Analysis/Walmart1/test.csv', nullstr='NA');

CREATE TABLE stores AS 
SELECT * FROM read_csv_auto('E:/Data Analysis/Walmart1/stores.csv', nullstr='NA');

CREATE TABLE features AS 
SELECT * FROM read_csv_auto('E:/Data Analysis/Walmart1/features.csv', nullstr='NA', columns={
    'Store': 'INTEGER', 
    'Date': 'DATE', 
    'Temperature': 'DOUBLE', 
    'Fuel_Price': 'DOUBLE', 
    'MarkDown1': 'DOUBLE', 
    'MarkDown2': 'DOUBLE', 
    'MarkDown3': 'DOUBLE', 
    'MarkDown4': 'DOUBLE', 
    'MarkDown5': 'DOUBLE', 
    'CPI': 'DOUBLE', 
    'Unemployment': 'DOUBLE', 
    'IsHoliday': 'BOOLEAN'
});


SELECT * FROM information_schema.tables WHERE table_name IN ('train', 'test', 'stores', 'features');
SELECT Date FROM features LIMIT 5;

CREATE TABLE walmart_final_train AS
SELECT 
    t.Store,
    t.Dept,
    
    -- 1. TIME SERIES STANDARDIZATION & ANTI-POLLUTION GUARD
    -- Forces the raw date string into a strict, clean ISO format ('YYYY-MM-DD').
    -- Truncates hidden microsecond anomalies and '12:00:00 AM' strings that cause
    -- relational cross-join explosions and artificial data inflation in the BI layer.
    strftime(CAST(t.Date AS DATE), '%Y-%m-%d') AS Transaction_Date,
    
    -- 2. METRIC TRACKING
    -- Target variable for the FB Prophet machine learning forecasting pipeline.
    t.Weekly_Sales,
    
    -- 3. EXOGENOUS REGRESSORS & FEATURES
    -- Categorical flags and numeric indicators used for holiday effect analysis.
    t.IsHoliday,
    s.Type AS Store_Type,
    s.Size AS Store_Size,
    f.Temperature,
    f.Fuel_Price,
    f.CPI,
    f.Unemployment,
    
    -- 4. PROMOTIONAL INSIGHTS & NULL HANDLING
    -- Converts missing promotional data into absolute numerical zeros (0.0).
    -- Prevents algorithmic failures in Python Pandas and calculation dropouts in DAX.
    COALESCE(CAST(f.MarkDown1 AS DOUBLE), CAST(0.0 AS DOUBLE)) AS MarkDown1,
    COALESCE(CAST(f.MarkDown2 AS DOUBLE), CAST(0.0 AS DOUBLE)) AS MarkDown2,
    COALESCE(CAST(f.MarkDown3 AS DOUBLE), CAST(0.0 AS DOUBLE)) AS MarkDown3,
    COALESCE(CAST(f.MarkDown4 AS DOUBLE), CAST(0.0 AS DOUBLE)) AS MarkDown4,
    COALESCE(CAST(f.MarkDown5 AS DOUBLE), CAST(0.0 AS DOUBLE)) AS MarkDown5
    
FROM train t

-- 5. RELATIONAL INTEGRITY JOIN
-- Connects the core sales fact table to dimension tables. 
-- Uses LEFT JOIN to preserve all transaction records even if external features are lagging.
LEFT JOIN stores s 
    ON t.Store = s.Store
LEFT JOIN features f 
    -- Kritis: Pastikan join juga menggunakan casting yang sama agar tidak meleset
    ON t.Store = f.Store AND CAST(t.Date AS DATE) = CAST(f.Date AS DATE)

-- 6. FORECAST PIPELINE PREPARATION
-- Strictly orders the data chronologically per Store-Department hierarchy.
-- Essential for windows functions and rolling-window training in FB Prophet.
    ORDER BY t.Store, t.Dept, Transaction_Date ASC;


-- AUDIT CHECK 1: GLOBAL METRIC RECONCILIATION
-- Purpose: Captures high-level macro metrics (row counts, absolute volume, and time scope).
-- Goal   : This serves as the financial baseline. The 'total_penjualan_global' must 
--          perfectly match the baseline sum before and after any ETL/BI transformation.
SELECT 
    COUNT(*) AS total_data_rows,
    SUM(Weekly_Sales) AS total_global_sales,
    MIN(Transaction_Date) AS earliest_transaction_date,
    MAX(Transaction_Date) AS latest_transaction_date
FROM walmart_final_train;


-- AUDIT CHECK 2: ANCHOR COORDINATE GROUND TRUTH VERIFICATION
-- Purpose: Slices a specific high-volume coordinate (Store 1, Dept 1, Holiday Peak Date).
-- Goal   : Validates the micro-level data behavior. The exact result here acts as the 
--          mathematical anchor to expose data inflation bugs (such as the $479M bug) 
--          occurring downstream in the Power BI dashboard layers.
SELECT 
    Store,
    Dept,
    Transaction_Date,
    Weekly_Sales
FROM walmart_final_train
WHERE Store = 1 
  AND Dept = 1 
  AND Transaction_Date = '2010-12-24';


-- AUDIT CHECK 3: GRANULARITY & PRIMARY KEY INTEGRITY CHECK
-- Purpose: Scans for duplicate entries on the unique composite key grain 
--          (Store + Dept + Transaction_Date).
-- Goal   : Proactively detects Cartesian multiplication risks. If this query returns 
--          even a single row, it indicates an upstream data ingestion failure that 
--          will artificially explode sales sums and corrupt time-series forecasting.
SELECT 
    Store,
    Dept,
    Transaction_Date,
    COUNT(*) AS jumlah_duplikasi
FROM walmart_final_train
GROUP BY Store, Dept, Transaction_Date
HAVING COUNT(*) > 1;