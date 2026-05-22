# Enterprise Demand Forecasting Engine & Star Schema Optimization

[![Tech Stack](https://img.shields.io/badge/Tech%20Stack-SQL%20%7C%20Python%20%7C%20Power%20BI-blue)](https://github.com/hilmy1509/walmart-forecasting)

## 📌 Executive Summary & Business Impact
This project builds a large-scale demand forecasting system using **FB Prophet** to predict weekly sales of Walmart departments for the next 12 weeks.

**Core Achievement:** Successfully resolved a critical *Data Architecture Defect* at the Business Intelligence (Power BI) level, which caused a **148x Cartesian data explosion** (value distortion from \$3.22 Million to \$479 Million). Through restructuring to *Star Schema* and enforcing *DAX Evaluation Context*, the system was successfully cured with 100% accuracy from upstream to downstream according to Python's absolute truth (*Ground Truth*) value of **$3,219,405.18**.


## 🏗️ System Architecture
This system uses a three-stage data pipeline architecture (*data pipeline*):
1. **Data Warehouse & Cleansing (SQL):** Standardization of ISO date format `YYYY-MM-DD` and elimination of database microsecond pollution.
2. **Predictive Engine (Python & FB Prophet):** Automatic time series modeling with ruthless cutting of *In-Sample Data Pollution* to produce pure future forecasts (*Out-of-Sample*).
3. **Dimensional Modeling (Power BI):** Transformation from *Flat Table* to *Star Schema* using independent dimension tables (`Dim_Store`, `Dim_Dept`) via Power Query & defensive DAX safety net.


## 🚀 Repository Directory Structure
* `/sql`: Database optimization queries and feature consolidation (*feature consolidation*).
* `/python`: Prophet modeling automation pipeline and Jupyter memory cleanup.
* `/powerbi`: Composite DAX formula documentation and valid dashboard screenshots.
* `ARCHITECTURE.md`: Deep forensic analysis of data regarding resolution of $479M bug.
