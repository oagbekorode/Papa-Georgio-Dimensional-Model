# Papa Georgio’s Pizzeria: Analytical Data Warehouse Design

## 1. Project Overview
This project involves designing a comprehensive dimensional model for **Papa Georgio’s Pizzeria**, a nationwide franchise operating across multiple locations and sales channels. The goal is to build a centralized analytical data warehouse that enables leadership to perform strategic, operational, and customer-focused analyses.

---

## 2. Business Analysis Use Cases
The model is engineered to support the following business processes:

- **Sales Performance:** Analyzing total revenue and quantity sold by store, region, and channel.  
- **Customer Behavior:** Identifying high-revenue groups, loyalty tier profitability, and demographic responses.  
- **Promotion Effectiveness:** Evaluating how holiday promotions and localized coupons affect revenue and volume.  
- **Operational Efficiency:** Tracking order fulfillment times from placement to delivery and monitoring employee productivity.  

---

## 3. Team Roles & Module Distribution
To ensure a decoupled workflow, the project is split into three independent modules. Each member is responsible for their specific schema files and documentation.

| Student   | Module                  | Key Deliverables & Requirements |
|-----------|------------------------|--------------------------------|
| Student 1 | Revenue & Marketing    | Atomic Transaction Fact, Snowflake Product Hierarchy, and Promotion (Why) Dimension |
| Student 2 | Fulfillment & CRM      | Accumulating Snapshot Fact, SCD Type 2 Customer Tracking, and Role-Playing Date Dimensions |
| Student 3 | Operations & HR        | Periodic Snapshot Fact, SCD Type 1 Employee Dimension, and Bridge Tables for hierarchies |

---

## 4. Technical Specifications
The design adheres to the following dimensional modeling standards:

- **Dimensions:** Inclusion of all "Five Ws" (Who, What, When, Where, Why).  
- **Hierarchies:** Support for balanced/unbalanced hierarchies in Product and Location.  
- **Measures:** Implementation of additive, semi-additive, and non-additive metrics.  
- **Schema:** Integration of both Star and Snowflake structures.  

---

## 5. GitHub Workflow
To maintain independent development until the final deliverable date:

- **Branching:** Each student works on a dedicated feature branch (`feature-sales`, `feature-ops`, `feature-hr`).  
- **Directories:** Keep SQL scripts in separate folders to avoid merge conflicts.  
- **Integration:** Pull Requests will be merged into `main` only after local verification of the individual sub-models.  
