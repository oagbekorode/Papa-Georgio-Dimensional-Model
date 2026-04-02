# Papa Georgio’s Pizzeria: Data Warehouse Project

## Overview
This project designs a **Galaxy Schema** data warehouse for Papa Georgio’s Pizzeria.  
The system supports analysis of sales, customers, promotions, and operations across all locations.

To enable parallel development, the project is divided into independent modules that connect through **shared (conformed) dimensions** such as Date, Location, and Product.

---

## Team Task Allocation

Each student owns a specific business process and fact table type.

### Student 1 — Revenue & Marketing
**Focus:** Sales performance and promotions  

- **Fact Table:** Atomic Transaction (sales)  
- **Key Dimensions:**  
  - Product (Snowflake hierarchy)  
  - Promotion ("Why" dimension)  
  - Location (Region → State → Store)  
- **Metrics:** Revenue, Quantity Sold  

---

### Student 2 — Fulfillment & CRM
**Focus:** Order lifecycle and customer behavior  

- **Fact Table:** Accumulating Snapshot (order process)  
- **Key Dimensions:**  
  - Customer (SCD Type 2)  
  - Date (Role-playing: Order Date, Delivery Date)  
- **Special:** Bridge table for many-to-many relationships  

---

### Student 3 — Operations & HR
**Focus:** Staffing and operational efficiency  

- **Fact Table:** Periodic Snapshot (daily metrics)  
- **Key Dimensions:**  
  - Employee (SCD Type 1)  
  - Organization (unbalanced hierarchy)  
- **Special:** Different grain (daily summaries vs transactions)  

---

## Shared Design Principles

- **Galaxy Schema:** Multiple fact tables sharing dimensions  
- **Conformed Dimensions:** Date, Product, Location  
- **Measures:** Additive, semi-additive, and non-additive  
- **Schemas:** Combination of Star and Snowflake designs  

---

## Workflow


- Keep SQL files in separate folders  
- Merge into `main` after testing  

---

## Final Deliverable

- Combined SQL model (`main_model.sql`)  
- Unified ERD diagram  
- Fully integrated Galaxy Schema  
